package pr2.levelEditor;

import haxe.crypto.Md5;
import pr2.net.ServerConfig;

typedef LevelEditorVariableSnapshot = {
	final title:String;
	final note:String;
	final data:String;
	final credits:Array<String>;
	final live:Float;
	final minRank:String;
	final song:String;
	final gravity:String;
	final maxTime:String;
	final allowedItems:Array<Int>;
	final badHats:Array<Int>;
	final hasPass:Int;
	final gameMode:String;
	final cowboyChance:String;
	final pass:Null<String>;
	final toNewest:Bool;
}

/** Encodes and decodes the legacy editor persistence boundary. */
class LevelEditorCodec {
	public static function encodeLevelData(color:Int, blockSave:String, objectSave:Array<String>, drawSave:Array<String>,
			artBackgroundCode:Null<Int>):String {
		return [
			"m4",
			StringTools.hex(color).toLowerCase(),
			blockSave,
			valueAt(objectSave, 0), valueAt(objectSave, 1), valueAt(objectSave, 2),
			valueAt(drawSave, 0), valueAt(drawSave, 1), valueAt(drawSave, 2),
			artBackgroundCode == null ? "" : Std.string(artBackgroundCode),
			valueAt(objectSave, 3), valueAt(objectSave, 4),
			valueAt(drawSave, 3), valueAt(drawSave, 4)
		].join("`");
	}

	public static function buildVariables(snapshot:LevelEditorVariableSnapshot):Map<String, String> {
		var vars = new Map<String, String>();
		vars.set("title", snapshot.title);
		vars.set("note", snapshot.note);
		vars.set("data", snapshot.data);
		vars.set("credits", snapshot.credits.join("`"));
		vars.set("live", Std.string(snapshot.live));
		vars.set("min_level", snapshot.minRank);
		vars.set("song", snapshot.song);
		vars.set("gravity", snapshot.gravity);
		vars.set("max_time", snapshot.maxTime);
		vars.set("items", snapshot.allowedItems.join("`"));
		vars.set("badHats", snapshot.badHats.join(","));
		vars.set("hasPass", Std.string(snapshot.hasPass));
		vars.set("gameMode", snapshot.gameMode == "eggs" ? "egg" : snapshot.gameMode);
		vars.set("cowboyChance", snapshot.cowboyChance);
		vars.set("passHash", passHash(snapshot.pass));
		vars.set("to_newest", snapshot.toNewest ? "1" : "0");
		return vars;
	}

	public static function passHash(pass:Null<String>):String {
		if (pass == null || pass == "" || StringTools.replace(pass, "*", "") == "") return "";
		return Md5.encode(pass + ServerConfig.LEVEL_PASS_SALT);
	}

	public static function copyVariables(vars:Map<String, String>):Map<String, String> {
		var copied = new Map<String, String>();
		if (vars != null) for (key in vars.keys()) copied.set(key, vars.get(key));
		return copied;
	}

	public static function parseFloatOr(value:Null<String>, fallback:Float):Float {
		if (value == null || value == "") return fallback;
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	public static function parseIntOr(value:Null<String>, fallback:Int):Int {
		if (value == null || value == "") return fallback;
		var parsed = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
	}

	public static function drawSections(rawData:String):Array<String> {
		var sections = rawData.split("`");
		return [valueAt(sections, 6), valueAt(sections, 7), valueAt(sections, 8), valueAt(sections, 12), valueAt(sections, 13)];
	}

	private static inline function valueAt(values:Array<String>, index:Int):String {
		return index < values.length ? values[index] : "";
	}
}
