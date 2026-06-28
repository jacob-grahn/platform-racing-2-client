package pr2.net;

import haxe.Json;
import haxe.crypto.Md5;

/**
	Fetches a course list for any lobby listing mode (`best`, `best_week`,
	`newest`, `favorites`, `campaign`, `search`) and parses it into
	`CampaignLevelInfo` entries, mirroring `LevelListing.requestCourses` /
	`loadHandler`.

	The Flash hash check (`MD5(ret.substr(10, len-53) + LEVEL_LIST_SALT)`) is
	replicated for parity; a mismatch is surfaced via `hashValid` rather than
	dropping the data, since the integrity slice depends on exact server JSON
	whitespace. `CampaignListClient` is the campaign-only special case.
**/
class LevelListClient {
	public static function fetch(mode:String, page:Int, onResult:LevelListResult->Void, ?onError:String->Void):Void {
		TextLoader.load(ServerConfig.listUrl(mode, page), function(body:String):Void {
			try {
				onResult(parse(body));
			} catch (error:Dynamic) {
				if (onError != null) {
					onError('failed to parse $mode list: ${Std.string(error)}');
				}
			}
		}, onError);
	}

	/**
		POST to `favorite_levels_get.php` (with `user_id` + `page`) and parse the
		same level-list payload, mirroring `level_browser.Favorites.requestCourses`.
		Favorites use this dedicated endpoint rather than the generic `listUrl` path.
	**/
	public static function fetchFavorites(userId:Int, page:Int, token:String, onResult:LevelListResult->Void, ?onError:String->Void):Void {
		// favorite_levels_get.php is authenticated: Flash's SuperLoader appends a
		// `token` (Main.token) and a `rand` to every request, so mirror that here.
		var params = [
			"user_id" => Std.string(userId),
			"page" => Std.string(page),
			"token" => token,
			"rand" => Std.string(Std.random(10000000)),
		];
		FormPostClient.post(ServerConfig.favoriteLevelsGetUrl(), params, function(body:String):Void {
			try {
				onResult(parse(body));
			} catch (error:Dynamic) {
				if (onError != null) {
					onError('failed to parse favorites list: ${Std.string(error)}');
				}
			}
		}, onError);
	}

	/**
		POST a search to `search_levels.php` and parse the same level-list payload,
		mirroring `level_browser.Search.requestCourses` + the shared `loadHandler`.
	**/
	public static function search(params:Map<String, String>, onResult:LevelListResult->Void, ?onError:String->Void):Void {
		FormPostClient.post(ServerConfig.searchLevelsUrl(), params, function(body:String):Void {
			try {
				onResult(parse(body));
			} catch (error:Dynamic) {
				if (onError != null) {
					onError('failed to parse search results: ${Std.string(error)}');
				}
			}
		}, onError);
	}

	/**
		Flash campaign page formula `((server_id + day) % 6) + 1`, where `day` is the
		weekday (0-6) of the last auth time. Campaign lists have six pages.
	**/
	public static function campaignPage(serverId:Int, weekday:Int):Int {
		return ((serverId + weekday) % 6) + 1;
	}

	public static function parse(body:String):LevelListResult {
		if (body == null || StringTools.trim(body) == "") {
			throw "empty response";
		}

		var obj:Dynamic = Json.parse(body);
		var rawLevels:Dynamic = Reflect.field(obj, "levels");
		if (rawLevels == null || !Std.isOfType(rawLevels, Array)) {
			throw "response had no levels array";
		}

		var levels:Array<CampaignLevelInfo> = [];
		for (entry in (rawLevels : Array<Dynamic>)) {
			levels.push(CampaignLevelInfo.fromDynamic(entry));
		}

		var expectedHash:Dynamic = Reflect.field(obj, "hash");
		var hashValid = expectedHash != null && Std.string(expectedHash) == computeHash(body);

		return new LevelListResult(levels, hashValid);
	}

	/** Replicates the integrity slice hashed by `LevelListing.loadHandler`. */
	public static function computeHash(body:String):String {
		var sliceLength = body.length - 53;
		if (sliceLength <= 0) {
			return "";
		}
		var levelsStr = body.substr(10, sliceLength);
		return Md5.encode(levelsStr + ServerConfig.LEVEL_LIST_SALT);
	}
}

class LevelListResult {
	public final levels:Array<CampaignLevelInfo>;
	public final hashValid:Bool;

	public function new(levels:Array<CampaignLevelInfo>, hashValid:Bool) {
		this.levels = levels;
		this.hashValid = hashValid;
	}
}
