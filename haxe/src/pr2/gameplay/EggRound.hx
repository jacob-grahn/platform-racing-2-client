package pr2.gameplay;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.effects.LaserShotView;
import pr2.effects.NativeEffectAnimation;
import pr2.effects.PhysicsEffect;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevel;
import pr2.level.ObjectCodes;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.util.FlashRandom;
import pr2.util.DisplayUtil;
import pr2.runtime.SvgAsset;

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
	final display:EggView;
}

typedef EggAttackVisual = {
	var posX:Float;
	var posY:Float;
	var velX:Float;
	var velY:Float;
	var life:Int;
	var alphaJitter:Bool;
	var effectType:String;
	var shooterId:Int;
	var hitPlayer:Bool;
	var hitBlock:Bool;
	var angle:Float;
	var baseAngle:Float;
	var rot:Int;
	var display:Sprite;
}

/**
	Ports the round state from `effects.Egg`: seeded id/position generation,
	PhysicsEffect movement, egg-mode gating in Course, collect emission, squash
	removal, per-egg remote removal commands, and the egg attack protocol/cooldown.
**/
class EggRound {
	public static inline var COLLECT_SOUND_PATH:String = "assets/audio/sfx/egg_collect.mp3";
	public static inline var LASER_HIT_SOUND_PATH:String = "assets/audio/sfx/laser_hit.mp3";
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
	private final visualRandom:Void->Float;
	private final onIcePlayerHit:Int->Void;
	private final onIceBlockHit:DecodedBlock->Void;
	private final playLaserHitSound:Int->Int->Void;
	private var eggs:Map<Int, EggState> = new Map();
	private var attackVisuals:Array<EggAttackVisual> = [];

