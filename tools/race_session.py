#!/usr/bin/env python3
"""
race_session.py - drive two PR2 OpenFL clients through one real-server race.

Launches two headless Chrome instances against the live server (via dev_proxy
for the HTTP/CORS side; the gameserver WebSocket is reached directly). One logs
in as a real account, the other as a guest. Both navigate to the SAME campaign
level so the server places them in one race room, then each races, sees the
other as a synchronized remote player, quits, and returns to the lobby without a
page reload.

This is the live half of the "uninterrupted real-server session" acceptance: it
captures the level-entry, countdown, racing, and finish screenshots and asserts
that each client actually observes the other (data-pr2-remote-count >= 1). The
deterministic command/state transcript is covered separately by
RaceSessionTranscriptTest.

Usage (start tools/dev_proxy.py first, or pass its URL):

    python3 tools/dev_proxy.py --port 8123 &
    python3 tools/race_session.py \
        --base-url "http://localhost:8123/index.html?apiHost=/api" \
        --account testjun6 --password testjun6 \
        --out-dir test/output/race

The account credentials default to the shared test account used by the
Don't Move JV parity run.
"""

import argparse
import contextlib
import json
import os
import sys
import threading
import time
import traceback

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import openfl_driver as od


# Walks the live OpenFL display list (exposed as window.__pr2Stage by Main) and
# returns the on-stage center of the first object with the given instance name.
# Used to click authored buttons whose position shifts at runtime (the in-race
# CourseMenu Play button is placed beside whichever join slot the player filled,
# so its coordinates are not fixed). OpenFL HTML5 exposes children through the
# get_numChildren()/get_name() accessors, not plain properties.
_FIND_NAMED_JS = r"""
(function(name){
  var stage=window.__pr2Stage; if(!stage) return null;
  var found=null;
  function nm(o){try{return o.get_name?o.get_name():o.name;}catch(e){return null;}}
  function kc(o){try{return o.get_numChildren?o.get_numChildren():o.numChildren;}catch(e){return 0;}}
  function walk(o,d){
    if(!o||d>60||found) return;
    if(nm(o)===name){ try{var r=o.getBounds(stage); found={x:Math.round(r.x+r.width/2),y:Math.round(r.y+r.height/2)};}catch(e){} }
    var n=kc(o); for(var i=0;i<n&&!found;i++){try{walk(o.getChildAt(i),d+1);}catch(e){}}
  }
  walk(stage,0);
  return found?JSON.stringify(found):null;
})("%s")
"""


# ---------------------------------------------------------------------------
# Body-attribute / DevTools helpers
# ---------------------------------------------------------------------------

def body_attr(devtools, name):
    return devtools.evaluate(f'document.body.getAttribute("data-pr2-{name}") || ""')


def find_named(devtools, name):
    """Return {x, y} stage center of the named display object, or None."""
    raw = devtools.evaluate(_FIND_NAMED_JS % name)
    if raw in (None, "", "null"):
        return None
    try:
        return json.loads(raw)
    except (ValueError, TypeError):
        return None


def wait_named(devtools, name, timeout):
    return wait_until(f"display object {name}", lambda: find_named(devtools, name), timeout)


