package pr2.net;

import com.jiggmin.data.Time;
import haxe.Timer;
#if js
import js.Browser;
import js.html.WebSocket;
#end
import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.messages.UnreadNotif;

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
	public static var sendNum:Int = 0;
	public static var closeCount:Int = 0;
	public static var campaignPage:Int = 0;
	public static var nowMs:Void->Float = defaultNowMs;

	/** Login-phase frame interceptor; when null, frames go to `CommandHandler`. */
	public static var onFrame:Null<String->Void>;

	/** Connection lifecycle hooks for the login UI; the lobby ignores these. */
	public static var onOpen:Null<Void->Void>;
	public static var onConnectionError:Null<Void->Void>;
	public static var onConnectionClose:Null<Void->Void>;

	private static var protocol:Null<LoginSocketProtocol>;
	private static var connected:Bool = false;
	private static var pingIntervalActive:Bool = false;
	private static var pingTimer:Null<Timer>;
	private static var serverTime:Time = new Time(function():Float return nowMs());
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
			connected = true;
			startPingInterval();
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
			handleConnectionError();
		};
		socket.onclose = function(_):Void {
			handleConnectionClose();
		};
		#end
	}

	public static function write(command:String):Void {
		sentCommands.push(command);
		sendNum++;
		if (sendNum == 12) {
			sendNum++;
		}
		#if js
		Browser.document.body.setAttribute("data-pr2-last-command", command);
		if (socket != null && socket.readyState == WebSocket.OPEN && protocol != null) {
			socket.send(protocol.commandFrame(command));
		}
		#end
	}

	public static function close():Void {
		closeCount++;
		if (connected) {
			write("close`");
		}
		stopPingInterval();
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
		connected = false;
		protocol = null;
		sendNum = 0;
		CommandHandler.commandHandler.sendNum = -1;
		clearRuntimeState();
	}

	/** True when a real transport is connected (vs. record-only headless mode). */
	public static function isConnected():Bool {
		#if js
		return connected && socket != null && socket.readyState == WebSocket.OPEN;
		#else
		return connected;
		#end
	}

	public static function resetSent():Void {
		sentCommands = [];
		sendNum = 0;
		closeCount = 0;
		connected = false;
		stopPingInterval();
		nowMs = defaultNowMs;
		serverTime = new Time(function():Float return nowMs());
	}

	/** Last command emitted, or "" if none — convenience for assertions. */
	public static function lastSent():String {
		return sentCommands.length == 0 ? "" : sentCommands[sentCommands.length - 1];
	}

	public static function sendPing():Void {
		if (isConnected()) {
			write("ping`");
		}
	}

	public static function receivePing(args:Array<String>):Void {
		var serverSeconds = args.length > 0 ? Std.parseFloat(args[0]) : Math.NaN;
		if (Math.isNaN(serverSeconds)) {
			return;
		}
		var localSeconds = serverTime.getTimestamp();
		if (Math.abs(serverSeconds - localSeconds) > 2) {
			serverTime.setTime(serverSeconds);
		}
	}

	public static function getMS():Float {
		return serverTime.getMS();
	}

	public static function getTimestamp():Float {
		return serverTime.getTimestamp();
	}

	public static function getDay():Float {
		return serverTime.getDay();
	}

	public static function pingIsActiveForTests():Bool {
		return pingIntervalActive;
	}

	public static function simulateOpenForTests():Void {
		connected = true;
		startPingInterval();
		if (onOpen != null) {
			onOpen();
		}
	}

	public static function simulateConnectionCloseForTests():Void {
		handleConnectionClose();
	}

	public static function simulateConnectionErrorForTests():Void {
		handleConnectionError();
	}

	public static function remove():Void {
		onOpen = null;
		onFrame = null;
		onConnectionError = null;
		onConnectionClose = null;
		close();
	}

	private static function startPingInterval():Void {
		stopPingInterval();
		pingIntervalActive = true;
		#if js
		pingTimer = new Timer(10000);
		pingTimer.run = sendPing;
		#end
	}

	private static function stopPingInterval():Void {
		#if js
		if (pingTimer != null) {
			pingTimer.stop();
		}
		#end
		pingTimer = null;
		pingIntervalActive = false;
	}

	private static function handleConnectionClose():Void {
		stopPingInterval();
		connected = false;
		clearRuntimeState();
		if (onConnectionClose != null) {
			onConnectionClose();
		} else {
			new MessagePopup("Disconnected.");
		}
	}

	private static function handleConnectionError():Void {
		stopPingInterval();
		connected = false;
		clearRuntimeState();
		if (onConnectionError != null) {
			onConnectionError();
		} else {
			new MessagePopup("Could not connect. This could be because: \n A: My server is broken. \n B: The internet is broken. \n C: Evil aliens.");
		}
	}

	private static function clearRuntimeState():Void {
		Memory.remove("coursePageNumcampaign");
		Memory.remove("campaignInfo" + campaignPage);
		LobbySession.isSpecialUser = false;
		LobbySession.isPrizer = false;
		LobbySession.isTempMod = false;
		LobbySession.isTrialMod = false;
		LobbySession.tournamentMode = false;
		LobbySession.serverOwner = 0;
		UnreadNotif.reset();
	}

	private static function defaultNowMs():Float {
		return Date.now().getTime();
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
