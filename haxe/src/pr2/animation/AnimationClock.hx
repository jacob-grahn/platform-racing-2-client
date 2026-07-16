package pr2.animation;

/** Owner-driven simulation clock; it never reads wall time or ENTER_FRAME. */
class AnimationClock {
	private var animations:Array<NativeAnimation> = [];
	public var disposed(default, null):Bool = false;

	public function new() {}

	public function add(animation:NativeAnimation):NativeAnimation {
		if (disposed) throw "Animation clock has been disposed";
		if (animations.indexOf(animation) < 0) animations.push(animation);
		return animation;
	}

	public function remove(animation:NativeAnimation):Void {
		animations.remove(animation);
	}

	public function advance(frames:Int = 1):Void {
		if (disposed) throw "Animation clock has been disposed";
		for (animation in animations.copy()) animation.advance(frames);
	}

	public function dispose():Void {
		if (disposed) return;
		disposed = true;
		for (animation in animations) animation.dispose();
		animations = [];
	}
}
