package pr2.animation;

interface NativeAnimation {
	public var state(default, null):PlaybackState;
	public var currentFrame(default, null):Int;
	public var durationFrames(default, null):Int;
	public var looping(default, null):Bool;
	public var onComplete:Null<Void->Void>;
	public function play(?restart:Bool = false):Void;
	public function pause():Void;
	public function stop():Void;
	public function advance(frames:Int):Void;
	public function dispose():Void;
}
