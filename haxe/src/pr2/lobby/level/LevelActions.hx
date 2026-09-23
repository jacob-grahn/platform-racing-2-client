package pr2.lobby.level;

import haxe.Json;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.LobbySession;
import pr2.lobby.SecureData;
import pr2.lobby.account.AccountState;
import pr2.lobby.level.LevelAccess.LevelAccessState;
import pr2.net.CampaignLevelInfo;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

class LevelActions {
	public static var passPostFactory:String->Map<String,String>->(String->Void)->(String->Void)->AsyncRemovable = FormPostClient.post;
	public static function access(info:CampaignLevelInfo, passOK:Bool):LevelAccessState {
		return LevelAccess.evaluate(info.pass, passOK, LobbySession.group, LobbySession.userName.toLowerCase() == info.userName.toLowerCase(),
			Std.int(SecureData.getNumber("userRank")), info.minLevel, AccountState.currentHat, info.badHats);
	}
	public static function passwordFields(id:Int, password:String):Map<String,String> {
		return ["course_id" => Std.string(id), "hash" => haxe.crypto.Md5.encode(password + ServerConfig.LEVEL_PASS_SALT)];
	}
	public static function parsePasswordResponse(body:String, id:Int):Bool {
		var ret:Dynamic = Json.parse(body);
		if (Reflect.field(ret, "success") != true) return false;
		var value = PR2Encryptor.decryptBase64(Std.string(Reflect.field(ret, "result")), ServerConfig.LEVEL_PASS_KEY, ServerConfig.LEVEL_PASS_IV);
		var start = value.indexOf("{"); var end = value.indexOf("}", start);
		if (start >= 0 && end >= start) value = value.substring(start, end + 1);
		var obj:Dynamic = Json.parse(StringTools.trim(value));
		return Std.parseInt(Std.string(Reflect.field(obj, "level_id"))) == id && Std.parseInt(Std.string(Reflect.field(obj, "access"))) == 1;
	}
	public static function favoriteResult(id:Int, mode:String):Void {
		if (mode == "add") { if (!LobbySession.isFavorite(id)) LobbySession.favoriteLevels.push(id); }
		else LobbySession.favoriteLevels.remove(id);
	}
}
