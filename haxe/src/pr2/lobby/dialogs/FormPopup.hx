package pr2.lobby.dialogs;

import openfl.events.KeyboardEvent;
import pr2.ui.controls.GameTextInput;
import pr2.util.DisplayUtil;

/** Shared authored-art, input, button-binding, and teardown lifecycle for form dialogs. */
class FormPopup extends Popup {
	private var art:Null<NativeFormView>;
	private var inputs:Array<GameTextInput> = [];
	private var submit:Null<Void->Void>;

	public function new() {
		super();
	}

	function initializeForm(linkage:String, inputNames:Array<String>, submit:Void->Void):Void {
		this.submit = submit;
		art = new NativeFormView(linkage);
		addChild(art);
		art.onSubmit = submit;
		art.onCancel = startFadeOut;
		for (name in inputNames) {
			var input = textInput(name);
			if (input != null) {
				input.addEventListener(KeyboardEvent.KEY_DOWN, listenForEnterKey);
				inputs.push(input);
			}
		}
	}

	function textInput(name:String):Null<GameTextInput> {
		return art == null ? null : art.inputs.get(name);
	}

	function inputText(name:String):String {
		var input = textInput(name);
		return input == null ? "" : input.text;
	}

	private function listenForEnterKey(event:KeyboardEvent):Void {
		if (event.keyCode == 13 && submit != null) {
			submit();
		}
	}

	override public function remove():Void {
		for (input in inputs) input.removeEventListener(KeyboardEvent.KEY_DOWN, listenForEnterKey);
		inputs = [];
		submit = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
