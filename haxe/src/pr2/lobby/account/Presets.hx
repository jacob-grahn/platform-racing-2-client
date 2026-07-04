package pr2.lobby.account;

/**
	Port of Flash `player_profile.Presets`: the loadout slot store. Backed by
	`Settings`, it always exposes exactly `NUM_PRESETS` presets, applies a chosen
	loadout to the live character / stats / part selectors, and saves the current
	style back into a slot.
**/
class Presets {
	public static inline var NUM_PRESETS:Int = 10;

	private static var presets:Array<Preset> = null;

	private function new() {}

	public static function load():Void {
		presets = [];
		var defaults:Array<Dynamic> = [];
		for (i in 0...NUM_PRESETS) {
			defaults.push({num: i + 1});
		}
		var stored:Dynamic = Settings.getValue(Settings.PRESETS, defaults);
		var list:Array<Dynamic> = (stored : Array<Dynamic>);
		for (i in 0...NUM_PRESETS) {
			presets.push(new Preset({num: i + 1}));
		}
		for (data in list) {
			if (data == null) {
				continue;
			}
			var preset = new Preset(data);
			if (preset.num >= 1 && preset.num <= NUM_PRESETS) {
				presets[preset.num - 1] = preset;
			}
		}
	}

	public static function getPresets():Array<Preset> {
		if (presets == null) {
			load();
		}
		return presets;
	}

	public static function resetForTests():Void {
		presets = null;
	}

	public static function loadedForTests():Bool {
		return presets != null;
	}

	public static function getPreset(i:Int):Preset {
		return getPresets()[i - 1];
	}

	public static function savePresets():Void {
		var out:Array<Dynamic> = [];
		for (preset in getPresets()) {
			out[preset.num - 1] = preset.getPresetData();
		}
		Settings.setValue(Settings.PRESETS, out);
	}

	public static function apply(preset:Preset, c:AccountCharacter, ss:StatsSelect, disp:PlayerDisplay):Void {
		if (ss != null) {
			ss.setStats(1, 1, 1);
			ss.setStats(preset.speed, preset.acceleration, preset.jumping);
		}
		var hatColor2 = preset.hatColor2;
		var headColor2 = preset.headColor2;
		var bodyColor2 = preset.bodyColor2;
		var feetColor2 = preset.feetColor2;
		if (disp != null) {
			disp.hatSelect.setValue(preset.hat);
			disp.headSelect.setValue(preset.head);
			disp.bodySelect.setValue(preset.body);
			disp.feetSelect.setValue(preset.feet);
			disp.hatSelect.setColors(preset.hatColor, preset.hatColor2);
			disp.headSelect.setColors(preset.headColor, preset.headColor2);
			disp.bodySelect.setColors(preset.bodyColor, preset.bodyColor2);
			disp.feetSelect.setColors(preset.feetColor, preset.feetColor2);
			hatColor2 = disp.hatSelect.getColor2();
			headColor2 = disp.headSelect.getColor2();
			bodyColor2 = disp.bodySelect.getColor2();
			feetColor2 = disp.feetSelect.getColor2();
		}
		if (c != null) {
			c.setHatId(preset.hat);
			c.setHeadId(preset.head);
			c.setBodyId(preset.body);
			c.setFeetId(preset.feet);
			c.setColors(preset.hatColor, hatColor2, preset.headColor, headColor2, preset.bodyColor, bodyColor2, preset.feetColor, feetColor2);
		}
		if (disp != null) {
			disp.refreshFromCharacter();
		}
	}
}
