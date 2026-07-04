package pr2.net;

import openfl.events.Event;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.net.URLVariables;

/**
	Small `SuperLoader` replacement for form POST requests.
**/
class FormPostClient {
	public static function post(url:String, fields:Map<String, String>, onText:String->Void, ?onError:String->Void):Void {
		var prepared = SuperLoader.prepareFields(fields);
		var vars = new URLVariables();
		for (key in prepared.keys()) {
			Reflect.setField(vars, key, prepared.get(key));
		}

		var request = new URLRequest(url);
		request.method = URLRequestMethod.POST;
		request.data = vars;

		load(request, onText, onError);
	}

	public static function load(request:URLRequest, onText:String->Void, ?onError:String->Void):Void {
		var loader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.TEXT;

		var status:Int = 0;
		var settled = false;
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
		onComplete = function(_:Event):Void {
			succeed(Std.string(loader.data));
		};
		onIoError = function(event:IOErrorEvent):Void {
			fail(SuperLoader.formatIoError(request.url, status, event.text));
		};
		onSecurityError = function(event:SecurityErrorEvent):Void {
			fail('request to ${request.url} blocked (likely CORS): ${event.text}');
		};

		loader.addEventListener(Event.COMPLETE, onComplete);
		loader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
		loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);

		try {
			loader.load(request);
		} catch (error:Dynamic) {
			fail('could not start request to ${request.url}: ${Std.string(error)}');
		}
	}
}
