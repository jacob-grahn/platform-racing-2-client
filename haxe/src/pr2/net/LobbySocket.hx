package pr2.net;

#if js
import js.Browser;
import js.html.WebSocket;
#end

/**
	The single persistent game socket, mirroring Flash `Main.socket`: it is opened
	once when the player connects to a server and then reused for the whole
	session — the login handshake and every lobby/gameplay command share it. There
	is no per-page socket and no handing a connection from one owner to another.

	Incoming frames (END_CHAR terminated) are routed to `CommandHandler` by
	default. The login phase sets `onFrame` to intercept frames while it runs the
	`request_login_id` / `loginSuccessful` handshake, then clears it so the lobby
	resumes the normal `CommandHandler` routing on the very same connection.

	With no transport attached — headless tests and the OpenFL harness — writes are
	simply recorded into `sentCommands`, which lets parity tests assert exactly
	which commands a tab would have emitted without needing a live server.
**/
class LobbySocket {
	/** Commands written since the last `resetSent()` — inspected by tests. */
	public static var sentCommands:Array<String> = [];

	/** Login-phase frame interceptor; when null, frames go to `CommandHandler`. */
	public static var onFrame:Null<String->Void>;

	/** Connection lifecycle hooks for the login UI; the lobby ignores these. */
	public static var onOpen:Null<Void->Void>;
	public static var onConnectionError:Null<Void->Void>;
	public static var onConnectionClose:Null<Void->Void>;

	private static var protocol:Null<LoginSocketProtocol>;
	#if js
	private static var socket:Null<WebSocket>;
	private static var buffer:String = "";
	#end

	private function new() {}

	/** Open the one game socket for `server`, replacing any previous connection. */
	public static function connect(server:ServerInfo, secure:Bool = false):Void {
		#if js
		close();
		protocol = new LoginSocketProtocol(server.serverId);
		buffer = "";
		socket = new WebSocket(server.websocketUrl(secure));
		socket.onopen = function(_):Void {
			if (onOpen != null) {
				onOpen();
			}
		};
		socket.onmessage = function(event):Void {
			for (frame in splitFrames(Std.string(event.data))) {
				var handler = onFrame;
				if (handler != null) {
					handler(frame);
				} else {
					CommandHandler.commandHandler.handleServerFrame(frame);
				}
			}
		};
		socket.onerror = function(_):Void {
			if (onConnectionError != null) {
				onConnectionError();
			}
		};
		socket.onclose = function(_):Void {
			if (onConnectionClose != null) {
				onConnectionClose();
			}
		};
		#end
	}

	public static function write(command:String):Void {
		sentCommands.push(command);
		#if js
		Browser.document.body.setAttribute("data-pr2-last-command", command);
		if (socket != null && socket.readyState == WebSocket.OPEN && protocol != null) {
			socket.send(protocol.commandFrame(command));
		}
		#end
	}

	public static function close():Void {
		#if js
		if (socket != null) {
			socket.onopen = null;
			socket.onmessage = null;
			socket.onerror = null;
			socket.onclose = null;
			socket.close();
			socket = null;
		}
		buffer = "";
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
