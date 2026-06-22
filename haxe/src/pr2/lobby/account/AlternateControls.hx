package pr2.lobby.account;

/** Resolves the five user-configurable gameplay keys stored by OptionsPopup. */
class AlternateControls {
	private function new() {}

	public static function matches(action:String, keyCode:UInt):Bool {
		var controls:Dynamic = Settings.getValue(Settings.ALTERNATE_CONTROLS, Settings.DEFAULT_ALT_CONTROLS);
		var configured:Null<Int> = Reflect.field(controls, action);
		if (configured == null) configured = Reflect.field(Settings.DEFAULT_ALT_CONTROLS, action);
		return keyCode == configured;
	}
}
