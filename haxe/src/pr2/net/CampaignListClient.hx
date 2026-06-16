package pr2.net;

import haxe.Json;
import haxe.crypto.Md5;

/**
	Fetches a campaign course list from the live server and parses it into
	`CampaignLevelInfo` entries, mirroring `LevelListing.requestCourses` /
	`loadHandler` from the Flash client.

	The Flash hash check is replicated for parity, but a mismatch is reported
	rather than fatal: the integrity slice (`substr(10, len-53)`) depends on the
	exact server JSON formatting, so we surface `hashValid` and let callers
	decide instead of dropping the data.
**/
class CampaignListClient {
	public static inline var MODE:String = "campaign";

	public static function fetch(page:Int, onResult:CampaignListResult->Void, ?onError:String->Void):Void {
		TextLoader.load(ServerConfig.listUrl(MODE, page), function(body:String):Void {
			try {
				onResult(parse(body));
			} catch (error:Dynamic) {
				if (onError != null) {
					onError('failed to parse campaign list: ${Std.string(error)}');
				}
			}
		}, onError);
	}

	public static function parse(body:String):CampaignListResult {
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

		return new CampaignListResult(levels, hashValid);
	}

	/**
		Replicates `LevelListing.loadHandler`: hash the slice
		`ret.substr(10, ret.length - 53)` plus `LEVEL_LIST_SALT`.
	**/
	private static function computeHash(body:String):String {
		var sliceLength = body.length - 53;
		if (sliceLength <= 0) {
			return "";
		}
		var levelsStr = body.substr(10, sliceLength);
		return Md5.encode(levelsStr + ServerConfig.LEVEL_LIST_SALT);
	}
}

class CampaignListResult {
	public final levels:Array<CampaignLevelInfo>;
	public final hashValid:Bool;

	public function new(levels:Array<CampaignLevelInfo>, hashValid:Bool) {
		this.levels = levels;
		this.hashValid = hashValid;
	}
}
