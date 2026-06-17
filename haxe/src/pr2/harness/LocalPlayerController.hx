package pr2.harness;

import pr2.character.CharacterState;
import pr2.level.FixtureLevel;
import pr2.level.FixtureLevel.LevelBlock;
import pr2.level.BlockType;

class LocalPlayerController {
	public static inline var STANDING_WIDTH:Float = 20;
	public static inline var STANDING_HEIGHT:Float = 55;
	public static inline var CROUCHING_HEIGHT:Float = 30;

	private static inline var BASE_ACCEL_FACTOR:Float = 0.35;
	private static inline var FRICTION:Float = 0.985;
	private static inline var HALF_WIDTH:Float = STANDING_WIDTH / 2;
	private static inline var MAX_SPEED:Float = 28;
	private static inline var DEFAULT_GRAVITY:Float = 0.7;
	private static inline var CRUMBLE_INITIAL_LIFE:Int = 10;
	private static inline var VANISH_FADE_FRAMES:Int = 10;
	private static inline var VANISH_REAPPEAR_FRAMES:Int = 54;
	private static inline var MINE_HIT_SPEED:Float = 50;
	private static inline var TELEPORT_DEFAULT_COLOR:String = "16744272";
	private static inline var TELEPORT_RESET_FRAMES:Int = 81;
	private static inline var MOVE_PREVIEW_FRAMES:Int = 27;
	private static inline var MOVE_RESELECT_FRAMES:Int = 135;

	public var x(default, null):Float;
	public var y(default, null):Float;
	public var vx(default, null):Float = 0;
	public var vy(default, null):Float = 0;
	public var grounded(default, null):Bool = false;
	public var crouching(default, null):Bool = false;
	public var touchedBlock(default, null):Null<LevelBlock> = null;
	public var mode(default, null):String = MODE_LAND;
	public var itemId(default, null):Null<Int> = null;

	public static inline var MODE_LAND:String = "land";
	public static inline var MODE_WATER:String = "water";
	public static inline var MODE_FREEZE:String = "freeze";

	private final level:FixtureLevel;
	private var accel:Float;
	private var maxVelX:Float;
	private var jumpVelocity:Float;
	private final gravity:Float;
	private final startingSpeedStat:Float;
	private final startingAccelerationStat:Float;
	private final startingJumpStat:Float;
	private var speedStat:Float;
	private var accelerationStat:Float;
	private var jumpStat:Float;
	private var targetVelX:Float = 0;
	private var accelFactor:Float = BASE_ACCEL_FACTOR;
	private var jumpHeld:Bool = false;
	private var jumpVelBoost:Float = 0;
	private var crouchCharge:Float = 0;
	private var waterTicks:Float = 0;
	private final crumbleLife:Map<String, Int> = new Map();
	private final removedBlocks:Map<String, Bool> = new Map();
	private final vanishFadeFrames:Map<String, Int> = new Map();
	private final vanishReappearFrames:Map<String, Int> = new Map();
	private final disabledTeleportFrames:Map<String, Int> = new Map();
	private final depletedItemBlocks:Map<String, Bool> = new Map();
	private final moveBlockDirections:Map<String, Int> = new Map();
	private var moveBlockTimer:Int = MOVE_PREVIEW_FRAMES;
	private var moveBlockPhase:String = "shift";
	private var moveRandomSeed:Int = 1;
	private var lastSafeX:Float;
	private var lastSafeY:Float;
	private var standingTileX:Int;
	private var standingTileY:Int;

	public function new(level:FixtureLevel) {
		this.level = level;
		startingSpeedStat = clamp(level.stats.speed, 0, 100);
		startingAccelerationStat = clamp((level.stats.acceleration - 0.2) * 60, 0, 100);
		startingJumpStat = clamp((level.stats.jump - 2) * 40, 0, 100);
		applyStats(startingSpeedStat, startingAccelerationStat, startingJumpStat);
		gravity = DEFAULT_GRAVITY * (level.gravity / 27);
		x = level.playerStart.x * level.tileSize + level.tileSize / 2;
		y = (level.playerStart.y + 1) * level.tileSize;
		lastSafeX = x;
		lastSafeY = y;
		standingTileX = level.playerStart.x;
		standingTileY = level.playerStart.y + 1;
		determineMoveBlockDirections();
		processBlocks(new LocalPlayerInput());
	}

