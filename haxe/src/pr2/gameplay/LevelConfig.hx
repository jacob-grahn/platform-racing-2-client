package pr2.gameplay;

import pr2.character.Parts;
import pr2.net.ServerLevelData;

/**
	Port of the level-configuration half of Flash `page.GamePage`.

	`GamePage` was both the in-session display page and the holder of a level's
	parsed settings (allowed items, banned hats, gravity, time limit, song, game
	mode, cowboy chance, credits, background color). The geometry decode (read
	modes `m1`..`m4`) already lives in `pr2.level.LevelDecoder`, and the
	fetch / MD5 / `validateSaveString` / var-parsing already lives in
	`pr2.net.LevelDataClient`; this class is the remaining piece — the faithful
	`setVariables` / `setItems` / `setBadHats` / etc. setter semantics that turn a
	parsed `ServerLevelData` into the resolved config gameplay reads.

	Factored out of the `GamePage` Page subclass so it can be exercised by an
	AS3-spec transcript test without standing up the display tree.
**/
class LevelConfig {
	/** Default background color, matching Flash `GamePage.color`. **/
	public static inline var DEFAULT_COLOR:Int = 12303325;

	public var color(default, null):Int = DEFAULT_COLOR;
	public var credits(default, null):Array<String> = [];
	public var levelId(default, null):Float = 0;
	public var updatedTime(default, null):Float = 0;
	public var title(default, null):String = "";
	public var note(default, null):String = "";
	public var song(default, null):String = "";
	public var gravity(default, null):String = "1";
	public var maxTime(default, null):String = "120";
	public var gameMode(default, null):String = "race";
	public var cowboyChance(default, null):String = "5";
	public var allowedItems(default, null):Array<Int> = [];
	public var badHats(default, null):Array<Int> = [];

	public function new() {
		// Match GamePage.initialize defaults before any server vars arrive.
		setItems("all");
		setBadHats("");
	}

	/** Build a config straight from a fetched `ServerLevelData`. **/
	public static function fromServerData(data:ServerLevelData):LevelConfig {
		var config = new LevelConfig();
		config.setVariables(data.vars);
		return config;
	}

	/**
		Port of `GamePage.setVariables`. Reads the same fields out of the parsed
		level vars in the same order, applying each setter's normalization.
	**/
	public function setVariables(vars:Map<String, String>):Void {
		updatedTime = numberOf(vars.get("time"), 0);
		setCredits(vars.get("credits"));
		title = strOf(vars.get("title"));
		note = strOf(vars.get("note"));
		setSong(vars.get("song"));
		var mode = vars.get("gameMode");
		setGameMode(mode == null ? "race" : mode);
		setCowboyChance(vars.get("cowboyChance"));

		var g = numberOf(vars.get("gravity"), 0);
		g = numLimitF(g, -99, 99);
		var gStr = formatNumber(g);
		if (gStr.indexOf(".") == -1) {
			gStr += ".0";
		}
		setGravity(gStr);

		var t = numLimitF(numberOf(vars.get("max_time"), 0), 0, 9999);
		setMaxTime(formatNumber(t));

		setItems(vars.get("items"));
		setBadHats(vars.get("badHats"));
		levelId = numberOf(vars.get("level_id"), 0);
	}

	public function setColor(value:Int = 0):Void {
		color = value;
	}

	public function setGravity(value:String):Void {
		gravity = value;
	}

	/**
		Port of `GamePage.setMaxTime`. The original computes a legacy 999->0
		override into a local that it then ignores, storing the raw string; we
		mirror that observable behavior (the value is stored as-is).
	**/
	public function setMaxTime(value:String):Void {
		maxTime = value;
	}

	public function setSong(value:Null<String>):Void {
		song = strOf(value);
	}

	/** Port of `GamePage.setGameMode`: legacy `eggs` normalizes to `egg`. **/
	public function setGameMode(mode:String):Void {
		gameMode = mode == "eggs" ? "egg" : mode;
		if (gameMode == Modes.roguelike) {
			banAllHats();
		}
	}

	/** Port of `GamePage.setCowboyChance`: default 5, clamp 0..100. **/
	public function setCowboyChance(chance:Null<String>):Void {
		var perc = 5;
		if (chance != null && chance != "") {
			var parsed = Std.parseInt(chance);
			perc = parsed == null ? 5 : numLimit(parsed, 0, 100);
		}
		cowboyChance = Std.string(perc);
	}

	public function setCredits(value:Null<String>):Void {
		var v = value == null ? "" : value;
		credits = v.split("`");
	}

	/**
		Port of `GamePage.setItems`. "" -> none; "all"/null -> every code; else a
		backtick list where each token is either a name (length > 1) or a numeric
		code, kept only when it resolves to a valid 1..N code.
	**/
	public function setItems(itemsStr:Null<String>):Void {
		if (itemsStr == "") {
			allowedItems = [];
			return;
		}
		if (itemsStr == "all" || itemsStr == null) {
			allowedItems = Items.getAllCodes();
			return;
		}
		allowedItems = [];
		var count = Items.getAllCodes().length;
		for (itemName in itemsStr.split("`")) {
			// Flash's original length heuristic worked while every item code was a
			// single digit. Snake is code 10, so an editor round-trip serialized
			// "10" and then misread it as an item name. Prefer an all-digit token as
			// a numeric code; retain name parsing for legacy level strings.
			var numericToken = ~/^[0-9]+$/.match(itemName);
			var itemCode = numericToken ? Std.int(numberOf(itemName, 0)) : Items.getCodeFromName(itemName);
			if (itemCode >= 1 && itemCode <= count) {
				allowedItems.push(itemCode);
			}
		}
	}

	/**
		Port of `GamePage.setBadHats`. Comma list of hat ids; kept when > 1 and
		<= the number of selectable hats + 1 (i.e. the greatest hat id).
	**/
	public function setBadHats(hatsStr:Null<String>):Void {
		if (gameMode == Modes.roguelike) {
			banAllHats();
			return;
		}
		badHats = [];
		if (hatsStr == "" || hatsStr == null) {
			return;
		}
		var hatArray = Parts.getPartArray("HAT");
		var maxHat = (hatArray == null ? 0 : hatArray.length) + 1;
		for (token in hatsStr.split(",")) {
			var hatCode = Std.int(numberOf(token, 0));
			if (hatCode > 1 && hatCode <= maxHat) {
				badHats.push(hatCode);
			}
		}
	}

	private function banAllHats():Void {
		badHats = [];
		var hatArray = Parts.getPartArray("HAT");
		var maxHat = (hatArray == null ? 0 : hatArray.length) + 1;
		for (hatId in 2...maxHat + 1) {
			badHats.push(hatId);
		}
	}

	// --- numeric helpers (AS3 `Number(...)` / `Data.numLimit` semantics) ------

	/** AS3 `Number(s)`: empty/null/NaN -> fallback, otherwise the numeric value. **/
	private static function numberOf(value:Null<String>, fallback:Float):Float {
		if (value == null || value == "") {
			return fallback;
		}
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	private static function numLimit(value:Int, min:Int, max:Int):Int {
		return value < min ? min : (value > max ? max : value);
	}

	private static function numLimitF(value:Float, min:Float, max:Float):Float {
		return value < min ? min : (value > max ? max : value);
	}

	/** AS3 `String(Number)`: integral values render without a trailing ".0". **/
	private static function formatNumber(value:Float):String {
		return value == Math.ffloor(value) ? Std.string(Std.int(value)) : Std.string(value);
	}

	private static function strOf(value:Null<String>):String {
		return value == null ? "" : value;
	}
}
