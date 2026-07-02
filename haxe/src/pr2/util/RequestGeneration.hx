package pr2.util;

/**
	A monotonic token for discarding stale async responses. Each `begin()` bumps
	the counter and returns the new token; a callback captured against an older
	token can tell it has been superseded (`isStale`) or atomically claim the
	right to run exactly once (`claim`).

	Two usage styles, both from the login flow:
	- server list fetch: capture `begin()`, then `if (gen.isStale(token)) return;`
	  in each callback (either branch may run, but only for the latest request).
	- account create: capture `begin()`, then `if (!gen.claim(token)) return;` in
	  each callback so only the first of the success/error/cancel callbacks to
	  fire proceeds and the rest see themselves as stale.

	`cancel()` invalidates the in-flight request without starting a new one (used
	by cancel buttons and teardown).
**/
class RequestGeneration {
	private var current:Int = 0;

	public function new() {}

	/** Start a new request, superseding any in-flight one; returns its token. */
	public function begin():Int {
		return ++current;
	}

	/** Invalidate the in-flight request without starting a new one. */
	public function cancel():Void {
		current++;
	}

	/** True when `token` is no longer the active request. */
	public function isStale(token:Int):Bool {
		return token != current;
	}

	/**
		Single-use latch: returns false if `token` is stale, otherwise bumps the
		counter (so sibling callbacks with the same token see themselves as stale)
		and returns true.
	**/
	public function claim(token:Int):Bool {
		if (token != current) {
			return false;
		}
		current++;
		return true;
	}
}
