package pr2.character;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.TimerEvent;
import openfl.utils.Timer;
import pr2.effects.StarEffect;

/**
	Focused port of `character.ParticleEmitter`: a setInterval-style particle
	spawner that follows a target and stops after `durationMs / intervalMs` ticks.
**/
class ParticleEmitter {
	public final intervalMs:Int;
	public final durationMs:Int;
	public var target(default, null):Null<DisplayObject>;

	private final parentLayer:DisplayObjectContainer;
	private final random:Void->Float;
	private var timer:Timer;
	private var life:Int;
	private var removed:Bool = false;

	public function new(intervalMs:Int, durationMs:Int, target:DisplayObject, parentLayer:DisplayObjectContainer, ?random:Void->Float) {
		this.intervalMs = intervalMs;
		this.durationMs = durationMs;
		this.target = target;
		this.parentLayer = parentLayer;
		this.random = random == null ? Math.random : random;
		life = Std.int(Math.floor(durationMs / intervalMs));
		timer = new Timer(intervalMs);
		timer.addEventListener(TimerEvent.TIMER, onTimer);
		timer.start();
	}

	private function onTimer(_:TimerEvent):Void {
		tick();
	}

	@:allow(pr2.character.ParticleEmitterTest)
	@:allow(pr2.gameplay.CharacterLifecycleTest)
	private function tick():Void {
		if (removed || target == null) {
			return;
		}
		var particle = createParticle(makeX(), makeY());
		if (particle != null && particle.parent == null) {
			parentLayer.addChild(particle);
		}
		life--;
		if (life <= 0) {
			remove();
		}
	}

	private function makeX():Float {
		return target.x + random() * 20 - 10;
	}

	private function makeY():Float {
		return target.y - random() * 55;
	}

	private function createParticle(x:Float, y:Float):Null<DisplayObject> {
		return new StarEffect(x, y);
	}

	public function remainingLife():Int {
		return life;
	}

	public function isRemoved():Bool {
		return removed;
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		target = null;
		timer.stop();
		timer.removeEventListener(TimerEvent.TIMER, onTimer);
	}
}
