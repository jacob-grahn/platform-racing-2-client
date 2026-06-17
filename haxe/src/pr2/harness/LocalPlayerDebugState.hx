package pr2.harness;

import pr2.character.CharacterState;

class LocalPlayerDebugState {
	public final x:Float;
	public final y:Float;
	public final vx:Float;
	public final vy:Float;
	public final grounded:Bool;
	public final crouching:Bool;
	public final characterState:CharacterState;
	public final animation:String;
	public final touchedBlockType:Null<String>;
	public final mode:String;
	public final itemId:Null<Int>;
	public final speedStat:Float;
	public final accelerationStat:Float;
	public final jumpStat:Float;

	public function new(
		x:Float,
		y:Float,
		vx:Float,
		vy:Float,
		grounded:Bool,
		crouching:Bool,
		characterState:CharacterState,
		touchedBlockType:Null<String>,
		mode:String = "land",
		?itemId:Null<Int>,
		speedStat:Float = 50,
		accelerationStat:Float = 50,
		jumpStat:Float = 50
	) {
		this.x = x;
		this.y = y;
		this.vx = vx;
		this.vy = vy;
		this.grounded = grounded;
		this.crouching = crouching;
		this.characterState = characterState;
		this.animation = characterState.toString();
		this.touchedBlockType = touchedBlockType;
		this.mode = mode;
		this.itemId = itemId;
		this.speedStat = speedStat;
		this.accelerationStat = accelerationStat;
		this.jumpStat = jumpStat;
	}

	public function serialize():String {
		var touched = touchedBlockType == null ? "none" : touchedBlockType;
		var item = itemId == null ? "none" : Std.string(itemId);
		return 'x=${round3(x)};y=${round3(y)};vx=${round3(vx)};vy=${round3(vy)};grounded=$grounded;crouching=$crouching;animation=$animation;touched=$touched;mode=$mode;item=$item;speed=${round3(speedStat)};accel=${round3(accelerationStat)};jump=${round3(jumpStat)}';
	}

	private static function round3(value:Float):Float {
		return Math.round(value * 1000) / 1000;
	}
}
