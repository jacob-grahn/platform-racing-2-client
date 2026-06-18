package pr2.lobby.players;

import pr2.net.CommandHandler;
import pr2.net.LobbySocket;

/**
	Port of Flash `social.Online`: the live online-players list. Registers an
	`addUser` command on the shared `CommandHandler` and asks the gameserver for
	the roster with `get_online_list``; each `addUser` frame adds a row.
**/
class Online extends PlayersTabList {
	override public function initialize():Void {
		super.initialize();
		hideLoadingGraphic();
		CommandHandler.commandHandler.defineCommand("addUser", onAddUser);
		LobbySocket.write("get_online_list`");
	}

	private function onAddUser(args:Array<String>):Void {
		var name = args.length > 0 ? args[0] : "";
		var group = args.length > 1 ? args[1] : "0";
		var rank = args.length > 2 ? intOf(args[2]) : 0;
		var hats = args.length > 3 ? intOf(args[3]) : 0;
		addUserEntry(name, group, rank, hats);
	}

	private static function intOf(value:String):Int {
		var parsed = Std.parseInt(value);
		return parsed == null ? 0 : parsed;
	}

	override public function remove():Void {
		CommandHandler.commandHandler.defineCommand("addUser", null);
		super.remove();
	}
}