	public function new(commandHandler:CommandHandler, onCollect:Int->Void, ?displayLayer:Sprite, ?cameraOffset:Void->Point,
			?playCollectSound:Int->Int->Void, ?visualRandom:Void->Float, ?onIcePlayerHit:Int->Void, ?onIceBlockHit:DecodedBlock->Void,
			?playLaserHitSound:Int->Int->Void) {
		this.commandHandler = commandHandler;
		this.onCollect = onCollect;
		this.displayLayer = displayLayer;
		this.cameraOffset = cameraOffset != null ? cameraOffset : function():Point return new Point();
		this.playCollectSound = playCollectSound != null ? playCollectSound : playDefaultCollectSound;
		this.visualRandom = visualRandom != null ? visualRandom : Math.random;
		this.onIcePlayerHit = onIcePlayerHit != null ? onIcePlayerHit : function(_:Int):Void {};
		this.onIceBlockHit = onIceBlockHit != null ? onIceBlockHit : function(_:DecodedBlock):Void {};
		this.playLaserHitSound = playLaserHitSound != null ? playLaserHitSound : playDefaultLaserHitSound;
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

	public function addFixedEgg(x:Int, y:Int, rot:Int = 0):Int {
		var id = nextId++;
		var velX = rand.nextMinMax(0, 2) == 1 ? 1 : -1;
		createEgg(id, x, y, rot, velX);
		return id;
	}

	public function step(level:ServerLevel, courseRotation:Int = 0, ?playerX:Float, ?playerY:Float, playerCrouching:Bool = false,
			playerRemoved:Bool = false, wrapAroundLevel:Bool = true):Void {
		stepAttackVisuals(level, courseRotation, playerX, playerY, playerCrouching, playerRemoved);
		for (id in ids()) {
			var egg = eggs.get(id);
			if (egg == null) {
				continue;
			}
			if (egg.removing) {
				stepRemovingEgg(id, egg);
				continue;
			}
			stepEgg(egg, level, courseRotation, playerX, playerY, playerCrouching, playerRemoved, wrapAroundLevel);
			if (playerX != null && playerY != null
				&& BlockCollision.isNearLocalPlayer(egg.x, egg.y, playerX, playerY, playerCrouching, playerRemoved)) {
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
		createEgg(id, rotated.x, rotated.y, rot, velX);
	}

	private function createEgg(id:Int, x:Int, y:Int, rot:Int, velX:Float):Void {
		var display = new EggView();
		applyEggVisualRandomization(display, visualRandom);
		display.x = x;
		display.y = y;
		display.rotation = rot;
		display.scaleX = velX > 0 ? 0.12 : -0.12;
		display.scaleY = 0.12;
		display.alpha = 0;
		if (displayLayer != null) {
			displayLayer.addChild(display);
		}
		eggs.set(id, {
			id: id,
			posX: x,
			posY: y,
			x: x,
			y: y,
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

	private static function applyEggVisualRandomization(display:EggView, nextRandom:Void->Float):Void {
		display.applyRandomColors(nextRandom);
	}

	private function beginSquash(egg:EggState):Void {
		egg.removing = true;
		egg.removeFrames = SQUASH_REMOVE_FRAMES;
		egg.display.playSquash();
	}

	private function stepRemovingEgg(id:Int, egg:EggState):Void {
		egg.removeFrames--;
		if (egg.removeFrames <= 0) {
			removeEggNow(id);
		}
	}

	private function stepEgg(egg:EggState, level:ServerLevel, courseRotation:Int, ?playerX:Float, ?playerY:Float, playerCrouching:Bool = false,
			playerRemoved:Bool = false, wrapAroundLevel:Bool = true):Void {
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
			var wallBlock = BlockCollision.blockFromPos(level, wallProbe.x, wallProbe.y, courseRotation);
			if (BlockCollision.isActiveBlock(wallBlock)) {
				var blockPos = BlockCollision.rotatedBlockPos(wallBlock, egg.rot);
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
		var groundBlock = BlockCollision.blockFromPos(level, rotatedPos.x, rotatedPos.y, courseRotation);
		if (BlockCollision.isActiveBlock(groundBlock)) {
			egg.grounded = true;
			var blockPos = BlockCollision.rotatedBlockPos(groundBlock, egg.rot);
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
		if (wrapAroundLevel) {
			wrapPosition(egg, level);
		}
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
			&& BlockCollision.isNearLocalPlayer(probe.x, probe.y, playerX, playerY, playerCrouching, playerRemoved);
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
				var shooterId = parsePartInt(parts, 5);
				var laser = addAttackVisual("LaserShotGraphic", x, y, 1, 1, Math.cos(angle * Math.PI / 180) * 29,
					Math.sin(angle * Math.PI / 180) * 29, 100, false, "Laser", shooterId);
				laser.display.rotation = angle - rot;
			case "IceWave":
				var base = parsePartInt(parts, 3);
				var rot = parsePartInt(parts, 4);
				var shooterId = parsePartInt(parts, 5);
				for (angle in [base, base + 30, base - 30]) {
					addIceWaveVisual(x, y, angle, rot, shooterId, base, 75);
				}
			default:
		}
	}

	private function addAttackVisual(linkage:String, x:Int, y:Int, scaleX:Float, scaleY:Float, velX:Float, velY:Float, life:Int,
			alphaJitter:Bool, effectType:String = "", shooterId:Int = -1):EggAttackVisual {
		var display:Sprite = linkage == "SlashAnimation"
			? new NativeEffectAnimation("slash", 6)
			: linkage == "LaserShotGraphic"
				? new LaserShotView()
				: new Sprite();
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
			effectType: effectType,
			shooterId: shooterId,
			hitPlayer: false,
			hitBlock: false,
			angle: 0,
			baseAngle: 0,
			rot: 0,
			display: display
		};
		attackVisuals.push(visual);
		return visual;
	}

	private function stepAttackVisuals(level:ServerLevel, courseRotation:Int, ?playerX:Float, ?playerY:Float, playerCrouching:Bool,
			playerRemoved:Bool):Void {
		var remaining:Array<EggAttackVisual> = [];
		var spawned:Array<EggAttackVisual> = [];
		var activeIceCount = iceWaveCount(attackVisuals);
		for (visual in attackVisuals) {
			visual.posX += visual.velX;
			visual.posY += visual.velY;
			visual.display.x = visual.posX;
			visual.display.y = visual.posY;
			if (visual.alphaJitter) {
				visual.display.alpha = (Math.random() * visual.life / 100) + 0.25;
			}
			if (visual.effectType == "IceWave") {
				if (!visual.hitPlayer && playerX != null && playerY != null
					&& BlockCollision.isNearLocalPlayer(Std.int(visual.posX), Std.int(visual.posY), playerX, playerY, playerCrouching, playerRemoved)) {
					visual.hitPlayer = true;
					onIcePlayerHit(visual.shooterId);
				}
				var block = PhysicsEffect.blockFromPos(level, Std.int(visual.posX), Std.int(visual.posY), courseRotation);
				if (block != null && block.code != ObjectCodes.BLOCK_ICE) {
					onIceBlockHit(block);
					if (activeIceCount < 10 && visual.life > 10) {
						for (childAngle in iceBranchAngles(visual.angle, visual.baseAngle)) {
							spawned.push(createIceWaveVisual(visual.display.x, visual.display.y, childAngle, visual.rot,
								visual.shooterId, visual.baseAngle, Std.int(visual.life / 2)));
							activeIceCount++;
						}
						visual.life -= 5;
						skipIcePastSpawn(visual);
					}
				}
			} else if (visual.effectType == "Laser" && !visual.hitBlock) {
				var block = PhysicsEffect.blockFromPos(level, Std.int(visual.posX), Std.int(visual.posY), courseRotation);
				if (block != null && PhysicsEffect.isActiveBlock(block)) {
					visual.hitBlock = true;
					visual.velX = 0;
					visual.velY = 0;
					visual.life = 18;
					Std.downcast(visual.display, LaserShotView).playHit();
					playLaserHitSound(Std.int(visual.posX), Std.int(visual.posY));
				}
			}
			visual.life--;
			if (visual.life <= 0) {
				removeAttackVisual(visual);
			} else {
				remaining.push(visual);
			}
		}
		attackVisuals = remaining.concat(spawned);
	}

	private function addIceWaveVisual(x:Float, y:Float, angle:Float, rot:Int, shooterId:Int, baseAngle:Float, life:Int):EggAttackVisual {
		var visual = createIceWaveVisual(x, y, angle, rot, shooterId, baseAngle, life);
		attackVisuals.push(visual);
		return visual;
	}

	private function createIceWaveVisual(x:Float, y:Float, angle:Float, rot:Int, shooterId:Int, baseAngle:Float, life:Int):EggAttackVisual {
		var display = new Sprite();
		display.x = x;
		display.y = y;
		display.rotation = angle - rot;
		addIceWaveCore(display);
		if (displayLayer != null) displayLayer.addChild(display);
		var radians = angle * Math.PI / 180;
		var visual:EggAttackVisual = {
			posX: x,
			posY: y,
			velX: Math.cos(radians) * 5,
			velY: Math.sin(radians) * 5,
			life: life,
			alphaJitter: true,
			effectType: "IceWave",
			shooterId: shooterId,
			hitPlayer: false,
			hitBlock: false,
			angle: angle,
			baseAngle: baseAngle,
			rot: rot,
			display: display
		};
		skipIcePastSpawn(visual);
		return visual;
	}

	private static function skipIcePastSpawn(visual:EggAttackVisual):Void {
		visual.posX += Math.cos(visual.angle * Math.PI / 180) * 30;
		visual.posY += Math.sin(visual.angle * Math.PI / 180) * 30;
	}

	private static function iceWaveCount(visuals:Array<EggAttackVisual>):Int {
		var count = 0;
		for (visual in visuals) if (visual.effectType == "IceWave") count++;
		return count;
	}

	public static function iceBranchAngles(angle:Float, baseAngle:Float):Array<Float> {
		var minimum = baseAngle - 60;
		var maximum = baseAngle + 60;
		var angles:Array<Float> = [];
		for (candidate in [angle + 30, angle - 30]) {
			var limited = Math.max(minimum, Math.min(maximum, candidate));
			if (limited != angle) angles.push(limited);
		}
		return angles;
	}

	private static function addIceWaveCore(display:Sprite):Void {
		var core = SvgAsset.create("assets/svg/effects/ice_wave_01.svg");
		core.name = "iceWaveCore";
		display.addChild(core);
	}

	private function clearAttackVisuals():Void {
		for (visual in attackVisuals) {
			removeAttackVisual(visual);
		}
		attackVisuals.resize(0);
	}

	private static function removeAttackVisual(visual:EggAttackVisual):Void {
		var nativeEffect = Std.downcast(visual.display, NativeEffectAnimation);
		if (nativeEffect != null) nativeEffect.dispose();
		var laser = Std.downcast(visual.display, LaserShotView);
		if (laser != null) laser.dispose();
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
		var limits = BlockCollision.movementLimits(level, egg.rot);
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

	private function playDefaultCollectSound(x:Int, y:Int):Void {
		if (!Assets.exists(COLLECT_SOUND_PATH)) {
			return;
		}
		var offset = cameraOffset();
		SoundEffects.playGameSound(Assets.getSound(COLLECT_SOUND_PATH), x, y, offset.x, offset.y, 1.5);
	}

	private function playDefaultLaserHitSound(x:Int, y:Int):Void {
		if (!Assets.exists(LASER_HIT_SOUND_PATH)) {
			return;
		}
		var offset = cameraOffset();
		SoundEffects.playGameSound(Assets.getSound(LASER_HIT_SOUND_PATH), x, y, offset.x, offset.y, 1.5);
	}
}
