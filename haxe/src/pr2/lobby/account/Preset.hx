package pr2.lobby.account;

/** Saved character outfit payload shape. */
typedef Outfit = {
	?hats:Array<Int>,
	?hat:Int,
	?head:Int,
	?body:Int,
	?feet:Int,
	?hatColor:Int,
	?headColor:Int,
	?bodyColor:Int,
	?feetColor:Int,
	?hatColor2:Int,
	?headColor2:Int,
	?bodyColor2:Int,
	?feetColor2:Int,
	?speed:Int,
	?acceleration:Int,
	?jumping:Int
};

/**
	Port of Flash `player_profile.Preset`: one saved loadout (number, stats, part
	ids, and per-part primary/epic colours), with the default style the IDE seeds.
**/
class Preset {
	public var num:Int = 1;
	public var speed:Int = 50;
	public var acceleration:Int = 50;
	public var jumping:Int = 50;
	public var hat:Int = 1;
	public var head:Int = 1;
	public var body:Int = 1;
	public var feet:Int = 1;
	public var hatColor:Int = 0;
	public var headColor:Int = 0;
	public var bodyColor:Int = 0;
	public var feetColor:Int = 0;
	public var hatColor2:Int = -1;
	public var headColor2:Int = -1;
	public var bodyColor2:Int = -1;
	public var feetColor2:Int = -1;

	public function new(?data:Dynamic) {
		if (data != null) {
			applyData(data);
		}
	}

	private function applyData(data:Dynamic):Void {
		for (field in Reflect.fields(data)) {
			var value = Reflect.field(data, field);
			if (value != null && Reflect.hasField(this, field)) {
				Reflect.setField(this, field, Std.int(value));
			}
		}
	}

	public function getPresetData():Dynamic {
		return {
			num: num, speed: speed, acceleration: acceleration, jumping: jumping,
			hat: hat, head: head, body: body, feet: feet,
			hatColor: hatColor, headColor: headColor, bodyColor: bodyColor, feetColor: feetColor,
			hatColor2: hatColor2, headColor2: headColor2, bodyColor2: bodyColor2, feetColor2: feetColor2
		};
	}

	public function getOutfitFormat():Outfit {
		return {
			hat: hat, head: head, body: body, feet: feet,
			hatColor: hatColor, headColor: headColor, bodyColor: bodyColor, feetColor: feetColor,
			hatColor2: hatColor2, headColor2: headColor2, bodyColor2: bodyColor2, feetColor2: feetColor2,
			speed: speed, acceleration: acceleration, jumping: jumping
		};
	}
}