	public function step(input:LocalPlayerInput):Void {
		touchedBlock = null;
		if (mode == MODE_FREEZE) {
			// Freeze mode parks the local character while course rotation runs.
		} else if (mode == MODE_WATER) {
			waterStep(input);
		} else {
			landStep(input);
		}
		updateTimedBlocks();
	}

	private function landStep(input:LocalPlayerInput):Void {
		if (input.right) {
			targetVelX += accel;
		}
		if (input.left) {
			targetVelX -= accel;
		}
		if (!input.right && !input.left) {
			targetVelX = 0;
		}

		if (input.jump) {
			if (grounded && !crouching) {
				jumpHeld = true;
				vy -= jumpVelocity;
				jumpVelBoost = -jumpVelocity;
			} else if (jumpHeld) {
				vy += jumpVelBoost;
				jumpVelBoost *= 0.75;
			}
		} else {
			jumpHeld = false;
		}

		if (input.down) {
			if (!crouching) {
				if (!grounded) {
					vy += 0.5;
					crouchCharge = 0;
				} else {
					if (crouchCharge < 100) {
						crouchCharge += 2;
					}
					if (crouchCharge > 25) {
						targetVelX = 0;
					}
				}
			}
		} else {
			if (crouchCharge > 25) {
				vy = -crouchCharge * 0.24;
				jumpHeld = false;
			}
			crouchCharge = 0;
		}

		position();
		processBlocks(input);
	}

	// Ports LocalCharacter.waterGo: directional paddling, heavy damping, a brief
	// linger (waterTicks) after leaving the water, and an upward boost on exit.
	private function waterStep(input:LocalPlayerInput):Void {
		if (input.right) {
			vx += accel * 0.5;
		}
		if (input.left) {
			vx -= accel * 0.5;
		}
		if (input.down) {
			vy += accel * 0.65;
		}
		if (input.jump) {
			vy -= accel * 0.65;
		}
		vy += DEFAULT_GRAVITY * 0.25;
		vx *= 0.92;
		vy *= 0.92;
		vx = clamp(vx, -MAX_SPEED, MAX_SPEED);
		vy = clamp(vy, -MAX_SPEED, MAX_SPEED);
		x += vx;
		y += vy;
		processBlocks(input);
		waterTicks--;
		if (waterTicks <= 0) {
			if (input.jump) {
				vy -= jumpVelocity * 0.5;
				jumpVelBoost = -jumpVelocity * 0.5;
				jumpHeld = true;
			}
			setMode(MODE_LAND);
		}
	}

	private function setMode(newMode:String):Void {
		if (mode != newMode) {
			mode = newMode;
			targetVelX = 0;
		}
	}

	public function debugState():LocalPlayerDebugState {
		return new LocalPlayerDebugState(x, y, vx, vy, grounded, crouching, characterState(), touchedBlock == null ? null : touchedBlock.type, mode, itemId, speedStat, accelerationStat, jumpStat);
	}

	private function position():Void {
		vy += gravity;
		targetVelX *= FRICTION;
		if (crouching) {
			targetVelX *= 0.7;
		}
		targetVelX = clamp(targetVelX, -maxVelX, maxVelX);

		var velocityRatio = 1 - Math.abs(vx) / MAX_SPEED;
		velocityRatio = velocityRatio * 0.9 + 0.1;
		var effectiveAccelFactor = accelFactor * velocityRatio;
		vx += (targetVelX - vx) * effectiveAccelFactor;
		vx = clamp(vx, -MAX_SPEED, MAX_SPEED);
		vy = clamp(vy, -MAX_SPEED, MAX_SPEED);
		x += vx;
		y += vy;
		accelFactor = BASE_ACCEL_FACTOR;
	}

