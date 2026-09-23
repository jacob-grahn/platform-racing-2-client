package pr2.lobby;

import pr2.page.Page;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.net.FormPostClient;

/** Session transitions shared by the classic strip and the mobile game menu. */
class LobbyActions {
	public static var createLoginPage:Void->Page = function() return pr2.app.ScreenFactory.login();
	public static var createLevelEditorPage:Bool->Page = function(isMod) return new pr2.levelEditor.LevelEditor(null, isMod);
	public static var logoutPostFactory:String->Map<String, String>->Void = function(url, fields) {
		FormPostClient.post(url, fields, function(_) {}, function(_) {});
	};
	public static inline var LOGOUT_WARNING = "You're currently a temporary moderator. Logging out will automatically demote you back to a member. Do you really want to proceed?";
	public static inline var EDITOR_WARNING = "You're currently a temporary moderator. Entering the level editor will log you out, which will automatically demote you back to a member. Do you really want to proceed?";
	public static inline var LOGOUT_MESSAGE = "You are now logged out. If you haven't already done so, please notify a member of the staff team that you've ended your moderation session.";
	private var navigate:Page->Void;
	private var confirm:(String, Void->Void)->Void;
	private var notify:String->Void;
	private var alive:Bool = true;
	public function new(navigate:Page->Void, confirm:(String, Void->Void)->Void, notify:String->Void) {
		this.navigate = navigate; this.confirm = confirm; this.notify = notify;
	}
	public static function needsWarning():Bool return LobbySession.isTempMod && (LobbySession.server == null || LobbySession.server.guildId == 0);
	public function logout(confirmed:Bool = false):Void {
		if (!alive) return;
		if (needsWarning() && !confirmed) { confirm(LOGOUT_WARNING, function() logout(true)); return; }
		endSession(needsWarning());
		navigate(createLoginPage());
	}
	public function editor(confirmed:Bool = false):Void {
		if (!alive) return;
		if (needsWarning() && !confirmed) { confirm(EDITOR_WARNING, function() editor(true)); return; }
		var isMod = !LobbySession.isTempMod && !LobbySession.isTrialMod && LobbySession.group >= 2;
		if (needsWarning()) endSession(true); else LobbySocket.close();
		navigate(createLevelEditorPage(isMod));
	}
	private function endSession(message:Bool):Void {
		if (message) notify(LOGOUT_MESSAGE);
		if (!LobbySession.remember) logoutPostFactory(ServerConfig.logoutUrl(), new Map());
		LobbySession.clear(); LobbySocket.close();
	}
	public function remove():Void { alive = false; navigate = null; confirm = null; notify = null; }
}
