package pr2.gameplay.player;

#if js
import js.Browser;
#end
import pr2.character.CharacterState;
import pr2.level.WorldLevel;
import pr2.level.WorldLevel.LevelBlock;
import pr2.level.BlockType;
import pr2.gameplay.RotationMath;
import pr2.gameplay.Items;
import pr2.gameplay.BlockController;
import pr2.gameplay.items.Item;
import pr2.gameplay.items.ItemRuntimeOwner;
import pr2.gameplay.player.BlockVisualEvent.BlockVisualEventKind;
import pr2.gameplay.player.LocalPlayerBlockStateStore.LocalPlayerBlockState;
import pr2.gameplay.player.LocalPlayerControllerTypes.BlockRefs;
import pr2.gameplay.player.LocalPlayerControllerTypes.PendingMinePlacement;
import pr2.gameplay.player.LocalPlayerControllerTypes.PendingProjectileDamage;
import pr2.gameplay.player.LocalPlayerControllerTypes.PhysicsBlockTrace;
import pr2.gameplay.player.LocalPlayerControllerTypes.PixelPoint;
import pr2.gameplay.player.LocalPlayerControllerTypes.PlayerStats;
import pr2.gameplay.player.LocalPlayerControllerTypes.TilePoint;

class LocalPlayerController implements ItemRuntimeOwner {
	public static inline var STANDING_WIDTH:Float = 20;
	public static inline var STANDING_HEIGHT:Float = 55;
	public static inline var CROUCHING_HEIGHT:Float = 30;

	private static inline var BASE_ACCEL_FACTOR:Float = 0.35;
	private static inline var FRICTION:Float = 0.985;
	private static inline var HALF_WIDTH:Float = STANDING_WIDTH / 2;
	private static inline var MAX_SPEED:Float = 28;
	private static inline var MAP_RETURN_MARGIN:Float = 500;
	private static inline var DEFAULT_GRAVITY:Float = 0.7;
	private static inline var CRUMBLE_INITIAL_LIFE:Int = 10;
	private static inline var MINE_HIT_SPEED:Float = 50;
	private static inline var FLASH_TWIPS_PER_PIXEL:Float = 20;
	private static inline var TELEPORT_DEFAULT_COLOR:String = "16744272";
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
	private static inline var ITEM_SNAKE:Int = 10;
	private static inline var TELEPORT_ITEM_DISTANCE:Float = 120;
	private static inline var SPEED_BURST_FRAMES:Int = 135;
	private static inline var FRAME_RATE:Int = 27;
	private static inline var JET_PACK_TOTAL_FUEL:Int = 200;
	private static inline var FAST_ITEM_RELOAD_FRAMES:Int = 22;
	private static inline var ICE_WAVE_RELOAD_FRAMES:Int = 27;
	private static inline var MINE_APPEAR_FRAMES:Int = 33;
	private static inline var SHOT_EFFECT_DEFAULT_SPEED:Float = 5;
	private static inline var LASER_SHOT_SPEED:Float = 29;
	public static inline var ROGUELIKE_MAX_LIVES:Int = 10;
	public static inline var ROGUELIKE_REQUIRED_FINISH_HITS:Int = 9;

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
	public var roguelikeFinishHits(default, null):Int = 0;
	public var courseTime(default, null):Int = 120;
	public var gameMode(default, null):String = "race";
	public var propellerHatActive:Bool = false;
	public var cowboyHatActive:Bool = false;
	public var santaHatActive:Bool = false;
	public var partyHatActive:Bool = false;
	public var jellyfishHatActive:Bool = false;
	public var topHatActive:Bool = false;
	public var crownHatActive:Bool = false;
	public var cheeseHatActive:Bool = false;
	public var onHeartGain:Null<Void->Void> = null;
	/** Called for Flash `LocalCharacter.hit` damage, including mine collisions. */
	public var onHitAccepted:Null<Void->Void> = null;
	public var detailedTraceEnabled(default, null):Bool = false;

	public static inline var MODE_LAND:String = "land";
	public static inline var MODE_WATER:String = "water";
	public static inline var MODE_FREEZE:String = "freeze";
	public static inline var MODE_JUMP:String = "jump";
	public static inline var MODE_FROZEN_SOLID:String = "frozenSolid";
	public static inline var MODE_HURT:String = "hurt";

	private final level:WorldLevel;
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
	// Snake trails are runtime-only solids. Keep them separate from authored
	// blocks so a trail over a freshly dug (removed) block does not inherit that
	// authored block's coordinate-keyed removed state.
	private final snakeTrailBlocks:Map<String, LevelBlock> = new Map();
	private final blockVisualEvents:Array<BlockVisualEvent> = [];
	private var itemRandom:Void->Float = Math.random;
	private var mapMinX:Float = 0;
	private var mapMinY:Float = 0;
	private var mapMaxX:Float = 0;
	private var mapMaxY:Float = 0;
	public var lastSafeX(default, null):Float;
	public var lastSafeY(default, null):Float;
	private var standingTileX:Int;
	private var standingTileY:Int;
	private var rotateFramesRemaining:Int = 0;
	private var rotateDirection:Int = 0;
	private var hurtFramesRemaining:Int = 0;
	private var frozenSolidFramesRemaining:Int = 0;
	private var facingDirection:Int = 1;
	private var animationState:CharacterState = CharacterState.Stand;
	private var touchedBlockX:Null<Int> = null;
	private var touchedBlockY:Null<Int> = null;
	private var lastCollisionEvent:Null<String> = null;
	public var facingScaleX(get, never):Int;
	private var speedBurstFramesRemaining:Int = 0;
	private var speedBurstFromItem:Bool = false;
	private var jetPackFuelRemaining:Null<Int> = null;
	private var jetPackActive:Bool = false;
	private var itemReloadFramesRemaining:Int = 0;
	private var itemAvailable:Bool = false;
	private var heldItem:Null<Item> = null;
	private var detailedTraceFrame:Int = 0;
	private var statsSelectSyncRequested:Bool = false;
	private var animationLeft:Bool = false;
	private var animationRight:Bool = false;
	private var pendingMinePlacements:Array<PendingMinePlacement> = [];
	private var pendingProjectileDamages:Array<PendingProjectileDamage> = [];
	// The level's allowed-item pool (GamePage.setItems), used when an item block
	// carries empty options. Defaults to every code so a standalone controller
	// still hands out items before Course wires the level config.
	private var allowedItems:Array<Int> = Items.getAllCodes();
	private final itemController:ItemController;
	public final blockController:BlockController;
	private final traceReporter:PhysicsTraceReporter;
	private var roguelikeStartX:Float;
	private var roguelikeStartY:Float;

