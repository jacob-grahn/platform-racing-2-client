package pr2.lobby.players;

import haxe.Json;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

typedef GuildFetch = String->(String->Void)->(String->Void)->AsyncRemovable;

/** One cancellable guild detail request shared by classic and mobile. */
class GuildSource {
	public static var fetch:GuildFetch = defaultFetch;
	private var guard = new AsyncRemovalGuard();
	private var active:Bool = true;
	public function new() {}
	public function load(id:Int, name:String, onResult:GuildData->Void, onError:String->Void):Void {
		guard.watch(fetch(ServerConfig.guildInfoUrl(id, name), guard.wrap(function(body) {
			if (!active) return;
			try {
				var raw:Dynamic = Json.parse(body);
				var data = new GuildData(raw);
				if (data.id == 0 || data.name == "") onError("Could not load this guild."); else onResult(data);
			} catch (_:Dynamic) onError("Could not load this guild.");
		}), guard.wrap(onError)));
	}
	public function remove():Void { if (!active) return; active = false; guard.remove(); }
	private static function defaultFetch(url:String, onResult:String->Void, onError:String->Void):AsyncRemovable return TextLoader.load(url, onResult, onError);
}
