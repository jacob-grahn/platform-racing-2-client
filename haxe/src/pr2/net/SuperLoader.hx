package pr2.net;

import haxe.Json;
import openfl.net.URLVariables;
import pr2.Constants;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.MessagePopup;

typedef SuperLoaderParsedResult = {
	final success:Bool;
	final data:Dynamic;
	final message:String;
}

/** Shared Flash `SuperLoader` request decoration and parsed-data semantics. */
class SuperLoader {
	public static var nextRand:Void->Int = function():Int return Std.random(10000000);
	public static var showMessage:String->Void = defaultShowMessage;

	private function new() {}

	public static function prepareFields(fields:Map<String, String>, rand:Bool = true):Map<String, String> {
		var prepared:Map<String, String> = new Map();
		for (key in fields.keys()) prepared.set(key, fields.get(key));
		if (rand) {
			if (Constants.BETA && !prepared.exists("beta")) prepared.set("beta", "1");
			if (!prepared.exists("rand")) prepared.set("rand", Std.string(nextRand()));
			if (LobbySession.token != "" && !prepared.exists("token")) prepared.set("token", LobbySession.token);
		}
		return prepared;
	}

	public static function appendQueryFields(url:String, rand:Bool = true):String {
		if (!rand) return url;
		var fields = prepareFields(new Map<String, String>(), true);
		var parts:Array<String> = [];
		for (key in fields.keys()) {
			parts.push(StringTools.urlEncode(key) + "=" + StringTools.urlEncode(fields.get(key)));
		}
		if (parts.length == 0) return url;
		return url + (url.indexOf("?") == -1 ? "?" : "&") + parts.join("&");
	}

	public static function decodeJson(source:String, body:String, autoEchoMessage:Bool = true):SuperLoaderParsedResult {
		return decodeParsed(source, body, function(text:String):Dynamic return Json.parse(text), "json", autoEchoMessage);
	}

	public static function decodeUrlVariables(source:String, body:String, autoEchoMessage:Bool = true):SuperLoaderParsedResult {
		return decodeParsed(source, body, function(text:String):Dynamic return new URLVariables(text), "url", autoEchoMessage);
	}

	public static function formatIoError(url:String, status:Int, text:String):String {
		var prefix = "Error: ";
		var rest = text;
		if (text != null && text.indexOf("Error #") == 0 && text.indexOf(":") != -1) {
			prefix = text.substr(0, text.indexOf(":"));
			rest = text.substr(text.indexOf(":"));
		}
		return prefix + rest + (status != 0 ? ' (HTTP $status)' : "");
	}

	public static function resetHooks():Void {
		nextRand = function():Int return Std.random(10000000);
		showMessage = defaultShowMessage;
	}

	private static function decodeParsed(source:String, body:String, parser:String->Dynamic, readMode:String, autoEchoMessage:Bool):SuperLoaderParsedResult {
		try {
			if (body == null || body == "") throw "empty response";
			var parsed = parser(body);
			var message = stringField(parsed, "message");
			if (message != "" && autoEchoMessage) showMessage(message);
			var hasError = Reflect.hasField(parsed, "error");
			var ok = !hasError && (Reflect.hasField(parsed, "success") ? boolField(Reflect.field(parsed, "success")) : true);
			if (ok) return {success: true, data: parsed, message: message};

			var error = hasError ? stringField(parsed, "error") : "An unknown error occurred. I suspect evil aliens.";
			showMessage("Error: " + error);
			return {success: false, data: parsed, message: error};
		} catch (error:Dynamic) {
			var message = 'Error: The loaded data was not in the expected format. \n\nlocation: SuperLoader::onComplete \nreadMode: $readMode\ndata: $body';
			showMessage(message);
			return {success: false, data: null, message: 'invalid response from $source: ${Std.string(error)}'};
		}
	}

	private static function stringField(data:Dynamic, field:String):String {
		var value = Reflect.field(data, field);
		return value == null ? "" : Std.string(value);
	}

	private static function boolField(value:Dynamic):Bool {
		if (Std.isOfType(value, Bool)) return value;
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) return Std.int(value) != 0;
		var text = Std.string(value).toLowerCase();
		return text == "1" || text == "true" || text == "yes";
	}

	private static function defaultShowMessage(message:String):Void {
		new MessagePopup(message);
	}
}
