package pr2.lobby.players;

import pr2.lobby.dialogs.UploadingPopup;
import pr2.lobby.players.SocialAction;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;

/**
	Executes a follow/friend/ignore action exactly as Flash `dialogs.PlayerPopup`
	does: POST `target_id`/`list`/`mode` to `user_list_modify.php` through the
	shared `UploadingPopup`, and write the matching gameserver socket command
	(`follow_user`, `add_friend`, ...). The decision of which list/mode/verb maps
	to each action lives in the pure `SocialActionPlan`.
**/
class SocialActions {
	private function new() {}

	public static function perform(action:SocialAction, targetId:Int, targetName:String):Void {
		var req = SocialActionPlan.plan(action);
		var fields = ["target_id" => Std.string(targetId), "list" => req.list, "mode" => req.mode];
		new UploadingPopup(ServerConfig.userListModifyUrl(), fields, "Updating...");
		LobbySocket.write(req.socketVerb + "`" + targetName);
	}
}
