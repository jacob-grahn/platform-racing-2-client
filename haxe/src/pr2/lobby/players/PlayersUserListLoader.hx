package pr2.lobby.players;

import haxe.Json;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;

/**
	Port of Flash `social.PlayersTabUserListDataLoader`: loads a player list from
	`user_list_get.php?mode=...` and adds each returned user as a row. Friends,
	Following, and Ignored are thin subclasses that pass their mode.
**/
class PlayersUserListLoader extends PlayersTabList {
	private var mode:String;

	public function new(mode:String) {
		super();
		this.mode = mode;
	}

	override public function initialize():Void {
		super.initialize();
		TextLoader.load(ServerConfig.userListUrl(mode), onData, onError);
	}

	private function onData(body:String):Void {
		try {
			var parsed:Dynamic = Json.parse(body);
			var users:Array<Dynamic> = parsed.users;
			if (users != null) {
				for (user in users) {
					var status:String = user.status != null ? Std.string(user.status) : "";
					addUserEntry(Std.string(user.name), Std.string(user.group), intOf(user.rank), intOf(user.hats), status);
				}
			}
		} catch (error:Dynamic) {
			// Malformed payload — leave the list empty, like the original on a bad parse.
		}
		hideLoadingGraphic();
	}

	private function onError(message:String):Void {
		hideLoadingGraphic();
	}

	private static function intOf(value:Dynamic):Int {
		if (value == null) {
			return 0;
		}
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			return Std.int(value);
		}
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? 0 : parsed;
	}
}
