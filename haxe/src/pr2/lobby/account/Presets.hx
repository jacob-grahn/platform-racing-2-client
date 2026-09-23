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
		applyValues(preset, ss == null ? null : ss.setStats, disp == null ? null : function(part, id, primary, secondary) {
			var selector:PartSelector = Reflect.field(disp, part + "Select");
			selector.setValue(id); selector.setColors(primary, secondary);
		});
		var hatColor2 = preset.hatColor2;
		var headColor2 = preset.headColor2;
		var bodyColor2 = preset.bodyColor2;
		var feetColor2 = preset.feetColor2;
		if (disp != null) {
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

	/** Same reset/order for both presentations; adapters own their views. */
	public static function applyValues(preset:Preset, stats:Int->Int->Int->Void, part:String->Int->Int->Int->Void):Void {
		if (stats != null) { stats(1, 1, 1); stats(preset.speed, preset.acceleration, preset.jumping); }
		if (part != null) for (name in ["hat", "head", "body", "feet"])
			part(name, Reflect.field(preset, name), Reflect.field(preset, name + "Color"), Reflect.field(preset, name + "Color2"));
	}
}
