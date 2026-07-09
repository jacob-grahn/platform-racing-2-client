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
	public final itemUses:Null<Int>;
	public final lastItemEffect:Null<String>;
	public final speedStat:Float;
	public final accelerationStat:Float;
	public final jumpStat:Float;
	public final courseRotation:Int;
	public final finished:Bool;
	public final finishBlockId:Null<Int>;
	public final finishX:Null<Int>;
	public final finishY:Null<Int>;
	public final lives:Int;
	public final courseTime:Int;
	public final jetPackActive:Bool;
	public final speedBurstActive:Bool;
	public final touchedBlockX:Null<Int>;
	public final touchedBlockY:Null<Int>;
	public final lastCollisionEvent:Null<String>;

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
		?itemUses:Null<Int>,
		?lastItemEffect:Null<String>,
		speedStat:Float = 50,
		accelerationStat:Float = 50,
		jumpStat:Float = 50,
		courseRotation:Int = 0,
		finished:Bool = false,
		?finishBlockId:Null<Int>,
		?finishX:Null<Int>,
		?finishY:Null<Int>,
		lives:Int = 3,
		courseTime:Int = 120,
		jetPackActive:Bool = false,
		speedBurstActive:Bool = false,
		?touchedBlockX:Null<Int>,
		?touchedBlockY:Null<Int>,
		?lastCollisionEvent:Null<String>
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
		this.itemUses = itemUses;
		this.lastItemEffect = lastItemEffect;
		this.speedStat = speedStat;
		this.accelerationStat = accelerationStat;
		this.jumpStat = jumpStat;
		this.courseRotation = courseRotation;
		this.finished = finished;
		this.finishBlockId = finishBlockId;
		this.finishX = finishX;
		this.finishY = finishY;
		this.lives = lives;
		this.courseTime = courseTime;
		this.jetPackActive = jetPackActive;
		this.speedBurstActive = speedBurstActive;
		this.touchedBlockX = touchedBlockX;
		this.touchedBlockY = touchedBlockY;
		this.lastCollisionEvent = lastCollisionEvent;
	}

	public function serialize():String {
		var touched = touchedBlockType == null ? "none" : touchedBlockType;
		var touchedPos = touchedBlockX == null || touchedBlockY == null ? "none" : '$touchedBlockX,$touchedBlockY';
		var event = lastCollisionEvent == null ? "none" : lastCollisionEvent;
		var item = itemId == null ? "none" : Std.string(itemId);
		var uses = itemUses == null ? "none" : Std.string(itemUses);
		var effect = lastItemEffect == null ? "none" : lastItemEffect;
		var finish = finishBlockId == null ? "none" : '$finishBlockId,$finishX,$finishY';
		return 'x=${round3(x)};y=${round3(y)};vx=${round3(vx)};vy=${round3(vy)};grounded=$grounded;crouching=$crouching;animation=$animation;touched=$touched;touchedPos=$touchedPos;event=$event;mode=$mode;item=$item;itemUses=$uses;itemEffect=$effect;speed=${round3(speedStat)};accel=${round3(accelerationStat)};jump=${round3(jumpStat)};rotation=$courseRotation;lives=$lives;time=$courseTime;jet=$jetPackActive;sparkle=$speedBurstActive;finished=$finished;finish=$finish';
	}

	private static function round3(value:Float):Float {
		return Math.round(value * 1000) / 1000;
	}
}
