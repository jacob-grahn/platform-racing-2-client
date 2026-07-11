package pr2.net;

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

	public static function fetch(page:Int, onResult:CampaignListResult->Void, ?onError:String->Void):SuperLoader {
		return TextLoader.load(ServerConfig.listUrl(MODE, page), function(body:String):Void {
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
		var payload = LevelListPayload.parse(body);
		return new CampaignListResult(payload.levels, payload.hashValid);
	}

	/**
		Replicates `LevelListing.loadHandler`: hash the slice
		`ret.substr(10, ret.length - 53)` plus `LEVEL_LIST_SALT`.
	**/
	private static function computeHash(body:String):String {
		return LevelListPayload.computeHash(body);
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
