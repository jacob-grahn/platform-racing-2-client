package pr2.net;

import haxe.crypto.Md5;

/**
	Fetches and verifies a single level payload, mirroring `Game.getLevelData` /
	`Game.loadHandler` and `GamePage.validateSaveString` from the Flash client.

	Steps: strip the trailing 32-char MD5, validate it, run `validateSaveString`
	(whitelist filter), then parse the `&`-joined vars into `ServerLevelData`. As
	with the campaign list, a hash mismatch is reported via `hashValid` rather
	than dropped, so the harness can still inspect what came back.
**/
class LevelDataClient {
	/** Params the Flash client keeps when sanitizing a level string. **/
	private static final ALLOWED_PARAMS:Array<String> = [
		"credits=", "data=", "title=", "note=", "song=", "gravity=", "max_time=",
		"items=", "level_id=", "live=", "time=", "min_level=", "has_pass=",
		"gameMode=", "version=", "user_id=", "cowboyChance=", "badHats="
	];

	public static function fetch(levelId:Int, version:Int, onResult:ServerLevelData->Void, ?onError:String->Void):Void {
		TextLoader.load(ServerConfig.levelDataUrl(levelId, version), function(body:String):Void {
			try {
				onResult(parse(body, levelId, version));
			} catch (error:Dynamic) {
				if (onError != null) {
					onError('failed to parse level $levelId: ${Std.string(error)}');
				}
			}
		}, onError);
	}

	public static function fetchEditorLoad(levelId:Int, version:Int, onResult:ServerLevelData->Void, ?onError:String->Void):Void {
		TextLoader.load(ServerConfig.levelDataUrl(levelId, version), function(body:String):Void {
			try {
				onResult(parseEditorLoad(body, levelId, version));
			} catch (error:Dynamic) {
				if (onError != null) {
					onError(Std.string(error));
				}
			}
		}, onError);
	}

	public static function parse(body:String, levelId:Int, version:Int):ServerLevelData {
		if (body == null || StringTools.trim(body) == "") {
			throw "empty level response";
		}
		if (body.length < 32) {
			throw "level response too short to contain a hash";
		}

		var hashPos = body.length - 32;
		var levelData = body.substr(0, hashPos);
		var levelHash = body.substr(hashPos);
		var hashValid = computeHash(version, levelId, levelData) == levelHash;

		var validated = validateSaveString(levelData);
		return new ServerLevelData(parseVars(validated), hashValid, validated);
	}

	/**
		Editor load flow variant from `level_management.LoadingLevelPopup`.
		Unlike race loading, Flash rejects bad hashes and empty level data before
		passing validated URLVariables into `LevelEditor.setVariables`.
	**/
	public static function parseEditorLoad(body:String, levelId:Int, version:Int):ServerLevelData {
		var data = parse(body, levelId, version);
		if (!data.hashValid) {
			throw "Error: The course did not download correctly.";
		}
		if (data.saveString == "") {
			throw "Error: The course did not load.";
		}
		return data;
	}

	/** `MD5(version + courseID + levelData + LEVEL_SALT_2)`, per `Game.loadHandler`. **/
	public static function computeHash(version:Int, levelId:Int, levelData:String):String {
		return Md5.encode(Std.string(version) + Std.string(levelId) + levelData + ServerConfig.LEVEL_SALT_2);
	}

	/**
		Port of `GamePage.validateSaveString`: neutralizes any param not on the
		whitelist by gluing its segment onto the previous value instead of letting
		it parse as its own key. Faithfully restores literal "and" inside values.
	**/
	public static function validateSaveString(levelData:String):String {
		var ret = "";
		var sections = StringTools.replace(levelData, "&", "and").split("and");
		for (section in sections) {
			var allowed = false;
			for (param in ALLOWED_PARAMS) {
				if (section.substr(0, param.length) == param) {
					allowed = true;
					break;
				}
			}
			var separator = allowed ? "&" : "and";
			if (ret == "") {
				separator = "";
			}
			ret += separator + section;
		}
		return ret;
	}

	private static function parseVars(query:String):Map<String, String> {
		var vars:Map<String, String> = new Map();
		for (pair in query.split("&")) {
			if (pair == "") {
				continue;
			}
			var eq = pair.indexOf("=");
			if (eq < 0) {
				vars.set(pair, "");
			} else {
				vars.set(pair.substr(0, eq), urlDecode(pair.substr(eq + 1)));
			}
		}
		return vars;
	}

	/** Match `URLVariables` decoding; tolerate malformed sequences in raw data. **/
	private static function urlDecode(value:String):String {
		try {
			return StringTools.urlDecode(value);
		} catch (error:Dynamic) {
			return value;
		}
	}
}
