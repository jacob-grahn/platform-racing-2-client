package pr2.effects;

import openfl.events.Event;
import pr2.gameplay.CoordinateFrames;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;
import pr2.runtime.FrameClock;
import pr2.gameplay.presentation.CharacterPresentationLayer;
import pr2.gameplay.presentation.PresentationPose;

typedef ShotEffectContext = {
	final level:Level;
	final courseRotation:Int;
	@:optional final players:Array<ShotEffectPlayer>;
}

typedef ShotEffectPlayer = {
	final tempId:Int;
	final x:Float;
	final y:Float;
	final removed:Bool;
	final local:Bool;
	@:optional final onHit:Float->Float->Void;
}

/**
	Shared Flash `effects.ShotEffect` projectile base used by laser and ice-wave
	shots. Concrete visuals/sounds stay in the item-specific effect classes.
**/
class ShotEffect extends Effect {
	public static inline var DEFAULT_SPEED:Float = 5;
	public static inline var DEFAULT_LIFE:Int = 100;

	public var speed(default, null):Float = DEFAULT_SPEED;
	public var posX:Float;
	public var posY:Float;
	public var velX(default, null):Float = 0;
	public var velY(default, null):Float = 0;
	public var angle(default, null):Float = 0;
	public var rot(default, null):Int;
	public var life:Float = DEFAULT_LIFE;
	public var shooterID(default, null):Int = -1;
	public var hitInactiveBlocks:Bool = false;
	public final type:String;

	private var contextProvider:Null<Void->ShotEffectContext>;
	private final presentationPose:PresentationPose = new PresentationPose();
	private var authoritativeDisplayX:Float;
	private var authoritativeDisplayY:Float;
	private var authoritativeDisplayRotation:Float;
	private var previousSimulationVelX:Float = 0;
	private var previousSimulationVelY:Float = 0;
	private var presentationCollisionPending:Bool = true;

	public function new(startX:Float, startY:Float, startAngle:Float, startRot:Int, tempID:Int, item:String, startCourseRotation:Int = 0,
			?contextProvider:Void->ShotEffectContext) {
		posX = startX;
		posY = startY;
		rot = startRot;
		shooterID = tempID;
		type = item;
		this.contextProvider = contextProvider;
		super(startX, startY);
		setAngle(startAngle);
		previousSimulationVelX = velX;
		previousSimulationVelY = velY;
		rotation = startAngle + startCourseRotation - startRot;
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		position(startCourseRotation);
		if (contextProvider != null) {
			var context = contextProvider();
			checkCollisions(context.level, context.courseRotation, context.players);
		}
	}

	public function setSpeed(value:Float):Void {
		speed = value;
		updateVelocity();
	}

	public function setAngle(value:Float):Void {
		angle = value;
		updateVelocity();
	}

	public function step(level:Level, courseRotation:Int, ?players:Array<ShotEffectPlayer>):Void {
		presentationPose.beginSimulationTick(
			authoritativeDisplayX,
			authoritativeDisplayY,
			authoritativeDisplayRotation,
			velX < 0 ? -1 : 1,
			CharacterPresentationLayer.Front
		);
		var directionChanged = PresentationPose.velocityReversed(previousSimulationVelX, velX)
			|| PresentationPose.velocityReversed(previousSimulationVelY, velY);
		move();
		position(courseRotation);
		checkCollisions(level, courseRotation, players);
		authoritativeDisplayX = x;
		authoritativeDisplayY = y;
		authoritativeDisplayRotation = rotation;
		var presentationDiscontinuity = presentationCollisionPending
			|| directionChanged
			|| PresentationPose.movementTooLarge(
				authoritativeDisplayX - presentationPose.previousX,
				authoritativeDisplayY - presentationPose.previousY,
				60
			);
		presentationPose.finishSimulationTick(
			authoritativeDisplayX,
			authoritativeDisplayY,
			authoritativeDisplayRotation,
			velX < 0 ? -1 : 1,
			CharacterPresentationLayer.Front,
			presentationDiscontinuity
		);
		presentationCollisionPending = false;
		previousSimulationVelX = velX;
		previousSimulationVelY = velY;
		life--;
		if (life <= 0) {
			onLifeEnd();
		}
	}

	function move():Void {
		posX += velX;
		posY += velY;
	}

	function position(courseRotation:Int):Void {
		var pos = CoordinateFrames.displayFromGravityValues(posX, posY, rot, courseRotation);
		x = pos.x;
		y = pos.y;
		rotation = angle + courseRotation - rot;
		authoritativeDisplayX = x;
		authoritativeDisplayY = y;
		authoritativeDisplayRotation = rotation;
	}

	function checkCollisions(level:Level, courseRotation:Int, ?players:Array<ShotEffectPlayer>):Void {
		var block = PhysicsEffect.blockFromPos(level, Std.int(x), Std.int(y), courseRotation);
		if (block != null && (hitInactiveBlocks || PhysicsEffect.isActiveBlock(block))) {
			hitBlock(block);
		}
		var player = getPlayerAt(Std.int(x), Std.int(y), players);
		if (player != null) {
			hitPlayer(player);
		}
	}

	function getPlayerAt(px:Int, py:Int, ?players:Array<ShotEffectPlayer>):Null<ShotEffectPlayer> {
		if (players == null) {
			return null;
		}
		for (player in players) {
			if (player.tempId == shooterID || player.removed) {
				continue;
			}
			if (player.y > py && player.y < py + 60) {
				if ((scaleX == 1 && player.x > px - 60 && player.x < px) || (scaleX == -1 && player.x < px + 60 && player.x > px)) {
					return player;
				}
			}
		}
		return null;
	}

	function updateVelocity():Void {
		var radians = angle * Math.PI / 180;
		velX = Math.cos(radians) * speed;
		velY = Math.sin(radians) * speed;
	}

	function hitBlock(block:LevelBlock):Void {
		presentationCollisionPending = true;
		onBlockDamage(block, velX);
		hitAnything();
	}

	function hitPlayer(player:ShotEffectPlayer):Void {
		presentationCollisionPending = true;
		if (player.local && player.onHit != null) {
			player.onHit(velX, velY);
		}
		x = player.x - velX;
		hitAnything();
	}

	function onBlockDamage(block:LevelBlock, damageX:Float):Void {}

	function hitAnything():Void {}

	function onLifeEnd():Void {
		remove();
	}

	private function onEnterFrame(_:Event):Void {
		if (!FrameClock.shouldRunSimulationFrame()) {
			if (FrameClock.shouldRenderIntermediatePresentationFrame()) renderPresentationFrame();
			return;
		}
		if (contextProvider == null) {
			return;
		}
		var context = contextProvider();
		step(context.level, context.courseRotation, context.players);
	}

	public function renderPresentationFrame():Void {
		if (!presentationPose.hasSamples) return;
		var factor = presentationPose.discontinuity ? 0.0 : 0.5;
		x = presentationPose.extrapolatedX(factor);
		y = presentationPose.extrapolatedY(factor);
		rotation = presentationPose.extrapolatedRotation(factor);
	}

	override public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		contextProvider = null;
		super.remove();
	}
}