	private function processBlocks(input:LocalPlayerInput):Void {
		var refs = refreshBlockRefs();
		updateGrounded(refs);

		if (vx >= -1 && refs.wallRight != null && getBlockAtTile(refs.wallRight.x - 1, refs.wallRight.y) == null) {
			onLeftHit(refs.wallRight);
			refs = refreshBlockRefs();
		}
		if (vx <= 1 && refs.wallLeft != null && getBlockAtTile(refs.wallLeft.x + 1, refs.wallLeft.y) == null) {
			onRightHit(refs.wallLeft);
			refs = refreshBlockRefs();
		}

		if (vy < 0) {
			if (grounded) {
				crouching = true;
			}
			var bumpBlock = mode == MODE_WATER ? null : blockWithOpenSpaceBelow(refs.ceiling);
			if (bumpBlock == null && mode != MODE_WATER) {
				bumpBlock = blockWithOpenSpaceBelow(refs.headBlock);
			}
			if (bumpBlock == null) {
				bumpBlock = blockWithOpenSpaceBelow(refs.topBlock);
			}
			if (bumpBlock != null) {
				onBump(bumpBlock, input);
				refs = refreshBlockRefs();
			}
		}

		if (!grounded) {
			updateGrounded(refs);
		}

		crouching = false;
		if (grounded) {
			var topBlock = getBlockAtPixel(x, y - 40);
			var bodyBlock = getBlockAtPixel(x, y - 10);
			if (topBlock != null && bodyBlock == null) {
				crouching = true;
				if (input.jump) {
					var yPriorToBump = y;
					onBump(topBlock, input);
					if (topBlock.type != BlockType.Teleport) {
						y = yPriorToBump;
					}
					vy = 0;
				}
				if (vy < 0) {
					vy = 0;
				}
			}
		}
		if (input.down && grounded) {
			crouching = true;
		}

		touchAt(x, y - 15);
		if (!crouching) {
			touchAt(x, y - 45);
		}
	}

	// Mirrors Block.onTouch dispatch: unlike the solid-collision lookups, this
	// sees non-solid blocks (water/safety) so their touch effects can fire.
	private function touchAt(pixelX:Float, pixelY:Float):Void {
		var block = level.blockAt(tileIndex(pixelX), tileIndex(pixelY));
		if (block == null || isBlockRemoved(block)) {
			return;
		}
		touch(block);
		switch (block.type) {
			case BlockType.Mine:
				hitMine(block);
			case BlockType.Water:
				if (!grounded) {
					setMode(MODE_WATER);
					waterTicks = 2;
				} else {
					targetVelX *= 0.9;
					accelFactor = 0.1;
				}
				updateSafeSpot(block, true);
			case BlockType.Safety:
				if (standingTileX != block.x || standingTileY < block.y || standingTileY > block.y + 2) {
					returnToLastSafeSpot();
				}
			default:
		}
	}

	private function refreshBlockRefs():BlockRefs {
		if (y < 0) {
			y += 0.001;
		}
		return {
			floorLeft: getBlockAtPixel(x - HALF_WIDTH, y),
			floorCenter: getBlockAtPixel(x, y),
			floorRight: getBlockAtPixel(x + HALF_WIDTH, y),
			wallLeft: getBlockAtPixel(x - HALF_WIDTH, y - 10),
			midBlock: getBlockAtPixel(x, y - 10),
			wallRight: getBlockAtPixel(x + HALF_WIDTH, y - 10),
			ceilLeft: getBlockAtPixel(x - HALF_WIDTH, y - 30),
			ceiling: getBlockAtPixel(x, y - 30),
			ceilRight: getBlockAtPixel(x + HALF_WIDTH, y - 30),
			headBlock: getBlockAtPixel(x, y - STANDING_HEIGHT + 30),
			topBlock: getBlockAtPixel(x, y - STANDING_HEIGHT)
		};
	}

	private function updateGrounded(refs:BlockRefs):Void {
		if (refs.floorCenter != null && refs.ceiling == null) {
			onStand(refs.floorCenter);
		} else {
			grounded = false;
		}
	}

	private function onStand(block:LevelBlock):Void {
		touch(block);
		var standForce = Math.round(vy * 2);
		y = block.y * level.tileSize;
		vy = 0;
		grounded = true;
		if (isSafeStandBlock(block)) {
			updateSafeSpot(block, false);
		}
		applyStandEffect(block, standForce);
	}

