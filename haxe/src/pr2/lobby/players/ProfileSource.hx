package pr2.lobby.players;

import haxe.Json;
import haxe.Timer;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

/** Socket-first profile lookup. Untagged socket replies must never cross targets. */
class ProfileSource {
	public static var fetch:String->(String->Void)->(String->Void)->AsyncRemovable = TextLoader.load;
	public static var connected:Void->Bool = LobbySocket.isConnected;
	private static var socketOwner:ProfileSource;
	private var guard = new AsyncRemovalGuard();
	private var timer:Timer;
	private var userName:String;
	private var done:Dynamic->Void;
	private var error:String->Void;
	private var httpStarted:Bool = false;
	public function new() {}
	public function load(name:String, done:Dynamic->Void, error:String->Void):Void {
		userName = name; this.done = done; this.error = error;
		if (connected() && socketOwner == null) {
			socketOwner = this;
			CommandHandler.commandHandler.defineCommand("playerInfo", socketReply);
			timer = Timer.delay(fromHTTP, 5000);
			LobbySocket.write("get_player_info`" + name);
		} else fromHTTP();
	}
	private function socketReply(args:Array<String>):Void {
		if (socketOwner != this) return;
		socketOwner = null; CommandHandler.commandHandler.defineCommand("playerInfo", null);
		stopTimer();
		if (!guard.isActive() || httpStarted) return;
		var data:Dynamic;
		try { data = parse(args.length == 0 ? "0" : args[0]); }
		catch (_:Dynamic) { fromHTTP(); return; }
		if (done != null) done(data);
	}
	private function fromHTTP():Void {
		stopTimer();
		if (!guard.isActive() || httpStarted) return;
		httpStarted = true;
		guard.watch(fetch(ServerConfig.getPlayerInfoUrl(userName), guard.wrap(function(body) {
			var data:Dynamic;
			try { data = parse(body); } catch (_:Dynamic) { if (error != null) error("Could not load this player. Please try again."); return; }
			if (done != null) done(data);
		}), guard.wrap(function(message) { if (error != null) error(message); })));
	}
	public static function parse(body:String):Dynamic {
		var data:Dynamic = Json.parse(body);
		if (data == null || !Reflect.hasField(data, "group") || Reflect.hasField(data, "error")) throw "Invalid profile";
		return data;
	}
	private function stopTimer():Void { if (timer != null) timer.stop(); timer = null; }
	public function remove():Void {
		guard.remove(); stopTimer(); done = null; error = null;
		// Keep the pending socket slot as a reply sink: the protocol has no request
		// id. New profiles use HTTP until this outstanding reply is consumed.
	}
}
