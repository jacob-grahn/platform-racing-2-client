package pr2.net;

import haxe.Json;

/** HTTP contract used by Flash `menu.ForgotPassPopup`. */
class ForgotPasswordClient {
	public static function send(name:String, email:String, onResult:ForgotPasswordResult->Void, ?onError:String->Void):Void {
		FormPostClient.post(ServerConfig.forgotPasswordUrl(), fields(name, email), function(body:String):Void {
			try {
				onResult(parse(body));
			} catch (error:Dynamic) {
				if (onError != null) {
					onError('failed to parse password recovery response: ${Std.string(error)}');
				}
			}
		}, onError);
	}

	public static function fields(name:String, email:String):Map<String, String> {
		return ["name" => name, "email" => email];
	}

	public static function parse(body:String):ForgotPasswordResult {
		if (body == null || StringTools.trim(body) == "") {
			throw "empty response";
		}
		var data:Dynamic = Json.parse(body);
		var error = stringField(data, "error");
		var success = error == "" && (!Reflect.hasField(data, "success") || boolField(data, "success"));
		var message = stringField(data, "message");
		if (!success && error != "") {
			message = "Error: " + error;
		} else if (!success && message == "") {
			message = "Error: An unknown error occurred. I suspect evil aliens.";
		}
		return new ForgotPasswordResult(success, message);
	}

	private static function stringField(data:Dynamic, name:String):String {
		var value:Dynamic = Reflect.field(data, name);
		return value == null ? "" : Std.string(value);
	}

	private static function boolField(data:Dynamic, name:String):Bool {
		var value:Dynamic = Reflect.field(data, name);
		if (Std.isOfType(value, Bool)) {
			return value;
		}
		var text = Std.string(value).toLowerCase();
		return text == "1" || text == "true" || text == "yes";
	}
}

class ForgotPasswordResult {
	public final success:Bool;
	public final message:String;

	public function new(success:Bool, message:String) {
		this.success = success;
		this.message = message;
	}
}
