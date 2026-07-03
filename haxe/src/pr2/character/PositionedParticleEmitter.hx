package pr2.character;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.geom.Point;
import pr2.character.PhysicsParticle.PhysicsParticleParams;

class PositionedParticleEmitter extends ParticleEmitter {
	private final params:PhysicsParticleParams;
	private final holder:DisplayObjectContainer;
	private final offsetX:Float;
	private final offsetY:Float;
	private final particleRandom:Void->Float;

	public function new(intervalMs:Int, durationMs:Int, target:DisplayObject, holder:DisplayObjectContainer, params:PhysicsParticleParams,
			offsetX:Float = 0, offsetY:Float = 0, ?random:Void->Float) {
		super(intervalMs, durationMs, target, holder, random);
		this.params = params;
		this.holder = holder;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		this.particleRandom = random == null ? Math.random : random;
	}

	override private function createParticle(x:Float, y:Float):Null<DisplayObject> {
		if (target == null || target.parent == null) {
			return null;
		}
		var particleParams = copyParams(params);
		particleParams.minX = x + params.minOffsetX;
		particleParams.maxX = x + params.maxOffsetX;
		particleParams.minY = y + params.minOffsetY;
		particleParams.maxY = y + params.maxOffsetY;
		var particle = new PhysicsParticle(particleParams, particleRandom);
		holder.addChild(particle);
		return particle;
	}

	override private function makeX():Float {
		return getTargetPoint().x;
	}

	override private function makeY():Float {
		return getTargetPoint().y;
	}

	private function getTargetPoint():Point {
		if (holder == null || target == null || target.parent == null) {
			return new Point();
		}
		var point = new Point(target.x - offsetX, target.y - offsetY);
		point = target.parent.localToGlobal(point);
		return holder.globalToLocal(point);
	}

	private static function copyParams(params:PhysicsParticleParams):PhysicsParticleParams {
		return {
			graphic: params.graphic,
			colors: params.colors == null ? [] : params.colors.copy(),
			life: params.life,
			startAlpha: params.startAlpha,
			minVelAlpha: params.minVelAlpha,
			maxVelAlpha: params.maxVelAlpha,
			minVelX: params.minVelX,
			maxVelX: params.maxVelX,
			minVelY: params.minVelY,
			maxVelY: params.maxVelY,
			velScaleX: params.velScaleX,
			velScaleY: params.velScaleY,
			fricX: params.fricX,
			fricY: params.fricY,
			minOffsetX: params.minOffsetX,
			maxOffsetX: params.maxOffsetX,
			minOffsetY: params.minOffsetY,
			maxOffsetY: params.maxOffsetY,
			minScale: params.minScale,
			maxScale: params.maxScale,
			minX: params.minX,
			maxX: params.maxX,
			minY: params.minY,
			maxY: params.maxY,
			accelX: params.accelX,
			accelY: params.accelY,
			targetAlpha: params.targetAlpha,
			minVelRotation: params.minVelRotation,
			maxVelRotation: params.maxVelRotation,
			minRotation: params.minRotation,
			maxRotation: params.maxRotation
		};
	}
}
