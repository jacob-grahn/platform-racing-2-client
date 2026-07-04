package pr2.net;

import pr2.net.LoginAuthClient.LoginAuthResult;

/** Waits for both halves of Flash's login handshake before exposing a session. */
class LoginSessionGate {
	private var http:Null<LoginAuthResult>;
	private var socket:Null<LoginSocketSession>;
	private var completed:Bool = false;
	private final onReady:LoginSessionResult->Void;

	public function new(onReady:LoginSessionResult->Void) {
		this.onReady = onReady;
	}

	public function acceptHttp(result:LoginAuthResult):Void {
		if (completed) return;
		http = result;
		maybeComplete();
	}

	public function acceptSocket(group:Int, userName:String):Void {
		if (completed) return;
		socket = new LoginSocketSession(group, userName);
		maybeComplete();
	}

	private function maybeComplete():Void {
		if (http == null || socket == null) return;
		completed = true;
		onReady(new LoginSessionResult(socket.group, socket.userName, http.data));
	}
}

class LoginSocketSession {
	public final group:Int;
	public final userName:String;

	public function new(group:Int, userName:String) {
		this.group = group;
		this.userName = userName;
	}
}

class LoginSessionResult {
	public final group:Int;
	public final userName:String;
	public final userId:Int;
	public final hasEmail:Bool;
	public final token:String;
	public final guildId:Int;
	public final guildOwner:Bool;
	public final guildName:String;
	public final emblem:String;
	public final favoriteLevels:Array<Int>;
	public final authTime:Float;
	public final lastRead:Float;
	public final lastRecv:Float;

	public function new(group:Int, userName:String, data:Dynamic) {
		this.group = group;
		this.userName = userName;
		userId = intField(data, "userId");
		hasEmail = boolField(data, "email");
		token = stringField(data, "token");
		guildId = intField(data, "guild");
		guildOwner = boolField(data, "guildOwner");
		guildName = stringField(data, "guildName");
		emblem = stringField(data, "emblem");
		favoriteLevels = intArrayField(data, "favoriteLevels");
		authTime = floatField(data, "time");
		lastRead = floatField(data, "lastRead");
		lastRecv = floatField(data, "lastRecv");
	}

	private static function stringField(data:Dynamic, name:String):String {
		var value = data == null ? null : Reflect.field(data, name);
		return value == null ? "" : Std.string(value);
	}

	private static function intField(data:Dynamic, name:String):Int {
		var parsed = Std.parseInt(stringField(data, name));
		return parsed == null ? 0 : parsed;
	}

	private static function floatField(data:Dynamic, name:String):Float {
		var parsed = Std.parseFloat(stringField(data, name));
		return Math.isNaN(parsed) ? 0 : parsed;
	}

	private static function boolField(data:Dynamic, name:String):Bool {
		var value = stringField(data, name).toLowerCase();
		return value == "1" || value == "true" || value == "yes";
	}

	private static function intArrayField(data:Dynamic, name:String):Array<Int> {
		var value:Dynamic = data == null ? null : Reflect.field(data, name);
		if (!Std.isOfType(value, Array)) return [];
		var result:Array<Int> = [];
		for (entry in (cast value:Array<Dynamic>)) {
			var parsed = Std.parseInt(Std.string(entry));
			if (parsed != null) result.push(parsed);
		}
		return result;
	}
}
