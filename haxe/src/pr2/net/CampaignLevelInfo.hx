package pr2.net;

/**
	One entry from a course-list response. Field names mirror the JSON the Flash
	client reads in `LevelListing.showCourses` (`level.level_id`, `level.version`,
	`level.title`, ...). Only the fields useful to the test harness are kept;
	others remain available on the raw object during parsing.
**/
class CampaignLevelInfo {
	public final levelId:Int;
	public final version:Int;
	public final title:String;
	public final userName:String;
	public final minLevel:Int;
	public final rating:Float;
	public final playCount:Int;

	/** Author access group string (Flash `level.user_group`), e.g. "1,1". */
	public final userGroup:String;

	/** Level description / note (Flash `level.note`). */
	public final note:String;

	/** Whether the level is password-protected (Flash `level.pass`). */
	public final pass:Bool;

	/** Game-mode code: r/d/e/o/h, used to pick the `bg` frame (Flash `level.type`). */
	public final type:String;

	/** Comma-separated list of disallowed hat ids (Flash `level.bad_hats`). */
	public final badHats:Array<Int>;

	/** Last-updated unix time (Flash `level.time`). */
	public final time:Int;

	public function new(
		levelId:Int,
		version:Int,
		title:String,
		userName:String,
		minLevel:Int,
		rating:Float,
		playCount:Int,
		userGroup:String = "0",
		note:String = "",
		pass:Bool = false,
		type:String = "r",
		?badHats:Array<Int>,
		time:Int = 0
	) {
		this.levelId = levelId;
		this.version = version;
		this.title = title;
		this.userName = userName;
		this.minLevel = minLevel;
		this.rating = rating;
		this.playCount = playCount;
		this.userGroup = userGroup;
		this.note = note;
		this.pass = pass;
		this.type = type;
		this.badHats = badHats != null ? badHats : [];
		this.time = time;
	}

	public static function fromDynamic(data:Dynamic):CampaignLevelInfo {
		return new CampaignLevelInfo(
			intField(data, "level_id"),
			intField(data, "version"),
			stringField(data, "title", "(untitled)"),
			stringField(data, "user_name", "(unknown)"),
			intField(data, "min_level"),
			floatField(data, "rating"),
			intField(data, "play_count"),
			stringField(data, "user_group", "0"),
			stringField(data, "note", ""),
			boolField(data, "pass"),
			stringField(data, "type", "r"),
			parseBadHats(stringField(data, "bad_hats", "")),
			intField(data, "time")
		);
	}

	/** Flash `badHatsStr.split(',')`, keeping ids > 1 (matches `LevelItem`). */
	private static function parseBadHats(raw:String):Array<Int> {
		var hats:Array<Int> = [];
		if (raw == null || raw == "") {
			return hats;
		}
		for (part in raw.split(",")) {
			var id = Std.parseInt(part);
			if (id != null && id > 1) {
				hats.push(id);
			}
		}
		return hats;
	}

	private static function boolField(data:Dynamic, name:String):Bool {
		var raw = rawString(data, name);
		if (raw == null) {
			return false;
		}
		return raw == "1" || raw == "true";
	}

	public function describe():String {
		return 'id=$levelId v=$version "$title" by $userName';
	}

	private static function intField(data:Dynamic, name:String):Int {
		var raw = rawString(data, name);
		if (raw == null) {
			return 0;
		}
		var parsed = Std.parseInt(raw);
		return parsed == null ? 0 : parsed;
	}

	private static function floatField(data:Dynamic, name:String):Float {
		var raw = rawString(data, name);
		if (raw == null) {
			return 0;
		}
		var parsed = Std.parseFloat(raw);
		return Math.isNaN(parsed) ? 0 : parsed;
	}

	private static function stringField(data:Dynamic, name:String, fallback:String):String {
		var raw = rawString(data, name);
		return raw == null ? fallback : raw;
	}

	/** JSON numbers and strings both serialize cleanly through `Std.string`. **/
	private static function rawString(data:Dynamic, name:String):Null<String> {
		var value:Dynamic = Reflect.field(data, name);
		return value == null ? null : Std.string(value);
	}
}
