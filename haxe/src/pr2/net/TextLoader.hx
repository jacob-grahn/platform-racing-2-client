package pr2.net;

import openfl.events.Event;
import openfl.net.URLRequest;

/**
	Minimal async text fetch over the shared Flash-compatible `SuperLoader`.
	Cross-origin requests to pr2hub.com require CORS headers on the html5 target.
**/
class TextLoader {
	/**
		Fetch `url` as text. `onText` receives the body on success; `onError`
		receives a human-readable message on failure. Exactly one callback fires.
	**/
	public static function load(url:String, onText:String->Void, ?onError:String->Void):SuperLoader {
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

		loader.load(new URLRequest(url));
		return loader;
	}
}