def wait_until(label, fn, timeout, interval=0.15):
    """Poll fn() until it returns a truthy value or timeout. Returns the value."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        value = fn()
        if value:
            return value
        time.sleep(interval)
    raise TimeoutError(f"timed out after {timeout:.0f}s waiting for {label}")


def wait_phase(devtools, targets, timeout):
    targets = set(targets)
    return wait_until(
        f"race-phase in {sorted(targets)}",
        lambda: (lambda p: p if p in targets else None)(body_attr(devtools, "race-phase")),
        timeout,
    )


def click(devtools, x, y):
    od.dispatch_click(devtools, x, y)


def type_text(devtools, text):
    devtools.request("Input.insertText", {"text": text})


def tap(devtools, key):
    od.dispatch_key(devtools, "keyDown", key)
    od.dispatch_key(devtools, "keyUp", key)


def shot(devtools, out_path):
    od.capture_devtools_shot(devtools, out_path)


# ---------------------------------------------------------------------------
# Login flows (each drives the authored login UI to the lobby)
# ---------------------------------------------------------------------------

def skip_intro(devtools):
    # Two clicks dismiss the Kongregate + Jiggmin intro animations; harmless
    # empty clicks if an intro is already gone.
    click(devtools, 275, 200)
    time.sleep(2.0)
    click(devtools, 275, 200)
    time.sleep(1.5)


def login_account(devtools, name, password):
    skip_intro(devtools)
    click(devtools, 275, 228)          # main menu: Log In
    time.sleep(1.0)
    click(devtools, 376, 178)          # '-' delete saved user (no-op on fresh form)
    time.sleep(1.0)
    click(devtools, 213, 253)          # confirm OK (harmless on empty area)
    time.sleep(0.5)
    click(devtools, 290, 135)          # focus name field
    time.sleep(0.3)
    type_text(devtools, name)
    time.sleep(0.4)
    click(devtools, 290, 163)          # focus pass field
    time.sleep(0.3)
    type_text(devtools, password)
    time.sleep(0.4)
    click(devtools, 232, 300)          # Log In (name/pass form)


def login_guest(devtools):
    skip_intro(devtools)
    click(devtools, 275, 250)          # main menu: Play as Guest
    time.sleep(1.2)
    click(devtools, 231, 251)          # server-select popup: Log In


def wait_for_lobby(devtools, timeout=40):
    page = wait_until(
        "lobby page",
        lambda: (lambda p: p if p.startswith("lobby:") else None)(body_attr(devtools, "page")),
        timeout,
    )
    return page


# ---------------------------------------------------------------------------
# Per-client race choreography
# ---------------------------------------------------------------------------

class ClientResult:
    def __init__(self, role):
        self.role = role
        self.error = None
        self.lobby_page = None
        self.remote_count_racing = None
        self.returned_to_lobby = False


def run_client(role, devtools, args, barriers, results):
    result = ClientResult(role)
    results[role] = result
    out = lambda name: os.path.join(args.out_dir, f"{role}-{name}.png")
    try:
        od.wait_for_app_ready(devtools)

        if role == "account":
            login_account(devtools, args.account, args.password)
        else:
            login_guest(devtools)
        result.lobby_page = wait_for_lobby(devtools)
        log(role, f"reached {result.lobby_page}")

        barriers["lobby"].wait(timeout=60)

        # Open the Campaign listing (it is the default tab, but click to be sure)
        click(devtools, args.campaign_tab_x, args.campaign_tab_y)
        time.sleep(1.5)

        # Both clients join the SAME top-left campaign tile, but each fills a
        # DISTINCT join slot (account -> slot 0, guest -> slot 1) so the server
        # puts them in one race room without colliding on the same slot. The
        # four slots stack 16px apart at x=258 (verified via the display list).
        slot_y = args.slot0_y if role == "account" else args.slot1_y
        barriers["select"].wait(timeout=30)
        click(devtools, args.slot_x, slot_y)
        # Filling our slot opens the CourseMenu beside it; its Play button is
        # placed relative to the slot, so locate it by name rather than guessing.
        play = wait_named(devtools, "play_bt", 12)
        shot(devtools, out("00-coursemenu"))
        click(devtools, play["x"], play["y"])
        log(role, f"filled slot y={slot_y:.0f}, clicked Play at {play['x']},{play['y']}")

        # Level entry: the GamePage mounts and the level draws.
        wait_phase(devtools, ["loading", "ready", "countdown", "racing"], 40)
        shot(devtools, out("01-level-entry"))
        log(role, "level entry")

        # Countdown (3-2-1). Brief; capture if we catch it.
        try:
            wait_phase(devtools, ["countdown"], 25)
            shot(devtools, out("02-countdown"))
            log(role, "countdown")
        except TimeoutError:
            log(role, "countdown not observed (already racing)")

        # Racing.
        wait_phase(devtools, ["racing"], 30)
        # Give the other client a moment to be registered as a remote, and emit
        # a few position frames, then drive a little movement.
        deadline = time.monotonic() + 8.0
        best = 0
        while time.monotonic() < deadline:
            try:
                best = max(best, int(body_attr(devtools, "remote-count") or "0"))
            except ValueError:
                pass
            if best >= 1:
                break
            time.sleep(0.25)
        result.remote_count_racing = best
        od.dispatch_key(devtools, "keyDown", "right")
        time.sleep(1.0)
        od.dispatch_key(devtools, "keyUp", "right")
        shot(devtools, out("03-racing"))
        log(role, f"racing, remote-count={best}")

        # Quit and return to the lobby without a reload.
        barriers["quit"].wait(timeout=30)
        click(devtools, args.quit_x, args.quit_y)   # in-race Quit button
        wait_phase(devtools, ["finished"], 15)
        shot(devtools, out("04-finished"))
        log(role, "finished page")

        click(devtools, args.return_x, args.return_y)   # Return to Lobby
        wait_until(
            "return to lobby",
            lambda: body_attr(devtools, "page").startswith("lobby:") and not body_attr(devtools, "race-phase"),
            20,
        )
        result.returned_to_lobby = True
        log(role, "returned to lobby")
    except Exception as error:  # noqa: BLE001 - reported per client
        result.error = error
        log(role, f"ERROR: {error}")
        traceback.print_exc()
        # Best-effort failure screenshot.
        with contextlib.suppress(Exception):
            shot(devtools, out("error"))
        # Release any barrier the other client may be waiting on so it can exit.
        for barrier in barriers.values():
            with contextlib.suppress(Exception):
                barrier.abort()


_log_lock = threading.Lock()


def log(role, message):
    with _log_lock:
        print(f"[{role:7}] {message}", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base-url", required=True, help="dev_proxy URL incl. ?apiHost=/api")
    parser.add_argument("--account", default="testjun6")
    parser.add_argument("--password", default="testjun6")
    parser.add_argument("--out-dir", default="test/output/race")
    parser.add_argument("--browser")
    parser.add_argument("--gpu", action="store_true")
    # Lobby UI coordinates (authored art is fixed, so these are stable).
    parser.add_argument("--campaign-tab-x", type=float, default=267)
    parser.add_argument("--campaign-tab-y", type=float, default=8)
    parser.add_argument("--slot-x", type=float, default=258)
    parser.add_argument("--slot0-y", type=float, default=61)
    parser.add_argument("--slot1-y", type=float, default=77)
    parser.add_argument("--quit-x", type=float, default=455)
    parser.add_argument("--quit-y", type=float, default=380)
    parser.add_argument("--return-x", type=float, default=330)
    parser.add_argument("--return-y", type=float, default=333)
    args = parser.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)
    browser = od.resolve_browser(args.browser)

    barriers = {
        "lobby": threading.Barrier(2),
        "select": threading.Barrier(2),
        "quit": threading.Barrier(2),
    }
    results = {}

    with contextlib.ExitStack() as stack:
        account_dt = stack.enter_context(od.browser_devtools_session(browser, args.base_url, args.gpu))
        guest_dt = stack.enter_context(od.browser_devtools_session(browser, args.base_url, args.gpu))

        threads = [
            threading.Thread(target=run_client, args=("account", account_dt, args, barriers, results)),
            threading.Thread(target=run_client, args=("guest", guest_dt, args, barriers, results)),
        ]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()

    print("\n=== Race session summary ===")
    ok = True
    for role in ("account", "guest"):
        result = results.get(role)
        if result is None:
            print(f"  {role}: no result"); ok = False; continue
        if result.error is not None:
            print(f"  {role}: FAILED ({result.error})"); ok = False; continue
        synced = (result.remote_count_racing or 0) >= 1
        print(f"  {role}: lobby={result.lobby_page} remoteCountRacing={result.remote_count_racing} "
              f"returnedToLobby={result.returned_to_lobby} synced={synced}")
        if not synced or not result.returned_to_lobby:
            ok = False

    if not ok:
        raise SystemExit("Race session did not meet the acceptance criteria.")
    print("Race session acceptance: PASS")


if __name__ == "__main__":
    main()
