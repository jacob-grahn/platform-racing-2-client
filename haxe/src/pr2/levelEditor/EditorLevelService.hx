package pr2.levelEditor;

import haxe.Json;
import haxe.crypto.Md5;
import pr2.lobby.LobbySession;
import pr2.net.FormPostClient;
import pr2.net.LevelDataClient;
import pr2.net.ServerConfig;
import pr2.net.ServerLevelData;
import pr2.net.SuperLoader;

/** Request fields and transport shared by the classic and mobile editor views. */
class EditorLevelService {
	public static function listFields():Map<String, String> {
		var fields = new Map<String, String>();
		fields.set("token", LobbySession.token);
		return fields;
	}

	public static function list(onResult:Dynamic->Void, onError:String->Void):SuperLoader {
		return postList(ServerConfig.levelsGetUrl(), listFields(), onResult, onError);
	}

	public static function postList(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):SuperLoader {
		return FormPostClient.post(url, fields, function(body:String):Void {
			if (body == null || body == "") { onResult({levels: []}); return; }
			try onResult(Json.parse(body)) catch (_:Dynamic) onError("The loaded data was not in the expected format.");
		}, onError);
	}

	public static function load(levelId:Int, version:Int, onResult:ServerLevelData->Void, onError:String->Void):Void {
		LevelDataClient.fetchEditorLoad(levelId, version, onResult, onError);
	}

	public static function deleteFields(levelId:Int):Map<String, String> {
		var fields = listFields();
		fields.set("level_id", Std.string(levelId));
		fields.set("rand", Std.string(Std.random(10000000)));
		return fields;
	}

	public static function deleteLevel(levelId:Int, onResult:Dynamic->Void, onError:String->Void):SuperLoader {
		var url = ServerConfig.deleteLevelUrl();
		return FormPostClient.post(url, deleteFields(levelId), function(body:String):Void {
			var result = SuperLoader.decodeUrlVariables(url, body, false);
			if (result.success) onResult(result.data); else onError(result.message);
		}, onError);
	}

	public static function saveFields(editor:LevelEditor, overrideBan:Bool = false, overwriteExisting:Bool = false):Map<String, String> {
		var fields = LevelEditor.copyVars(editor.getLevelVars());
		var data = fields.get("data");
		var title = fields.get("title");
		fields.set("hash", Md5.encode((title == null ? "" : title) + LobbySession.userName.toLowerCase()
			+ (data == null ? "" : data) + ServerConfig.LEVEL_SALT));
		fields.set("to_newest", editor.toNewest ? "1" : "0");
		fields.set("override_banned", overrideBan ? "1" : "0");
		fields.set("overwrite_existing", overwriteExisting ? "1" : "0");
		fields.set("rand", Std.string(Std.random(10000000)));
		fields.set("token", LobbySession.token);
		return fields;
	}

	public static function upload(editor:LevelEditor, overrideBan:Bool, overwriteExisting:Bool,
			onResult:Dynamic->Void, onError:String->Void):SuperLoader {
		var url = ServerConfig.uploadLevelUrl();
		return FormPostClient.post(url, saveFields(editor, overrideBan, overwriteExisting), function(body:String):Void {
			var result = SuperLoader.decodeUrlVariables(url, body, false);
			// The upload endpoint also returns actionable statuses (exists/banned)
			// in unsuccessful responses; the caller must be able to present them.
			if (result.data != null) onResult(result.data); else onError(result.message);
		}, onError);
	}
}
