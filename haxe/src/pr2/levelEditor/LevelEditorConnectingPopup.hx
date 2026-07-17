package pr2.levelEditor;

import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.net.LoginAuthClient;
import pr2.net.LoginSessionGate;
import pr2.net.LoginSessionGate.LoginSessionResult;
import pr2.net.ServerInfo;
import pr2.page.LobbyPage;
import pr2.page.LoginSessionInstaller;
import pr2.page.LoginSocketProbe;
import pr2.page.LoginSocketProbe.LoginProbeStatus;
import pr2.ui.view.StatusPopupView;

class LevelEditorConnectingPopup extends Popup {
	public var art(default, null):Null<StatusPopupView>;
	public var connectionAttempted(default, null):Bool = false;
	private var probe:Null<LoginSocketProbe>;
	private var gate:Null<LoginSessionGate>;
	private var server:Null<ServerInfo>;
	private var userName:String;
	private var token:String;
	private var remember:Bool;
	private var reconnectStopped:Bool = false;

	public function new() {
		super();
		art = new StatusPopupView("Connecting...", true);
		art.onClose = cancel;
		addChild(art);
		userName = LobbySession.userName;
		token = LobbySession.token;
		remember = LobbySession.remember;
		server = LobbySession.server;
		startConnection();
	}

	private function startConnection():Void {
		if (server == null) {
			fail("The previous lobby server is no longer available.");
			return;
		}
		connectionAttempted = true;
		probe = new LoginSocketProbe(server, handleProbeStatus);
		gate = new LoginSessionGate(enterLobby);
		probe.connect();
	}

	private function handleProbeStatus(status:LoginProbeStatus):Void {
		if (reconnectStopped) {
			return;
		}
		switch (status) {
			case LoginId(loginId):
				var parsed = Std.parseInt(loginId);
				if (parsed == null) {
					fail('Invalid login id from server: $loginId');
					return;
				}
				var payloadUserName = token == "" ? userName : "";
				LoginAuthClient.login(payloadUserName, "", server, remember, parsed, function(result):Void {
					if (reconnectStopped || gate == null) return;
					if (result.success) gate.acceptHttp(result); else fail(result.message == "" ? "Login failed." : result.message);
				}, fail, token);
			case LoginSuccessful(group, socketUserName):
				if (gate != null) gate.acceptSocket(group, socketUserName == "" ? userName : socketUserName);
			case LoginFailed(message), ConnectionClosed(message):
				fail(message);
			case Message(_):
		}
	}

	private function enterLobby(session:LoginSessionResult):Void {
		if (reconnectStopped || server == null) {
			return;
		}
		if (probe != null) {
			probe.release();
			probe = null;
		}
		LoginSessionInstaller.install(session, server, remember);
		var editor = LevelEditor.editor;
		remove();
		if (editor != null && editor.pageHolder != null) {
			editor.pageHolder.changePage(new LobbyPage(session.userName, server));
		}
	}

	private function fail(message:String):Void {
		if (reconnectStopped) {
			return;
		}
		remove();
		new MessagePopup(message == "" ? "Could not reconnect to the lobby." : message);
	}

	private function cancel():Void {
		remove();
	}

	override public function remove():Void {
		if (reconnectStopped) {
			return;
		}
		reconnectStopped = true;
		gate = null;
		if (probe != null) {
			probe.close();
			probe = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