	private function onBump(block:LevelBlock, input:LocalPlayerInput):Void {
		touch(block);
		var bumpForce = Math.round(-vy);
		y = (block.y + 1) * level.tileSize + (crouching ? STANDING_HEIGHT / 2 : STANDING_HEIGHT);
		vy *= -0.25;
		jumpVelBoost = 0;
		applyBumpEffect(block, input, bumpForce);
	}

	private function onLeftHit(block:LevelBlock):Void {
		touch(block);
		var sideForce = Math.round(Math.abs(vx) * 1.75);
		x = block.x * level.tileSize - HALF_WIDTH;
		if (vx > 0) {
			vx *= -0.05;
		}
		if (targetVelX > 0) {
			targetVelX = 0;
		}
		applySideHitEffect(block, sideForce);
	}

	private function onRightHit(block:LevelBlock):Void {
		touch(block);
		var sideForce = Math.round(Math.abs(vx) * 1.75);
		x = (block.x + 1) * level.tileSize + HALF_WIDTH;
		if (vx < 0) {
			vx *= -0.05;
		}
		if (targetVelX < 0) {
			targetVelX = 0;
		}
		applySideHitEffect(block, sideForce);
	}

	private function applyStandEffect(block:LevelBlock, force:Int):Void {
		switch (block.type) {
			case BlockType.Crumble:
				applyCrumbleForce(block, force);
			case BlockType.Vanish:
				activateVanish(block);
			case BlockType.Mine:
				hitMine(block);
			case BlockType.Teleport:
				maybeTeleport(block);
			case BlockType.Push:
				pushBlock(block, 0, 1);
			case BlockType.Ice:
				accelFactor = 0.05;
			case BlockType.ArrowUp:
				if (!crouching) {
					vy -= 10;
				} else {
					pushArrow(block.type);
				}
			case BlockType.ArrowDown | BlockType.ArrowLeft | BlockType.ArrowRight:
				pushArrow(block.type);
			default:
		}
	}

	private function applyBumpEffect(block:LevelBlock, input:LocalPlayerInput, force:Int):Void {
		switch (block.type) {
			case BlockType.Crumble:
				applyCrumbleForce(block, force);
			case BlockType.Vanish:
				activateVanish(block);
			case BlockType.Mine:
				hitMine(block);
			case BlockType.Item | BlockType.InfiniteItem:
				useItemBlock(block);
			case BlockType.CustomStats:
				useCustomStatsBlock(block);
			case BlockType.Teleport:
				maybeTeleport(block);
			case BlockType.Push:
				pushBlock(block, 0, -1);
			case BlockType.RotateRight | BlockType.RotateLeft:
				startRotate(block);
			case BlockType.ArrowUp:
				vy = !input.down && !crouching ? -14 : 0;
			case BlockType.ArrowDown | BlockType.ArrowLeft | BlockType.ArrowRight:
				pushArrow(block.type);
			default:
		}
	}

	private function applySideHitEffect(block:LevelBlock, force:Int):Void {
		switch (block.type) {
			case BlockType.Crumble:
				applyCrumbleForce(block, force);
			case BlockType.Vanish:
				activateVanish(block);
			case BlockType.Mine:
				hitMine(block);
			case BlockType.Teleport:
				maybeTeleport(block);
			case BlockType.Push:
				pushBlock(block, vx >= 0 ? 1 : -1, 0);
			case BlockType.ArrowDown | BlockType.ArrowUp | BlockType.ArrowLeft | BlockType.ArrowRight:
				pushArrow(block.type);
			default:
		}
	}

	private function pushArrow(type:BlockType):Void {
		switch (type) {
			case BlockType.ArrowUp:
				if (!crouching) {
					vy -= 1.2;
				}
			case BlockType.ArrowDown:
				vy += 5;
			case BlockType.ArrowLeft:
				vx -= 3;
			case BlockType.ArrowRight:
				vx += 3;
			default:
		}
	}

	private function isSafeStandBlock(block:LevelBlock):Bool {
		return switch (block.type) {
			case BlockType.Crumble | BlockType.Vanish | BlockType.Mine | BlockType.Move | BlockType.Teleport | BlockType.Push | BlockType.Water | BlockType.Safety: false;
			default: true;
		}
	}

