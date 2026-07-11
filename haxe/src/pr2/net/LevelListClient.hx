package pr2.net;

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
	public static function fetch(mode:String, page:Int, onResult:LevelListResult->Void, ?onError:String->Void):SuperLoader {
		return TextLoader.load(ServerConfig.listUrl(mode, page), function(body:String):Void {
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
	public static function fetchFavorites(userId:Int, page:Int, token:String, onResult:LevelListResult->Void, ?onError:String->Void):SuperLoader {
		// favorite_levels_get.php is authenticated: Flash's SuperLoader appends a
		// `token` (Main.token) and a `rand` to every request, so mirror that here.
		var params = [
			"user_id" => Std.string(userId),
			"page" => Std.string(page),
			"token" => token,
			"rand" => Std.string(Std.random(10000000)),
		];
		return FormPostClient.post(ServerConfig.favoriteLevelsGetUrl(), params, function(body:String):Void {
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
	public static function search(params:Map<String, String>, onResult:LevelListResult->Void, ?onError:String->Void):SuperLoader {
		return FormPostClient.post(ServerConfig.searchLevelsUrl(), params, function(body:String):Void {
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
		Flash campaign page formula `((server_id + day) % 6) + 1`, where `day` is
		`Main.lastAuthTime.getDay()` from the server-synced auth clock.
	**/
	public static function campaignPage(serverId:Int, day:Int):Int {
		return ((serverId + day) % 6) + 1;
	}

	public static function parse(body:String):LevelListResult {
		var payload = LevelListPayload.parse(body);
		return new LevelListResult(payload.levels, payload.hashValid);
	}

	/** Replicates the integrity slice hashed by `LevelListing.loadHandler`. */
	public static function computeHash(body:String):String {
		return LevelListPayload.computeHash(body);
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
