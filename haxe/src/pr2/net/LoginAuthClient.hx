package pr2.net;

import haxe.Json;
import pr2.crypto.PR2Encryptor;

class LoginAuthClient {
	private static inline var LOGIN_KEY:String = "VUovam5GKndSMHFSSy9kSA==";
	private static inline var LOGIN_IV:String = "JmM5KnkqNXA9MVVOeC9Ucg==";

	public static function login(
		userName:String,
		userPass:String,
		server:ServerInfo,
		remember:Bool,
		loginId:Int,
		onResult:LoginAuthResult->Void,
		?onError:String->Void,
		?token:String,
		?awardKong:Bool = false
	):Void {
		FormPostClient.post(ServerConfig.loginUrl(), fields(userName, userPass, server, remember, loginId, token, awardKong), function(body:String):Void {
			try {
				onResult(parse(body));
			} catch (error:Dynamic) {
				if (onError != null) {
					onError('failed to parse login response: ${Std.string(error)}');
				}
			}
		}, onError);
	}

	public static function fields(userName:String, userPass:String, server:ServerInfo, remember:Bool, loginId:Int, ?token:String, ?awardKong:Bool = false):Map<String, String> {
		var result = [
			"i" => encryptPayload(payloadJson(userName, userPass, server, remember, loginId, awardKong)),
			"build" => ServerConfig.BUILD,
		];
		if (token != null && token != "") result.set("token", token);
		return result;
	}

	public static function payloadJson(userName:String, userPass:String, server:ServerInfo, remember:Bool, loginId:Int, ?awardKong:Bool = false):String {
		return Json.stringify({
			user_name: userName,
			user_pass: userPass,
			build: ServerConfig.BUILD,
			server: server.toLoginObject(),
			domain: "local",
			remember: remember,
			login_id: loginId,
			award_kong: awardKong,
		});
	}

	public static function encryptPayload(payload:String):String {
		return PR2Encryptor.encryptBase64(payload, LOGIN_KEY, LOGIN_IV);
	}

	public static function parse(body:String):LoginAuthResult {
		if (body == null || StringTools.trim(body) == "") {
			throw "empty response";
		}
		var data:Dynamic = Json.parse(body);
		return new LoginAuthResult(boolField(data, "success", false), firstMessage(data), data);
	}

	private static function firstMessage(data:Dynamic):String {
		for (field in ["message", "error", "reason"]) {
			var value:Dynamic = Reflect.field(data, field);
			if (value != null && Std.string(value) != "") {
				return Std.string(value);
			}
		}
		return "";
	}

	private static function boolField(data:Dynamic, name:String, fallback:Bool):Bool {
		var value:Dynamic = Reflect.field(data, name);
		if (value == null) {
			return fallback;
		}
		if (Std.isOfType(value, Bool)) {
			return value;
		}
		var text = Std.string(value).toLowerCase();
		return text == "1" || text == "true" || text == "yes";
	}
}

class LoginAuthResult {
	public final success:Bool;
	public final message:String;
	public final data:Dynamic;

	public function new(success:Bool, message:String, data:Dynamic) {
		this.success = success;
		this.message = message;
		this.data = data;
	}
}
