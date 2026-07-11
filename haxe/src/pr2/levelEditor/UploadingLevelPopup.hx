package pr2.levelEditor;

import haxe.crypto.Md5;
import haxe.Timer;
import pr2.lobby.LobbySession;
import pr2.lobby.chat.ChatText;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.ServerConfig;
import pr2.levelEditor.EditorPersistenceTypes.UploadingLevelPostFactory;
import pr2.levelEditor.EditorPersistenceTypes.UploadingLevelRetryFactory;

class UploadingLevelPopup extends Popup {
	public static var postFactory:UploadingLevelPostFactory = defaultPost;
	public static var retryFactory:UploadingLevelRetryFactory = defaultRetry;

	public final editor:LevelEditor;
	public final overrideBanConfirmed:Bool;
	public final overwriteExistingConfirmed:Bool;
	private var uploading:Null<UploadingPopup>;
	private var waitTimer:Null<Timer>;

	public function new(editor:LevelEditor, overrideBan:Bool = false, overwriteExisting:Bool = false) {
		super();
		this.editor = editor;
		overrideBanConfirmed = overrideBan;
		overwriteExistingConfirmed = overwriteExisting;
		if (uploadLevel()) {
			startFadeOut();
		}
	}

	private function uploadLevel():Bool {
		if (editor.isDrawing()) {
			clearWaitTimer();
			waitTimer = retryFactory(function():Void {
				waitTimer = null;
				if (uploadLevel()) {
					startFadeOut();
				}
			}, 1000);
			return false;
		}
		var fields = buildFields(editor, overrideBanConfirmed, overwriteExistingConfirmed);
		if (fields.get("data") == null || fields.get("data") == "") {
			new MessagePopup("The client is glitching out. Could not save your level.");
			return true;
		}
		uploading = postFactory(ServerConfig.uploadLevelUrl(), fields, "Uploading level...", handleResponse, handleUploadError);
		return true;
	}

	private function handleResponse(ret:Dynamic):Void {
		if (ret == null) {
			new MessagePopup("Error: The loaded data was not in the expected format.");
			return;
		}
		var message = Reflect.field(ret, "message");
		if (message != null) {
			new MessagePopup(Std.string(message));
		}
		var status = Reflect.field(ret, "status");
		if (status == "exists") {
			new ConfirmPopup(function():Void {
				new UploadingLevelPopup(editor, overrideBanConfirmed, true);
			}, "You have another level with this title. Is it okay to overwrite the existing level with this save?");
		} else if (status == "banned") {
			new ConfirmPopup(function():Void {
				new UploadingLevelPopup(editor, true, overwriteExistingConfirmed);
			}, bannedConfirmationMessage(ret));
		} else if (status != "banned" && failedResponse(ret)) {
			new MessagePopup("Error: " + errorMessage(ret));
		}
	}

	private function handleUploadError(message:String):Void {
		if (message != null && message != "") {
			new MessagePopup("Error: " + message);
		}
	}

	private static function failedResponse(ret:Dynamic):Bool {
		return Reflect.hasField(ret, "error") || (Reflect.hasField(ret, "success") && Reflect.field(ret, "success") != true);
	}

	private static function errorMessage(ret:Dynamic):String {
		if (Reflect.hasField(ret, "error")) {
			return Std.string(Reflect.field(ret, "error"));
		}
		return "An unknown error occurred. I suspect evil aliens.";
	}

	private static function bannedConfirmationMessage(ret:Dynamic):String {
		var banId = Reflect.hasField(ret, "ban_id") ? Std.string(Reflect.field(ret, "ban_id")) : "";
		var banLang = Reflect.field(ret, "scope") == "s" ? "socially " : "";
		var url = ServerConfig.getHost() + "/bans/show_record.php?ban_id=" + ChatText.escapeString(banId);
		var link = '<a href="' + ChatText.escapeString(url) + '" target="_blank"><u><font color="#0000FF">'
			+ banLang + "banned</font></u></a>";
		return "Because you are currently " + link
			+ ", you can only save this level as unpublished without a password. Is it okay to continue with these settings?";
	}

	public static function buildFields(editor:LevelEditor, overrideBan:Bool = false, overwriteExisting:Bool = false):Map<String, String> {
		var fields = LevelEditor.copyVars(editor.getLevelVars());
		var data = fields.get("data");
		if (data == null) {
			data = "";
		}
		var title = fields.get("title");
		if (title == null) {
			title = "";
		}
		fields.set("hash", Md5.encode(title + LobbySession.userName.toLowerCase() + data + ServerConfig.LEVEL_SALT));
		fields.set("to_newest", editor.toNewest ? "1" : "0");
		fields.set("override_banned", overrideBan ? "1" : "0");
		fields.set("overwrite_existing", overwriteExisting ? "1" : "0");
		fields.set("rand", Std.string(Std.random(10000000)));
		fields.set("token", LobbySession.token);
		return fields;
	}

	public static function defaultPost(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
			onError:String->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult, onError);
	}

	public static function defaultRetry(callback:Void->Void, delayMs:Int):Null<Timer> {
		return Timer.delay(callback, delayMs);
	}

	private function clearWaitTimer():Void {
		if (waitTimer != null) {
			waitTimer.stop();
			waitTimer = null;
		}
	}

	override public function remove():Void {
		clearWaitTimer();
		super.remove();
	}
}