	private function updateSafeSpot(block:LevelBlock, centerY:Bool):Void {
		lastSafeX = block.x * level.tileSize + level.tileSize / 2;
		lastSafeY = (block.y + (centerY ? 0.5 : 0)) * level.tileSize;
		standingTileX = block.x;
		standingTileY = block.y;
	}

	private function returnToLastSafeSpot():Void {
		x = lastSafeX;
		y = lastSafeY;
		vx = 0;
		vy = 0;
		targetVelX = 0;
		jumpVelBoost = 0;
		jumpHeld = false;
		setMode(MODE_LAND);
		grounded = true;
	}

	private function startRotate(block:LevelBlock):Void {
		setMode(MODE_FREEZE);
		vx = 0;
		vy = 0;
		targetVelX = 0;
	}

	private function pushBlock(block:LevelBlock, dx:Int, dy:Int):Void {
		if (dx == 0 && dy == 0) {
			return;
		}

		var destX = block.x + dx;
		var destY = block.y + dy;
		if (!canMoveBlockTo(destX, destY)) {
			return;
		}

		block.x = destX;
		block.y = destY;
	}

	private function canMoveBlockTo(tileX:Int, tileY:Int):Bool {
		if (tileX < 0 || tileY < 0 || tileX >= level.widthTiles || tileY >= level.heightTiles) {
			return false;
		}
		if (level.blockAt(tileX, tileY) != null) {
			return false;
		}
		return !playerOccupiesTile(tileX, tileY);
	}

	private function hitMine(block:LevelBlock):Void {
		if (isBlockRemoved(block)) {
			return;
		}

		var mineCenterX = block.x * level.tileSize + level.tileSize / 2;
		var mineCenterY = block.y * level.tileSize + level.tileSize / 2;
		var charHeight = crouching ? CROUCHING_HEIGHT : STANDING_HEIGHT;
		var angle = Math.atan2((y - charHeight / 2) - mineCenterY, x - mineCenterX);
		vx += Math.cos(angle) * MINE_HIT_SPEED;
		vy += Math.sin(angle) * MINE_HIT_SPEED;
		removedBlocks.set(blockKey(block.x, block.y), true);
	}

	private function useItemBlock(block:LevelBlock):Void {
		if (block.type == BlockType.Item) {
			var key = blockKey(block.x, block.y);
			if (depletedItemBlocks.exists(key)) {
				return;
			}
			depletedItemBlocks.set(key, true);
		}

		var nextItem = itemFromBlockOptions(block.options);
		if (nextItem != null) {
			itemId = nextItem;
		}
	}

	private function itemFromBlockOptions(options:String):Null<Int> {
		if (options == "" || options == "none") {
			return null;
		}
		var ids = options.split("-");
		for (id in ids) {
			var parsed = Std.parseInt(id);
			if (parsed != null && parsed > 0) {
				return parsed;
			}
		}
		return null;
	}

	private function useCustomStatsBlock(block:LevelBlock):Void {
		var key = blockKey(block.x, block.y);
		if (depletedItemBlocks.exists(key)) {
			return;
		}
		depletedItemBlocks.set(key, true);

		if (block.options == "reset") {
			applyStats(startingSpeedStat, startingAccelerationStat, startingJumpStat);
			return;
		}

		var stats = parseCustomStats(block.options);
		applyStats(stats.speed, stats.acceleration, stats.jump);
	}

	private function parseCustomStats(options:String):PlayerStats {
		if (options == "") {
			return new PlayerStats(50, 50, 50);
		}
		var values = options.split("-");
		return new PlayerStats(
			customStatAt(values, 0, 50),
			customStatAt(values, 1, 50),
			customStatAt(values, 2, 50)
		);
	}

	private function customStatAt(values:Array<String>, index:Int, fallback:Float):Float {
		if (index >= values.length) {
			return fallback;
		}
		var parsed = Std.parseInt(values[index]);
		return parsed == null ? fallback : clamp(parsed, 0, 100);
	}

	private function applyStats(speed:Float, acceleration:Float, jump:Float):Void {
		speedStat = clamp(speed, 0, 100);
		accelerationStat = clamp(acceleration, 0, 100);
		jumpStat = clamp(jump, 0, 100);
		maxVelX = 2 + speedStat / 10;
		accel = 0.2 + accelerationStat / 60;
		jumpVelocity = 2 + jumpStat / 40;
	}

