package pr2.page;

import pr2.net.LobbySocket;
import pr2.net.LoginSocketProtocol;
import pr2.net.LoginSocketProtocol.LoginSocketMessage;
import pr2.net.ServerInfo;

enum LoginProbeStatus {
	Message(message:String);
	LoginId(loginId:String);
	LoginSuccessful(group:Int, userName:String);
	LoginFailed(message:String);
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
		#if js
		LobbySocket.onOpen = function():Void {
			onStatus(Message('Connected to ${server.label()}; requesting login id...'));
			LobbySocket.write("request_login_id`");
		};
		LobbySocket.onFrame = function(frame:String):Void {
			var message = LoginSocketProtocol.parseFrame(frame);
			if (message != null) {
				handleMessage(message);
			}
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

	/** Detach the login-phase hooks without tearing down the connection, so the
		lobby can keep using the same socket with normal `CommandHandler` routing. */
	public function release():Void {
		LobbySocket.onOpen = null;
		LobbySocket.onFrame = null;
		LobbySocket.onConnectionError = null;
		LobbySocket.onConnectionClose = null;
	}

	/** Cancel the login attempt and close the connection. */
	public function close():Void {
		release();
		LobbySocket.close();
	}

	private function handleMessage(message:LoginSocketMessage):Void {
		switch (message) {
			case LoginId(loginId):
				onStatus(LoginId(loginId));
			case LoginSuccessful(group, userName):
				onStatus(LoginSuccessful(group, userName));
			case LoginFailure(message):
				onStatus(LoginFailed(message == "" ? "Login failed." : message));
			case Other(command):
				onStatus(Message('Received $command from ${server.label()}.'));
		}
	}
}
