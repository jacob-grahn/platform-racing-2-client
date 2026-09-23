package pr2.mobile;

import pr2.lobby.LobbySession;
import pr2.lobby.level.LevelActions;
import pr2.lobby.level.LevelRoom;
import pr2.lobby.level.LevelAccess.LevelAccessState;
import pr2.net.CampaignLevelInfo;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;
import pr2.util.AsyncRemovalGuard;

/** Lifetime of one mobile list entry; survives panel changes and resizes. */
class MobileLevelCard {
	public final info:CampaignLevelInfo;
	public final room:LevelRoom;
	public var onChange:Void->Void;
	public var message:String = "";
	public var passPending:Bool = false;
	public var passwordDraft:String = "";
	public var favoritePending:Bool = false;
	private var passOK:Bool = false;
	private var guard = new AsyncRemovalGuard();
	public function new(info:CampaignLevelInfo) { this.info = info; room = new LevelRoom(info.levelId, info.version); room.onChange = changed; }
	public function access():LevelAccessState return LevelActions.access(info, passOK);
	public function unlock(password:String):Void {
		if (passPending || access() != PassNeeded) return;
		passwordDraft = "";
		passPending = true; message = "Checking password…"; changed();
		guard.watch(LevelActions.passPostFactory(ServerConfig.levelPassCheckUrl(), LevelActions.passwordFields(info.levelId, password), guard.wrap(function(body) {
			passPending = false;
			try { passOK = LevelActions.parsePasswordResponse(body, info.levelId); } catch (_:Dynamic) { passOK = false; }
			message = passOK ? "" : "Incorrect password. Try again."; changed();
		}), guard.wrap(function(_) { passPending = false; message = "Couldn’t check password. Try again."; changed(); })));
	}
	public function toggleFavorite():Void {
		if (!LobbySession.isMember() || favoritePending) return;
		var mode = LobbySession.isFavorite(info.levelId) ? "remove" : "add";
		favoritePending = true; message = "Saving favorite…"; changed();
		guard.watch(FormPostClient.post(ServerConfig.favoriteModifyUrl(), ["mode" => mode, "level_id" => Std.string(info.levelId)], guard.wrap(function(body) {
			favoritePending = false;
			var result = SuperLoader.decodeJson(ServerConfig.favoriteModifyUrl(), body, false);
			if (result.success) {
				var returned = Reflect.field(result.data, "mode");
				LevelActions.favoriteResult(info.levelId, returned == null ? mode : Std.string(returned)); message = "";
			} else message = result.message == "" ? "Couldn’t save favorite." : result.message;
			changed();
		}), guard.wrap(function(_) { favoritePending = false; message = "Couldn’t save favorite. Try again."; changed(); })));
	}
	private function changed():Void { if (onChange != null) onChange(); }
	public function remove():Void { passwordDraft = ""; onChange = null; guard.remove(); room.onChange = null; room.remove(); }
}
