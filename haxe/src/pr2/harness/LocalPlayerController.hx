package pr2.harness;

import pr2.character.CharacterState;
import pr2.level.FixtureLevel;
import pr2.level.FixtureLevel.LevelBlock;
import pr2.level.BlockType;
import pr2.gameplay.RotationMath;
import pr2.harness.BlockVisualEvent.BlockVisualEventKind;

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
	private static inline var ROTATE_FRAMES:Int = 30;
	private static inline var HURT_FRAMES:Int = 60;
	private static inline var FROZEN_SOLID_FRAMES:Int = 54;
	private static inline var ITEM_LASER_GUN:Int = 1;
	private static inline var ITEM_MINE:Int = 2;
	private static inline var ITEM_LIGHTNING:Int = 3;
	private static inline var ITEM_TELEPORT:Int = 4;
	private static inline var ITEM_SUPER_JUMP:Int = 5;
	private static inline var ITEM_JET_PACK:Int = 6;
	private static inline var ITEM_SPEED_BURST:Int = 7;
	private static inline var ITEM_SWORD:Int = 8;
	private static inline var ITEM_ICE_WAVE:Int = 9;
	private static inline var TELEPORT_ITEM_DISTANCE:Float = 120;
	private static inline var SPEED_BURST_FRAMES:Int = 135;
	private static inline var FRAME_RATE:Int = 27;
	private static inline var JET_PACK_TOTAL_FUEL:Int = 200;
	private static inline var FAST_ITEM_RELOAD_FRAMES:Int = 22;
	private static inline var ICE_WAVE_RELOAD_FRAMES:Int = 27;

	public var x(default, null):Float;
	public var y(default, null):Float;
	public var vx(default, null):Float = 0;
	public var vy(default, null):Float = 0;
	public var grounded(default, null):Bool = false;
	public var crouching(default, null):Bool = false;
	public var touchedBlock(default, null):Null<LevelBlock> = null;
	public var mode(default, null):String = MODE_LAND;
	public var itemId(default, null):Null<Int> = null;
	public var itemUses(default, null):Null<Int> = null;
	public var lastItemEffect(default, null):Null<String> = null;
	public var courseRotation(default, null):Int = 0;
	public var courseTweenRotation(default, null):Int = 0;
	public var characterRotation(default, null):Int = 0;
	public var finished(default, null):Bool = false;
	public var finishBlockId(default, null):Null<Int> = null;
	public var finishX(default, null):Null<Int> = null;
	public var finishY(default, null):Null<Int> = null;
	public var lives(default, null):Int = 3;
	public var courseTime(default, null):Int = 120;
	public var gameMode(default, null):String = "race";
	public var propellerHatActive:Bool = false;
	public var cowboyHatActive:Bool = false;
	public var santaHatActive:Bool = false;
	public var partyHatActive:Bool = false;
	public var jellyfishHatActive:Bool = false;
	public var topHatActive:Bool = false;
	public var crownHatActive:Bool = false;

	public static inline var MODE_LAND:String = "land";
	public static inline var MODE_WATER:String = "water";
	public static inline var MODE_FREEZE:String = "freeze";
	public static inline var MODE_FROZEN_SOLID:String = "frozenSolid";
	public static inline var MODE_HURT:String = "hurt";

	private final level:FixtureLevel;
	private var accel:Float;
	private var maxVelX:Float;
	private var jumpVelocity:Float;
	private var gravity:Float;
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
	private final blockVisualEvents:Array<BlockVisualEvent> = [];
	private final vanishFadeFrames:Map<String, Int> = new Map();
	private final vanishReappearFrames:Map<String, Int> = new Map();
	private final vanishFadeInFrames:Map<String, Int> = new Map();
	private final disabledTeleportFrames:Map<String, Int> = new Map();
	private final depletedItemBlocks:Map<String, Bool> = new Map();
	private final depletedSupplyBlocks:Map<String, Bool> = new Map();
	private final moveBlockDirections:Map<String, Int> = new Map();
	private var moveBlockTimer:Int = MOVE_PREVIEW_FRAMES;
	private var moveBlockPhase:String = "shift";
	private var moveRandomSeed:Int = 1;
	public var lastSafeX(default, null):Float;
	public var lastSafeY(default, null):Float;
	private var standingTileX:Int;
	private var standingTileY:Int;
	private var rotateFramesRemaining:Int = 0;
	private var rotateDirection:Int = 0;
	private var hurtFramesRemaining:Int = 0;
	private var frozenSolidFramesRemaining:Int = 0;
	private var facingDirection:Int = 1;
	public var facingScaleX(get, never):Int;
	private var speedBurstFramesRemaining:Int = 0;
	private var jetPackFuelRemaining:Null<Int> = null;
	private var itemReloadFramesRemaining:Int = 0;
	private var itemAvailable:Bool = false;
	private var animationLeft:Bool = false;
	private var animationRight:Bool = false;
	// The level's allowed-item pool (GamePage.setItems), used when an item block
	// carries empty options. Defaults to every code so a standalone controller
	// still hands out items before Course wires the level config.
	private var allowedItems:Array<Int> = pr2.gameplay.Items.getAllCodes();

	public function new(level:FixtureLevel) {
		this.level = level;
		startingSpeedStat = clamp(level.stats.speed, 0, 100);
		startingAccelerationStat = clamp((level.stats.acceleration - 0.2) * 60, 0, 100);
		startingJumpStat = clamp((level.stats.jump - 2) * 40, 0, 100);
		applyStats(startingSpeedStat, startingAccelerationStat, startingJumpStat);
		setGravity(level.gravity);
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
		lastItemEffect = null;
		animationLeft = input.left;
		animationRight = input.right;
		updateItemReload();
		// LocalCharacter.updateKeys applies RIGHT first and LEFT second, so LEFT
		// determines the facing direction when both keys are held.
		if (input.right) {
			facingDirection = 1;
		}
		if (input.left) {
			facingDirection = -1;
		}
		useHeldItem(input);
		if (cowboyHatActive && !grounded && mode == MODE_LAND) {
			setMode(MODE_WATER);
			waterTicks = 2;
		}
		if (mode == MODE_FREEZE) {
			updateRotation();
		} else if (mode == MODE_FROZEN_SOLID) {
			frozenSolidStep(input);
		} else if (mode == MODE_HURT) {
			hurtStep(input);
		} else if (mode == MODE_WATER) {
			waterStep(input);
		} else {
			landStep(input);
		}
		updateTimedBlocks();
	}

	public function setGravity(multiplier:Float):Void {
		gravity = DEFAULT_GRAVITY * multiplier;
	}

	public function setStats(speed:Float, acceleration:Float, jump:Float):Void {
		applyStats(speed, acceleration, jump);
	}

	public function ensureCowboyStats():Void {
		applyStats(Math.max(speedStat, 100), Math.max(accelerationStat, 99.6), Math.max(jumpStat, 100));
	}

	public function ensureSantaStats():Void {
		if (santaHatActive) {
			maxVelX += 1;
		}
	}

	public function resetStats():Void {
		applyStats(startingSpeedStat, startingAccelerationStat, startingJumpStat);
	}

	public function grantSpeedBurst(durationMs:Int):Void {
		if (speedBurstFramesRemaining > 0) {
			speedBurstFramesRemaining = 0;
			applyMovementStats();
		}
		itemId = ITEM_SPEED_BURST;
		itemUses = null;
		itemAvailable = false;
		activateSpeedBurst(msToFrames(durationMs));
	}

	// The pool an empty-options item block draws from (Course passes the decoded
	// LevelConfig.allowedItems). Empty means the level grants no items.
	public function setAllowedItems(items:Array<Int>):Void {
		allowedItems = items != null ? items : [];
	}

	public function setGameMode(mode:String):Void {
		gameMode = mode == "eggs" ? "egg" : (mode == null || mode == "" ? "race" : mode);
		if (gameMode == "deathmatch") {
			setLife(3);
		}
	}

	public function setLife(value:Int):Void {
		lives = Std.int(clamp(value, 0, 15));
	}

	private function get_facingScaleX():Int {
		return facingDirection;
	}

	public function freeze():Void {
		if (mode == MODE_FROZEN_SOLID || frozenSolidFramesRemaining > 0) {
			return;
		}
		frozenSolidFramesRemaining = FROZEN_SOLID_FRAMES;
		setMode(MODE_FROZEN_SOLID);
	}

	public function isFrozen():Bool {
		return frozenSolidFramesRemaining > 0;
	}

	public function receiveSting():Void {
		if (!partyHatActive && !jellyfishHatActive) {
			receiveHurtEffect();
		}
	}

	public function receiveZap():Void {
		if (!partyHatActive) {
			receiveHurtEffect();
		}
	}

	public function squashBounce():Void {
		vy = -3;
		grounded = true;
	}

	private function receiveHurtEffect():Void {
		setMode(MODE_HURT);
		beginHurtRecovery();
	}

	private function frozenSolidStep(input:LocalPlayerInput):Void {
		targetVelX = 0;
		position(input);
		processBlocks(input);
		if (input.jump && grounded && !crouching) {
			vy -= jumpVelocity;
		}
		frozenSolidFramesRemaining--;
		if (frozenSolidFramesRemaining <= 0) {
			setMode(MODE_LAND);
		}
	}

	private function hurtStep(input:LocalPlayerInput):Void {
		targetVelX = 0;
		position(input);
		processBlocks(input);
		hurtFramesRemaining--;
		if (hurtFramesRemaining <= 0) {
			setMode(MODE_LAND);
		}
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
				blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.SuperJumpSound, 0, 0));
			}
			crouchCharge = 0;
		}

		applyJetPackThrust(input);
		position(input);
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
		return new LocalPlayerDebugState(x, y, vx, vy, grounded, crouching, characterState(), touchedBlock == null ? null : touchedBlock.type, mode, itemId, itemUses, lastItemEffect, speedStat, accelerationStat, jumpStat, courseRotation, finished, finishBlockId, finishX, finishY, lives, courseTime);
	}

	public function blockAlphaAt(tileX:Int, tileY:Int):Float {
		var key = blockKey(tileX, tileY);
		if (vanishFadeFrames.exists(key)) {
			return vanishFadeFrames.get(key) / VANISH_FADE_FRAMES;
		}
		if (vanishFadeInFrames.exists(key)) {
			return 1 - vanishFadeInFrames.get(key) / VANISH_FADE_FRAMES;
		}
		return removedBlocks.exists(key) ? 0 : 1;
	}

	public function blockColorMultiplierAt(tileX:Int, tileY:Int):Float {
		var key = blockKey(tileX, tileY);
		var block = level.blockAt(tileX, tileY);
		return block != null && block.type == BlockType.Item && depletedItemBlocks.exists(key) ? 0.5 : 1;
	}

	public function consumeBlockVisualEvents():Array<BlockVisualEvent> {
		var events = blockVisualEvents.copy();
		blockVisualEvents.resize(0);
		return events;
	}

	/**
		Tile keys ("x,y") of blocks whose alpha/tint currently differs from the
		default: fading/removed vanish blocks and depleted item blocks. Lets the
		renderer restyle only these instead of every block in the level each frame.
	**/
	public function activeVisualBlockKeys():Array<String> {
		var seen:Map<String, Bool> = new Map();
		for (key in vanishFadeFrames.keys()) seen.set(key, true);
		for (key in vanishFadeInFrames.keys()) seen.set(key, true);
		for (key in removedBlocks.keys()) seen.set(key, true);
		for (key in depletedItemBlocks.keys()) seen.set(key, true);
		return [for (key in seen.keys()) key];
	}

	public function activeMoveBlockDirections():Map<String, Int> {
		var directions:Map<String, Int> = new Map();
		if (moveBlockPhase != "shift") {
			return directions;
		}
		for (key in moveBlockDirections.keys()) {
			directions.set(key, moveBlockDirections.get(key));
		}
		return directions;
	}

	private function position(input:LocalPlayerInput):Void {
		vy += gravity;
		if (input.jump && propellerHatActive && vy > 0) {
			vy *= 0.85;
		}
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
		if (santaHatActive) {
			var floorTile = rotatedTileAtPixel(x, y);
			var floorBlock = level.blockAt(floorTile.x, floorTile.y);
			if (floorBlock != null && !isBlockRemoved(floorBlock)
					&& ((floorBlock.type == BlockType.Water && mode != MODE_WATER) || floorBlock.type == BlockType.Safety)) {
				onStand(floorBlock);
				refs = refreshBlockRefs();
			}
		}

		if (vx >= -1 && refs.wallRight != null && getBlockLeftOf(refs.wallRight) == null) {
			onLeftHit(refs.wallRight);
			refs = refreshBlockRefs();
		}
		if (vx <= 1 && refs.wallLeft != null && getBlockRightOf(refs.wallLeft) == null) {
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

		touchAt(x, y - 15);
		if (!crouching) {
			touchAt(x, y - 45);
		}
	}

	// Mirrors Block.onTouch dispatch: unlike the solid-collision lookups, this
	// sees non-solid blocks (water/safety) so their touch effects can fire.
	private function touchAt(pixelX:Float, pixelY:Float):Void {
		var tile = rotatedTileAtPixel(pixelX, pixelY);
		var block = level.blockAt(tile.x, tile.y);
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
				blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.WaterRipple, block.x, block.y));
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
			floorLeft: getBlockAtPixel(x - HALF_WIDTH, y, true),
			floorCenter: getBlockAtPixel(x, y, true),
			floorRight: getBlockAtPixel(x + HALF_WIDTH, y, true),
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
		y = rotatedBlockPos(block).y;
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
		y = rotatedBlockPos(block).y + level.tileSize + (crouching ? STANDING_HEIGHT / 2 : STANDING_HEIGHT);
		vy *= -0.25;
		jumpVelBoost = 0;
		if (bumpPlaysThump(block)) {
			blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.BlockBumpSound, block.x, block.y));
		}
		applyBumpEffect(block, input, bumpForce);
	}

	private function bumpPlaysThump(block:LevelBlock):Bool {
		return switch (block.type) {
			case BlockType.ArrowDown | BlockType.ArrowUp | BlockType.ArrowLeft | BlockType.ArrowRight:
				false;
			default:
				true;
		}
	}

	private function onLeftHit(block:LevelBlock):Void {
		touch(block);
		var sideForce = Math.round(Math.abs(vx) * 1.75);
		x = rotatedBlockPos(block).x - HALF_WIDTH;
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
		x = rotatedBlockPos(block).x + level.tileSize + HALF_WIDTH;
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
				animateArrow(block);
			case BlockType.ArrowDown | BlockType.ArrowLeft | BlockType.ArrowRight:
				pushArrow(block.type);
				animateArrow(block);
			default:
		}
	}

	private function applyBumpEffect(block:LevelBlock, input:LocalPlayerInput, force:Int):Void {
		switch (block.type) {
			case BlockType.Brick:
				removedBlocks.set(blockKey(block.x, block.y), true);
				blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.BrickPieces, block.x, block.y, 6));
			case BlockType.Finish:
				finish(block);
			case BlockType.Happy:
				useStatSupply(block, false);
			case BlockType.Sad:
				useStatSupply(block, true);
			case BlockType.Heart:
				if (useSupply(block)) setLife(lives + 1);
			case BlockType.Time:
				if (useSupply(block)) courseTime += 10;
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
				animateArrow(block);
			case BlockType.ArrowDown | BlockType.ArrowLeft | BlockType.ArrowRight:
				pushArrow(block.type);
				animateArrow(block);
			default:
		}
	}

	// FinishBlock extends SupplyBlock in Flash: it fires once, and only through
	// onBump. Side, stand, and touch collisions must not complete the race.
	private function finish(block:LevelBlock):Void {
		if (finished) {
			return;
		}
		finished = true;
		var id = 0;
		for (candidate in level.blocks) {
			if (candidate.type == BlockType.Finish) {
				id++;
				if (candidate == block) {
					break;
				}
			}
		}
		finishBlockId = id;
		finishX = block.x * level.tileSize + Std.int(level.tileSize / 2);
		finishY = block.y * level.tileSize + Std.int(level.tileSize / 2);
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
				animateArrow(block);
			default:
		}
	}

	private function animateArrow(block:LevelBlock):Void {
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.ArrowAnimate, block.x, block.y));
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
			case BlockType.Brick | BlockType.Crumble | BlockType.Vanish | BlockType.Mine | BlockType.Move | BlockType.Teleport | BlockType.Push | BlockType.Water | BlockType.Safety: false;
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
		var poofTile = rotatedTileAtPixel(lastSafeX, lastSafeY);
		x = lastSafeX;
		y = lastSafeY;
		vx = 0;
		vy = 0;
		targetVelX = 0;
		jumpVelBoost = 0;
		jumpHeld = false;
		setMode(MODE_LAND);
		grounded = true;
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.SafetyPoof, poofTile.x, poofTile.y));
	}

	private function startRotate(block:LevelBlock):Void {
		if (rotateFramesRemaining > 0) {
			return;
		}
		setMode(MODE_FREEZE);
		vx = 0;
		vy = 0;
		targetVelX = 0;
		grounded = false;
		rotateDirection = block.type == BlockType.RotateRight ? 1 : -1;
		rotateFramesRemaining = ROTATE_FRAMES;
		courseTweenRotation = 0;
		characterRotation = 0;
	}

	private function updateRotation():Void {
		if (rotateFramesRemaining <= 0) {
			return;
		}
		courseTweenRotation += rotateDirection * 3;
		characterRotation = -courseTweenRotation;
		rotateFramesRemaining--;
		if (rotateFramesRemaining == 0) {
			finishRotation();
		}
	}

	private function finishRotation():Void {
		if (rotateDirection > 0) {
			var nextX = -y;
			y = x;
			x = nextX;
			var safeX = -lastSafeY;
			lastSafeY = lastSafeX;
			lastSafeX = safeX;
			courseRotation = RotationMath.normalizeDisplayRotation(courseRotation + 90);
		} else {
			var nextX = y;
			y = -x;
			x = nextX;
			var safeX = lastSafeY;
			lastSafeY = -lastSafeX;
			lastSafeX = safeX;
			courseRotation = RotationMath.normalizeDisplayRotation(courseRotation - 90);
		}
		rotateDirection = 0;
		courseTweenRotation = 0;
		characterRotation = 0;
		setMode(MODE_LAND);
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
		var crownProtected = crownHatActive && gameMode != "deathmatch" && gameMode != "dm" && gameMode != "hat";
		if (!crownProtected) {
			vx += Math.cos(angle) * MINE_HIT_SPEED;
			vy += Math.sin(angle) * MINE_HIT_SPEED;
		}
		removedBlocks.set(blockKey(block.x, block.y), true);
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.MinePieces, block.x, block.y, 10));
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.MineExplode, block.x, block.y));
		if (!crownProtected && mode != MODE_FREEZE) {
			setMode(MODE_HURT);
			beginHurtRecovery();
		}
	}

	private function beginHurtRecovery():Void {
		if (hurtFramesRemaining > 0) {
			return;
		}
		hurtFramesRemaining = HURT_FRAMES;
		if (gameMode == "deathmatch") {
			setLife(lives - 1);
			if (lives <= 0) {
				finished = true;
			}
		}
	}

	private function useItemBlock(block:LevelBlock):Void {
		if (block.type == BlockType.Item) {
			var key = blockKey(block.x, block.y);
			if (depletedItemBlocks.exists(key)) {
				return;
			}
			depletedItemBlocks.set(key, true);
		}
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.ItemBlockSound, block.x, block.y));

		var nextItem = itemFromBlockOptions(block.options);
		if (nextItem != null) {
			itemId = nextItem;
			itemUses = initialItemUses(nextItem);
			jetPackFuelRemaining = nextItem == ITEM_JET_PACK ? JET_PACK_TOTAL_FUEL : null;
			itemAvailable = false;
		}
	}

	// Mirrors ItemBlock.useSupply: an empty options string means "any of the
	// level's allowed items", "none" yields nothing, and otherwise the dash list
	// is the candidate pool. Flash then picks one candidate at random; the
	// deterministic LCG keeps the test suite reproducible (single-item blocks,
	// the only ones the suite exercises, resolve to the same id regardless).
	private function itemFromBlockOptions(options:String):Null<Int> {
		var candidates:Array<Int>;
		if (options == "") {
			candidates = allowedItems;
		} else if (options == "none") {
			candidates = [];
		} else {
			candidates = [];
			for (id in options.split("-")) {
				var parsed = Std.parseInt(id);
				if (parsed != null && parsed > 0) {
					candidates.push(parsed);
				}
			}
		}
		if (candidates.length == 0) {
			return null;
		}
		return candidates[nextMoveRandom(candidates.length)];
	}

	private function useHeldItem(input:LocalPlayerInput):Void {
		if (!input.item) {
			itemAvailable = true;
			return;
		}
		if (itemId == null || itemReloadFramesRemaining > 0) {
			return;
		}
		if (itemId == ITEM_JET_PACK) {
			useJetPack();
			return;
		}
		if (!itemAvailable) {
			return;
		}

		switch (itemId) {
			case ITEM_LASER_GUN:
				useLaserGun();
			case ITEM_MINE:
				useMineItem();
			case ITEM_LIGHTNING:
				useLightning();
			case ITEM_TELEPORT:
				useTeleportItem();
			case ITEM_SUPER_JUMP:
				useSuperJump();
			case ITEM_JET_PACK:
				useJetPack();
			case ITEM_SPEED_BURST:
				useSpeedBurst();
			case ITEM_SWORD:
				useSword();
			case ITEM_ICE_WAVE:
				useIceWave();
			default:
		}
	}

	private function useLaserGun():Void {
		var direction = facingDirection < 0 ? "left" : "right";
		vx += facingDirection < 0 ? 15 : -15;
		lastItemEffect = "laser:" + direction;
		consumeHeldItemUse();
	}

	private function useMineItem():Void {
		var tile = rotatedTileAtPixel(x + facingDirection * level.tileSize, y - 15);
		if (level.blockAt(tile.x, tile.y) != null) {
			return;
		}
		level.blocks.push(new LevelBlock(tile.x, tile.y, BlockType.Mine));
		var effectPos = rotatePoint(tile.x * level.tileSize + 15, tile.y * level.tileSize + 15, courseRotation);
		lastItemEffect = "mine:" + effectPos.x + "," + effectPos.y + ":" + courseRotation;
		consumeHeldItemUse();
	}

	private function useLightning():Void {
		lastItemEffect = "zap`";
		consumeHeldItemUse();
	}

	private function useTeleportItem():Void {
		var startX = x;
		var startY = y - 25;
		var destX = x + TELEPORT_ITEM_DISTANCE * facingDirection;
		if (getBlockAtPixel(destX, y - 5) != null) {
			return;
		}
		x = destX;
		lastItemEffect = "teleport:" + Std.int(startX) + "," + Std.int(startY) + ":" + Std.int(x) + "," + Std.int(y - 25);
		consumeHeldItemUse();
	}

	private function useSuperJump():Void {
		if (crouching) {
			return;
		}
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.SuperJumpSound, 0, 0));
		vy -= 25;
		consumeHeldItemUse();
	}

	private function useSpeedBurst():Void {
		if (speedBurstFramesRemaining > 0) {
			return;
		}
		activateSpeedBurst(SPEED_BURST_FRAMES);
	}

	private function activateSpeedBurst(frames:Int):Void {
		if (frames <= 0) {
			return;
		}
		accel *= 2;
		maxVelX *= 2;
		speedBurstFramesRemaining = frames;
	}

	private static function msToFrames(ms:Int):Int {
		return Std.int(Math.round(ms * FRAME_RATE / 1000));
	}

	private function useJetPack():Void {
		if (jetPackFuelRemaining == null || jetPackFuelRemaining <= 0 || crouching) {
			return;
		}
		vy -= vy > -5 ? 1.25 : 0.5;
		jetPackFuelRemaining--;
		itemUses = Std.int(Math.ceil((jetPackFuelRemaining / JET_PACK_TOTAL_FUEL) * 3));
		if (jetPackFuelRemaining <= 0) {
			consumeHeldItemCompletely();
		}
	}

	private function useSword():Void {
		var direction = facingDirection < 0 ? "left" : "right";
		vx += facingDirection < 0 ? -8 : 8;
		lastItemEffect = "slash:" + direction;
		consumeHeldItemUse();
	}

	private function useIceWave():Void {
		var direction = facingDirection < 0 ? "left" : "right";
		lastItemEffect = "ice_wave:" + direction;
		consumeHeldItemUse();
	}

	private function consumeHeldItemUse():Void {
		if (itemUses == null || itemUses <= 1) {
			consumeHeldItemCompletely();
			return;
		}
		itemUses--;
		itemReloadFramesRemaining = switch (itemId) {
			case ITEM_LASER_GUN | ITEM_SWORD: FAST_ITEM_RELOAD_FRAMES;
			case ITEM_ICE_WAVE: ICE_WAVE_RELOAD_FRAMES;
			default: 0;
		}
	}

	private function initialItemUses(id:Int):Int {
		return switch (id) {
			case ITEM_LASER_GUN | ITEM_SWORD | ITEM_ICE_WAVE: 3;
			case ITEM_JET_PACK: 3;
			default: 1;
		}
	}

	private function applyJetPackThrust(input:LocalPlayerInput):Void {
		if (input.item && itemId == ITEM_JET_PACK && !crouching) jumpHeld = false;
	}

	private function consumeHeldItemCompletely():Void {
		itemId = null;
		itemUses = null;
		itemReloadFramesRemaining = 0;
		jetPackFuelRemaining = null;
		itemAvailable = false;
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

	private function useStatSupply(block:LevelBlock, negative:Bool):Void {
		if (!useSupply(block)) {
			return;
		}
		var parsed = Std.parseInt(block.options);
		var amount = parsed == null ? (negative ? -5 : 5) : parsed;
		amount = Std.int(clamp(amount, negative ? -100 : 5, negative ? -5 : 100));
		applyStats(speedStat + amount, accelerationStat + amount, jumpStat + amount);
	}

	private function useSupply(block:LevelBlock):Bool {
		var key = blockKey(block.x, block.y);
		if (depletedSupplyBlocks.exists(key)) {
			return false;
		}
		depletedSupplyBlocks.set(key, true);
		return true;
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
		if (speedBurstFramesRemaining > 0) {
			jumpVelocity = 2 + jumpStat / 40;
			return;
		}
		applyMovementStats();
	}

	private function applyMovementStats():Void {
		maxVelX = 2 + speedStat / 10;
		accel = 0.2 + accelerationStat / 60;
		jumpVelocity = 2 + jumpStat / 40;
		ensureSantaStats();
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
		return getBlockBelow(block) == null ? block : null;
	}

	private function getBlockLeftOf(block:LevelBlock):Null<LevelBlock> {
		return getBlockAtPixel(block.x * level.tileSize - level.tileSize, block.y * level.tileSize);
	}

	private function getBlockRightOf(block:LevelBlock):Null<LevelBlock> {
		return getBlockAtPixel(block.x * level.tileSize + level.tileSize, block.y * level.tileSize);
	}

	private function getBlockBelow(block:LevelBlock):Null<LevelBlock> {
		return getBlockAtPixel(block.x * level.tileSize, block.y * level.tileSize + level.tileSize);
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
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.CrumblePieces, block.x, block.y, Std.int(Math.min(damage * 2, 20))));
		if (life <= 0) {
			blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.CrumblePieces, block.x, block.y, 10));
			removedBlocks.set(key, true);
		}
	}

	private function activateVanish(block:LevelBlock):Void {
		var key = blockKey(block.x, block.y);
		if (!vanishReappearFrames.exists(key) && !vanishFadeFrames.exists(key) && !vanishFadeInFrames.exists(key)) {
			vanishFadeFrames.set(key, VANISH_FADE_FRAMES);
		}
	}

	private function updateTimedBlocks():Void {
		updateSpeedBurst();
		updateVanishBlocks();
		updateTeleportBlocks();
		updateMoveBlocks();
	}

	private function updateItemReload():Void {
		if (itemReloadFramesRemaining > 0) {
			itemReloadFramesRemaining--;
		}
	}

	private function updateSpeedBurst():Void {
		if (speedBurstFramesRemaining <= 0) {
			return;
		}
		speedBurstFramesRemaining--;
		if (speedBurstFramesRemaining <= 0) {
			itemId = null;
			itemUses = null;
			itemAvailable = false;
			applyMovementStats();
		}
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

		var fadingIn:Array<String> = [for (key in vanishFadeInFrames.keys()) key];
		for (key in fadingIn) {
			var frames = vanishFadeInFrames.get(key) - 1;
			if (frames <= 0) {
				vanishFadeInFrames.remove(key);
			} else {
				vanishFadeInFrames.set(key, frames);
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
				vanishFadeInFrames.set(key, VANISH_FADE_FRAMES - 2);
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
		return CharacterState.fromMotion(mode, grounded, crouching, crouchCharge, animationLeft, animationRight);
	}

	private function getBlockAtPixel(pixelX:Float, pixelY:Float, allowTopHatVanishCollision:Bool = false):Null<LevelBlock> {
		var tile = rotatedTileAtPixel(pixelX, pixelY);
		return getBlockAtTile(tile.x, tile.y, allowTopHatVanishCollision);
	}

	private function getBlockAtTile(tileX:Int, tileY:Int, allowTopHatVanishCollision:Bool = false):Null<LevelBlock> {
		var block = level.blockAt(tileX, tileY);
		if (block == null || isBlockRemoved(block) || !block.type.isSolid()) {
			return null;
		}
		if (topHatActive && block.type == BlockType.Vanish && !allowTopHatVanishCollision) {
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

	private function rotatedTileAtPixel(pixelX:Float, pixelY:Float):TilePoint {
		var point = rotatePoint(pixelX, pixelY, courseRotation);
		return new TilePoint(tileIndex(point.x), tileIndex(point.y));
	}

	private function rotatedBlockPos(block:LevelBlock):PixelPoint {
		var offsetX:Float = 0;
		var offsetY:Float = 0;
		if (courseRotation == 90) {
			offsetY = level.tileSize;
		} else if (Math.abs(courseRotation) == 180) {
			offsetX = level.tileSize;
			offsetY = level.tileSize;
		} else if (courseRotation == -90) {
			offsetX = level.tileSize;
		}
		return rotatePoint(block.x * level.tileSize + offsetX, block.y * level.tileSize + offsetY, -courseRotation);
	}

	private static function rotatePoint(x:Float, y:Float, rotation:Int):PixelPoint {
		var point = RotationMath.rotatePoint(x, y, rotation);
		return new PixelPoint(point.x, point.y);
	}

	private static function clamp(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}
}

private class PixelPoint {
	public final x:Float;
	public final y:Float;

	public function new(x:Float, y:Float) {
		this.x = x;
		this.y = y;
	}
}

private class TilePoint {
	public final x:Int;
	public final y:Int;

	public function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
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