	private function maybeTeleport(block:LevelBlock):Void {
		var color = teleportColor(block);
		if (disabledTeleportFrames.exists(color)) {
			return;
		}

		var blocks = teleportBlocksOfColor(color);
		if (blocks.length == 0) {
			return;
		}

		disabledTeleportFrames.set(color, TELEPORT_RESET_FRAMES);
		var index = blocks.indexOf(block);
		if (index < 0) {
			index = 0;
		}
		var dest = blocks[(index + 1) % blocks.length];
		x += (dest.x - block.x) * level.tileSize;
		y += (dest.y - block.y) * level.tileSize;
	}

	private function teleportBlocksOfColor(color:String):Array<LevelBlock> {
		return level.blocks.filter(function(candidate) {
			return candidate.type == BlockType.Teleport && teleportColor(candidate) == color;
		});
	}

	private function teleportColor(block:LevelBlock):String {
		return block.options == "" ? TELEPORT_DEFAULT_COLOR : block.options;
	}

	private function blockWithOpenSpaceBelow(block:Null<LevelBlock>):Null<LevelBlock> {
		if (block == null) {
			return null;
		}
		return getBlockAtTile(block.x, block.y + 1) == null ? block : null;
	}

	private function applyCrumbleForce(block:LevelBlock, force:Int):Void {
		var damage = Std.int(Math.floor(force / 4));
		if (damage <= 0) {
			return;
		}

		var key = blockKey(block.x, block.y);
		var life = crumbleLife.exists(key) ? crumbleLife.get(key) : CRUMBLE_INITIAL_LIFE;
		life -= damage;
		crumbleLife.set(key, life);
		if (life <= 0) {
			removedBlocks.set(key, true);
		}
	}

	private function activateVanish(block:LevelBlock):Void {
		var key = blockKey(block.x, block.y);
		if (!vanishReappearFrames.exists(key) && !vanishFadeFrames.exists(key)) {
			vanishFadeFrames.set(key, VANISH_FADE_FRAMES);
		}
	}

	private function updateTimedBlocks():Void {
		updateVanishBlocks();
		updateTeleportBlocks();
		updateMoveBlocks();
	}

	private function updateMoveBlocks():Void {
		if (moveBlockDirections.keys().hasNext() == false) {
			return;
		}

		moveBlockTimer--;
		if (moveBlockTimer > 0) {
			return;
		}

		if (moveBlockPhase == "shift") {
			shiftMoveBlocks();
			moveBlockPhase = "reselect";
			moveBlockTimer = MOVE_RESELECT_FRAMES;
		} else {
			determineMoveBlockDirections();
			moveBlockPhase = "shift";
			moveBlockTimer = MOVE_PREVIEW_FRAMES;
		}
	}

	private function determineMoveBlockDirections():Void {
		moveBlockDirections.clear();
		for (block in level.blocks) {
			if (block.type == BlockType.Move) {
				moveBlockDirections.set(blockKey(block.x, block.y), moveBlockDirection(block));
			}
		}
	}

	private function shiftMoveBlocks():Void {
		var moveBlocks = level.blocks.filter(function(block) return block.type == BlockType.Move);
		for (block in moveBlocks) {
			var direction = moveBlockDirections.get(blockKey(block.x, block.y));
			if (direction == null) {
				continue;
			}
			switch (direction) {
				case 0:
					pushBlock(block, 0, 1);
				case 1:
					pushBlock(block, 0, -1);
				case 2:
					pushBlock(block, 1, 0);
				case 3:
					pushBlock(block, -1, 0);
				default:
			}
		}
	}

	private function moveBlockDirection(block:LevelBlock):Int {
		return switch (block.options) {
			case "down": 0;
			case "up": 1;
			case "right": 2;
			case "left": 3;
			default: nextMoveRandom(4);
		}
	}

	private function nextMoveRandom(maxValue:Int):Int {
		moveRandomSeed = (moveRandomSeed * 1103515245 + 12345) & 0x7fffffff;
		return moveRandomSeed % maxValue;
	}

