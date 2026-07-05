package pr2.net;

import haxe.Json;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.net.URLVariables;
import pr2.Constants;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.MessagePopup;

typedef SuperLoaderParsedResult = {
	final success:Bool;
	final data:Dynamic;
	final message:String;
}

/**
	Flash-compatible request wrapper used by popup and list loaders.

	The original client extends `URLLoader`; this port wraps it so teardown can
	detach every internal listener and late transport events no-op after removal.
**/
class SuperLoader extends EventDispatcher {
	public static inline var j:String = "json";
	public static inline var u:String = "url";
	public static inline var raw:String = "raw";
	public static inline var d:String = "parsedData";
	public static inline var e:String = "anyError";

	public static var nextRand:Void->Int = function():Int return Std.random(10000000);
	public static var showMessage:String->Void = defaultShowMessage;
	public static var transportFactory:Void->Dynamic = defaultTransportFactory;

	public var useRandomNum:Bool;
	public var parsedData(default, null):Dynamic = null;
	public var data(default, null):String = null;
	public var httpStatus(default, null):Int = 0;
	public var errorMessage(default, null):String = "";

	private var readMode:String;
	private var autoEchoMessage:Bool;
	private var transport:Dynamic = null;
	private var active:Bool = false;
	private var removed:Bool = false;
	private var toURL:String = "";

	private var onComplete:Event->Void = null;
	private var onIoError:Event->Void = null;
	private var onSecurityError:Event->Void = null;
	private var onHttpStatus:Event->Void = null;
	private var onProgress:Event->Void = null;

	public function new(rand:Bool = true, read:String = u, aem:Bool = true) {
		super();
		useRandomNum = rand;
		readMode = read;
		autoEchoMessage = aem;
	}

	public function load(request:URLRequest):Void {
		removeTransportListeners();
		removed = false;
		active = true;
		parsedData = null;
		data = null;
		errorMessage = "";
		httpStatus = 0;
		decorateRequest(request);
		toURL = request.url;

		transport = transportFactory();
		transport.dataFormat = URLLoaderDataFormat.TEXT;
		attachTransportListeners();

		try {
			transport.load(request);
		} catch (error:Dynamic) {
			fail('could not start request to ${request.url}: ${Std.string(error)}', true);
		}
	}

	public function cancel():Void {
		remove();
	}

	public function remove():Void {
		active = false;
		removed = true;
		removeTransportListeners();
		if (transport != null) {
			try {
				transport.close();
			} catch (_:Dynamic) {}
			transport = null;
		}
	}

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
		if (text == null) text = "";
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
		transportFactory = defaultTransportFactory;
	}

	private function decorateRequest(request:URLRequest):Void {
		if (!useRandomNum) return;
		if (isUrlVariablesPayload(request.data)) {
			var vars:URLVariables = cast request.data;
			var fields = urlVariablesToMap(vars);
			var prepared = prepareFields(fields, true);
			for (key in prepared.keys()) Reflect.setField(vars, key, prepared.get(key));
			request.data = vars;
		} else {
			request.url = appendQueryFields(request.url, true);
		}
	}

	private function attachTransportListeners():Void {
		onComplete = function(_:Event):Void {
			if (!active || removed) return;
			data = Std.string(transport.data);
			var result = decodeBody();
			if (!active || removed) return;
			dispatchEvent(new Event(Event.COMPLETE));
			if (result.success) {
				dispatchEvent(new Event(d));
			} else {
				dispatchEvent(new Event(e));
			}
			active = false;
			removeTransportListeners();
		};
		onIoError = function(event:Event):Void {
			var text = Std.isOfType(event, IOErrorEvent) ? (cast event : IOErrorEvent).text : Std.string(event);
			fail(formatIoError(toURL, httpStatus, text), true, event);
		};
		onSecurityError = function(event:Event):Void {
			var text = Std.isOfType(event, SecurityErrorEvent) ? (cast event : SecurityErrorEvent).text : Std.string(event);
			fail('request to $toURL blocked (likely CORS): $text', true, event);
		};
		onHttpStatus = function(event:Event):Void {
			if (!active || removed) return;
			httpStatus = (cast event : HTTPStatusEvent).status;
			dispatchEvent(event.clone());
		};
		onProgress = function(event:Event):Void {
			if (!active || removed) return;
			dispatchEvent(event.clone());
		};

		transport.addEventListener(Event.COMPLETE, onComplete);
		transport.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
		transport.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
		transport.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
		transport.addEventListener(ProgressEvent.PROGRESS, onProgress);
	}

	private function removeTransportListeners():Void {
		if (transport == null || onComplete == null) return;
		transport.removeEventListener(Event.COMPLETE, onComplete);
		transport.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
		transport.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
		transport.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
		transport.removeEventListener(ProgressEvent.PROGRESS, onProgress);
		onComplete = null;
		onIoError = null;
		onSecurityError = null;
		onHttpStatus = null;
		onProgress = null;
	}

	private function decodeBody():SuperLoaderParsedResult {
		if (readMode == raw || readMode == "" || readMode == null) {
			parsedData = data;
			return {success: true, data: parsedData, message: ""};
		}
		var result = readMode == j ? decodeJson(toURL, data, autoEchoMessage) : decodeUrlVariables(toURL, data, autoEchoMessage);
		parsedData = result.data;
		if (!result.success) errorMessage = result.message;
		return result;
	}

	private function fail(message:String, show:Bool, ?sourceEvent:Event):Void {
		if (!active || removed) return;
		active = false;
		errorMessage = message;
		removeTransportListeners();
		if (show && autoEchoMessage && message != "" && toURL.indexOf("server_status_2.txt") == -1) showMessage(message);
		if (sourceEvent != null) dispatchEvent(sourceEvent.clone());
		dispatchEvent(new Event(e));
	}

	private static function urlVariablesToMap(vars:URLVariables):Map<String, String> {
		var fields:Map<String, String> = new Map();
		for (key in Reflect.fields(vars)) {
			var value = Reflect.field(vars, key);
			if (value != null) fields.set(key, Std.string(value));
		}
		return fields;
	}

	private static function isUrlVariablesPayload(data:Dynamic):Bool {
		return data != null && !Std.isOfType(data, String) && !Reflect.hasField(data, "readUnsignedByte")
			&& !Reflect.hasField(data, "writeByte") && !Reflect.hasField(data, "bytesAvailable");
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

	private static function defaultTransportFactory():Dynamic {
		return new URLLoader();
	}
}
