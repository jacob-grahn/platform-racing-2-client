package pr2.gameplay;

import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevel;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.runtime.PR2MovieClip;
import pr2.gameplay.RotationMath.RotatedPoint;

typedef EggState = {
	final id:Int;
	var posX:Float;
	var posY:Float;
	var x:Int;
	var y:Int;
	final rot:Int;
	var velX:Float;
	var velY:Float;
	var grounded:Bool;
	var wallCooldown:Int;
	var attackCooldown:Int;
	var removing:Bool;
	var removeFrames:Int;
	final display:PR2MovieClip;
}

typedef EggAttackVisual = {
	var posX:Float;
	var posY:Float;
	var velX:Float;
	var velY:Float;
	var life:Int;
	var alphaJitter:Bool;
	var display:PR2MovieClip;
}

/**
	Ports the round state from `effects.Egg`: seeded id/position generation,
	PhysicsEffect movement, egg-mode gating in Course, collect emission, squash
	removal, per-egg remote removal commands, and the egg attack protocol/cooldown.
**/
class EggRound {
	public static inline var COLLECT_SOUND_PATH:String = "assets/audio/sfx/sound898.mp3";
	private static inline var SQUASH_REMOVE_FRAMES:Int = 27;
	private static inline var ATTACK_COOLDOWN_FRAMES:Int = 120;
	private static inline var MODE_ICE:Int = 0;
	private static inline var MODE_SLASH:Int = 1;
	private static inline var MODE_LASER:Int = 2;
	private static inline var MODE_RANDOM:Int = 3;

	private var rand:FlashRandom = new FlashRandom(1);
	private var nextId:Int = 1;
	private var mode:Int = 3;
	private final commandHandler:CommandHandler;
	private final onCollect:Int->Void;
	private final displayLayer:Null<Sprite>;
	private final cameraOffset:Void->Point;
	private final playCollectSound:Int->Int->Void;
	private var eggs:Map<Int, EggState> = new Map();
	private var attackVisuals:Array<EggAttackVisual> = [];

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

	public function step(level:ServerLevel, courseRotation:Int = 0, ?playerX:Float, ?playerY:Float, playerCrouching:Bool = false,
			playerRemoved:Bool = false):Void {
		stepAttackVisuals();
		for (id in ids()) {
			var egg = eggs.get(id);
			if (egg == null) {
				continue;
			}
			if (egg.removing) {
				stepRemovingEgg(id, egg);
				continue;
			}
			stepEgg(egg, level, courseRotation, playerX, playerY, playerCrouching, playerRemoved);
			if (playerX != null && playerY != null && isNearLocalPlayer(egg.x, egg.y, playerX, playerY, playerCrouching, playerRemoved)) {
				collectEgg(id);
			}
		}
	}

	public function collectEgg(id:Int):Bool {
		var egg = eggs.get(id);
		if (egg == null) {
			return false;
		}
		if (egg.removing) {
			return false;
		}
		playCollectSound(egg.x, egg.y);
		beginSquash(egg);
		onCollect(id);
		return true;
	}

	public function removeEgg(id:Int):Bool {
		return removeEggNow(id);
	}

