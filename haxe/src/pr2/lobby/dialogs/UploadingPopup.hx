package pr2.lobby.dialogs;

import openfl.events.Event;
import openfl.net.URLRequest;
import openfl.net.URLVariables;
import pr2.net.FormPostClient;
import pr2.net.SuperLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.ui.view.ProgressPopupView;

typedef UploadPostFactory = String->Map<String, String>->(String->Void)->(String->Void)->Void;
typedef UploadRequestFactory = URLRequest->(String->Void)->(String->Void)->Void;

/**
	Port of Flash `dialogs.UploadingPopup`: a modal that POSTs a request, shows a
	progress message with a close button, and dispatches `DONE` (with `parsedData`)
	or `ERROR` when the request settles, then fades out.

	The authored progress bar starts empty and eases to completion when the POST
	settles, matching the Flash control's layout and interpolation.
**/
class UploadingPopup extends Popup {
	public static inline var DONE:String = "uploadDone";
	public static inline var ERROR:String = "uploadError";
	public static inline var PARSED_DATA:String = "parsedData";
	public static inline var ANY_ERROR:String = "anyError";
	public static var postFactory:UploadPostFactory = defaultPost;
	public static var requestFactory:UploadRequestFactory = defaultRequest;

	public var data:String = null;
	public var parsedData:Dynamic = null;

	private var art:ProgressPopupView;
	private var progressBar:ProgressBar;
	private var asyncGuard:AsyncRemovalGuard = new AsyncRemovalGuard();

	public function new(requestOrUrl:Dynamic = null, ?fieldsOrDataMode:Dynamic = null, dispText:String = "Uploading...", ?aemOrOnResult:Dynamic = true,
			?onError:String->Void, ?autoEchoMessage:Bool) {
		super();
		var options = parseOptions(requestOrUrl, fieldsOrDataMode, dispText, aemOrOnResult, onError, autoEchoMessage);
		art = new ProgressPopupView(options.dispText);
		art.onClose = function():Void startFadeOut();
		addChild(art);
		progressBar = new ProgressBar();
		progressBar.x = -100;
		progressBar.y = -5;
		addChild(progressBar);

		if (options.request != null) {
			prepareRequest(options.request);
			requestFactory(options.request, asyncGuard.wrap(function(body:String):Void handleBody(body, options)),
				asyncGuard.wrap(function(message:String):Void handleError(message, options)));
		} else if (options.url != null) {
			postFactory(options.url, options.fields, asyncGuard.wrap(function(body:String):Void handleBody(body, options)),
				asyncGuard.wrap(function(message:String):Void handleError(message, options)));
		}
	}

	private static function defaultPost(url:String, fields:Map<String, String>, onResult:String->Void, onError:String->Void):Void {
		FormPostClient.post(url, fields, onResult, onError);
	}

	private static function defaultRequest(request:URLRequest, onResult:String->Void, onError:String->Void):Void {
		FormPostClient.load(request, onResult, onError);
	}

	private function handleBody(body:String, options:UploadOptions):Void {
		progressBar.setProgress(1);
		data = body;
		dispatchEvent(new Event(Event.COMPLETE));
		var result = options.dataMode == "json" ? SuperLoader.decodeJson(options.source, body, options.autoEchoMessage)
			: SuperLoader.decodeUrlVariables(options.source, body, options.autoEchoMessage);
		parsedData = result.data;
		if (result.success) {
			if (options.onResult != null) {
				options.onResult(parsedData);
			}
			dispatchEvent(new Event(PARSED_DATA));
			dispatchEvent(new Event(DONE));
		} else {
			if (options.onError != null) {
				options.onError(result.message);
			}
			dispatchEvent(new Event(ANY_ERROR));
			dispatchEvent(new Event(ERROR));
		}
		startFadeOut();
	}

	private function handleError(message:String, options:UploadOptions):Void {
		progressBar.setProgress(1);
		if (options.onError != null) {
			options.onError(message);
		}
		dispatchEvent(new Event(ANY_ERROR));
		dispatchEvent(new Event(ERROR));
		startFadeOut();
	}

	private static function parseOptions(requestOrUrl:Dynamic, fieldsOrDataMode:Dynamic, dispText:String, aemOrOnResult:Dynamic,
			onError:String->Void, autoEchoMessage:Null<Bool>):UploadOptions {
		var options:UploadOptions = {
			request: null,
			url: null,
			fields: new Map(),
			dataMode: "json",
			dispText: dispText,
			autoEchoMessage: true,
			onResult: null,
			onError: onError,
			source: ""
		};
		if (Reflect.isFunction(aemOrOnResult)) {
			options.onResult = cast aemOrOnResult;
		} else if (aemOrOnResult != null) {
			options.autoEchoMessage = aemOrOnResult == true;
		}
		if (autoEchoMessage != null) {
			options.autoEchoMessage = autoEchoMessage;
		}
		if (Std.isOfType(requestOrUrl, URLRequest)) {
			options.request = cast requestOrUrl;
			options.dataMode = fieldsOrDataMode == null ? "url" : Std.string(fieldsOrDataMode);
			options.source = options.request.url;
		} else if (requestOrUrl != null) {
			options.url = Std.string(requestOrUrl);
			options.fields = fieldsOrDataMode == null ? new Map() : cast fieldsOrDataMode;
			options.source = options.url;
		} else {
			options.dataMode = fieldsOrDataMode == null ? "url" : Std.string(fieldsOrDataMode);
		}
		return options;
	}

	private static function prepareRequest(request:URLRequest):Void {
		if (request.data != null && !Std.isOfType(request.data, String)) {
			var prepared = SuperLoader.prepareFields(urlVariablesToMap(cast request.data));
			var vars:URLVariables = cast request.data;
			for (key in prepared.keys()) {
				Reflect.setField(vars, key, prepared.get(key));
			}
			request.data = vars;
		} else {
			request.url = SuperLoader.appendQueryFields(request.url);
		}
	}

	private static function urlVariablesToMap(vars:URLVariables):Map<String, String> {
		var fields:Map<String, String> = new Map();
		for (key in Reflect.fields(vars)) {
			var value = Reflect.field(vars, key);
			if (value != null) fields.set(key, Std.string(value));
		}
		return fields;
	}

	override public function remove():Void {
		asyncGuard.remove();
		if (progressBar != null) {
			progressBar.remove();
			progressBar = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}

private typedef UploadOptions = {
	var request:Null<URLRequest>;
	var url:Null<String>;
	var fields:Map<String, String>;
	var dataMode:String;
	var dispText:String;
	var autoEchoMessage:Bool;
	var onResult:Null<Dynamic->Void>;
	var onError:Null<String->Void>;
	var source:String;
}
