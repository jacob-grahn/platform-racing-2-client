package pr2.net;

import openfl.events.Event;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;

/**
	Minimal async text fetch over `openfl.net.URLLoader`, which maps to
	`XMLHttpRequest` on the html5 target. The Flash client wrapped its requests
	in `SuperLoader`; this is the small slice of that we need to pull public
	level data. Cross-origin requests to pr2hub.com require CORS headers on the
	html5 target — see the campaign harness TODO.
**/
class TextLoader {
	/**
		Fetch `url` as text. `onText` receives the body on success; `onError`
		receives a human-readable message on failure. Exactly one callback fires.
	**/
	public static function load(url:String, onText:String->Void, ?onError:String->Void):Void {
		var loader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.TEXT;

		var status:Int = 0;
		var settled = false;

		// Declared up front so the mutually-referencing closures below can see
		// each other; Haxe does not hoist named local functions.
		var onComplete:Event->Void = null;
		var onIoError:IOErrorEvent->Void = null;
		var onSecurityError:SecurityErrorEvent->Void = null;
		var onHttpStatus:HTTPStatusEvent->Void = null;

		function cleanup():Void {
			loader.removeEventListener(Event.COMPLETE, onComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
		}

		function fail(message:String):Void {
			if (settled) {
				return;
			}
			settled = true;
			cleanup();
			if (onError != null) {
				onError(message);
			}
		}

		function succeed(body:String):Void {
			if (settled) {
				return;
			}
			settled = true;
			cleanup();
			onText(body);
		}

		onHttpStatus = function(event:HTTPStatusEvent):Void {
			status = event.status;
		};

		onComplete = function(event:Event):Void {
			succeed(Std.string(loader.data));
		};

		onIoError = function(event:IOErrorEvent):Void {
			fail('request to $url failed' + (status != 0 ? ' (HTTP $status)' : "") + ': ${event.text}');
		};

		onSecurityError = function(event:SecurityErrorEvent):Void {
			fail('request to $url blocked (likely CORS): ${event.text}');
		};

		loader.addEventListener(Event.COMPLETE, onComplete);
		loader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
		loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);

		var requestUrl = SuperLoader.appendQueryFields(url);
		try {
			loader.load(new URLRequest(requestUrl));
		} catch (error:Dynamic) {
			fail('could not start request to $requestUrl: ${Std.string(error)}');
		}
	}
}
