package pr2.lobby.account;

/** Editable account state without display objects or input listeners. */
class RacerModel {
	public static final PARTS = ["hat", "head", "body", "feet"];
	public static final STATS = ["speed", "acceleration", "jumping"];
	public final session = new CustomizationSession();
	public var data(default, null):AccountCustomizeData;
	public var outfit(default, null):Preset;
	public var total(default, null):Int = 150;
	public function new() {}
	public function accept(value:AccountCustomizeData):Void {
		data = value; session.accept(data); total = CustomizationRules.budget(data);
		outfit = new Preset(data);
		// Match the original's ordered slider initialization and 0–100 clamps.
		outfit.speed = outfit.acceleration = outfit.jumping = 0;
		setStats(data.speed, data.acceleration, data.jumping);
	}
	public function owned(part:String):Array<String> return switch part {
		case "hat": data.hats; case "head": data.heads; case "body": data.bodies; default: data.feetParts;
	}
	public function epics(part:String):Array<String> return switch part {
		case "hat": data.epicHats; case "head": data.epicHeads; case "body": data.epicBodies; default: data.epicFeet;
	}
	public function value(field:String):Int return Reflect.field(outfit, field);
	public function epic(part:String):Bool return CustomizationRules.epic(epics(part), value(part));
	public function secondary(part:String):Int return epic(part) ? value(part + "Color2") : -1;
	public function remaining():Int return total - outfit.speed - outfit.acceleration - outfit.jumping;
	public function stat(field:String, next:Int):Void Reflect.setField(outfit, field, CustomizationRules.stat(next, remaining() + value(field)));
	public function setStats(speed:Int, acceleration:Int, jumping:Int):Void {
		stat("speed", speed); stat("acceleration", acceleration); stat("jumping", jumping);
	}
	public function select(part:String, id:Int):Void {
		if (owned(part).indexOf(Std.string(id)) >= 0) Reflect.setField(outfit, part, id);
	}
	public function step(part:String, direction:Int):Void {
		var list = owned(part); if (list.length == 0) return;
		var index = list.indexOf(Std.string(value(part)));
		select(part, Std.parseInt(list[(index + direction + list.length) % list.length]));
	}
	public function color(part:String, secondary:Bool, next:Int):Void {
		if (next < 0 || next > 0xFFFFFF || (secondary && !epic(part))) return;
		Reflect.setField(outfit, part + (secondary ? "Color2" : "Color"), next);
	}
	public function randomize():Void {
		for (part in PARTS) {
			var list = owned(part);
			if (list.length > 0) select(part, Std.parseInt(list[Std.random(list.length)]));
			Reflect.setField(outfit, part + "Color", Std.int(Math.random() * 0xFFFFFF));
			Reflect.setField(outfit, part + "Color2", Std.int(Math.random() * 0xFFFFFF));
		}
	}
	public function applyPreset(preset:Preset):Void {
		Presets.applyValues(preset, setStats, function(part, id, primary, secondary) {
			Reflect.setField(outfit, part, id);
			Reflect.setField(outfit, part + "Color", primary);
			if (secondary != -1) Reflect.setField(outfit, part + "Color2", secondary);
		});
	}
	public function savePreset(slot:Int):Void {
		var saved = new Preset(outfit.getPresetData()); saved.num = slot;
		Presets.getPresets()[slot - 1] = saved; Presets.savePresets();
	}
	public function paint(character:AccountCharacter):Void {
		character.setHatId(outfit.hat); character.setHeadId(outfit.head); character.setBodyId(outfit.body); character.setFeetId(outfit.feet);
		character.setColors(outfit.hatColor, secondary("hat"), outfit.headColor, secondary("head"), outfit.bodyColor, secondary("body"), outfit.feetColor, secondary("feet"));
		if (AccountState.currentHat != outfit.hat) {
			AccountState.currentHat = outfit.hat;
			pr2.net.CommandHandler.commandHandler.dispatch("testLevelAccess", []);
		}
	}
	public function save():Void {
		if (outfit == null) return;
		var parts:Array<Int> = [];
		for (part in PARTS) parts.push(value(part + "Color"));
		for (part in PARTS) parts.push(secondary(part));
		for (part in PARTS) parts.push(value(part));
		session.save(parts.join("`"), [outfit.speed, outfit.acceleration, outfit.jumping].join("`"));
	}
}
