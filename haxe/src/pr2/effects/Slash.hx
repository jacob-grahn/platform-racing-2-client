package pr2.effects;

import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.gameplay.RotationMath;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;

typedef SlashContext = {
	final level:Level;
	final courseRotation:Int;
	@:optional final player:SlashPlayer;
	@:optional final onBlockDamage:LevelBlock->Float->Void;
	@:optional final playSound:Float->Float->Void;
}

typedef SlashPlayer = {
	final tempId:Int;
	final x:Float;
	final y:Float;
	final removed:Bool;
	final hit:Float->Float->Void;
}

/** Concrete port of `effects.Slash`: authored animation, six probes, and swish. */
class Slash extends Effect {
	public static inline var LIFETIME_FRAMES:Int = 6;
	public static inline var RIGHT_REACH:Int = 29;
	public static inline var HIT_VEL_Y:Int = -9;
	public static inline var SOUND_PATH:String = "assets/audio/sfx/slash_swish.mp3";

	public var animation(default, null):NativeEffectAnimation;
	public var reach(default, null):Int = RIGHT_REACH;
	public final shooterID:Int;
	private var context:Null<SlashContext>;

	public function new(startX:Int, startY:Int, dir:String, tempID:Int, ?context:SlashContext) {
		shooterID = tempID;
		this.context = context;
		super(startX, startY);
		animation = new NativeEffectAnimation("slash", LIFETIME_FRAMES);
		addChild(animation);
		scheduleRemove(LIFETIME_FRAMES);
		if (dir == "left") {
			reach = -RIGHT_REACH;
			scaleX = -1;
		}
		hitAt(Std.int(x), Std.int(y - 14));
		hitAt(Std.int(x), Std.int(y + 14));
		hitAt(Std.int(x + reach), Std.int(y - 14));
		hitAt(Std.int(x + reach), Std.int(y + 14));
		hitAt(Std.int(x + reach * 2), Std.int(y - 14));
		hitAt(Std.int(x + reach * 2), Std.int(y + 14));
		playSwish(startX, startY);
	}

	private function hitAt(px:Int, py:Int):Void {
		if (context == null) {
			return;
		}
		var rotated = RotationMath.rotatePoint(px, py, context.courseRotation);
		var block = PhysicsEffect.blockFromPos(context.level, rotated.x, rotated.y, 0);
		if (block != null && PhysicsEffect.isActiveBlock(block) && context.onBlockDamage != null) {
			context.onBlockDamage(block, reach);
		}
		var player = context.player;
		if (player != null && player.tempId != shooterID && !player.removed && player.y > py - 14 && player.y < py + 74) {
			if (player.x > px - 14 && player.x < px + 14) {
				player.hit(reach, HIT_VEL_Y);
			}
		}
	}

	private function playSwish(worldX:Float, worldY:Float):Void {
		if (context != null && context.playSound != null) {
			context.playSound(worldX, worldY);
			return;
		}
		if (Assets.exists(SOUND_PATH)) {
			SoundEffects.playGameSound(Assets.getSound(SOUND_PATH), worldX, worldY, 0, 0);
		}
	}

	override public function remove():Void {
		if (animation != null) {
			animation.dispose();
			if (animation.parent == this) {
				removeChild(animation);
			}
			animation = null;
		}
		context = null;
		super.remove();
	}
}