	private function updateVanishBlocks():Void {
		var fading:Array<String> = [for (key in vanishFadeFrames.keys()) key];
		for (key in fading) {
			var frames = vanishFadeFrames.get(key) - 1;
			if (frames <= 0) {
				vanishFadeFrames.remove(key);
				removedBlocks.set(key, true);
				vanishReappearFrames.set(key, VANISH_REAPPEAR_FRAMES);
			} else {
				vanishFadeFrames.set(key, frames);
			}
		}

		var reappearing:Array<String> = [for (key in vanishReappearFrames.keys()) key];
		for (key in reappearing) {
			var frames = vanishReappearFrames.get(key) - 1;
			if (frames > 0) {
				vanishReappearFrames.set(key, frames);
			} else if (!playerOccupiesBlock(key)) {
				vanishReappearFrames.remove(key);
				removedBlocks.remove(key);
			} else {
				vanishReappearFrames.set(key, VANISH_REAPPEAR_FRAMES);
			}
		}
	}

	private function updateTeleportBlocks():Void {
		var colors:Array<String> = [for (color in disabledTeleportFrames.keys()) color];
		for (color in colors) {
			var frames = disabledTeleportFrames.get(color) - 1;
			if (frames <= 0) {
				disabledTeleportFrames.remove(color);
			} else {
				disabledTeleportFrames.set(color, frames);
			}
		}
	}

	private function playerOccupiesBlock(key:String):Bool {
		var parts = key.split(",");
		if (parts.length != 2) {
			return false;
		}
		var tileX = Std.parseInt(parts[0]);
		var tileY = Std.parseInt(parts[1]);
		return tileX != null && tileY != null && playerOccupiesTile(tileX, tileY);
	}

	private function playerOccupiesTile(targetTileX:Int, targetTileY:Int):Bool {
		var left = tileIndex(x - HALF_WIDTH);
		var right = tileIndex(x + HALF_WIDTH);
		var top = tileIndex(y - (crouching ? CROUCHING_HEIGHT : STANDING_HEIGHT));
		var bottom = tileIndex(y);
		for (tileX in left...right + 1) {
			for (tileY in top...bottom + 1) {
				if (tileX == targetTileX && tileY == targetTileY) {
					return true;
				}
			}
		}
		return false;
	}

	private function touch(block:Null<LevelBlock>):Void {
		if (block != null) {
			touchedBlock = block;
		}
	}

	private function characterState():CharacterState {
		return CharacterState.fromMotion(mode, grounded, crouching, crouchCharge, vx, vy);
	}

	private function getBlockAtPixel(pixelX:Float, pixelY:Float):Null<LevelBlock> {
		return getBlockAtTile(tileIndex(pixelX), tileIndex(pixelY));
	}

	private function getBlockAtTile(tileX:Int, tileY:Int):Null<LevelBlock> {
		var block = level.blockAt(tileX, tileY);
		if (block == null || isBlockRemoved(block) || !block.type.isSolid()) {
			return null;
		}
		return block;
	}

	private function isBlockRemoved(block:LevelBlock):Bool {
		return removedBlocks.exists(blockKey(block.x, block.y));
	}

	private function blockKey(tileX:Int, tileY:Int):String {
		return tileX + "," + tileY;
	}

	private function tileIndex(value:Float):Int {
		return Std.int(Math.floor(value / level.tileSize));
	}

	private static function clamp(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}
}

private typedef BlockRefs = {
	final floorLeft:Null<LevelBlock>;
	final floorCenter:Null<LevelBlock>;
	final floorRight:Null<LevelBlock>;
	final wallLeft:Null<LevelBlock>;
	final midBlock:Null<LevelBlock>;
	final wallRight:Null<LevelBlock>;
	final ceilLeft:Null<LevelBlock>;
	final ceiling:Null<LevelBlock>;
	final ceilRight:Null<LevelBlock>;
	final headBlock:Null<LevelBlock>;
	final topBlock:Null<LevelBlock>;
}

private class PlayerStats {
	public final speed:Float;
	public final acceleration:Float;
	public final jump:Float;

	public function new(speed:Float, acceleration:Float, jump:Float) {
		this.speed = speed;
		this.acceleration = acceleration;
		this.jump = jump;
	}
}
