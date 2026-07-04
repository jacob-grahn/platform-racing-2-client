package pr2.lobby.dialogs;

import pr2.lobby.LobbySession;
import pr2.net.ServerConfig;

class GuildJoinPopup extends UploadingPopup {
	public function new(id:Int) {
		super(ServerConfig.guildJoinUrl(), ["guild_id" => Std.string(id)], "Joining guild...", parsedDataHandler);
	}

	private function parsedDataHandler(ret:Dynamic):Void {
		LobbySession.updateGuildFromData(ret, false);
	}
}
