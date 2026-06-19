package pr2.page;

#if js
import js.Browser;
#end
import pr2.net.LoginSocketProtocol;
import pr2.net.LoginSocketProtocol.LoginSocketMessage;
import pr2.net.ServerInfo;

enum LoginProbeStatus {
	Message(message:String);
	LoginId(loginId:String);
	LoginSuccessful(userName:String);
}

class LoginSocketProbe {
	private var server:ServerInfo;
	private var onStatus:LoginProbeStatus->Void;
	private var protocol:LoginSocketProtocol;
	#if js
	private var socket:Null<js.html.WebSocket>;
	#end

	public function new(server:ServerInfo, onStatus:LoginProbeStatus->Void) {
		this.server = server;
		this.onStatus = onStatus;
		this.protocol = new LoginSocketProtocol(server.serverId);
	}

	public function connect():Void {
		#if js
		var secure = Browser.location.protocol == "https:";
		var url = server.websocketUrl(secure);
		try {
			socket = new js.html.WebSocket(url);
			socket.onopen = function(_):Void {
				onStatus(Message('Connected to ${server.label()}; requesting login id...'));
				write("request_login_id`");
			};
			socket.onmessage = function(event):Void {
				for (message in protocol.append(Std.string(event.data))) {
					handleMessage(message);
				}
			};
			socket.onerror = function(_):Void {
				onStatus(Message('Could not connect to ${server.label()} over WebSocket.'));
			};
			socket.onclose = function(_):Void {
				onStatus(Message('Connection to ${server.label()} closed.'));
			};
		} catch (error:Dynamic) {
			onStatus(Message('Could not open WebSocket: ${Std.string(error)}'));
		}
		#else
		onStatus(Message("Server connection probing is available on the html5 target."));
		#end
	}

	public function close():Void {
		#if js
		if (socket != null) {
			socket.close();
			socket = null;
		}
		#end
	}

	private function write(command:String):Void {
		#if js
		if (socket == null || socket.readyState != js.html.WebSocket.OPEN) {
			return;
		}
		socket.send(protocol.commandFrame(command));
		#end
	}

	private function handleMessage(message:LoginSocketMessage):Void {
		switch (message) {
			case LoginId(loginId):
				onStatus(LoginId(loginId));
			case LoginSuccessful(userName):
				onStatus(LoginSuccessful(userName));
			case LoginFailure(message):
				onStatus(Message('Server rejected login: $message'));
			case Other(command):
				onStatus(Message('Received $command from ${server.label()}.'));
		}
	}
}
