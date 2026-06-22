package pr2.audio;

#if (js && html5)
import js.Browser;
import js.html.Event;
import lime.media.AudioManager;

/**
	Primes browser audio before any page needs a sound, then resumes it from the
	first accepted user gesture. This is application chrome, so page changes do
	not reinstall it or affect playback timing after the initial gesture.
**/
class BrowserAudioUnlock {
	private static var installed:Bool = false;
	private static var gate = new AudioUnlockGate();
	private static final EVENTS = ["pointerdown", "touchstart", "touchend", "click", "keydown"];

	public static function install():Void {
		if (installed) {
			return;
		}
		installed = true;

		// Howler creates its AudioContext lazily. Reading its volume initializes
		// the context now, ensuring a gesture on an audio-free intro still counts.
		var howler:Dynamic = untyped js.Syntax.code("typeof Howler !== 'undefined' ? Howler : null");
		if (howler != null) {
			howler.volume();
		}
		for (name in EVENTS) {
			Browser.document.addEventListener(name, onGesture, true);
		}
	}

	private static function onGesture(_:Event):Void {
		if (gate.attempt(resumeContexts)) {
			removeListeners();
		}
	}

	private static function resumeContexts():Bool {
		var pending:Bool = false;
		var howler:Dynamic = untyped js.Syntax.code("typeof Howler !== 'undefined' ? Howler : null");
		if (howler != null && howler.ctx != null && howler.ctx.state != "running") {
			pending = true;
			resumeContext(howler.ctx);
		}

		var limeContext = AudioManager.context;
		if (limeContext != null && limeContext.web != null
			&& untyped limeContext.web.state != "running") {
			pending = true;
			resumeContext(limeContext.web);
		}
		return !pending;
	}

	private static function resumeContext(context:Dynamic):Void {
		var result:Dynamic = context.resume();
		if (result != null && result.then != null) {
			result.then(function(_:Dynamic):Void {
				if (resumeContexts()) {
					gate.attempt(function() return true);
					removeListeners();
				}
			}, function(_:Dynamic):Void {});
		}
	}

	private static function removeListeners():Void {
		for (name in EVENTS) {
			Browser.document.removeEventListener(name, onGesture, true);
		}
	}
}
#else
class BrowserAudioUnlock {
	public static function install():Void {}
}
#end
