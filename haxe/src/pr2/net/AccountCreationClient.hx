package pr2.net;

import haxe.Json;

class AccountCreationClient {
	public static function create(
		name:String,
		password:String,
		email:String,
		onResult:AccountCreationResult->Void,
		?onError:String->Void
	):Void {
		FormPostClient.post(ServerConfig.registerUserUrl(), fields(name, password, email), function(body:String):Void {
			try {
				onResult(parse(body));
			} catch (error:Dynamic) {
				if (onError != null) {
					onError('failed to parse account creation response: ${Std.string(error)}');
				}
			}
		}, onError);
	}

	public static function fields(name:String, password:String, email:String):Map<String, String> {
		return [
			"name" => name,
			"password" => password,
			"email" => email,
		];
	}

	public static function parse(body:String):AccountCreationResult {
		if (body == null || StringTools.trim(body) == "") {
			throw "empty response";
		}
		var data:Dynamic = Json.parse(body);
		var success = boolField(data, "success", false);
		return new AccountCreationResult(success, firstMessage(data));
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

class AccountCreationResult {
	public final success:Bool;
	public final message:String;

	public function new(success:Bool, message:String) {
		this.success = success;
		this.message = message;
	}
}
