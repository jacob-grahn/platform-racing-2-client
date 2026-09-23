package pr2.gameplay;

/** Flash's 45-tick experience interpolation, shared by both result views. */
class ExperienceProgress {
	public var current(default, null):Float = 0;
	public var target(default, null):Float = 0;
	public var toRank(default, null):Float = 0;
	public var active(default, null):Bool = false;
	private var step:Float = 0;
	public function new() {}
	public function start(old:Float, next:Float, rank:Float):Void {
		toRank = rank; current = Math.min(old, rank); target = Math.min(next, rank);
		step = (target - current) / 45; active = current <= target;
	}
	public function tick():Void {
		if (!active) return;
		current += step;
		if (current >= target) { current = target; active = false; }
	}
	public function ratio():Float return toRank == 0 ? 0 : current / toRank;
	public function text():String return pr2.lobby.NumberFormat.withCommas(Std.int(Math.floor(current))) + " / " + pr2.lobby.NumberFormat.withCommas(Std.int(toRank));
}
