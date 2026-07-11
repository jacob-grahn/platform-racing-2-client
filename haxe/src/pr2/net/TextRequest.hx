package pr2.net;

import openfl.events.Event;
import openfl.net.URLRequest;

/** Shared exactly-once text response handling for `SuperLoader` requests. */
class TextRequest {
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

	private function new() {}
}
