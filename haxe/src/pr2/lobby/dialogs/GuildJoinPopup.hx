package pr2.lobby.dialogs;

import pr2.lobby.LobbySession;
import pr2.net.ServerConfig;

class GuildJoinPopup extends UploadingPopup {
	public function new(id:Int) {
		super(ServerConfig.guildJoinUrl(), ["guild_id" => Std.string(id)], "Joining guild...", parsedDataHandler);
	}

	private function parsedDataHandler(ret:Dynamic):Void {
		if (ret == null) {
			return;
		}
		LobbySession.guildId = intAny(ret, ["guild_id", "guildId"]);
		LobbySession.emblem = strAny(ret, ["emblem"]);
		LobbySession.guildName = strAny(ret, ["guild_name", "guildName"]);
		LobbySession.guildOwner = false;
		LobbySession.notifyAccountChange();
	}

	private static function intAny(ret:Dynamic, names:Array<String>):Int {
		for (name in names) {
			var value:Dynamic = Reflect.field(ret, name);
			if (value != null) {
				var parsed = Std.parseInt(Std.string(value));
				return parsed == null ? 0 : parsed;
			}
		}
		return 0;
	}

	private static function strAny(ret:Dynamic, names:Array<String>):String {
		for (name in names) {
			var value:Dynamic = Reflect.field(ret, name);
			if (value != null) return Std.string(value);
		}
		return "";
	}
}
