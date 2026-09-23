package pr2.lobby.players;

import haxe.Json;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.util.AsyncRemovalGuard;

typedef DirectoryFetch = String->(String->Void)->(String->Void)->pr2.util.AsyncRemovalGuard.AsyncRemovable;

/** Owns Flash's roster command and HTTP directory requests, independent of artwork. */
class DirectorySource {
	public static var userFetch:DirectoryFetch = defaultFetch;
	public static var guildFetch:DirectoryFetch = defaultFetch;
	private static var onlineOwner:DirectorySource;
	private var guard = new AsyncRemovalGuard();
	private var names:Map<String, Bool> = [];
	private var row:DirectoryEntry->Void;
	public function new() {}
	public static function modes(member:Bool):Array<String> return member ? ["online", "friends", "following", "ignored"] : ["online", "guilds"];
	public function start(mode:String, row:DirectoryEntry->Void, done:Void->Void, error:String->Void):Void {
		this.row = row;
		if (mode == "online") {
			onlineOwner = this;
			CommandHandler.commandHandler.defineCommand("addUser", guard.wrap(onUser));
			LobbySocket.write("get_online_list`");
			done(); // The roster protocol has no completion frame, matching Flash.
		} else {
			var guild = mode == "guilds";
			guard.watch((guild ? guildFetch : userFetch)(guild ? ServerConfig.guildsTopUrl() : ServerConfig.userListUrl(mode), guard.wrap(function(body) {
				try {
					var parsed:Dynamic = Json.parse(body);
					var values:Dynamic = Reflect.field(parsed, guild ? "guilds" : "users");
					if (!Std.isOfType(values, Array)) throw "Invalid directory response";
					for (value in (cast values:Array<Dynamic>)) {
						if (value == null) throw "Invalid directory row";
						var entry = new DirectoryEntry(stringOf(Reflect.field(value, guild ? "guild_name" : "name")));
						if (guild) {
							entry.guildId = intOf(value.guild_id); entry.activeMembers = intOf(value.active_count); entry.gpToday = intOf(value.gp_today);
							row(entry);
						} else {
							entry.group = stringOf(value.group); entry.rank = intOf(value.rank); entry.hats = intOf(value.hats); entry.status = stringOf(value.status);
							add(entry);
						}
					}
					done();
				} catch (_:Dynamic) { error("Could not read this list. Please try again."); }
			}), guard.wrap(function(_) error("Could not load this list. Please try again."))));
		}
	}
	private function onUser(args:Array<String>):Void {
		var entry = new DirectoryEntry(args.length > 0 ? args[0] : "");
		entry.group = args.length > 1 ? args[1] : "0";
		entry.rank = args.length > 2 ? intOf(args[2]) : 0; entry.hats = args.length > 3 ? intOf(args[3]) : 0;
		add(entry);
	}
	private function add(entry:DirectoryEntry):Void {
		if (names.exists(entry.name)) return;
		names.set(entry.name, true); row(entry);
	}
	public static function intOf(value:Dynamic):Int {
		if (value == null) return 0;
		var parsed = Std.parseInt(Std.string(value)); return parsed == null ? 0 : parsed;
	}
	private static function stringOf(value:Dynamic):String return value == null ? "" : Std.string(value);
	private static function defaultFetch(url:String, data:String->Void, error:String->Void):pr2.util.AsyncRemovalGuard.AsyncRemovable return TextLoader.load(url, data, error);
	public function remove():Void {
		guard.remove(); row = null;
		if (onlineOwner == this) { onlineOwner = null; CommandHandler.commandHandler.defineCommand("addUser", null); }
	}
}
