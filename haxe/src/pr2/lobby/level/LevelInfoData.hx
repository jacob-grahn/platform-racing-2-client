package pr2.lobby.level;

import pr2.gameplay.Modes;
import pr2.lobby.NumberFormat;

/** Normalized level details from level_info.php, shared by both presentations. */
class LevelInfoData {
	public static inline var DEFAULT_ITEMS:String = "Laser Gun`Mine`Lightning`Teleport`Super Jump`Jet Pack`Speed Burst`Sword`Ice Wave`Snake";

	private static final SONGS:Array<String> = [
		"None", "Orbital Trance - Space Planet", "Code - Stefano Maccarelli", "Paradise on E - API", "Crying Soul (FL Mix) - Pyroific",
		"My Vision - David Orr", "Switchblade - Detective Jabsco", "The Wires - Cheez-R-Us", "Before Mydnite - F-777", "",
		"Broked It - SWiTCH", "Hello? - TMM43", "Pyrokinesis - Sean Tucker", "Flowerz 'n' Herbz - Brunzolaitis", "Instrumental #4 - Reasoner",
		"Prismatic - Lunanova", "We Are Loud - Dynamedion", "Toodaloo - mustangman", "Night Shade - Goliathe", "Blizzard! - Majicke",
		"Pasture (Instrumental) - Dangevin", "Sunset Raiders - AVL"
	];
	private static final MONTHS:Array<String> = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
	private static final MONTHS_LONG:Array<String> = [
		"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
	];

	public final live:Bool;
	public final hasPass:Bool;
	public final userId:Int;
	public final userName:String;
	public final userGroup:String;
	public final rating:Float;
	public final time:Float;
	public final gravity:Float;
	public final maxTime:Int;
	public final items:String;
	public final song:String;
	public final mode:String;
	public final modeFrame:Int;
	public final gameMode:String;
	public final cowboyChance:Int;
	public final badHats:String;
	public final title:String;
	public final note:String;
	public final version:Int;
	public final plays:Int;
	public final minRank:Int;

	public function new(raw:Dynamic) {
		live = bool(raw, "live", false);
		hasPass = bool(raw, "has_pass", true);
		userId = int(raw, "user_id");
		userName = string(raw, "user_name");
		userGroup = string(raw, "user_group", "0");
		rating = float(raw, "rating");
		time = float(raw, "time");
		gravity = float(raw, "gravity", 1);
		maxTime = int(raw, "max_time", 120);
		items = string(raw, "items", DEFAULT_ITEMS);
		mode = string(raw, "gameMode", "race").toLowerCase();
		modeFrame = frameForMode(mode);
		gameMode = Modes.getFullName(mode);
		song = normalizeSong(string(raw, "song"));
		cowboyChance = int(raw, "cowboyChance", 5);
		badHats = string(raw, "badHats");
		title = string(raw, "title");
		note = string(raw, "note");
		version = int(raw, "version", 1);
		plays = int(raw, "play_count");
		minRank = int(raw, "min_rank");
	}

	public static function shortDate(seconds:Float):String {
		var date = Date.fromTime(seconds * 1000);
		return date.getDate() + "/" + MONTHS[date.getMonth()] + "/" + date.getFullYear();
	}

	public static function dateTime(seconds:Float):String {
		var date = Date.fromTime(seconds * 1000);
		var hour = date.getHours();
		var ampm = hour >= 12 ? "PM" : "AM";
		var hour12 = hour % 12;
		if (hour12 == 0) hour12 = 12;
		var minutes = StringTools.lpad(Std.string(date.getMinutes()), "0", 2);
		var secondsText = StringTools.lpad(Std.string(date.getSeconds()), "0", 2);
		return MONTHS_LONG[date.getMonth()] + " " + date.getDate() + ", " + date.getFullYear() + " " + hour12 + ":" + minutes + ":" + secondsText + " " + ampm;
	}

	public static function formatTime(seconds:Int):String {
		return Math.floor(seconds / 60) + ":" + StringTools.lpad(Std.string(Math.floor(seconds % 60)), "0", 2);
	}

	public function minRankText():String {
		return minRank <= 0 ? "Any rank" : "Rank " + NumberFormat.withCommas(minRank) + " required";
	}

	private static function normalizeSong(value:String):String {
		if (value == "" || value == "random") return "Random";
		if (value == "0" || value == "none") return "None";
		var index = Std.parseInt(value);
		return index == null || index < 0 || index >= SONGS.length ? "" : SONGS[index];
	}

	private static function frameForMode(value:String):Int {
		return switch (value) {
			case "deathmatch", "dm", "d": 2;
			case "egg", "eggs", "e": 3;
			case "objective", "obj", "o": 4;
			case "hat", "h": 5;
			default: 1;
		}
	}

	private static function string(data:Dynamic, key:String, fallback:String = ""):String {
		var value = data == null ? null : Reflect.field(data, key);
		return value == null ? fallback : Std.string(value);
	}

	private static function int(data:Dynamic, key:String, fallback:Int = 0):Int {
		var value:Dynamic = data == null ? null : Reflect.field(data, key);
		if (value == null) return fallback;
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) return Std.int(value);
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}

	private static function float(data:Dynamic, key:String, fallback:Float = 0):Float {
		var value = data == null ? null : Reflect.field(data, key);
		if (value == null) return fallback;
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	private static function bool(data:Dynamic, key:String, fallback:Bool):Bool {
		var value:Dynamic = data == null ? null : Reflect.field(data, key);
		if (value == null) return fallback;
		if (Std.isOfType(value, Bool)) return cast value;
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) return (cast value:Float) != 0;
		var text = Std.string(value).toLowerCase();
		if (text == "true" || text == "1") return true;
		if (text == "false" || text == "0" || text == "") return false;
		return fallback;
	}
}
