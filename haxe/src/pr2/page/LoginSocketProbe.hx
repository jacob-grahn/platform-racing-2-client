package pr2.page;

import pr2.net.LobbySocket;
import pr2.net.CommandHandler;
import pr2.net.ServerInfo;

enum LoginProbeStatus {
	Message(message:String);
	LoginId(loginId:String);
	LoginSuccessful(group:Int, userName:String);
	LoginFailed(message:String);
	ServerMessageReceived(message:String);
	ConnectionClosed(message:String);
}

/**
	Drives the login handshake over the one global `LobbySocket` connection: it
	opens the socket, requests a login id, and parses the login frames into
	`LoginProbeStatus` updates for the menu UI. It owns no socket of its own — once
	login succeeds the same connection is reused by the lobby (see
	`LoginPage.enterLobby`), matching the Flash single `Main.socket`.
**/
class LoginSocketProbe {
	private var server:ServerInfo;
	private var onStatus:LoginProbeStatus->Void;

	public function new(server:ServerInfo, onStatus:LoginProbeStatus->Void) {
		this.server = server;
		this.onStatus = onStatus;
	}

	public function connect():Void {
		var handler = CommandHandler.commandHandler;
		handler.serverId = server.serverId;
		handler.defineCommand("setLoginID", function(args):Void {
			onStatus(LoginId(args.length > 0 ? args[0] : ""));
		});
		handler.defineCommand("loginSuccessful", function(args):Void {
			var group = args.length > 0 ? Std.parseInt(args[0]) : null;
			onStatus(LoginSuccessful(group == null ? 0 : group, args.length > 1 ? args[1] : ""));
		});
		handler.defineCommand("loginFailure", function(args):Void {
			var message = args.join(" ");
			onStatus(LoginFailed(message == "" ? "Login failed." : message));
		});
		// The login UI needs the server message so a following connection close can
		// report the real reason. This temporarily overrides the default message
		// handler, just as Flash pages temporarily register socket commands.
		handler.defineCommand("message", function(args):Void {
			onStatus(ServerMessageReceived(args.length > 0 ? args[0] : ""));
		});
		#if js
		LobbySocket.onOpen = function():Void {
			onStatus(Message('Connected to ${server.label()}; requesting login id...'));
			LobbySocket.write("request_login_id`");
		};
		LobbySocket.onConnectionError = function():Void {
			onStatus(LoginFailed('Could not connect to ${server.label()} over WebSocket.'));
		};
		LobbySocket.onConnectionClose = function():Void {
			onStatus(ConnectionClosed('Connection to ${server.label()} closed.'));
		};
		var secure = js.Browser.location.protocol == "https:";
		LobbySocket.connect(server, secure);
		#else
		onStatus(Message("Server connection probing is available on the html5 target."));
		#end
	}

	/** Detach login-only commands without tearing down the shared connection. */
	public function release():Void {
		var handler = CommandHandler.commandHandler;
		handler.defineCommand("setLoginID", null);
		handler.defineCommand("loginSuccessful", null);
		handler.defineCommand("loginFailure", null);
		handler.defineCommand("message", null);
		LobbySocket.onOpen = null;
		LobbySocket.onConnectionError = null;
		LobbySocket.onConnectionClose = null;
	}

	/** Cancel the login attempt and close the connection. */
	public function close():Void {
		release();
		LobbySocket.close();
	}

}
