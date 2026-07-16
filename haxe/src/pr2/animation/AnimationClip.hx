package pr2.animation;

/** Deterministic frame-clock animation for sequences and property tweens. */
class AnimationClip implements NativeAnimation {
	public var state(default, null):PlaybackState = Stopped;
	public var currentFrame(default, null):Int = 0;
	public var durationFrames(default, null):Int;
	public var looping(default, null):Bool;
	public var onComplete:Null<Void->Void>;

	private var renderFrame:Int->Void;

	public function new(durationFrames:Int, renderFrame:Int->Void, ?looping:Bool = false) {
		if (durationFrames < 1) throw "Animation duration must be at least one frame";
		this.durationFrames = durationFrames;
		this.renderFrame = renderFrame;
		this.looping = looping;
		renderFrame(0);
	}

	public static function frames(frameCount:Int, showFrame:Int->Void, ?looping:Bool = false):AnimationClip {
		if (frameCount < 1) throw "Frame sequence requires at least one frame";
		return new AnimationClip(frameCount, function(frame:Int):Void showFrame(Std.int(Math.min(frame, frameCount - 1))), looping);
	}

	public static function tween(durationFrames:Int, from:Float, to:Float, apply:Float->Void, ?ease:Float->Float):AnimationClip {
		var easing = ease == null ? function(value:Float):Float return value : ease;
		return new AnimationClip(durationFrames, function(frame:Int):Void {
			var progress = frame / durationFrames;
			apply(from + (to - from) * easing(progress));
		});
	}

	public function play(?restart:Bool = false):Void {
		ensureAlive();
		if (restart || state == Completed) {
			currentFrame = 0;
			renderFrame(0);
		}
		state = Playing;
	}

	public function pause():Void {
		ensureAlive();
		if (state == Playing) state = Paused;
	}

	public function stop():Void {
		ensureAlive();
		state = Stopped;
		currentFrame = 0;
		renderFrame(0);
	}

	public function advance(frames:Int):Void {
		ensureAlive();
		if (frames < 0) throw "Animation cannot advance by a negative frame count";
		if (state != Playing || frames == 0) return;
		var target = currentFrame + frames;
		if (looping) {
			currentFrame = target % durationFrames;
			renderFrame(currentFrame);
			return;
		}
		if (target >= durationFrames) {
			currentFrame = durationFrames;
			renderFrame(currentFrame);
			state = Completed;
			var callback = onComplete;
			if (callback != null) callback();
			return;
		}
		currentFrame = target;
		renderFrame(currentFrame);
	}

	public function dispose():Void {
		if (state == Disposed) return;
		state = Disposed;
		onComplete = null;
		renderFrame = function(_):Void {};
	}

	private function ensureAlive():Void {
		if (state == Disposed) throw "Animation has been disposed";
	}
}
