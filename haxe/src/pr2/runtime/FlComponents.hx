package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.text.TextField;

/**
	Shared helpers for working with instantiated `fl.controls.*` component ports.

	Instances authored as `fl.controls.TextInput` / `TextArea` are built by
	`PR2MovieClip.createComponent` as `FlTextInput` / `FlTextArea` sprites that
	wrap an inner editable `TextField`. Callers that look a component up by
	instance name and want to read/write its `text` must unwrap it; a flat
	`Std.downcast(child, TextField)` returns null for these. This lives in
	`pr2.runtime` (next to the component classes) so both the lobby and the
	login/menu pages can depend on it without coupling to each other.
**/
class FlComponents {
	private function new() {}

	/**
		Resolve `display` to the editable `TextField` callers expect to read/write:
		the inner field of an `FlTextInput` / `FlTextArea`, or a raw text instance
		returned directly. Returns null for anything else.
	**/
	public static function asTextField(display:Null<DisplayObject>):Null<TextField> {
		var flInput = Std.downcast(display, FlTextInput);
		if (flInput != null) {
			return flInput.textField;
		}
		var flArea = Std.downcast(display, FlTextArea);
		if (flArea != null) {
			return flArea.textField;
		}
		return Std.downcast(display, TextField);
	}
}
