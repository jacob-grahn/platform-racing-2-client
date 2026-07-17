package pr2.levelEditor;

import openfl.display.Sprite;
import pr2.character.LocalCharacter;
import pr2.lobby.account.Settings;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.util.DisplayUtil;

class TestCourseHatPicker extends Sprite {
	private static inline var MIN_HAT:Int = 1;
	private static inline var MAX_HAT:Int = 16;
	private static inline var ARTIFACT_HAT:Int = 14;
	private static inline var DEFAULT_HAT:Int = 2;

	private var localCharacter:Null<LocalCharacter>;
	private var art:Null<TestCourseHatPickerView>;
	private var bindings:Array<Binding> = [];
	public var pickedHat(default, null):Int = DEFAULT_HAT;

	public function new(localCharacter:LocalCharacter) {
		super();
		this.localCharacter = localCharacter;
		art = new TestCourseHatPickerView();
		addChild(art);
		bind("left", clickLeft);
		bind("right", clickRight);
		pickedHat = normalizeHat(parseInt(Std.string(Settings.getValue(Settings.LE_TEST_HAT, DEFAULT_HAT)), DEFAULT_HAT));
		display();
	}

	public function resetHat():Void {
		if (localCharacter == null) {
			return;
		}
		var color = localCharacter.hat1Color;
		var color2 = localCharacter.hat1Color2;
		localCharacter.setHats([]);
		localCharacter.setHats([pickedHat, color, color2]);
	}

	public function remove():Void {
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		localCharacter = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function bind(name:String, handler:Void->Void):Void {
		var target = art == null ? null : DisplayUtil.findByName(art, name);
		var binding = LobbyArt.bind(target, handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function clickLeft():Void {
		pickedHat--;
		if (pickedHat == ARTIFACT_HAT) {
			pickedHat = ARTIFACT_HAT - 1;
		}
		if (pickedHat < MIN_HAT) {
			pickedHat = MAX_HAT;
		}
		display();
	}

	private function clickRight():Void {
		pickedHat++;
		if (pickedHat == ARTIFACT_HAT) {
			pickedHat = ARTIFACT_HAT + 1;
		}
		if (pickedHat > MAX_HAT) {
			pickedHat = MIN_HAT;
		}
		display();
	}

	private function display():Void {
		if (art != null) art.setHat(pickedHat);
		var color = Math.round(Math.random() * 0xFFFFFF);
		var color2 = 0;
		if (localCharacter != null) {
			localCharacter.setHats([pickedHat, color, color2]);
		}
		Settings.setValue(Settings.LE_TEST_HAT, pickedHat);
	}

	private static function normalizeHat(hatId:Int):Int {
		if (hatId == ARTIFACT_HAT) {
			return ARTIFACT_HAT + 1;
		}
		if (hatId < MIN_HAT || hatId > MAX_HAT) {
			return DEFAULT_HAT;
		}
		return hatId;
	}

	private static function parseInt(value:Null<String>, fallback:Int):Int {
		if (value == null || value == "") {
			return fallback;
		}
		var parsed = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
	}
}
