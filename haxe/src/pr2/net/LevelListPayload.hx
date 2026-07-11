package pr2.net;

import haxe.Json;
import haxe.crypto.Md5;

/** Parsed fields shared by every level-list endpoint. */
class LevelListPayload {
	public final levels:Array<CampaignLevelInfo>;
	public final hashValid:Bool;

	public function new(levels:Array<CampaignLevelInfo>, hashValid:Bool) {
		this.levels = levels;
		this.hashValid = hashValid;
	}

	public static function parse(body:String):LevelListPayload {
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
		return new LevelListPayload(levels, expectedHash != null && Std.string(expectedHash) == computeHash(body));
	}

	public static function computeHash(body:String):String {
		var sliceLength = body.length - 53;
		if (sliceLength <= 0) {
			return "";
		}
		return Md5.encode(body.substr(10, sliceLength) + ServerConfig.LEVEL_LIST_SALT);
	}
}
