package pr2.lobby.dialogs;

import openfl.events.KeyboardEvent;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.runtime.FlTextInput;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/** Shared authored-art, input, button-binding, and teardown lifecycle for form dialogs. */
class FormPopup extends Popup {
	private var art:Null<PR2MovieClip>;
	private var bindings:Array<Null<Binding>> = [];
	private var inputs:Array<FlTextInput> = [];
	private var submit:Null<Void->Void>;

	public function new() {
		super();
	}

	function initializeForm(linkage:String, inputNames:Array<String>, submit:Void->Void):Void {
		this.submit = submit;
		art = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 4});
		addChild(art);
		bindings.push(LobbyArt.bind(DisplayUtil.findByName(art, "ok_bt"), submit));
		bindings.push(LobbyArt.bind(DisplayUtil.findByName(art, "cancel_bt"), startFadeOut));
		for (name in inputNames) {
			var input = textInput(name);
			if (input != null) {
				input.addEventListener(KeyboardEvent.KEY_DOWN, listenForEnterKey);
				inputs.push(input);
			}
		}
	}

	function textInput(name:String):Null<FlTextInput> {
		return Std.downcast(DisplayUtil.findByName(art, name), FlTextInput);
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
		for (binding in bindings) LobbyArt.unbind(binding);
		bindings = [];
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
