package pr2.net;

#if js
import js.html.WebSocket;
#end

/**
	Wrapper for the Flash `Main.socket` used by lobby pages to talk to the
	gameserver. Pages call `LobbySocket.write("set_chat_room`main")` and register
	incoming-command handlers through `CommandHandler`.

	On the html5 target this drives a real WebSocket (frames are END_CHAR
	terminated). With no transport attached — headless tests and the OpenFL
	harness — writes are simply recorded into `sentCommands`, which lets parity
	tests assert exactly which commands a tab would have emitted without needing a
	live server.
**/
class LobbySocket {
	/** Commands written since the last `resetSent()` — inspected by tests. */
	public static var sentCommands:Array<String> = [];

	private static var protocol:Null<LoginSocketProtocol>;
	#if js
	private static var socket:Null<WebSocket>;
	private static var buffer:String = "";
	#end

	private function new() {}

	/** Attach a live WebSocket session for a connected server. */
	public static function attach(server:ServerInfo, secure:Bool = false):Void {
		#if js
		protocol = new LoginSocketProtocol(server.serverId);
		buffer = "";
		socket = new WebSocket(server.websocketUrl(secure));
		socket.onmessage = function(event):Void {
			for (frame in splitFrames(Std.string(event.data))) {
				CommandHandler.commandHandler.handleServerFrame(frame);
			}
		};
		#end
	}

	public static function write(command:String):Void {
		sentCommands.push(command);
		#if js
		if (socket != null && socket.readyState == WebSocket.OPEN && protocol != null) {
			socket.send(protocol.commandFrame(command));
		}
		#end
	}

	public static function close():Void {
		#if js
		if (socket != null) {
			socket.close();
			socket = null;
		}
		#end
		protocol = null;
	}

	/** True when a real transport is connected (vs. record-only headless mode). */
	public static function isConnected():Bool {
		#if js
		return socket != null && socket.readyState == WebSocket.OPEN;
		#else
		return false;
		#end
	}

	public static function resetSent():Void {
		sentCommands = [];
	}

	/** Last command emitted, or "" if none — convenience for assertions. */
	public static function lastSent():String {
		return sentCommands.length == 0 ? "" : sentCommands[sentCommands.length - 1];
	}

	#if js
	// Server frames are terminated by END_CHAR (\x04). Buffer partial reads and
	// emit only complete frames.
	private static function splitFrames(data:String):Array<String> {
		buffer += data;
		var frames = [];
		var endIndex = buffer.indexOf(LoginSocketProtocol.END_CHAR);
		while (endIndex >= 0) {
			frames.push(buffer.substr(0, endIndex));
			buffer = buffer.substr(endIndex + 1);
			endIndex = buffer.indexOf(LoginSocketProtocol.END_CHAR);
		}
		return frames;
	}
	#end
}
