# Live E2E Tests

These tests hit the live PR2 services and should not be run as part of the
normal local/unit test loop. They are slower, network-dependent, and may mutate
server-side login/session state for the dedicated test account.

Run explicitly from the repo root:

```sh
LIVE_PR2_E2E=1 haxe --library lime --library openfl -cp haxe/src -cp haxe/e2e --main pr2.e2e.LiveLoginE2ETest --interp
```
