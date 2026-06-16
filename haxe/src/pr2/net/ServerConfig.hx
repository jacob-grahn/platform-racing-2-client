package pr2.net;

/**
	Endpoints and hash salts for talking to the live PR2 server, mirrored from
	the Flash client (`Main.baseURL`/`Main.levelsURL` and `Env`). Only the values
	needed to fetch and validate public level data are included here; account and
	socket secrets are intentionally left out of the port for now.
**/
final class ServerConfig {
	/** Production build string accepted by the current PR2 server. **/
	public static inline var BUILD:String = "29-oct-2023-v168_2_1";

	/** Default origin, matching `Main.baseURL` in the Flash client. **/
	public static inline var DEFAULT_HOST:String = "https://pr2hub.com";

	/** Hash salt used when listing levels (`Env.LEVEL_LIST_SALT`). **/
	public static inline var LEVEL_LIST_SALT:String = "984cn98c54$";

	/** Hash salt applied to a downloaded level txt file (`Env.LEVEL_SALT_2`). **/
	public static inline var LEVEL_SALT_2:String = "0kg4%dsw";

	/** Pixels per block segment; the Flash block strings are in these units. **/
	public static inline var SEG_SIZE:Int = 30;

	/**
		Host (origin or path prefix) that level endpoints are built on.
		pr2hub.com sends no CORS headers, so a browser cannot read its responses
		cross-origin. For html5 dev, point this at a same-origin proxy prefix
		such as `/api` (see `tools/dev_proxy.py`) via `?apiHost=/api`.
	**/
	private static var host:String = DEFAULT_HOST;

	private function new() {}

	public static function setHost(value:Null<String>):Void {
		if (value != null && StringTools.trim(value) != "") {
			host = StringTools.trim(value);
		}
	}

	public static function getHost():String {
		return host;
	}

	/**
		Course list endpoint, e.g. `listUrl("campaign", 1)` ->
		`{host}/files/lists/campaign/1`. Matches `LevelListing.requestCourses`.
	**/
	public static function listUrl(mode:String, page:Int):String {
		return host + "/files/lists/" + mode + "/" + page;
	}

	/**
		Single level txt endpoint, matching `Game.getLevelData`:
		`{host}/levels/{id}.txt?version={version}`.
	**/
	public static function levelDataUrl(levelId:Int, version:Int):String {
		return host + "/levels/" + levelId + ".txt?version=" + version;
	}

	/**
		Live multiplayer server status endpoint, matching `CheckServers`.
	**/
	public static function serverStatusUrl():String {
		return host + "/files/server_status_2.txt";
	}

	/**
		Account creation endpoint, matching `CreateAccountPopup`.
	**/
	public static function registerUserUrl():String {
		return host + "/register_user.php";
	}

	/**
		Encrypted login endpoint, matching `LoggingInPopup`.
	**/
	public static function loginUrl():String {
		return host + "/login.php";
	}
}
