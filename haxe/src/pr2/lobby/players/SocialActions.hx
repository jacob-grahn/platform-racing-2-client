package pr2.lobby.players;

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
		pr2.app.ScreenFactory.upload(ServerConfig.userListModifyUrl(), fields(action, targetId), "Updating...", function(_:Dynamic) {});
		notifyServer(action, targetName);
	}
	public static function fields(action:SocialAction, targetId:Int):Map<String,String> {
		var req = SocialActionPlan.plan(action);
		return ["target_id" => Std.string(targetId), "list" => req.list, "mode" => req.mode];
	}
	public static function notifyServer(action:SocialAction, name:String):Void LobbySocket.write(SocialActionPlan.plan(action).socketVerb + "`" + name);
}
