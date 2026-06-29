package pr2.app;

#if js
import js.Browser;
#end

/**
	Writes `data-pr2-*` attributes on the document body for harness observation.

	The Flash client already published a few of these ad hoc (`data-pr2-page`,
	`data-pr2-last-command`, `data-pr2-intro-state`); this centralizes the pattern
	so screens can report state to the OpenFL driver without scattering `#if js`
	blocks. On non-`js` targets every call is a no-op, so callers stay portable and
	deterministic tests can invoke them freely.
**/
class DebugSignal {
	private function new() {}

	/** Set `data-pr2-<name>` to `value` (no-op off the browser target). */
	public static function set(name:String, value:String):Void {
		#if js
		Browser.document.body.setAttribute("data-pr2-" + name, value);
		#end
	}

	/** Clear `data-pr2-<name>` (no-op off the browser target). */
	public static function clear(name:String):Void {
		#if js
		Browser.document.body.removeAttribute("data-pr2-" + name);
		#end
	}
}
