package pr2.harness;

class LocalPlayerDebugState {
	public final x:Float;
	public final y:Float;
	public final vx:Float;
	public final vy:Float;
	public final grounded:Bool;
	public final crouching:Bool;
	public final animation:String;
	public final touchedBlockType:Null<String>;

	public function new(
		x:Float,
		y:Float,
		vx:Float,
		vy:Float,
		grounded:Bool,
		crouching:Bool,
		animation:String,
		touchedBlockType:Null<String>
	) {
		this.x = x;
		this.y = y;
		this.vx = vx;
		this.vy = vy;
		this.grounded = grounded;
		this.crouching = crouching;
		this.animation = animation;
		this.touchedBlockType = touchedBlockType;
	}

	public function serialize():String {
		var touched = touchedBlockType == null ? "none" : touchedBlockType;
		return 'x=${round3(x)};y=${round3(y)};vx=${round3(vx)};vy=${round3(vy)};grounded=$grounded;crouching=$crouching;animation=$animation;touched=$touched';
	}

	private static function round3(value:Float):Float {
		return Math.round(value * 1000) / 1000;
	}
}
