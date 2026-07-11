package pr2.effects;

import openfl.events.Event;
import pr2.gameplay.BlockCollision;
import pr2.gameplay.RotationMath;
import pr2.gameplay.RotationMath.RotatedPoint;
import pr2.level.ServerLevel;
import pr2.level.ServerLevel.DecodedBlock;

typedef PhysicsEffectContext = {
	final level:ServerLevel;
	final courseRotation:Int;
	@:optional final playerX:Float;
	@:optional final playerY:Float;
	@:optional final playerCrouching:Bool;
	@:optional final playerRemoved:Bool;
}

/**
	Shared Flash `effects.PhysicsEffect` movement/collision base used by loose
	race effects such as eggs and hats.
**/
class PhysicsEffect extends Effect {
	public static inline var GRAVITY:Float = 0.2;
	public static inline var MAX_FALL_SPEED:Float = 8;

	public var velX(default, null):Float = 0;
	public var velY(default, null):Float = 0;
	public var posX:Float;
	public var posY:Float;
	public var rot:Int;
	public var hitInactiveBlocks:Bool = false;

	private var grounded:Bool = false;
	private var contextProvider:Null<Void->PhysicsEffectContext>;

	public function new(startX:Int, startY:Int, startRot:Int, ?contextProvider:Void->PhysicsEffectContext) {
		posX = startX;
		posY = startY;
		rot = startRot;
		this.contextProvider = contextProvider;
		super(startX, startY);
		activate();
	}

	public function activate():Void {
		addEventListener(Event.ENTER_FRAME, go);
	}

	public function deactivate():Void {
		removeEventListener(Event.ENTER_FRAME, go);
	}

	public function setVelocity(x:Float, y:Float):Void {
		velX = x;
		velY = y;
	}

	public function isGrounded():Bool {
		return grounded;
	}

	public function step(level:ServerLevel, courseRotation:Int, ?playerX:Float, ?playerY:Float, playerCrouching:Bool = false,
			playerRemoved:Bool = false):Void {
		velY += GRAVITY;
		if (velY > MAX_FALL_SPEED) {
			velY = MAX_FALL_SPEED;
		}
		posY += velY;
		posX += velX;
		rotation = RotationMath.normalizeDisplayRotation(courseRotation - rot);

		var rotatedPos = RotationMath.rotatePoint(posX, posY, -rotation);
		if (velX != 0) {
			var wallProbe = RotationMath.rotatePoint(posX + velX, posY - 10, -rotation);
			var wallBlock = blockFromPos(level, wallProbe.x, wallProbe.y, courseRotation);
			if (canHitBlock(wallBlock)) {
				var blockPos = rotatedBlockPos(wallBlock, rot);
				posX = velX < 0 ? blockPos.x + 31 : blockPos.x - 1;
				onTouchWall();
			}
		}

		var groundBlock = blockFromPos(level, rotatedPos.x, rotatedPos.y, courseRotation);
		if (canHitBlock(groundBlock)) {
			grounded = true;
			var blockPos = rotatedBlockPos(groundBlock, rot);
			if (velY < 0) {
				velY *= -0.5;
				posY = blockPos.y + 31;
			} else {
				velY = 0;
				posY = blockPos.y;
			}
		} else {
			grounded = false;
		}

		if (playerX != null && playerY != null && isNearLocalPlayer(Std.int(x), Std.int(y), playerX, playerY, playerCrouching, playerRemoved)) {
			onTouchLocalPlayer();
		}

		rotatedPos = RotationMath.rotatePoint(posX, posY, -rotation);
		x = rotatedPos.x;
		y = rotatedPos.y;
	}

	private function go(_:Event):Void {
		if (contextProvider == null) {
			return;
		}
		var context = contextProvider();
		step(context.level, context.courseRotation, context.playerX, context.playerY, context.playerCrouching == true, context.playerRemoved == true);
	}

	private function canHitBlock(block:Null<DecodedBlock>):Bool {
		return block != null && (hitInactiveBlocks || isActiveBlock(block));
	}

	function onTouchLocalPlayer():Void {}

	function onTouchWall():Void {}

	override public function remove():Void {
		deactivate();
		contextProvider = null;
		super.remove();
	}

	public static function blockFromPos(level:ServerLevel, posX:Int, posY:Int, rotation:Int):Null<DecodedBlock> {
		return BlockCollision.blockFromPos(level, posX, posY, rotation);
	}

	public static function isActiveBlock(block:Null<DecodedBlock>):Bool {
		return BlockCollision.isActiveBlock(block);
	}

	public static function rotatedBlockPos(block:DecodedBlock, rot:Int):RotatedPoint {
		return BlockCollision.rotatedBlockPos(block, rot);
	}

	public static function isNearLocalPlayer(px:Int, py:Int, playerX:Float, playerY:Float, playerCrouching:Bool, playerRemoved:Bool):Bool {
		return BlockCollision.isNearLocalPlayer(px, py, playerX, playerY, playerCrouching, playerRemoved);
	}
}
