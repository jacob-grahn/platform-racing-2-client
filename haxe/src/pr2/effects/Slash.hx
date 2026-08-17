package pr2.effects;

import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.gameplay.CoordinateFrames;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;

typedef SlashContext = {
	final level:Level;
	final courseRotation:Int;
	/** Gravity frame in which the sender serialized the slash coordinates. */
	@:optional final senderRotation:Int;
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
		var senderRotation = context == null || context.senderRotation == null ? (context == null ? 0 : context.courseRotation) : context.senderRotation;
		var receiverRotation = context == null ? senderRotation : context.courseRotation;
		var displayPosition = CoordinateFrames.displayFromGravityValues(startX, startY, senderRotation, receiverRotation);
		x = displayPosition.x;
		y = displayPosition.y;
		rotation = receiverRotation - senderRotation;
		hitAt(startX, startY - 14);
		hitAt(startX, startY + 14);
		hitAt(startX + reach, startY - 14);
		hitAt(startX + reach, startY + 14);
		hitAt(startX + reach * 2, startY - 14);
		hitAt(startX + reach * 2, startY + 14);
		playSwish(startX, startY);
	}

	private function hitAt(px:Int, py:Int):Void {
		if (context == null) {
			return;
		}
		var senderRotation = context.senderRotation == null ? context.courseRotation : context.senderRotation;
		var rotated = CoordinateFrames.canonicalFromGravityValues(px, py, senderRotation);
		var block = PhysicsEffect.blockFromPos(context.level, rotated.x, rotated.y, 0);
		if (block != null && PhysicsEffect.isActiveBlock(block) && context.onBlockDamage != null) {
			context.onBlockDamage(block, reach);
		}
		var player = context.player;
		var displayProbe = CoordinateFrames.displayFromGravityValues(px, py, senderRotation, context.courseRotation);
		if (player != null && player.tempId != shooterID && !player.removed && player.y > displayProbe.y - 14 && player.y < displayProbe.y + 74) {
			if (player.x > displayProbe.x - 14 && player.x < displayProbe.x + 14) {
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
