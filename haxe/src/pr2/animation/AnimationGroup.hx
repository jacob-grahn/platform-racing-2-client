package pr2.animation;

/** A composed clip that advances and tears down child clips as one unit. */
class AnimationGroup implements NativeAnimation {
	public var state(default, null):PlaybackState = Stopped;
	public var currentFrame(default, null):Int = 0;
	public var durationFrames(default, null):Int = 0;
	public var looping(default, null):Bool;
	public var onComplete:Null<Void->Void>;

	private var children:Array<NativeAnimation>;

	public function new(children:Array<NativeAnimation>, ?looping:Bool = false) {
		if (children.length == 0) throw "Animation group requires at least one child";
		this.children = children.copy();
		this.looping = looping;
		for (child in children) if (child.durationFrames > durationFrames) durationFrames = child.durationFrames;
	}

	public function play(?restart:Bool = false):Void {
		ensureAlive();
		if (restart || state == Completed) currentFrame = 0;
		state = Playing;
		for (child in children) child.play(restart || child.state == Completed);
	}

	public function pause():Void {
		ensureAlive();
		if (state != Playing) return;
		state = Paused;
		for (child in children) child.pause();
	}

	public function stop():Void {
		ensureAlive();
		state = Stopped;
		currentFrame = 0;
		for (child in children) child.stop();
	}

	public function advance(frames:Int):Void {
		ensureAlive();
		if (frames < 0) throw "Animation cannot advance by a negative frame count";
		if (state != Playing || frames == 0) return;
		for (child in children) child.advance(frames);
		currentFrame += frames;
		if (currentFrame < durationFrames) return;
		if (looping) {
			currentFrame %= durationFrames;
			for (child in children) child.play(true);
			if (currentFrame > 0) for (child in children) child.advance(currentFrame);
		} else {
			currentFrame = durationFrames;
			state = Completed;
			var callback = onComplete;
			if (callback != null) callback();
		}
	}

	public function dispose():Void {
		if (state == Disposed) return;
		for (child in children) child.dispose();
		children = [];
		onComplete = null;
		state = Disposed;
	}

	private function ensureAlive():Void {
		if (state == Disposed) throw "Animation group has been disposed";
	}
}