	public function new(level:WorldLevel, ?courseBlockController:BlockController) {
		this.level = level;
		itemController = new ItemController(this);
		blockController = courseBlockController == null ? new BlockController(level) : courseBlockController;
		blockController.bindPlayer(this, courseBlockController == null);
		traceReporter = new PhysicsTraceReporter(this);
		for (i in 0...level.blocks.length) {
			var block = level.blocks[i];
			var blockX = block.x * level.tileSize;
			var blockY = block.y * level.tileSize;
			if (i == 0) {
				mapMinX = mapMaxX = blockX;
				mapMinY = mapMaxY = blockY;
			} else {
				mapMinX = Math.min(mapMinX, blockX);
				mapMinY = Math.min(mapMinY, blockY);
				mapMaxX = Math.max(mapMaxX, blockX);
				mapMaxY = Math.max(mapMaxY, blockY);
			}
		}
		startingSpeedStat = clamp(level.stats.speed, 0, 100);
		startingAccelerationStat = clamp((level.stats.acceleration - 0.2) * 60, 0, 100);
		startingJumpStat = clamp((level.stats.jump - 2) * 40, 0, 100);
		applyStats(startingSpeedStat, startingAccelerationStat, startingJumpStat);
		setGravity(level.gravity);
		setPlayerPos(level.playerStart.x * level.tileSize + level.tileSize / 2, (level.playerStart.y + 1) * level.tileSize);
		roguelikeStartX = x;
		roguelikeStartY = y;
		lastSafeX = x;
		lastSafeY = y;
		standingTileX = level.playerStart.x;
		standingTileY = level.playerStart.y + 1;
		processBlocks(new LocalPlayerInput());
	}

	public function setPosition(px:Float, py:Float):Void {
		setPlayerPos(px, py);
	}

	public function resetPreRacePosition(px:Float, py:Float):Void {
		setPlayerPos(px, py);
		roguelikeStartX = px;
		roguelikeStartY = py;
		vx = 0;
		vy = 0;
		grounded = false;
		crouching = false;
		touchedBlock = null;
		touchedBlockX = null;
		touchedBlockY = null;
		lastCollisionEvent = null;
		lastItemEffect = null;
		mode = MODE_LAND;
		animationState = CharacterState.Stand;
		targetVelX = 0;
		accelFactor = BASE_ACCEL_FACTOR;
		jumpHeld = false;
		jumpVelBoost = 0;
		crouchCharge = 0;
		waterTicks = 0;
		standingTileX = tileIndex(x);
		standingTileY = tileIndex(y);
		lastSafeX = x;
		lastSafeY = y;
		rotateFramesRemaining = 0;
		rotateDirection = 0;
		hurtFramesRemaining = 0;
		frozenSolidFramesRemaining = 0;
		snakeTrailBlocks.clear();
		blockVisualEvents.resize(0);
		blockController.resetPreRaceState();
		pendingMinePlacements.resize(0);
		pendingProjectileDamages.resize(0);
	}

	public function resetTestCourseState(startX:Float, startY:Float, maxTime:Int):Void {
		blockController.resetTestCourseState();
		setPlayerPos(startX, startY);
		vx = 0;
		vy = 0;
		grounded = false;
		crouching = false;
		touchedBlock = null;
		mode = MODE_LAND;
		animationState = CharacterState.Stand;
		itemId = null;
		itemUses = null;
		heldItem = null;
		itemAvailable = false;
		lastItemEffect = null;
		courseRotation = 0;
		courseTweenRotation = 0;
		characterRotation = 0;
		finished = false;
		finishBlockId = null;
		finishX = null;
		finishY = null;
		lives = 3;
		courseTime = maxTime;
		targetVelX = 0;
		accelFactor = BASE_ACCEL_FACTOR;
		jumpHeld = false;
		jumpVelBoost = 0;
		crouchCharge = 0;
		waterTicks = 0;
		standingTileX = Std.int(Math.floor(x / level.tileSize));
		standingTileY = Std.int(Math.floor(y / level.tileSize));
		lastSafeX = x;
		lastSafeY = y;
		rotateFramesRemaining = 0;
		rotateDirection = 0;
		hurtFramesRemaining = 0;
		frozenSolidFramesRemaining = 0;
		facingDirection = 1;
		speedBurstFramesRemaining = 0;
		speedBurstFromItem = false;
		jetPackFuelRemaining = null;
		jetPackActive = false;
		itemReloadFramesRemaining = 0;
		statsSelectSyncRequested = false;
		animationLeft = false;
		animationRight = false;
		pendingMinePlacements.resize(0);
		pendingProjectileDamages.resize(0);
		snakeTrailBlocks.clear();
		blockVisualEvents.resize(0);
		processBlocks(new LocalPlayerInput());
	}

	public function beginDetailedTraceFrame(frame:Int):Void {
		detailedTraceEnabled = true;
		detailedTraceFrame = frame;
	}

	public function stopDetailedTrace():Void {
		detailedTraceEnabled = false;
	}

	public function step(input:LocalPlayerInput):Void {
		setPlayerPos(Math.round(x), Math.round(y));
		traceCharacterFrame("before");
		hurtFramesRemaining--;
		touchedBlock = null;
		lastItemEffect = null;
		animationLeft = input.left;
		animationRight = input.right;
		updatePendingMinePlacements();
		updatePendingProjectileDamages();
		itemController.updateReload();
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
		if (mode == MODE_FREEZE || mode == MODE_JUMP) {
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
		itemController.updateTimedEffects();
		blockController.update();
		traceCharacterFrame("after");
	}

	public function setGravity(multiplier:Float):Void {
		var before = gravity;
		gravity = DEFAULT_GRAVITY * multiplier;
		traceGravityChange("setGravity", before, gravity, multiplier);
	}

	public function setStats(speed:Float, acceleration:Float, jump:Float):Void {
		applyStats(speed, acceleration, jump);
	}

	public function consumeStatsSelectSyncRequest():Bool {
		var requested = statsSelectSyncRequested;
		statsSelectSyncRequested = false;
		return requested;
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
		if (gameMode == "roguelike") {
			applyStats(0, 0, 0);
		} else {
			applyStats(startingSpeedStat, startingAccelerationStat, startingJumpStat);
		}
	}

	public function grantSpeedBurst(durationMs:Int):Void {
		if (speedBurstFramesRemaining > 0) {
			speedBurstFramesRemaining = 0;
			applyMovementStats();
		}
		itemId = ITEM_SPEED_BURST;
		itemUses = null;
		heldItem = Items.getFromCode(ITEM_SPEED_BURST);
		itemAvailable = false;
		speedBurstFromItem = false;
		activateSpeedBurst(msToFrames(durationMs));
	}

	public function clearSpeedBurst():Void {
		if (itemId == ITEM_SPEED_BURST) {
			itemId = null;
			itemUses = null;
			heldItem = null;
			speedBurstFromItem = false;
			itemAvailable = false;
		}
		if (speedBurstFramesRemaining > 0) {
			speedBurstFramesRemaining = 0;
			speedBurstFromItem = false;
			applyMovementStats();
		}
	}

	public function clampCourseTime(maxSeconds:Int):Void {
		if (courseTime > maxSeconds) {
			courseTime = maxSeconds;
		}
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
		} else if (gameMode == "roguelike") {
			initializeRoguelikeRun();
		}
	}

