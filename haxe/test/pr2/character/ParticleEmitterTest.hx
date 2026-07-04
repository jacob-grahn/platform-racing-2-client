package pr2.character;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.character.PhysicsParticle.PhysicsParticleParams;
import pr2.effects.ArrowEffect;
import pr2.effects.StarEffect;

class ParticleEmitterTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testArrowEffectDriftsFadesAndRemoves();
		testBaseParticleEmitterCreatesStarEffect();
		testArrowSparkleEmitterCreatesColoredArrowEffect();
		testRainbowStarEmitterCreatesColoredRotatedStarEffect();
		testPhysicsParticleAppliesRandomizedMotionAndLifetime();
		testPositionedParticleEmitterCreatesPhysicsParticleAtTargetPoint();
		trace('ParticleEmitterTest passed $assertions assertions');
	}

	private static function testArrowEffectDriftsFadesAndRemoves():Void {
		var parent = new Sprite();
		var arrow = new ArrowEffect(10, 20);
		parent.addChild(arrow);

		assertClose(0.25, arrow.scaleX, "arrow effect uses Flash scale x");
		assertClose(0.25, arrow.scaleY, "arrow effect uses Flash scale y");
		assertEquals("Arrow2Graphic", arrow.graphic.symbol.linkageClassName, "arrow effect uses authored Arrow2Graphic");
		arrow.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(20.1, arrow.y, "arrow effect applies Flash vertical drift");
		assertClose(0.94, arrow.alpha, "arrow effect fades by Flash alpha delta");

		for (_ in 0...14) {
			arrow.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(0, parent.numChildren, "arrow effect removes itself after 15 frames");
	}

	private static function testBaseParticleEmitterCreatesStarEffect():Void {
		var target = new Sprite();
		target.x = 50;
		target.y = 80;
		var parent = new Sprite();
		var emitter = new ParticleEmitter(33, 66, target, parent, sequence([0.25, 0.4]));

		emitter.tick();
		assertEquals(1, parent.numChildren, "base particle emitter mounts a default particle");
		var star = Std.downcast(parent.getChildAt(0), StarEffect);
		assertTrue(star != null, "base particle emitter creates StarEffect particles");
		assertClose(45, star.x, "base particle emitter randomizes x in Flash's 20px range");
		assertClose(58, star.y, "base particle emitter randomizes y in Flash's 55px range");
		assertEquals("PointyStar", star.graphic.symbol.linkageClassName, "star effect uses authored PointyStar");
		for (_ in 0...StarEffect.LIFETIME_FRAMES) {
			star.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(0, parent.numChildren, "star effect removes itself after 15 frames");
		star.remove();
		emitter.remove();
	}

	private static function testArrowSparkleEmitterCreatesColoredArrowEffect():Void {
		var values = [0.5, 0.2, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8];
		var target = new Sprite();
		target.x = 100;
		target.y = 200;
		var parent = new Sprite();
		var emitter = new ArrowSparkleEmitter(33, 99, target, parent, sequence(values));

		emitter.tick();
		assertEquals(1, parent.numChildren, "arrow sparkle emitter mounts one particle per tick");
		var arrow = Std.downcast(parent.getChildAt(0), ArrowEffect);
		assertTrue(arrow != null, "arrow sparkle emitter creates ArrowEffect particles");
		assertClose(100, arrow.x, "arrow sparkle x uses target plus randomized 20px range");
		assertClose(189, arrow.y, "arrow sparkle y uses target minus randomized 55px range");
		var color = arrow.transform.colorTransform;
		assertClose(0.1, color.redMultiplier, "arrow sparkle randomizes red multiplier");
		assertClose(0.4, color.alphaMultiplier, "arrow sparkle randomizes alpha multiplier");
		assertClose(0.8, color.alphaOffset, "arrow sparkle randomizes alpha offset");
		assertEquals(2, emitter.remainingLife(), "arrow sparkle emitter decrements Flash interval life");

		emitter.remove();
		assertTrue(emitter.isRemoved(), "arrow sparkle emitter remove stops future ticks");
		assertEquals(null, emitter.target, "arrow sparkle emitter release clears target reference");
		arrow.remove();
	}

	private static function testRainbowStarEmitterCreatesColoredRotatedStarEffect():Void {
		var target = new Sprite();
		target.x = 100;
		target.y = 200;
		var parent = new Sprite();
		var emitter = new RainbowStarEmitter(33, 99, target, parent, sequence([0.5, 0.2, 0.25, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]));

		emitter.tick();
		var star = Std.downcast(parent.getChildAt(0), StarEffect);
		assertTrue(star != null, "rainbow-star emitter creates StarEffect particles");
		assertClose(90, star.rotation, "rainbow-star emitter randomizes star rotation");
		assertClose(0.1, star.transform.colorTransform.redMultiplier, "rainbow-star emitter randomizes color transform");
		star.remove();
		emitter.remove();
	}

	private static function testPhysicsParticleAppliesRandomizedMotionAndLifetime():Void {
		var parent = new Sprite();
		var particle = new PhysicsParticle(basePhysicsParams(), sequence([0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]));
		parent.addChild(particle);

		assertClose(15, particle.x, "physics particle randomizes initial x");
		assertClose(15, particle.y, "physics particle randomizes initial y");
		assertClose(1.5, particle.scaleX, "physics particle randomizes initial scale");
		particle.tick(new Event(Event.ENTER_FRAME));
		assertClose(18, particle.x, "physics particle applies velocity x");
		assertClose(17, particle.y, "physics particle applies velocity y");
		assertClose(1.6, particle.scaleX, "physics particle applies scale velocity");
		assertClose(0.4, particle.alpha, "physics particle applies alpha velocity and life fade");
		for (_ in 0...3) {
			particle.tick(new Event(Event.ENTER_FRAME));
		}
		assertEquals(0, parent.numChildren, "physics particle removes after configured life");
	}

	private static function testPositionedParticleEmitterCreatesPhysicsParticleAtTargetPoint():Void {
		var holder = new Sprite();
		var targetParent = new Sprite();
		targetParent.x = 100;
		targetParent.y = 50;
		var target = new Sprite();
		target.x = 10;
		target.y = 20;
		targetParent.addChild(target);
		holder.addChild(targetParent);
		var emitter = new PositionedParticleEmitter(75, 150, target, holder, basePhysicsParams(), -15, -10, sequence([0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]));

		emitter.tick();
		assertEquals(1, holder.numChildren - 1, "positioned emitter mounts one physics particle");
		var particle = Std.downcast(holder.getChildAt(1), PhysicsParticle);
		assertTrue(particle != null, "positioned emitter creates PhysicsParticle instances");
		assertClose(125, particle.x, "positioned emitter converts target x into holder space plus offsets");
		assertClose(80, particle.y, "positioned emitter converts target y into holder space plus offsets");
		particle.remove();
		emitter.remove();
	}

	private static function basePhysicsParams():PhysicsParticleParams {
		return {
			graphic: "DjinnIceGraphic",
			colors: [0x112233, 0x445566],
			life: 4,
			startAlpha: 0.1,
			minVelAlpha: 0.2,
			maxVelAlpha: 0.4,
			minVelX: 2,
			maxVelX: 4,
			minVelY: 1,
			maxVelY: 3,
			velScaleX: 0.1,
			velScaleY: 0.1,
			fricX: 1,
			fricY: 1,
			minOffsetX: -5,
			maxOffsetX: 5,
			minOffsetY: -5,
			maxOffsetY: 5,
			minScale: 1,
			maxScale: 2,
			minX: 10,
			maxX: 20,
			minY: 10,
			maxY: 20
		};
	}

	private static function sequence(values:Array<Float>):Void->Float {
		var index = 0;
		return function() {
			return values[index++];
		};
	}

	private static function assertEquals<T>(expected:T, actual:T, message:String):Void {
		assertions++;
		if (actual != expected) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) {
			throw message;
		}
	}

	private static function assertClose(expected:Float, actual:Float, message:String, epsilon:Float = 0.0001):Void {
		assertions++;
		if (Math.isNaN(actual) || Math.abs(expected - actual) > epsilon) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
