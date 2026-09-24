package pr2.levelEditor;

import pr2.lobby.chat.ChatText;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;

/** Moderator report fields and request results shared by both editor views. */
class EditorReportService {
	public static function list(onResult:Dynamic->Void, onError:String->Void):Void {
		EditorLevelService.postList(ServerConfig.levelsGetReportedUrl(), EditorLevelService.listFields(), onResult, onError);
	}

	public static function archiveFields(level:Dynamic):Map<String, String> {
		return ["level_id" => field(level, "level_id"), "version" => field(level, "version")];
	}

	public static function banFields(level:Dynamic, reason:String, duration:Int):Map<String, String> {
		var id = field(level, "level_id");
		return [
			"level_id" => id,
			"banned_name" => field(level, "creator"),
			"duration" => Std.string(duration),
			"reason" => "Inappropriate Level -- " + reason,
			"scope" => "social",
			"record" => "Level ID: " + id + "\nTitle: " + ChatText.escapeString(field(level, "title")) + "\nNote: "
				+ ChatText.escapeString(field(level, "note")) + "\nVersion: " + field(level, "version")
		];
	}

	public static function archive(level:Dynamic, onResult:Dynamic->Void, onError:String->Void):Void {
		post(ServerConfig.archiveReportUrl(), archiveFields(level), onResult, onError);
	}

	public static function ban(level:Dynamic, reason:String, duration:Int, onResult:Dynamic->Void, onError:String->Void):Void {
		post(ServerConfig.banUserUrl(), banFields(level, reason, duration), onResult, onError);
	}

	private static function post(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
		FormPostClient.post(url, fields, function(body:String):Void {
			var result = SuperLoader.decodeUrlVariables(url, body, false);
			if (result.success) onResult(result.data); else onError(result.message);
		}, onError);
	}

	public static function field(level:Dynamic, key:String):String {
		var value = level == null ? null : Reflect.field(level, key);
		return value == null ? "" : Std.string(value);
	}
}
