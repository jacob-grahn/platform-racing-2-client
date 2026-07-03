package pr2.character;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.effects.ArrowEffect;

class ParticleEmitterTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testArrowEffectDriftsFadesAndRemoves();
		testArrowSparkleEmitterCreatesColoredArrowEffect();
		trace('ParticleEmitterTest passed $assertions assertions');
	}

	private static function testArrowEffectDriftsFadesAndRemoves():Void {
		var parent = new Sprite();
		var arrow = new ArrowEffect(10, 20);
		parent.addChild(arrow);

		arrow.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(20.1, arrow.y, "arrow effect applies Flash vertical drift");
		assertClose(0.94, arrow.alpha, "arrow effect fades by Flash alpha delta");

		for (_ in 0...14) {
			arrow.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(0, parent.numChildren, "arrow effect removes itself after 15 frames");
	}

	private static function testArrowSparkleEmitterCreatesColoredArrowEffect():Void {
		var values = [0.5, 0.2, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8];
		var index = 0;
		var target = new Sprite();
		target.x = 100;
		target.y = 200;
		var parent = new Sprite();
		var emitter = new ArrowSparkleEmitter(33, 99, target, parent, function() {
			return values[index++];
		});

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
