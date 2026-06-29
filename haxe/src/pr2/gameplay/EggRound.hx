package pr2.gameplay;

import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.level.ServerLevel;
import pr2.net.CommandHandler;
import pr2.runtime.PR2MovieClip;

typedef EggState = {
	final id:Int;
	final x:Int;
	final y:Int;
	final rot:Int;
	final velX:Int;
	final display:PR2MovieClip;
}

/**
	Ports the server-visible round state from `effects.Egg`: seeded id/position
	generation, egg-mode gating in Course, collect emission, and per-egg remote
	removal commands. The animated/attacking PhysicsEffect body remains separate.
**/
class EggRound {
	public static inline var COLLECT_SOUND_PATH:String = "assets/audio/sfx/sound898.mp3";

	private var rand:FlashRandom = new FlashRandom(1);
	private var nextId:Int = 1;
	private var mode:Int = 3;
	private final commandHandler:CommandHandler;
	private final onCollect:Int->Void;
	private final displayLayer:Null<Sprite>;
	private final cameraOffset:Void->Point;
	private final playCollectSound:Int->Int->Void;
	private var eggs:Map<Int, EggState> = new Map();

	public function new(commandHandler:CommandHandler, onCollect:Int->Void, ?displayLayer:Sprite, ?cameraOffset:Void->Point,
			?playCollectSound:Int->Int->Void) {
		this.commandHandler = commandHandler;
		this.onCollect = onCollect;
		this.displayLayer = displayLayer;
		this.cameraOffset = cameraOffset != null ? cameraOffset : function():Point return new Point();
		this.playCollectSound = playCollectSound != null ? playCollectSound : playDefaultCollectSound;
	}

	public function initRound(seed:Int):Void {
		clear();
		rand = new FlashRandom(seed);
		nextId = 1;
		mode = rand.nextMinMax(0, 5);
		if (mode > 3) {
			mode = 3;
		}
	}

	public function addEggs(count:Int, level:ServerLevel):Void {
		var remaining = count;
		while (remaining > 0) {
			spawn(level);
			remaining--;
		}
	}

	public function collectEgg(id:Int):Bool {
		var egg = eggs.get(id);
		if (egg == null) {
			return false;
		}
		playCollectSound(egg.x, egg.y);
		removeEgg(id);
		onCollect(id);
		return true;
	}

	public function removeEgg(id:Int):Bool {
		if (!eggs.exists(id)) {
			return false;
		}
		var egg = eggs.get(id);
		if (egg.display.parent != null) {
			egg.display.parent.removeChild(egg.display);
		}
		eggs.remove(id);
		commandHandler.defineCommand('removeEgg$id', null);
		return true;
	}

	public function clear():Void {
		for (id in ids()) {
			removeEgg(id);
		}
	}

	public function count():Int {
		var total = 0;
		for (_ in eggs.keys()) {
			total++;
		}
		return total;
	}

	public function ids():Array<Int> {
		var result:Array<Int> = [];
		for (id in eggs.keys()) {
			result.push(id);
		}
		result.sort(function(a, b) return a - b);
		return result;
	}

	public function egg(id:Int):Null<EggState> {
		return eggs.get(id);
	}

	public function currentMode():Int {
		return mode;
	}

	private function spawn(level:ServerLevel):Void {
		var id = nextId++;
		var minX = Std.int(Math.min(level.minX, level.maxX));
		var maxX = Std.int(Math.max(level.minX, level.maxX));
		var minY = Std.int(Math.min(level.minY, level.maxY));
		var maxY = Std.int(Math.max(level.minY, level.maxY));
		var rawX = rand.nextMinMax(minX, maxX);
		var rawY = rand.nextMinMax(minY, maxY);
		var rot = rand.nextMinMax(-1, 3) * 90;
		var rotated = RotationMath.rotatePoint(rawX, rawY, -rot);
		var velX = rand.nextMinMax(0, 2) == 1 ? 1 : -1;
		var display = PR2MovieClip.fromLinkage("EggGraphic", {maxNestedDepth: 8});
		display.x = rotated.x;
		display.y = rotated.y;
		display.rotation = rot;
		display.scaleX = velX > 0 ? 0.12 : -0.12;
		display.scaleY = 0.12;
		if (displayLayer != null) {
			displayLayer.addChild(display);
		}
		eggs.set(id, {id: id, x: rotated.x, y: rotated.y, rot: rot, velX: velX, display: display});
		commandHandler.defineCommand('removeEgg$id', function(_:Array<String>):Void {
			removeEgg(id);
		});
	}

	private function playDefaultCollectSound(x:Int, y:Int):Void {
		if (!Assets.exists(COLLECT_SOUND_PATH)) {
			return;
		}
		var offset = cameraOffset();
		SoundEffects.playGameSound(Assets.getSound(COLLECT_SOUND_PATH), x, y, offset.x, offset.y, 1.5);
	}
}

private class FlashRandom {
	private static inline var MBIG:Int = 0x7fffffff;
	private static inline var MSEED:Int = 0x9a4ec86;
	private var inext:Int = 0;
	private var inextp:Int = 0x15;
	private var seedArray:Array<Int> = [];

	public function new(seed:Int) {
		for (_ in 0...0x38) {
			seedArray.push(0);
		}
		var num2 = MSEED - Std.int(Math.abs(seed));
		seedArray[0x37] = num2;
		var num3 = 1;
		for (i in 1...0x37) {
			var index = (0x15 * i) % 0x37;
			seedArray[index] = num3;
			num3 = num2 - num3;
			if (num3 < 0) {
				num3 += MBIG;
			}
			num2 = seedArray[index];
		}
		for (_ in 1...5) {
			for (k in 1...0x38) {
				seedArray[k] -= seedArray[1 + ((k + 30) % 0x37)];
				if (seedArray[k] < 0) {
					seedArray[k] += MBIG;
				}
			}
		}
	}

	public function nextMinMax(minValue:Int, maxValue:Int):Int {
		if (minValue > maxValue) {
			throw 'Argument "minValue" must be less than or equal to "maxValue".';
		}
		var num:Float = maxValue - minValue;
		if (num <= MBIG) {
			return Std.int(sample() * num) + minValue;
		}
		return Std.int(getSampleForLargeRange() * num) + minValue;
	}

	private function sample():Float {
		return internalSample() * 4.6566128752457969E-10;
	}

	private function getSampleForLargeRange():Float {
		var num = internalSample();
		if ((internalSample() % 2) == 0) {
			num = -num;
		}
		return (num + 2147483646.0) / 4294967293.0;
	}

	private function internalSample():Int {
		var next = inext;
		var nextp = inextp;
		if (++next >= 0x38) {
			next = 1;
		}
		if (++nextp >= 0x38) {
			nextp = 1;
		}
		var num = seedArray[next] - seedArray[nextp];
		if (num < 0) {
			num += MBIG;
		}
		seedArray[next] = num;
		inext = next;
		inextp = nextp;
		return num;
	}
}