	private function removeEggNow(id:Int):Bool {
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
		clearAttackVisuals();
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

	public function activeAttackVisualCount():Int {
		return attackVisuals.length;
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
		display.alpha = 0;
		if (displayLayer != null) {
			displayLayer.addChild(display);
		}
		eggs.set(id, {
			id: id,
			posX: rotated.x,
			posY: rotated.y,
			x: rotated.x,
			y: rotated.y,
			rot: rot,
			velX: velX,
			velY: 0,
			grounded: false,
			wallCooldown: 0,
			attackCooldown: 0,
			removing: false,
			removeFrames: 0,
			display: display
		});
		commandHandler.defineCommand('removeEgg$id', function(_:Array<String>):Void {
			removeEggNow(id);
		});
	}

	private function beginSquash(egg:EggState):Void {
		egg.removing = true;
		egg.removeFrames = SQUASH_REMOVE_FRAMES;
		egg.display.gotoAndPlay("squash");
	}

	private function stepRemovingEgg(id:Int, egg:EggState):Void {
		egg.removeFrames--;
		if (egg.removeFrames <= 0) {
			removeEggNow(id);
		}
	}

	private function stepEgg(egg:EggState, level:ServerLevel, courseRotation:Int, ?playerX:Float, ?playerY:Float, playerCrouching:Bool = false,
			playerRemoved:Bool = false):Void {
		egg.velY += 0.2;
		if (egg.velY > 8) {
			egg.velY = 8;
		}
		egg.posY += egg.velY;
		egg.posX += egg.velX;
		var displayRotation = RotationMath.normalizeDisplayRotation(courseRotation - egg.rot);
		var rotatedPos = RotationMath.rotatePoint(egg.posX, egg.posY, -displayRotation);
		if (egg.velX != 0) {
			var wallProbe = RotationMath.rotatePoint(egg.posX + egg.velX, egg.posY - 10, -displayRotation);
			var wallBlock = blockFromPos(level, wallProbe.x, wallProbe.y, courseRotation);
			if (isActiveBlock(wallBlock)) {
				var blockPos = rotatedBlockPos(wallBlock, egg.rot);
				if (egg.velX < 0) {
					egg.posX = blockPos.x + 31;
				} else {
					egg.posX = blockPos.x - 1;
				}
				if (egg.grounded) {
					if (egg.wallCooldown > 0) {
						egg.posY -= 30;
					}
					egg.wallCooldown = 2;
					egg.velX *= -1;
				}
			}
		}
		var groundBlock = blockFromPos(level, rotatedPos.x, rotatedPos.y, courseRotation);
		if (isActiveBlock(groundBlock)) {
			egg.grounded = true;
			var blockPos = rotatedBlockPos(groundBlock, egg.rot);
			if (egg.velY < 0) {
				egg.velY *= -0.5;
				egg.posY = blockPos.y + 31;
			} else {
				egg.velY = 0;
				egg.posY = blockPos.y;
			}
		} else {
			egg.grounded = false;
		}
		if (egg.wallCooldown > 0) {
			egg.wallCooldown--;
		}
		wrapPosition(egg, level);
		rotatedPos = RotationMath.rotatePoint(egg.posX, egg.posY, -displayRotation);
		egg.x = rotatedPos.x;
		egg.y = rotatedPos.y;
		egg.display.x = egg.x;
		egg.display.y = egg.y;
		egg.display.rotation = displayRotation;
		egg.display.scaleX = egg.velX > 0 ? 0.12 : -0.12;
		egg.display.scaleY = 0.12;
		if (egg.display.alpha < 1) {
			egg.display.alpha += 0.02;
		}
		stepAttack(egg, displayRotation, playerX, playerY, playerCrouching, playerRemoved);
	}

	private function stepAttack(egg:EggState, displayRotation:Int, ?playerX:Float, ?playerY:Float, playerCrouching:Bool = false,
			playerRemoved:Bool = false):Void {
		var probeX = egg.posX + (egg.velX * (Math.random() * 100)) + 50;
		var probe = RotationMath.rotatePoint(probeX, egg.posY, -displayRotation);
		var nearLocalPlayer = playerX != null && playerY != null
			&& isNearLocalPlayer(probe.x, probe.y, playerX, playerY, playerCrouching, playerRemoved);
		if (egg.attackCooldown <= 0 && nearLocalPlayer) {
			egg.attackCooldown = ATTACK_COOLDOWN_FRAMES;
			var angle = 0;
			var dir = "right";
			if (egg.display.scaleX < 0) {
				angle = 180;
				dir = "left";
			}
			var attackX = Std.int(egg.posX);
			var attackY = Std.int(egg.posY - 10);
			var payload = attackPayload(attackX, attackY, angle, dir, egg.rot);
			if (payload != "") {
				mountAttackVisual(payload);
				LobbySocket.write('add_effect`$payload');
			}
		} else {
			egg.attackCooldown--;
		}
	}

	private function attackPayload(x:Int, y:Int, angle:Int, dir:String, rot:Int):String {
		var randomMode = -1.0;
		if (mode == MODE_RANDOM) {
			randomMode = Math.random();
		}
		if (mode == MODE_ICE || randomMode > 0.66) {
			return 'IceWave`$x`$y`$angle`$rot`-1';
		}
		if (mode == MODE_SLASH || randomMode > 0.33) {
			return 'Slash`$x`$y`$dir`-1';
		}
		if (mode == MODE_LASER || randomMode > 0) {
			return 'Laser`$x`$y`$dir`$rot`-1';
		}
		return "";
	}

	public function mountAttackVisual(payload:String):Void {
		if (displayLayer == null) {
			return;
		}
		var parts = payload.split("`");
		var type = parts[0];
		var x = parsePartInt(parts, 1);
		var y = parsePartInt(parts, 2);
		switch (type) {
			case "Slash":
				var dir = parts.length > 3 ? parts[3] : "right";
				addAttackVisual("SlashAnimation", x, y, dir == "left" ? -1 : 1, 1, 0, 0, 6, false);
			case "Laser":
				var dir = parts.length > 3 ? parts[3] : "right";
				var angle = dir == "left" ? 180 : 0;
				var rot = parsePartInt(parts, 4);
				var laser = addAttackVisual("LaserShotGraphic", x, y, 1, 1, Math.cos(angle * Math.PI / 180) * 29,
					Math.sin(angle * Math.PI / 180) * 29, 100, false);
				laser.display.rotation = angle - rot;
			case "IceWave":
				var base = parsePartInt(parts, 3);
				var rot = parsePartInt(parts, 4);
				for (angle in [base, base + 30, base - 30]) {
					var shot = addAttackVisual("IceWaveGraphic", x, y, 1, 1, Math.cos(angle * Math.PI / 180) * 5,
						Math.sin(angle * Math.PI / 180) * 5, 75, true);
					shot.display.rotation = angle - rot;
				}
			default:
		}
	}

	private function addAttackVisual(linkage:String, x:Int, y:Int, scaleX:Float, scaleY:Float, velX:Float, velY:Float, life:Int,
			alphaJitter:Bool):EggAttackVisual {
		var display = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 8});
		display.x = x;
		display.y = y;
		display.scaleX = scaleX;
		display.scaleY = scaleY;
		displayLayer.addChild(display);
		var visual:EggAttackVisual = {
			posX: x + 0.0,
			posY: y + 0.0,
			velX: velX,
			velY: velY,
			life: life,
			alphaJitter: alphaJitter,
			display: display
		};
		attackVisuals.push(visual);
		return visual;
	}

	private function stepAttackVisuals():Void {
		var remaining:Array<EggAttackVisual> = [];
		for (visual in attackVisuals) {
			visual.posX += visual.velX;
			visual.posY += visual.velY;
			visual.display.x = visual.posX;
			visual.display.y = visual.posY;
			if (visual.alphaJitter) {
				visual.display.alpha = (Math.random() * visual.life / 100) + 0.25;
			}
			visual.life--;
			if (visual.life <= 0) {
				removeAttackVisual(visual);
			} else {
				remaining.push(visual);
			}
		}
		attackVisuals = remaining;
	}

	private function clearAttackVisuals():Void {
		for (visual in attackVisuals) {
			removeAttackVisual(visual);
		}
		attackVisuals.resize(0);
	}

	private static function removeAttackVisual(visual:EggAttackVisual):Void {
		visual.display.dispose();
		if (visual.display.parent != null) {
			visual.display.parent.removeChild(visual.display);
		}
	}

	private static function parsePartInt(parts:Array<String>, index:Int):Int {
		if (index >= parts.length) {
			return 0;
		}
		var value = Std.parseInt(parts[index]);
		return value == null ? 0 : value;
	}

	private static function wrapPosition(egg:EggState, level:ServerLevel):Void {
		var limits = movementLimits(level, egg.rot);
		if (egg.posX > limits.maxX) {
			egg.posX = limits.minX;
		}
		if (egg.posX < limits.minX) {
			egg.posX = limits.maxX;
		}
		if (egg.posY > limits.maxY) {
			egg.posY = limits.minY;
		}
		if (egg.posY < limits.minY) {
			egg.posY = limits.maxY;
		}
	}

	private static function blockFromPos(level:ServerLevel, posX:Int, posY:Int, rotation:Int):Null<DecodedBlock> {
		var probeX = posX;
		var probeY = posY;
		if (rotation != 0) {
			var pos = RotationMath.rotatePoint(posX, posY, rotation);
			probeX = pos.x;
			probeY = pos.y;
		}
		var tileX = Math.floor(probeX / 30);
		var tileY = Math.floor(probeY / 30);
		for (block in level.blocks) {
			if (Math.floor(block.x / 30) == tileX && Math.floor(block.y / 30) == tileY) {
				return block;
			}
		}
		return null;
	}

	private static function isActiveBlock(block:Null<DecodedBlock>):Bool {
		if (block == null) {
			return false;
		}
		return switch (block.code) {
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4
				| ObjectCodes.BLOCK_WATER | ObjectCodes.BLOCK_SAFETY:
				false;
			default:
				true;
		}
	}

	private static function rotatedBlockPos(block:DecodedBlock, rot:Int):RotatedPoint {
		var offsetX = 0;
		var offsetY = 0;
		if (rot == 90) {
			offsetY = 30;
		} else if (Math.abs(rot) == 180) {
			offsetX = 30;
			offsetY = 30;
		} else if (rot == -90) {
			offsetX = 30;
		}
		return RotationMath.rotatePoint(block.x + offsetX, block.y + offsetY, -rot);
	}

	private static function movementLimits(level:ServerLevel, rot:Int):{minX:Int, maxX:Int, minY:Int, maxY:Int} {
		var minX = level.minX - 300;
		var maxX = level.maxX + 300;
		var minY = level.minY - 300;
		var maxY = level.maxY + 300;
		var minPoint = RotationMath.rotatePoint(minX, minY, -rot);
		var maxPoint = RotationMath.rotatePoint(maxX, maxY, -rot);
		var resultMinX = minPoint.x;
		var resultMinY = minPoint.y;
		var resultMaxX = maxPoint.x;
		var resultMaxY = maxPoint.y;
		if (resultMaxX < resultMinX) {
			var tmp = resultMaxX;
			resultMaxX = resultMinX;
			resultMinX = tmp;
		}
		if (resultMaxY < resultMinY) {
			var tmp = resultMaxY;
			resultMaxY = resultMinY;
			resultMinY = tmp;
		}
		return {minX: resultMinX, maxX: resultMaxX, minY: resultMinY, maxY: resultMaxY};
	}

	private static function isNearLocalPlayer(px:Int, py:Int, playerX:Float, playerY:Float, playerCrouching:Bool, playerRemoved:Bool):Bool {
		if (playerRemoved) {
			return false;
		}
		return Math.abs(playerX - px) < 25
			&& playerY > py - 5
			&& ((!playerCrouching && playerY < py + 65) || (playerCrouching && playerY < py + 25));
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
