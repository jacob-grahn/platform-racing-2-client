package pr2.lobby.messages;

import haxe.Json;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

class MessagesSource {
	public static var fetch:String->(String->Void)->(String->Void)->AsyncRemovable = TextLoader.load;
	private var guard = new AsyncRemovalGuard();
	public function new() {}
	public function load(page:Int, done:Array<MessageData>->Void, error:String->Void):Void {
		guard.remove(); guard = new AsyncRemovalGuard();
		guard.watch(fetch(ServerConfig.messagesGetUrl(MessagesPaging.startIndex(page), MessagesPaging.ITEMS_PER_PAGE), guard.wrap(function(body) {
			var rows:Array<MessageData>;
			try { rows = parse(body); } catch (_:Dynamic) { error("Could not load messages. Please try again."); return; }
			done(rows);
		}), guard.wrap(error)));
	}
	public static function parse(body:String):Array<MessageData> {
		var data:Dynamic = Json.parse(body);
		if (data == null || !Std.isOfType(data.messages, Array)) throw "Invalid messages response";
		var rows:Array<Dynamic> = data.messages;
		return [for (row in rows) new MessageData(row)];
	}
	public function remove():Void guard.remove();
}
