import sys, time, contextlib
sys.path.insert(0, "tools")
import openfl_driver as d

ROOT = "export/html5/bin"
URL_QUERY = "screen=harness&hat=1&head=1&body=1&feet=1&render=composite"

# (label, headOffset, bodyOffset) in slot-local units (+ = down)
COMBOS = [
    ("base", 0, 0),
    ("h48", 48, 0),
    ("h55", 55, 0),
    ("h62", 62, 0),
    ("b48", 0, 48),
    ("b55", 0, 55),
    ("b62", 0, 62),
    ("both", 55, 55),
]

browser = d.resolve_browser(None)
with d.serve(ROOT) as url:
    full = d.append_query(url, URL_QUERY)
    with d.browser_devtools_session(browser, full) as dt:
        time.sleep(8.0)
        for label, ho, bo in COMBOS:
            dt.evaluate(f"window.__pr2cal_head={ho}; window.__pr2cal_body={bo}; true")
            time.sleep(0.5)
            d.capture_devtools_shot(dt, f"test/output/cal-{label}.png")
print("done")
