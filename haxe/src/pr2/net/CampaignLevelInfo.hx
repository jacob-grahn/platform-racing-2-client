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

	public function new(
		levelId:Int,
		version:Int,
		title:String,
		userName:String,
		minLevel:Int,
		rating:Float,
		playCount:Int
	) {
		this.levelId = levelId;
		this.version = version;
		this.title = title;
		this.userName = userName;
		this.minLevel = minLevel;
		this.rating = rating;
		this.playCount = playCount;
	}

	public static function fromDynamic(data:Dynamic):CampaignLevelInfo {
		return new CampaignLevelInfo(
			intField(data, "level_id"),
			intField(data, "version"),
			stringField(data, "title", "(untitled)"),
			stringField(data, "user_name", "(unknown)"),
			intField(data, "min_level"),
			floatField(data, "rating"),
			intField(data, "play_count")
		);
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
