package pr2.e2e;

import haxe.Http;
import haxe.crypto.Md5;
import pr2.net.LoginAuthClient;
import pr2.net.ServerConfig;
import pr2.net.ServerInfo;
import pr2.net.ServerStatusClient;
import sys.net.Host;
import sys.net.Socket;

/**
	Live, slow PR2 login e2e test.

	This intentionally lives under `haxe/e2e`, not `haxe/test`, because it opens
	real network connections, logs in with the dedicated `haxe-port-test`
	account, and depends on live PR2 service availability.
**/
class LiveLoginE2ETest {
	private static inline var USER_NAME = "haxe-port-test";
	private static inline var USER_PASS = "haxe-port-test";
	private static var assertions = 0;

	public static function main():Void {
		if (Sys.getEnv("LIVE_PR2_E2E") != "1") {
			trace("Skipping live PR2 e2e test. Set LIVE_PR2_E2E=1 to run it.");
			return;
		}

		var server = firstUsableServer();
		trace('Using ${server.label()} at ${server.address}:${server.port}');

		var socket = new PR2RawSocket(server);
		try {
			socket.connect();
			var loginId = socket.requestLoginId();
			assertEquals(true, loginId > 0, "received positive login id");

			var result = postLogin(server, loginId);
			assertEquals(true, result.success, result.message == "" ? "login.php auth success" : result.message);

			var socketLogin = socket.readCommand("loginSuccessful");
			assertEquals("loginSuccessful", socketLogin.command, "socket loginSuccessful command");
			assertEquals(USER_NAME.toLowerCase(), socketLogin.args[1].toLowerCase(), "socket login username");
			socket.close();
		} catch (error:Dynamic) {
			socket.close();
			throw error;
		}

		trace('LiveLoginE2ETest passed $assertions assertions');
	}

	private static function firstUsableServer():ServerInfo {
		var response = httpGet(ServerConfig.serverStatusUrl());
		var servers = ServerStatusClient.parse(response).servers;
		for (server in servers) {
			if (server.address != "" && server.port > 0 && server.serverId != 10) {
				return server;
			}
		}
		throw "No usable live server found.";
	}

	private static function postLogin(server:ServerInfo, loginId:Int) {
		var fields = LoginAuthClient.fields(USER_NAME, USER_PASS, server, false, loginId);
		var body = httpPost(ServerConfig.loginUrl(), fields);
		var result = LoginAuthClient.parse(body);
		if (!result.success) {
			throw 'login.php failed: ${result.message} body=$body';
		}
		return result;
	}

	private static function httpGet(url:String):String {
		var data:String = null;
		var error:String = null;
		var http = new Http(url);
		http.onData = function(value:String):Void {
			data = value;
		};
		http.onError = function(value:String):Void {
			error = value;
		};
		http.request(false);
		if (error != null) {
			throw 'GET $url failed: $error';
		}
		return data;
	}

	private static function httpPost(url:String, fields:Map<String, String>):String {
		var data:String = null;
		var error:String = null;
		var http = new Http(url);
		for (key in fields.keys()) {
			http.setParameter(key, fields.get(key));
		}
		http.onData = function(value:String):Void {
			data = value;
		};
		http.onError = function(value:String):Void {
			error = value;
		};
		http.request(true);
		if (error != null) {
			throw 'POST $url failed: $error';
		}
		return data;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}

private class PR2RawSocket {
	private static inline var COMM_PASS = "QHE0NSNwKWZZQVEhU19xMA==";
	private static inline var COMM_PASS_SERVER_10 = "ayo3JnBGQCZVRiEhVjFAQA==";
	private static inline var END_CHAR = "\x04";

	private var server:ServerInfo;
	private var socket:Null<Socket>;
	private var sendNum = 0;

	public function new(server:ServerInfo) {
		this.server = server;
	}

	public function connect():Void {
		socket = new Socket();
		socket.setTimeout(15);
		socket.connect(new Host(server.address), server.port);
	}

	public function requestLoginId():Int {
		write("request_login_id`");
		var command = readCommand("setLoginID");
		var loginId = Std.parseInt(command.args[0]);
		if (loginId == null) {
			throw 'Invalid setLoginID payload: ${command.args.join("`")}';
		}
		return loginId;
	}

	public function readCommand(expected:String):PR2Command {
		var deadline = haxe.Timer.stamp() + 20;
		while (haxe.Timer.stamp() < deadline) {
			var command = readOne();
			if (command.command == expected) {
				return command;
			}
		}
		throw 'Timed out waiting for $expected';
	}

	public function close():Void {
		if (socket != null) {
			try {
				write("close`");
			} catch (_:Dynamic) {}
			try {
				socket.close();
			} catch (_:Dynamic) {}
			socket = null;
		}
	}

	private function write(command:String):Void {
		if (socket == null) {
			throw "socket is not connected";
		}
		sendNum++;
		if (sendNum == 12) {
			sendNum++;
		}
		var payload = sendNum + "`" + command;
		var hash = Md5.encode(socketToken() + payload).substr(0, 3);
		socket.output.writeString(hash + "`" + payload + END_CHAR);
		socket.output.flush();
	}

	private function readOne():PR2Command {
		if (socket == null) {
			throw "socket is not connected";
		}
		var buffer = new StringBuf();
		while (true) {
			var code = socket.input.readByte();
			if (code == 4) {
				break;
			}
			buffer.addChar(code);
		}
		return PR2Command.parse(buffer.toString());
	}

	private function socketToken():String {
		return server.serverId == 10 ? COMM_PASS_SERVER_10 : COMM_PASS;
	}
}

private class PR2Command {
	public final command:String;
	public final args:Array<String>;

	public function new(command:String, args:Array<String>) {
		this.command = command;
		this.args = args;
	}

	public static function parse(frame:String):PR2Command {
		var parts = frame.split("`");
		if (parts.length < 3) {
			throw 'Invalid PR2 frame: $frame';
		}
		return new PR2Command(parts[2], parts.slice(3));
	}
}