	public function setLife(value:Int):Void {
		var maxLives = gameMode == "roguelike" ? ROGUELIKE_MAX_LIVES : 15;
		lives = Std.int(clamp(value, 0, maxLives));
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

	public function receiveHit(impulseX:Float = 0, impulseY:Float = 0):Void {
		var crownProtected = crownHatActive && gameMode != "deathmatch" && gameMode != "dm" && gameMode != "hat";
		if (crownProtected) {
			return;
		}
		vx += impulseX;
		vy += impulseY;
		if (onHitAccepted != null) {
			onHitAccepted();
		}
		if (!crownHatActive) {
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
		updateLandAnimationState(input);
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
		var waterGravity = DEFAULT_GRAVITY * 0.25;
		vy += waterGravity;
		traceGravityChange("water", waterGravity, waterGravity, waterGravity);
		vx *= 0.92;
		vy *= 0.92;
		vx = clamp(vx, -MAX_SPEED, MAX_SPEED);
		vy = clamp(vy, -MAX_SPEED, MAX_SPEED);
		movePlayerBy(vx, vy);
		processBlocks(input);
		// A block interaction can replace water mode (notably a rotate-block bump
		// across a one-tile air gap). Do not let the remainder of this stale water
		// frame count down and overwrite the newly-entered mode with land.
		if (mode != MODE_WATER) {
			return;
		}
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

	private function updateLandAnimationState(input:LocalPlayerInput):Void {
		if (!grounded) {
			animationState = CharacterState.Jump;
		} else if (crouchCharge > 25) {
			animationState = CharacterState.SuperJump;
		} else if (input.left || input.right) {
			animationState = crouching ? CharacterState.CrouchWalk : CharacterState.Run;
		} else {
			animationState = crouching ? CharacterState.Crouch : CharacterState.Stand;
		}
	}

	private function setMode(newMode:String):Void {
		if (mode != newMode) {
			mode = newMode;
			targetVelX = 0;
			if (mode == MODE_HURT) {
				animationState = CharacterState.Bumped;
			}
			if (mode == MODE_WATER && animationState != CharacterState.Bumped) {
				animationState = CharacterState.Swim;
			}
			// Flash's generically named "freeze" mode is only the physics pause used
			// while Course rotates. The freeze-ray visual belongs exclusively to the
			// separate frozenSolid mode.
			if (mode == MODE_FROZEN_SOLID) {
				animationState = CharacterState.Freeze;
			}
			if (mode == MODE_JUMP) {
				animationState = CharacterState.Jump;
			}
		}
	}

	public function stateSnapshot():LocalPlayerState {
		return new LocalPlayerState(x, y, vx, vy, grounded, crouching, animationState, touchedBlock == null ? null : touchedBlock.type, mode, itemId, itemUses, lastItemEffect, speedStat, accelerationStat, jumpStat, courseRotation, finished, finishBlockId, finishX, finishY, lives, courseTime, jetPackActive, speedBurstFramesRemaining > 0 && speedBurstFromItem, touchedBlockX, touchedBlockY, lastCollisionEvent, roguelikeFinishHits);
	}

	public function blockAlphaAt(tileX:Int, tileY:Int):Float {
		return blockController.blockAlphaAt(tileX, tileY);
	}

	public function blockColorMultiplierAt(tileX:Int, tileY:Int):Float {
		return blockController.blockColorMultiplierAt(tileX, tileY);
	}

	public function blockIceOverlayAlphaAt(tileX:Int, tileY:Int):Float {
		return blockController.blockIceOverlayAlphaAt(tileX, tileY);
	}

	public function freezeBlock(tileX:Int, tileY:Int, fadeRate:Float = BlockController.SANTA_ICE_OVERLAY_FADE_RATE):Void {
		blockController.freezeBlock(tileX, tileY, fadeRate);
	}

	public inline function freezeBlockForTest(tileX:Int, tileY:Int, fadeRate:Float = BlockController.SANTA_ICE_OVERLAY_FADE_RATE):Void {
		freezeBlock(tileX, tileY, fadeRate);
	}

	public function consumeBlockVisualEvents():Array<BlockVisualEvent> {
		var events = blockVisualEvents.copy();
		blockVisualEvents.resize(0);
		return events;
	}

	/** Apply Flash Block.remoteActivate to the shared local map model. */
	public function applyRemoteBlockActivation(tileX:Int, tileY:Int, payload:String = ""):Bool {
		var block = level.blockAt(tileX, tileY);
		return block != null && activateBlock(block, payload, false);
	}

	private function activateBlock(block:LevelBlock, payload:String, local:Bool):Bool {
		var state = blockState(blockKey(block.x, block.y));
		switch (block.type) {
			case BlockType.Basic:
				if (state.removed) {
					return true;
				}
				if (local) {
					emitLocalActivate(block, payload);
				}
				state.removed = true;
				if (payload == "snake") {
					blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.BasicDigPieces, block.x, block.y, 6));
				}
			case BlockType.Push:
				if (local) {
					emitLocalActivate(block, payload);
				}
				var dx = 0;
				var dy = 0;
				switch (payload) {
					case "down": dy = 1;
					case "up": dy = -1;
					case "right": dx = 1;
					case "left": dx = -1;
					default: return true;
				}
				var rotated = RotationMath.rotatePoint(dx, dy, courseRotation);
				moveBlockChain(block, rotated.x, rotated.y);
			case BlockType.Mine:
				if (state.removed) {
					return true;
				}
				if (local) {
					emitLocalActivate(block, payload);
				}
				state.removed = true;
				blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.MinePieces, block.x, block.y, 10));
				blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.MineExplode, block.x, block.y));
			case BlockType.Brick:
				if (state.removed) {
					return true;
				}
				if (local) {
					emitLocalActivate(block, payload);
				}
				state.removed = true;
				blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.BrickPieces, block.x, block.y, 6));
			case BlockType.Crumble:
				// Flash removes a spent crumble from Map, so subsequent queued activate
				// commands cannot find it. WorldLevel retains its LevelBlock; explicitly
				// ignore those late commands instead of spawning another final shower.
				if (state.removed) {
					return true;
				}
				var force = Std.parseInt(payload);
				var damage = Std.int(Math.floor((force == null ? 0 : force) / 4));
				if (damage > 0) {
					// Deliberate multiplayer divergence from Flash: Flash sends every
					// onStand activation, including settled force 1 (damage 0). Replicate
					// only an actual state transition so idle standing cannot flood the
					// room with redundant crumble commands.
					if (local) {
						emitLocalActivate(block, payload);
					}
					var life = state.crumbleLife != null ? state.crumbleLife : CRUMBLE_INITIAL_LIFE;
					life -= damage;
					state.crumbleLife = life;
					blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.CrumblePieces, block.x, block.y,
						Std.int(Math.min(damage * 2, 20))));
					if (life <= 0) {
						blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.CrumblePieces, block.x, block.y, 10));
						state.removed = true;
					}
				}
			case BlockType.Vanish:
				activateVanish(block);
			default:
				return false;
		}
		return true;
	}

	/** Flash RemoteCharacter directly activates vanish blocks it visibly touches. */
	public function applyRemoteBlockTouch(tileX:Int, tileY:Int):Bool {
		var block = level.blockAt(tileX, tileY);
		if (block == null || block.type != BlockType.Vanish) {
			return false;
		}
		return activateBlock(block, "", false);
	}

	/**
		Tile keys ("x,y") of blocks whose alpha/tint currently differs from the
		default: fading/removed vanish blocks and depleted supply blocks. Lets the
		renderer restyle only these instead of every block in the level each frame.
	**/
	public function activeVisualBlockKeys():Array<String> {
		return blockController.activeVisualBlockKeys();
	}

	private static function depletesAsSupplyVisual(type:BlockType):Bool {
		return switch (type) {
			case BlockType.Finish | BlockType.Item | BlockType.CustomStats | BlockType.Happy | BlockType.Sad | BlockType.Heart | BlockType.Time:
				true;
			default:
				false;
		}
	}

	public function activeMoveBlockDirections():Map<String, Int> {
		return blockController.activeMoveBlockDirections();
	}

	/** The runtime state for a tile, creating (and storing) a fresh one on first write. */
	private function blockState(key:String):LocalPlayerBlockState {
		return blockController.stateForKey(key);
	}

	private function position(input:LocalPlayerInput):Void {
		var gravityBefore = gravity;
		vy += gravityBefore;
		traceGravityChange("position", gravityBefore, gravity, gravityBefore);
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
		movePlayerBy(vx, vy);
		if (isPastMapReturnBoundary()) {
			returnToLastSafeSpot();
		}
		accelFactor = BASE_ACCEL_FACTOR;
	}

	private function isPastMapReturnBoundary():Bool {
		var position = RotationMath.rotatePoint(x, y, courseRotation);
		return (courseRotation == 0 && position.y > mapMaxY + MAP_RETURN_MARGIN)
			|| (Math.abs(courseRotation) == 180 && position.y < mapMinY - MAP_RETURN_MARGIN)
			|| (courseRotation == 90 && position.x > mapMaxX + MAP_RETURN_MARGIN)
			|| (courseRotation == -90 && position.x < mapMinX - MAP_RETURN_MARGIN);
	}

	private function processBlocks(input:LocalPlayerInput):Void {
		var refs = refreshBlockRefs();
		if (updateGrounded(refs, "floorCenter")) {
			refs = refreshBlockRefs();
		}
		if (santaHatActive) {
			var floorTile = rotatedTileAtPixel(x, y);
			var floorBlock = level.blockAt(floorTile.x, floorTile.y);
			if (floorBlock != null && !isBlockRemoved(floorBlock)
					&& ((floorBlock.type == BlockType.Water && mode != MODE_WATER) || floorBlock.type == BlockType.Safety)) {
				onStand(floorBlock, "santaFloor");
				refs = refreshBlockRefs();
			}
		}

		if (vx >= -1 && refs.wallRight != null && getBlockLeftOf(refs.wallRight) == null) {
			onLeftHit(refs.wallRight, "wallRight");
			refs = refreshBlockRefs();
		}
		if (vx <= 1 && refs.wallLeft != null && getBlockRightOf(refs.wallLeft) == null) {
			onRightHit(refs.wallLeft, "wallLeft");
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
				onBump(bumpBlock, input, "upward");
				refs = refreshBlockRefs();
			}
		}

		if (!grounded) {
			if (updateGrounded(refs, "floorCenterRetry")) {
				refs = refreshBlockRefs();
			}
		}

		crouching = false;
		if (grounded) {
			var topBlock = getBlockAtPixel(x, y - 40);
			var bodyBlock = getBlockAtPixel(x, y - 10);
			if (topBlock != null && bodyBlock == null) {
				crouching = true;
				if (input.jump) {
					var yPriorToBump = y;
					onBump(topBlock, input, "crouchTop");
					if (topBlock.type != BlockType.Teleport) {
						setPlayerY(yPriorToBump);
					}
					vy = 0;
				}
				if (vy < 0) {
					vy = 0;
				}
			}
		}

		touchAt(x, y - 15, "bodyTouch");
		if (!crouching) {
			touchAt(x, y - 45, "headTouch");
		}
	}

	// Mirrors Block.onTouch dispatch: unlike the solid-collision lookups, this
	// sees non-solid blocks (water/safety) so their touch effects can fire.
	private function touchAt(pixelX:Float, pixelY:Float, source:String):Void {
		var tile = rotatedTileAtPixel(pixelX, pixelY);
		var block = level.blockAt(tile.x, tile.y);
		if (block == null || isBlockRemoved(block)) {
			return;
		}
		var trace = beginBlockTrace(block, "touch", source);
		touch(block);
		switch (block.type) {
			case BlockType.Mine:
				hitMine(block);
			case BlockType.Water:
				if (!grounded && mode != MODE_FREEZE && mode != MODE_HURT) {
					setMode(MODE_WATER);
					waterTicks = 2;
				} else {
					targetVelX *= 0.9;
					accelFactor = 0.1;
				}
				updateSafeSpot(block, true);
				blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.WaterRipple, block.x, block.y));
			case BlockType.Safety:
				if (isBlockFrozen(block)) {
					endBlockTrace(trace);
					return;
				}
				if (standingTileX != block.x || standingTileY < block.y || standingTileY > block.y + 2) {
					returnToLastSafeSpot(true);
				}
			default:
		}
		endBlockTrace(trace);
	}

	private function refreshBlockRefs():BlockRefs {
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

	private function updateGrounded(refs:BlockRefs, source:String):Bool {
		if (refs.floorCenter != null && refs.ceiling == null) {
			onStand(refs.floorCenter, source);
			return true;
		} else {
			grounded = false;
			return false;
		}
	}

	private function onStand(block:LevelBlock, source:String):Void {
		var trace = beginBlockTrace(block, "stand", source);
		recordCollision(block, "stand");
		touch(block);
		var standForce = Math.round(vy * 2);
		maybeFreezeSantaBlock(block);
		setPlayerY(rotatedBlockPos(block).y);
		vy = 0;
		grounded = true;
		if (isSafeStandBlock(block)) {
			updateSafeSpot(block, false);
		}
		applyStandEffect(block, standForce);
		endBlockTrace(trace);
	}

	private function onBump(block:LevelBlock, input:LocalPlayerInput, source:String):Void {
		var trace = beginBlockTrace(block, "bump", source);
		recordCollision(block, "bump");
		touch(block);
		var bumpForce = Math.round(-vy);
		var preBumpY = y;
		setPlayerY(rotatedBlockPos(block).y + level.tileSize + (crouching ? STANDING_HEIGHT / 2 : STANDING_HEIGHT));
		vy *= -0.25;
		jumpVelBoost = 0;
		if (bumpPlaysThump(block)) {
			blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.BlockBumpSound, block.x, block.y));
		}
		applyBumpEffect(block, input, bumpForce, preBumpY);
		endBlockTrace(trace);
	}

	private function bumpPlaysThump(block:LevelBlock):Bool {
		return switch (block.type) {
			case BlockType.ArrowDown | BlockType.ArrowUp | BlockType.ArrowLeft | BlockType.ArrowRight:
				false;
			default:
				true;
		}
	}

	private function onLeftHit(block:LevelBlock, source:String):Void {
		var trace = beginBlockTrace(block, "leftHit", source);
		recordCollision(block, "leftHit");
		touch(block);
		var sideForce = Math.round(Math.abs(vx) * 1.75);
		setPlayerX(rotatedBlockPos(block).x - HALF_WIDTH);
		if (vx > 0) {
			vx *= -0.05;
		}
		if (targetVelX > 0) {
			targetVelX = 0;
		}
		applySideHitEffect(block, sideForce, -1);
		endBlockTrace(trace);
	}

	private function onRightHit(block:LevelBlock, source:String):Void {
		var trace = beginBlockTrace(block, "rightHit", source);
		recordCollision(block, "rightHit");
		touch(block);
		var sideForce = Math.round(Math.abs(vx) * 1.75);
		setPlayerX(rotatedBlockPos(block).x + level.tileSize + HALF_WIDTH);
		if (vx < 0) {
			vx *= -0.05;
		}
		if (targetVelX < 0) {
			targetVelX = 0;
		}
		applySideHitEffect(block, sideForce, 1);
		endBlockTrace(trace);
	}

	private function applyStandEffect(block:LevelBlock, force:Int):Void {
		if (isBlockFrozen(block)) {
			accelFactor = 0.05;
			return;
		}
		if (isArrowBlock(block)) {
			var rotation = arrowEffectiveRotation(block);
			if (rotation == 0 && !crouching) {
				vy -= 10;
			} else {
				pushArrow(rotation);
			}
			animateArrow(block);
			return;
		}
		switch (block.type) {
			case BlockType.Crumble:
				applyCrumbleForce(block, cheeseCrumbleForce(force, true));
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
			default:
		}
	}

	private function applyBumpEffect(block:LevelBlock, input:LocalPlayerInput, force:Int, preBumpY:Float):Void {
			switch (block.type) {
			case BlockType.Brick:
				activateBlock(block, "", true);
			case BlockType.Finish:
				finish(block);
			case BlockType.Happy:
				useStatSupply(block, false);
			case BlockType.Sad:
				useStatSupply(block, true);
			case BlockType.Heart:
				if (useSupply(block)) {
					if (onHeartGain != null) {
						onHeartGain();
					} else {
						setLife(lives + 1);
					}
				}
			case BlockType.Time:
				if (useSupply(block)) {
					courseTime += 10;
					blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.TimeBlockSound, block.x, block.y));
				}
			case BlockType.Crumble:
				applyCrumbleForce(block, cheeseCrumbleForce(force));
			case BlockType.Vanish:
				activateVanish(block);
			case BlockType.ArrowDown | BlockType.ArrowUp | BlockType.ArrowLeft | BlockType.ArrowRight:
				var rotation = arrowEffectiveRotation(block);
				if (rotation == 0) {
					vy = !input.down && !crouching ? -14 : 0;
				} else {
					pushArrow(rotation);
				}
				animateArrow(block);
			case BlockType.Mine:
				hitMine(block);
			case BlockType.Item | BlockType.InfiniteItem:
				useItemBlock(block);
			case BlockType.CustomStats:
				useCustomStatsBlock(block);
			case BlockType.Teleport:
				if (crouching) {
					setPlayerY(preBumpY);
				}
				maybeTeleport(block);
			case BlockType.Push:
				pushBlock(block, 0, -1);
			case BlockType.RotateRight | BlockType.RotateLeft:
				startRotate(block);
			default:
		}
	}

	// FinishBlock extends SupplyBlock in Flash: it fires once, and only through
	// onBump. Side, stand, and touch collisions must not complete the race.
	private function finish(block:LevelBlock):Void {
		if (finished) {
			return;
		}
		if (!useSupply(block)) {
			return;
		}
		if (gameMode == "roguelike") {
			// A finish must be reusable, but the bump response pushes the character
			// away before another collision can occur, preventing per-frame repeats.
			resetSupplyState(block);
			roguelikeFinishHits++;
			if (roguelikeFinishHits < ROGUELIKE_REQUIRED_FINISH_HITS) {
				applyRoguelikeDamage();
				return;
			}
			// The ninth hit wins before a last-heart death can restart the run.
			finished = true;
			setLife(lives - 1);
			setFinishLocation(block);
			return;
		}
		finished = true;
		setFinishLocation(block);
	}

	private function setFinishLocation(block:LevelBlock):Void {
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

	private function applySideHitEffect(block:LevelBlock, force:Int, playerTileOffset:Int):Void {
		switch (block.type) {
			case BlockType.Crumble:
				var crumbleForce = cheeseCrumbleForce(force);
				maybeBreakCheeseAdjacentCrumble(block, crumbleForce, playerTileOffset);
				applyCrumbleForce(block, crumbleForce);
			case BlockType.Vanish:
				activateVanish(block);
			case BlockType.Mine:
				hitMine(block);
			case BlockType.Teleport:
				maybeTeleport(block);
			case BlockType.Push:
				pushBlock(block, -playerTileOffset, 0);
			case BlockType.ArrowDown | BlockType.ArrowUp | BlockType.ArrowLeft | BlockType.ArrowRight:
				pushArrow(arrowEffectiveRotation(block));
				animateArrow(block);
			default:
		}
	}

	private function animateArrow(block:LevelBlock):Void {
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.ArrowAnimate, block.x, block.y));
	}

	private function pushArrow(rotation:Int):Void {
		if (rotation == 0 && !crouching) {
			vy -= 1.2;
		}
		if (Math.abs(rotation) == 180) {
			vy += 5;
		}
		if (rotation == -90) {
			vx -= 3;
		}
		if (rotation == 90) {
			vx += 3;
		}
	}

	private function isArrowBlock(block:LevelBlock):Bool {
		return switch (block.type) {
			case BlockType.ArrowDown | BlockType.ArrowUp | BlockType.ArrowLeft | BlockType.ArrowRight:
				true;
			default:
				false;
		}
	}

	private function arrowEffectiveRotation(block:LevelBlock):Int {
		return RotationMath.normalizeDisplayRotation(courseRotation + arrowBaseRotation(block.type));
	}

	private static function arrowBaseRotation(type:BlockType):Int {
		return switch (type) {
			case BlockType.ArrowUp: 0;
			case BlockType.ArrowDown: 180;
			case BlockType.ArrowLeft: -90;
			case BlockType.ArrowRight: 90;
			default: 0;
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

	private function returnToLastSafeSpot(preserveMotion:Bool = false):Void {
		var poofTile = rotatedTileAtPixel(lastSafeX, lastSafeY);
		setPlayerPos(lastSafeX, lastSafeY);
		if (!preserveMotion) {
			vx = 0;
			vy = 0;
			targetVelX = 0;
			jumpVelBoost = 0;
			jumpHeld = false;
			setMode(MODE_LAND);
			grounded = true;
		}
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.SafetyPoof, poofTile.x, poofTile.y));
	}

	private function startRotate(block:LevelBlock):Void {
		if (rotateFramesRemaining > 0 || isBlockFrozen(block)) {
			return;
		}
		// Flash pauses character physics in `freezeGo` while Course owns the
		// rotation tween. This also prevents adjacent water from replacing the
		// rotate mode in the bump frame (level 6507177 relies on that layout).
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
			var previousX = x;
			var nextX = -y;
			setPlayerPos(nextX, previousX);
			var safeX = -lastSafeY;
			lastSafeY = lastSafeX;
			lastSafeX = safeX;
			courseRotation = RotationMath.normalizeDisplayRotation(courseRotation + 90);
		} else {
			var previousX = x;
			var nextX = y;
			setPlayerPos(nextX, -previousX);
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
		if (isBlockFrozen(block)) {
			return;
		}
		var activationPayload = pushActivationPayload(dx, dy);
		var rotatedDelta = RotationMath.rotatePoint(dx, dy, courseRotation);
		dx = rotatedDelta.x;
		dy = rotatedDelta.y;

		var destX = block.x + dx;
		var destY = block.y + dy;
		if (!canMoveBlockChain(block, dx, dy)) {
			return;
		}

		if (block.type == BlockType.Push) {
			activateBlock(block, activationPayload, true);
		} else {
			// Flash MoveBlock.shift calls Block.move directly. Only PushBlock uses
			// localActivate/remoteActivate replication when a player moves it.
			moveBlockChain(block, dx, dy);
		}
	}

	private function moveBlockChain(block:LevelBlock, dx:Int, dy:Int):Void {
		var destX = block.x + dx;
		var destY = block.y + dy;
		var destBlock = level.blockAt(destX, destY);
		if (destBlock != null && destBlock.type == BlockType.Push) {
			moveBlockChain(destBlock, dx, dy);
		}
		var fromX = block.x;
		var fromY = block.y;
		block.x = destX;
		block.y = destY;
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.PushBlockMove, fromX, fromY, 1, destX, destY));
	}

	private function pushActivationPayload(dx:Int, dy:Int):String {
		if (dy > 0) {
			return "down";
		}
		if (dy < 0) {
			return "up";
		}
		if (dx > 0) {
			return "right";
		}
		return "left";
	}

	private function canMoveBlockChain(block:LevelBlock, dx:Int, dy:Int):Bool {
		var destX = block.x + dx;
		var destY = block.y + dy;
		if (!level.containsTile(destX, destY)) {
			return false;
		}
		var destBlock = level.blockAt(destX, destY);
		if (destBlock != null) {
			if (destBlock.type != BlockType.Push || isBlockFrozen(destBlock)) {
				return false;
			}
			if (!canMoveBlockChain(destBlock, dx, dy)) {
				return false;
			}
		}
		return !blockController.playerOccupiesTile(destX, destY);
	}

	private function hitMine(block:LevelBlock):Void {
		if (isBlockRemoved(block) || isBlockFrozen(block)) {
			return;
		}

		var mineCenterX = block.x * level.tileSize + level.tileSize / 2;
		var mineCenterY = block.y * level.tileSize + level.tileSize / 2;
		// Flash's LocalCharacter.charHeight remains 55 while crouching; MineBlock
		// uses that field directly when calculating the blast angle.
		var angle = Math.atan2((y - STANDING_HEIGHT / 2) - mineCenterY, x - mineCenterX);
		var crownProtected = crownHatActive && gameMode != "deathmatch" && gameMode != "dm" && gameMode != "hat";
		if (!crownProtected) {
			vx += Math.cos(angle) * MINE_HIT_SPEED;
			vy += Math.sin(angle) * MINE_HIT_SPEED;
			if (onHitAccepted != null) {
				onHitAccepted();
			}
		}
		activateBlock(block, "", true);
		if (!crownProtected && !crownHatActive && mode != MODE_FREEZE) {
			setMode(MODE_HURT);
			beginHurtRecovery();
		}
	}

	private function beginHurtRecovery():Void {
		if (hurtFramesRemaining > 0) {
			return;
		}
		hurtFramesRemaining = HURT_FRAMES;
		if (gameMode == "deathmatch" || gameMode == "roguelike") {
			setLife(lives - 1);
			if (lives <= 0) {
				if (gameMode == "roguelike") {
					resetRoguelikeRun();
				} else {
					finished = true;
				}
			}
		}
	}

	private function applyRoguelikeDamage():Void {
		setLife(lives - 1);
		if (lives <= 0) {
			resetRoguelikeRun();
		}
	}

	private function initializeRoguelikeRun():Void {
		roguelikeFinishHits = 0;
		setLife(1);
		applyStats(0, 0, 0);
	}

	private function resetRoguelikeRun():Void {
		roguelikeFinishHits = 0;
		finished = false;
		finishBlockId = null;
		finishX = null;
		finishY = null;
		// Course rotation is shared run state, so preserve it and rotate the
		// original start coordinate into the controller's current physics axes.
		var rotatedStart = RotationMath.rotatePoint(roguelikeStartX, roguelikeStartY, -courseRotation);
		setPlayerPos(rotatedStart.x, rotatedStart.y);
		vx = 0;
		vy = 0;
		grounded = false;
		crouching = false;
		touchedBlock = null;
		touchedBlockX = null;
		touchedBlockY = null;
		mode = MODE_LAND;
		animationState = CharacterState.Stand;
		targetVelX = 0;
		jumpHeld = false;
		jumpVelBoost = 0;
		crouchCharge = 0;
		waterTicks = 0;
		hurtFramesRemaining = 0;
		frozenSolidFramesRemaining = 0;
		rotateFramesRemaining = 0;
		rotateDirection = 0;
		standingTileX = tileIndex(x);
		standingTileY = tileIndex(y);
		lastSafeX = x;
		lastSafeY = y;
		clearHeldItemAndEffects();
		resetRoguelikeProgressionBlocks();
		setLife(1);
		applyStats(0, 0, 0);
		statsSelectSyncRequested = true;
	}

	private function clearHeldItemAndEffects():Void {
		consumeHeldItemCompletely();
		speedBurstFramesRemaining = 0;
		speedBurstFromItem = false;
		pendingMinePlacements.resize(0);
		pendingProjectileDamages.resize(0);
		lastItemEffect = null;
	}

	private function resetRoguelikeProgressionBlocks():Void {
		for (block in level.blocks) {
			switch (block.type) {
				case BlockType.Happy | BlockType.Sad | BlockType.Heart | BlockType.Item | BlockType.CustomStats:
					resetSupplyState(block);
				default:
			}
		}
	}

	private function resetSupplyState(block:LevelBlock):Void {
		var state = blockController.stateAt(blockKey(block.x, block.y));
		if (state != null) {
			state.depletedItem = false;
			state.depletedSupply = false;
			state.depletedVisualSupply = false;
		}
	}

	private function useItemBlock(block:LevelBlock):Void {
		if (isBlockFrozen(block)) {
			return;
		}
		if (block.type == BlockType.Item) {
			var state = blockState(blockKey(block.x, block.y));
			if (state.depletedItem) {
				return;
			}
			state.depletedItem = true;
			state.depletedVisualSupply = true;
		}
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.ItemBlockSound, block.x, block.y));

		var nextItem = itemFromBlockOptions(block.options);
		if (nextItem != null) {
			heldItem = Items.getFromCode(nextItem);
			itemId = Items.getCodeFromItem(heldItem);
			itemUses = heldItem == null ? null : heldItem.initialUses;
			jetPackFuelRemaining = nextItem == ITEM_JET_PACK ? JET_PACK_TOTAL_FUEL : null;
			itemAvailable = false;
		}
	}

	// Mirrors ItemBlock.useSupply: an empty options string means "any of the
	// level's allowed items", "none" yields nothing, and otherwise the dash list
	// is the candidate pool. Flash picks one candidate with Math.random when the
	// block is used, rather than deriving a repeatable sequence from the level.
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
		return candidates[itemController.nextRandom(candidates.length)];
	}

	private function setItemRandomForTest(random:Void->Float):Void {
		itemRandom = random == null ? Math.random : random;
	}

	private function useHeldItem(input:LocalPlayerInput):Void itemController.useHeldItem(input);

	public function performLaserGunItem():Void itemController.performLaserGunItem();
	public function performMineItem():Void itemController.performMineItem();
	public function performLightningItem():Void itemController.performLightningItem();
	public function performTeleportItem():Void itemController.performTeleportItem();
	public function performSuperJumpItem():Void itemController.performSuperJumpItem();
	public function performJetPackItem():Void itemController.performJetPackItem();
	public function performSpeedBurstItem():Void itemController.performSpeedBurstItem();
	public function performSwordItem():Void itemController.performSwordItem();
	public function performIceWaveItem():Void itemController.performIceWaveItem();
	public function performSnakeItem():Void itemController.performSnakeItem();

	public function grantItemForDebug(itemCode:Int):Void itemController.grantItemForDebug(itemCode);
	public function addSnakeTrail(tileX:Int, tileY:Int):Void itemController.addSnakeTrail(tileX, tileY);
	public function removeSnakeTrail(tileX:Int, tileY:Int):Void itemController.removeSnakeTrail(tileX, tileY);
	public function clearSnakeTrails():Void itemController.clearSnakeTrails();
	public function snakeTileAtPixel(pixelX:Float, pixelY:Float):{x:Int, y:Int} return itemController.snakeTileAtPixel(pixelX, pixelY);
	public function snakeGridDirection(dx:Int, dy:Int):{x:Int, y:Int} return itemController.snakeGridDirection(dx, dy);
	public function enterSnakeTile(tileX:Int, tileY:Int):String return itemController.enterSnakeTile(tileX, tileY);

	private function updatePendingMinePlacements():Void itemController.updatePendingMinePlacements();
	private function updatePendingProjectileDamages():Void itemController.updatePendingProjectileDamages();
	private function applyJetPackThrust(input:LocalPlayerInput):Void itemController.applyJetPackThrust(input);
	private function activateSpeedBurst(frames:Int):Void itemController.activateSpeedBurst(frames);
	private function consumeHeldItemCompletely():Void itemController.consumeHeldItemCompletely();

	private static function msToFrames(ms:Int):Int return ItemController.msToFrames(ms);

	private function useCustomStatsBlock(block:LevelBlock):Void {
		if (isBlockFrozen(block)) {
			return;
		}
		var state = blockState(blockKey(block.x, block.y));
		if (state.depletedItem) {
			return;
		}
		state.depletedItem = true;
		state.depletedVisualSupply = true;

		if (block.options == "reset") {
			if (gameMode == "roguelike") {
				applyStats(0, 0, 0);
			} else {
				applyStats(startingSpeedStat, startingAccelerationStat, startingJumpStat);
			}
			statsSelectSyncRequested = true;
			return;
		}

		var stats = parseCustomStats(block.options);
		applyStats(stats.speed, stats.acceleration, stats.jump);
		statsSelectSyncRequested = true;
	}

	private function useStatSupply(block:LevelBlock, negative:Bool):Void {
		if (!useSupply(block)) {
			return;
		}
		var parsed = Std.parseInt(block.options);
		var amount = parsed == null ? (negative ? -5 : 5) : parsed;
		amount = Std.int(clamp(amount, negative ? -100 : 5, negative ? -5 : 100));
		applyStats(speedStat + amount, accelerationStat + amount, jumpStat + amount);
		statsSelectSyncRequested = true;
		blockVisualEvents.push(new BlockVisualEvent(negative ? BlockVisualEventKind.SadBlockSound : BlockVisualEventKind.HappyBlockSound, block.x, block.y));
	}

	private function useSupply(block:LevelBlock):Bool {
		if (isBlockFrozen(block)) {
			return false;
		}
		var state = blockState(blockKey(block.x, block.y));
		if (state.depletedSupply) {
			return false;
		}
		state.depletedSupply = true;
		if (depletesAsSupplyVisual(block.type)) {
			state.depletedVisualSupply = true;
		}
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
		if (blockController.teleportDisabled(color)) {
			return;
		}

		var blocks = teleportBlocksOfColor(color);
		if (blocks.length == 0) {
			return;
		}

		blockController.disableTeleports(color);
		var index = blocks.indexOf(block);
		if (index < 0) {
			index = 0;
		}
		var dest = blocks[(index + 1) % blocks.length];
		var startX = x;
		var startY = y - 25;
		for (candidate in blocks) {
			var state = blockState(blockKey(candidate.x, candidate.y));
			state.depletedSupply = true;
			state.depletedVisualSupply = true;
		}
		movePlayerBy((dest.x - block.x) * level.tileSize, (dest.y - block.y) * level.tileSize);
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.TeleportBlockPop, block.x, block.y, 1, null, null, startX, startY));
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.TeleportBlockPop, dest.x, dest.y, 1, null, null, x, y - 25));
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

	private function applyCrumbleForce(block:LevelBlock, force:Int, emitActivation:Bool = true):Void {
		activateBlock(block, Std.string(force), emitActivation);
	}

	private function cheeseCrumbleForce(force:Int, standing:Bool = false):Int {
		if (cheeseHatActive && force > 1) {
			return standing ? force * 2 : 50;
		}
		return force;
	}

	private function maybeBreakCheeseAdjacentCrumble(block:LevelBlock, force:Int, playerTileOffset:Int):Void {
		if (!cheeseHatActive || force != 50 || crouching) {
			return;
		}
		if (level.blockAt(block.x + playerTileOffset, block.y - 1) != null) {
			return;
		}
		var above = level.blockAt(block.x, block.y - 1);
		if (above != null && above.type == BlockType.Crumble && !isBlockRemoved(above)) {
			applyCrumbleForce(above, 50);
		}
	}

	private function emitLocalActivate(block:LevelBlock, payload:String = ""):Void {
		blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.LocalActivate, block.x, block.y, 1, null, null, 0, -15, payload));
	}

	private function activateVanish(block:LevelBlock):Void {
		var state = blockState(blockKey(block.x, block.y));
		if (state.vanishReappearFrames == null && state.vanishFadeFrames == null && state.vanishFadeInFrames == null) {
			// Flash attaches fadeOut during onStand/onBump, then the listener starts
			// ticking on a later ENTER_FRAME. This controller ticks timed blocks at
			// the end of the same deterministic step, so seed one extra frame.
			state.vanishFadeFrames = BlockController.VANISH_FADE_FRAMES + 1;
		}
	}

	private function touch(block:Null<LevelBlock>):Void {
		if (block != null) {
			touchedBlock = block;
			touchedBlockX = block.x;
			touchedBlockY = block.y;
		}
	}

	private function recordCollision(block:LevelBlock, event:String):Void {
		touchedBlock = block;
		touchedBlockX = block.x;
		touchedBlockY = block.y;
		lastCollisionEvent = event + ":" + Std.string(block.type) + "@" + block.x + "," + block.y;
	}

	private function traceCharacterFrame(phase:String):Void traceReporter.traceCharacterFrame(phase);
	private function traceGravityChange(kind:String, before:Float, after:Float, input:Float):Void
		traceReporter.traceGravityChange(kind, before, after, input);
	private function beginBlockTrace(block:LevelBlock, kind:String, source:String):Null<PhysicsBlockTrace>
		return traceReporter.beginBlockTrace(block, kind, source);
	private function endBlockTrace(info:Null<PhysicsBlockTrace>):Void traceReporter.endBlockTrace(info);

	private function characterState():CharacterState {
		return animationState;
	}

	private function getBlockAtPixel(pixelX:Float, pixelY:Float, allowTopHatVanishCollision:Bool = false):Null<LevelBlock> {
		var tile = rotatedTileAtPixel(pixelX, pixelY);
		return getBlockAtTile(tile.x, tile.y, allowTopHatVanishCollision);
	}

	private function getBlockAtTile(tileX:Int, tileY:Int, allowTopHatVanishCollision:Bool = false):Null<LevelBlock> {
		var trail = snakeTrailBlocks.get(blockKey(tileX, tileY));
		if (trail != null) {
			return trail;
		}
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
		return blockController.isBlockRemoved(block);
	}

	private function isBlockFrozen(block:LevelBlock):Bool {
		return blockController.isBlockFrozen(block);
	}

	private function maybeFreezeSantaBlock(block:LevelBlock):Void {
		if (!santaHatActive || !canSantaFreeze(block) || isBlockFrozen(block)) {
			return;
		}
		var state = blockState(blockKey(block.x, block.y));
		state.frozenIceAlpha = BlockController.SANTA_ICE_OVERLAY_START_ALPHA;
		state.frozenIceFadeRate = BlockController.SANTA_ICE_OVERLAY_FADE_RATE;
	}

	private function canSantaFreeze(block:LevelBlock):Bool {
		return switch (block.type) {
			case BlockType.Finish | BlockType.Ice | BlockType.Vanish | BlockType.Crumble | BlockType.ArrowUp | BlockType.ArrowLeft | BlockType.ArrowRight | BlockType.ArrowDown | BlockType.Move:
				false;
			default:
				true;
		}
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

	private function setPlayerX(value:Float):Void {
		x = flashCoordinate(value);
	}

	private function setPlayerY(value:Float):Void {
		y = flashCoordinate(value);
	}

	private function setPlayerPos(px:Float, py:Float):Void {
		setPlayerX(px);
		setPlayerY(py);
	}

	private function movePlayerBy(dx:Float, dy:Float):Void {
		setPlayerPos(x + dx, y + dy);
	}

	private static function flashCoordinate(value:Float):Float {
		// Flash stores DisplayObject coordinates in twips, so LocalCharacter.x/y
		// lose sub-1/20px precision even though velocity fields keep full precision.
		return Math.floor(value * FLASH_TWIPS_PER_PIXEL) / FLASH_TWIPS_PER_PIXEL;
	}

	private static function clamp(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}
}
