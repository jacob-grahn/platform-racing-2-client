package pr2.net;

import openfl.events.Event;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.net.URLVariables;

/**
	Small form POST wrapper over the shared Flash-compatible `SuperLoader`.
**/
class FormPostClient {
	public static function post(url:String, fields:Map<String, String>, onText:String->Void, ?onError:String->Void):SuperLoader {
		var vars = new URLVariables();
		for (key in fields.keys()) {
			Reflect.setField(vars, key, fields.get(key));
		}

		var request = new URLRequest(url);
		request.method = URLRequestMethod.POST;
		request.data = vars;

		return load(request, onText, onError);
	}

	public static function load(request:URLRequest, onText:String->Void, ?onError:String->Void):SuperLoader {
		var loader = new SuperLoader(true, SuperLoader.raw, false);
		var settled = false;
		var onComplete:Event->Void = null;
		var onErrorEvent:Event->Void = null;

		function cleanup():Void {
			loader.removeEventListener(Event.COMPLETE, onComplete);
			loader.removeEventListener(SuperLoader.e, onErrorEvent);
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

		onComplete = function(_:Event):Void {
			if (settled) {
				return;
			}
			settled = true;
			cleanup();
			onText(loader.data);
		};
		onErrorEvent = function(_:Event):Void {
			fail(loader.errorMessage);
		};

		loader.addEventListener(Event.COMPLETE, onComplete);
		loader.addEventListener(SuperLoader.e, onErrorEvent);

		loader.load(request);
		return loader;
	}
}
