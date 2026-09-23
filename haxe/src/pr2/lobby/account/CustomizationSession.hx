package pr2.lobby.account;

import pr2.net.LobbySocket;
import pr2.net.CommandHandler;
import pr2.lobby.SecureData;

/** Shared command serialization, deduplication and rank-token transitions. */
class CustomizationSession {
	public var rank(default, null):Int = 0;
	public var used(default, null):Int = 0;
	public var available(default, null):Int = 0;
	private var lastCommand:String = "";
	public function new() {}
	public function accept(data:AccountCustomizeData):Void {
		rank = data.rank; used = data.rankTokensUsed; available = data.rankTokensAvailable;
		AccountState.applyCustomize(data);
	}
	public function save(parts:String, stats:String):Void {
		var command = "set_customize_info`" + parts + "`" + stats;
		if (command == lastCommand) return;
		lastCommand = command; LobbySocket.write(command);
	}
	public function token(add:Bool):Bool {
		if (add ? used >= available : used <= 0) return false;
		used += add ? 1 : -1; rank += add ? 1 : -1;
		SecureData.setNumber("userRank", rank);
		LobbySocket.write(add ? "use_rank_token`" : "unuse_rank_token`");
		refresh(); CommandHandler.commandHandler.dispatch("testLevelAccess", []);
		return true;
	}
	public function refresh():Void LobbySocket.write("get_customize_info`");
}
