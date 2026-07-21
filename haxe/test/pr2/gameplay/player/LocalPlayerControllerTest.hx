package pr2.gameplay.player;

import com.jiggmin.data.SecureData;
import pr2.character.LocalCharacter;
import pr2.gameplay.BlockController;
import pr2.level.LevelParser;
import pr2.level.BlockType;
import pr2.level.Level;
import pr2.level.ObjectCodes;
import pr2.level.Level.LevelBlock;
import pr2.level.Level.StatDefaults;
import pr2.level.Level.TilePosition;
import sys.io.File;

class LocalPlayerControllerTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testStartBlockHasNoCollision();
		if (pr2.DeterministicTestMode.finishSmokeSuite("LocalPlayerControllerTest")) return;
		testSideCollisionDoesNotFinishRace();
		testBumpingFinishBlockFinishesRaceOnce();
		testObjectiveModeCanBumpSubsequentFinishBlocks();
		testJumpAndLandOnFlatFixture();
		testGravityUsesFlashMultiplierAndSupportsRuntimeChanges();
		testVelocityIntegrationOrderAndTerminalClamp();
		testFacingFollowsPressedDirection();
		testSnakeTrailAndDiggingInteractions();
		testAnimationFollowsDirectionalInput();
		testLowCeilingForcesCrouchAndBlocksJump();
		testPressingUpUnderBlockBumpsIt();
		testHoldingDownChargesAndLaunchesSuperJump();
		testIceBlockReducesNextFrameAcceleration();
		testSantaHatFreezesSafeStandBlock();
		testFrozenMineSuppressesHit();
		testFrozenPushBlockSuppressesMovement();
		testFrozenRotateBlockSuppressesRotation();
		testFrozenSafetyBlockSuppressesReturn();
		testFrozenSupplyBlockSuppressesUse();
		testRecoveryAllowsStackedHitImpulses();
		testArrowStandEffectsMatchAs3Deltas();
		testFallingIntoWaterEntersSwimMode();
		testWaterTouchEmitsRippleVisual();
		testWaterDampsSinkingAndPaddlesUp();
		testLeavingWaterReturnsToLand();
		testSafetyAboveCurrentFloorIsIgnored();
		testSafetyBlockReturnsPlayerToLastSafeSpot();
		testSafetyBlockDoesNotEmitTeleportPoof();
		testDeathmatchSafetyReturnRemovesLifeAndFinishesAtZero();
		testFallingPastMapReturnsPlayerToLastSafeSpot();
		testHighImpactFallBreaksCrumbleBlock();
		testSettledCrumbleStandDoesNotEmitPieces();
		testCheeseHatDoublesStandingCrumbleForce();
		testCheeseHatForcesBumpCrumbleDamage();
		testCheeseHatBreaksAdjacentHeadLevelCrumbleOnSideHit();
		testStandingOnVanishBlockFallsThroughAfterFadeOut();
		testVanishBlockReappearsAfterDelayWhenUnoccupied();
		testVanishCeilingReappearsWhileChargingSuperJump();
		testMineBlockLaunchesPlayerAndRemovesItself();
		testDontMoveSpawnMarkerOverlapPreservesMineAndTeleport();
		testDeathmatchMineHitRemovesLifeAndFinishesAtZero();
		testBumpingItemBlockGrantsConfiguredItem();
		testBumpingItemBlockEmitsStarSound();
		testEmptyOptionsItemBlockGrantsAllowedItem();
		testItemBlockUsesRuntimeRandom();
		testItemBlockRandomnessDoesNotAffectMoveBlocks();
		testRegularItemBlockDepletesAfterFirstUse();
		testNewlyCollectedItemRequiresReleaseBeforeUse();
		testSuperJumpItemLaunchesPlayerAndConsumesItem();
		testSuperJumpItemClipsThroughBlockAboveWater();
		testSuperJumpItemDoesNothingWhileCrouching();
		testTeleportItemMovesPlayerForwardAndConsumesItem();
		testTeleportItemBlockedBySolidDestination();
		testSpeedBurstBoostsMovementThenExpires();
		testJetPackLiftsPlayerThenExpires();
		testGroundJumpStacksWithJetPackThrust();
		testLaserGunReloadTiming();
		testLaserGunShotAnimatesBlockFromSide();
		testLaserGunDamageBreaksBrickBlock();
		testLaserSkipsPreviouslyDestroyedBrick();
		testTopHatLaserDamagesVanishBlock();
		testMineItemPlacesMineAndConsumesItem();
		testMineItemBlockedByOccupiedTile();
		testMineItemReusesDestroyedBrickTile();
		testMineAppearSkipsPlacementWhenTileBecomesOccupied();
		testLightningEmitsZapAndConsumesItem();
		testReloadableItemReleaseGateThenHeldRefire();
		testSwordReloadTiming();
		testSwordDamageBreaksTwoByTwoBrickGrid();
		testSwordDamageActivatesVanishBlock();
		testIceWaveReloadTiming();
		testIceWaveShotAnimatesBlockFromSide();
		testIceWaveDamageExplodesMineBlock();
		testLaserGunDamageChipsCrumbleBlock();
		testFrozenSolidDisablesMovementAndThaws();
		testBumpingCustomStatsBlockAppliesConfiguredStats();
		testBumpingResetCustomStatsBlockRestoresStartingStats();
		testBumpingBrickBlockBreaksIt();
		testBumpingHappyBlockRaisesStats();
		testBumpingSadBlockLowersStats();
		testBumpingHeartBlockAddsCappedLife();
		testBumpingTimeBlockAddsTenSeconds();
		testTeleportBlockMovesPlayerToNextSameColorBlock();
		testTeleportBlockEmitsStartAndDestinationPops();
		testCrouchingTeleportBlockBumpPreservesPreBumpY();
		testTeleportCooldownPreventsImmediateReturn();
		testTeleportCooldownTintsAndResetsSameColorBlocks();
		testTeleportDefaultColorOptionsMatchEmptyOptions();
		testPreRacePositionResetClearsConstructorTeleportCooldown();
		testStandingOnPushBlockMovesItDown();
		testPushBlockMovesIntoDestroyedBrickTile();
		testPushBlockRecursivelyMovesDestinationPushBlock();
		testUnconfiguredMoveBlocksUseFlashRandomDirections();
		testTimedMoveBlockPreviewDirections();
		testTimedMoveBlockShiftsAfterPreview();
		testTimedMoveBlockRecursivelyMovesDestinationPushBlock();
		testTimedMoveBlockWaitsWhenDestinationBlocked();
		testTimedMoveBlockWaitsWhenDestinationOccupied();
		testBumpingRotateBlockPutsPlayerInFreezeState();
		testWaterTouchDoesNotCancelRotation();
		testWaterBelowGapDoesNotStrandRotation();
		testRotateRightCompletesCourseRotation();
		testRotateLeftCompletesCourseRotation();
		testRotationTweenMatchesCourseFrames();
		testRotationMapsSafePosition();
		testRotatedSafeSpotUsesDisplayedBlockPosition();
		testRotatedSafetyAndMapReturnsUseRotatedSafeSpot();
		testCollisionSnapsAgainstRotatedCeiling();
		testCollisionStopsLeftMovementAfterRotation();
		testArrowPushUsesRotatedCourseDirection();
		testPushBlockUsesRotatedCourseDirection();
		trace('LocalPlayerControllerTest passed $assertions assertions');
	}

	private static function testFacingFollowsPressedDirection():Void {
		var player = newPlayer();
		assertEquals(1, player.facingScaleX, "character initially faces right");

		player.step(new LocalPlayerInput(true, false));
		assertEquals(-1, player.facingScaleX, "left input flips the character");

		player.step(new LocalPlayerInput());
		assertEquals(-1, player.facingScaleX, "released input preserves facing");

		player.step(new LocalPlayerInput(false, true));
		assertEquals(1, player.facingScaleX, "right input faces the character right");

		player.step(new LocalPlayerInput(true, true));
		assertEquals(-1, player.facingScaleX, "left wins when both directions are held like AS3 updateKeys");
	}

	private static function testSnakeTrailAndDiggingInteractions():Void {
		var level = new Level("snake", "Snake", 10, 6, 30, 1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40), new TilePosition(1, 3), new TilePosition(9, 4), [
				new LevelBlock(2, 2, BlockType.Basic),
				new LevelBlock(3, 2, BlockType.Brick),
				new LevelBlock(4, 2, BlockType.Crumble),
				new LevelBlock(5, 2, BlockType.Water),
				new LevelBlock(6, 2, BlockType.Mine)
			]);
		var controller = new LocalPlayerController(level);
		controller.consumeBlockVisualEvents();
		assertEquals("clear", controller.enterSnakeTile(2, 2), "Snake digs through a basic block");
		assertEquals(0.0, controller.blockAlphaAt(2, 2), "dug basic block is removed from collision and rendering");
		assertBasicSnakeDigEvents(controller.consumeBlockVisualEvents());
		assertEquals("clear", controller.enterSnakeTile(3, 2), "Snake destroys a brick block");
		assertEquals(0.0, controller.blockAlphaAt(3, 2), "destroyed brick is removed");
		var brickEvents = controller.consumeBlockVisualEvents();
		assertEquals("", brickEvents[0].activationPayload, "brick Snake dig uses normal brick activation");
		assertEquals("BrickPieces", Type.enumConstructor(brickEvents[1].kind), "brick Snake dig retains authored brick fragments");
		assertEquals("clear", controller.enterSnakeTile(4, 2), "Snake destroys a crumble block in one step");
		assertEquals(0.0, controller.blockAlphaAt(4, 2), "destroyed crumble is removed");
		var crumbleEvents = controller.consumeBlockVisualEvents();
		assertEquals("50", crumbleEvents[0].activationPayload, "crumble Snake dig uses normal force-50 activation");
		assertEquals("CrumblePieces", Type.enumConstructor(crumbleEvents[1].kind), "crumble Snake dig retains authored crumble fragments");
		assertEquals("hazard", controller.enterSnakeTile(5, 2), "water destroys the Snake");
		assertEquals("hazard", controller.enterSnakeTile(6, 2), "mine activation destroys the Snake");
		assertEquals(0.0, controller.blockAlphaAt(6, 2), "Snake-triggered mine explodes and is removed");

		controller.addSnakeTrail(7, 2);
		assertEquals("hazard", controller.enterSnakeTile(7, 2), "own or remote Snake trail destroys a Snake head");
		var trail = @:privateAccess controller.getBlockAtTile(7, 2);
		assertEquals(BlockType.SnakeTrail, trail.type, "Snake trail enters normal solid player collision lookup");
		controller.removeSnakeTrail(7, 2);
		assertEquals(null, @:privateAccess controller.getBlockAtTile(7, 2), "expired Snake trail leaves player collision lookup");
	}

	private static function assertBasicSnakeDigEvents(events:Array<BlockVisualEvent>):Void {
		assertEquals(2, events.length, "basic Snake dig emits activation and one particle event");
		assertEquals("LocalActivate", Type.enumConstructor(events[0].kind), "basic Snake dig replicates removal first");
		assertEquals("snake", events[0].activationPayload, "basic Snake dig carries its network marker");
		assertEquals("BasicDigPieces", Type.enumConstructor(events[1].kind), "basic Snake dig uses cropped bitmap fragments");
		assertEquals(6, events[1].count, "basic Snake dig emits six fragments like BrickBlock");
	}

	private static function testAnimationFollowsDirectionalInput():Void {
		var player = newPlayer();
		for (_ in 0...40) {
			player.step(new LocalPlayerInput());
		}

		player.step(new LocalPlayerInput(false, true));
		assertEquals("run", player.stateSnapshot().animation, "held direction runs like LocalCharacter");

		player.step(new LocalPlayerInput());
		assertEquals("stand", player.stateSnapshot().animation, "coasting without input stands like LocalCharacter");

		player.step(new LocalPlayerInput(false, false, false, true));
		player.step(new LocalPlayerInput(false, true, false, true));
		assertEquals("run", player.stateSnapshot().animation, "down on flat ground charges, not crouches: held direction still runs");

		player.step(new LocalPlayerInput(false, false, false, true));
		assertEquals("stand", player.stateSnapshot().animation, "down on flat ground does not crouch: released direction stands while charging");
	}

	private static function testStartBlockHasNoCollision():Void {
		var player = newPlayer();
		var state = player.stateSnapshot();

		assertClose(75, state.x, "initial x centers player in start tile");
		assertClose(270, state.y, "initial feet align with start block top");
		assertEquals(false, state.grounded, "start block does not ground player");

		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}
		state = player.stateSnapshot();
		assertClose(300, state.y, "player falls through start block to solid floor");
		assertEquals(true, state.grounded, "solid floor grounds player");
	}

	private static function testSideCollisionDoesNotFinishRace():Void {
		var player = newPlayer();
		var input = new LocalPlayerInput(false, true);
		var touchedFinish = false;

		for (_ in 0...120) {
			player.step(input);
			var state = player.stateSnapshot();
			if (state.touchedBlockType == "finish") {
				touchedFinish = true;
				break;
			}
		}

		var state = player.stateSnapshot();
		assertEquals(true, touchedFinish, "scripted run reaches finish block");
		assertClose(470, state.x, "finish collision stops at block edge");
		assertEquals(true, state.grounded, "player is grounded after run");
		assertEquals("finish", state.touchedBlockType, "debug state reports touched finish block");
		assertEquals(false, state.finished, "side collision does not activate finish supply");
	}

	private static function testBumpingFinishBlockFinishesRaceOnce():Void {
		var player = new LocalCharacter(finishBumpLevel());

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().finished) {
				break;
			}
		}

		var state = player.stateSnapshot();
		assertEquals(true, state.finished, "bumping finish block completes race");
		assertEquals(1, state.finishBlockId, "finish reports Flash-style one-based block id");
		assertEquals(105, state.finishX, "finish reports block center x");
		assertEquals(45, state.finishY, "finish reports block center y");
		assertClose(0.5, player.blockColorMultiplierAt(3, 1), "depleted finish block uses SupplyBlock grey transform");

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
		}
		assertEquals(1, player.stateSnapshot().finishBlockId, "finish supply remains latched after first use");
	}

	private static function testObjectiveModeCanBumpSubsequentFinishBlocks():Void {
		var level = new Level(
			"objective-finishes",
			"Objective Finishes",
			6,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(3, 3),
			new TilePosition(3, 1),
			[
				new LevelBlock(2, 1, BlockType.Finish),
				new LevelBlock(4, 1, BlockType.Finish),
				new LevelBlock(3, 4, BlockType.Solid)
			]
		);
		var player = new LocalCharacter(level);
		player.setGameMode("objective");

		@:privateAccess player.controller.finish(level.blocks[0]);
		assertEquals(1, player.stateSnapshot().finishBlockId, "objective mode reports the first finish block");
		@:privateAccess player.controller.finish(level.blocks[1]);
		assertEquals(2, player.stateSnapshot().finishBlockId, "objective mode reports a subsequent finish block");
		@:privateAccess player.controller.finish(level.blocks[0]);
		assertEquals(2, player.stateSnapshot().finishBlockId, "an objective finish supply still fires only once");
	}

	private static function testJumpAndLandOnFlatFixture():Void {
		var player = newPlayer();
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		player.step(new LocalPlayerInput(false, false, true));
		var jumpState = player.stateSnapshot();
		assertEquals(false, jumpState.grounded, "jump leaves ground");
		assertEquals("stand", jumpState.animation, "jump input keeps previous ground animation until Flash's next land frame");
		assertBelow(jumpState.y, 300, "jump moves player up");
		player.step(new LocalPlayerInput());
		assertEquals("jump", player.stateSnapshot().animation, "airborne land frame changes to jump animation");

		for (_ in 0...40) {
			player.step(new LocalPlayerInput());
		}

		var landedState = player.stateSnapshot();
		assertEquals(true, landedState.grounded, "scripted jump lands");
		assertClose(300, landedState.y, "jump lands back on solid floor");
		assertEquals("stand", landedState.animation, "landed animation");
	}

	private static function testGravityUsesFlashMultiplierAndSupportsRuntimeChanges():Void {
		var player = new LocalCharacter(emptyLevel(2.5));
		player.step(new LocalPlayerInput());
		assertClose(1.75, player.stateSnapshot().vy, "gravity is Flash's 0.7 times the level multiplier");

		player.setGravity(0.5);
		player.step(new LocalPlayerInput());
		assertClose(2.1, player.stateSnapshot().vy, "runtime gravity changes replace the active multiplier");
	}

	private static function testVelocityIntegrationOrderAndTerminalClamp():Void {
		var player = new LocalCharacter(emptyLevel(1));
		player.step(new LocalPlayerInput(false, true));
		var state = player.stateSnapshot();
		var acceleration = 0.2 + 50 / 60;
		var expectedVx = acceleration * 0.985 * 0.35;
		assertClose(expectedVx, state.vx, "horizontal integration applies input, friction, then acceleration factor");
		assertClose(flashCoordinate(75 + expectedVx), state.x, "horizontal position uses Flash twip-quantized integrated velocity");
		assertClose(0.7, state.vy, "vertical integration applies gravity before movement");
		assertClose(flashCoordinate(90.7), state.y, "vertical position uses Flash twip-quantized velocity after gravity");

		player = new LocalCharacter(emptyLevel(100));
		player.step(new LocalPlayerInput());
		state = player.stateSnapshot();
		assertClose(28, state.vy, "positive velocity is clamped to Flash's terminal speed");
		assertClose(118, state.y, "terminal velocity is clamped before position integration");

		player.setGravity(-100);
		player.step(new LocalPlayerInput());
		state = player.stateSnapshot();
		assertClose(-28, state.vy, "negative velocity is clamped to Flash's terminal speed");
		assertClose(90, state.y, "negative terminal velocity is clamped before position integration");
	}

	// LocalCharacter.processBlocks forces crouch only when a solid block sits above
	// the head while the body tile is clear; down never crouches on open ground.
	private static function testLowCeilingForcesCrouchAndBlocksJump():Void {
		var player = new LocalCharacter(lowCeilingLevel());
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		var crouchState = player.stateSnapshot();
		assertEquals(true, crouchState.crouching, "a low ceiling forces the character to crouch");
		assertEquals("crouch", crouchState.animation, "forced crouch shows the crouch animation");
		assertClose(300, crouchState.y, "crouch preserves feet position on the floor");

		player.step(new LocalPlayerInput(false, false, true, false));
		var jumpState = player.stateSnapshot();
		assertEquals(true, jumpState.crouching, "the low ceiling keeps the character crouched");
		assertEquals(true, jumpState.grounded, "crouching under a ceiling blocks the jump");
	}

	private static function testPressingUpUnderBlockBumpsIt():Void {
		var player = new LocalCharacter(lowItemCeilingLevel());
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		var crouchState = player.stateSnapshot();
		assertEquals(true, crouchState.crouching, "the low item block forces crouch before input");
		assertEquals(null, crouchState.itemId, "standing under the item block does not collect it");

		player.step(new LocalPlayerInput(false, false, true));
		var bumpState = player.stateSnapshot();
		assertEquals(true, bumpState.grounded, "pressing up under a block stays grounded");
		assertEquals(true, bumpState.crouching, "the block still forces crouch after the bump");
		assertEquals(4, bumpState.itemId, "pressing up under the block routes through onBump");
		assertEquals("item", bumpState.touchedBlockType, "debug state reports the bumped ceiling block");
	}

	// LocalCharacter.landGo charges crouchCharge while down is held on the ground and
	// launches a super jump of -crouchCharge*0.24 when it releases above the 25 floor.
	private static function testHoldingDownChargesAndLaunchesSuperJump():Void {
		var player = newPlayer();
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		// crouchCharge grows by 2 each frame; it must pass 25 to arm a super jump.
		for (_ in 0...15) {
			player.step(new LocalPlayerInput(false, false, false, true));
		}
		var charged = player.stateSnapshot();
		assertEquals(false, charged.crouching, "holding down on open ground never crouches");
		assertEquals(true, charged.grounded, "charging a super jump stays grounded");
		assertEquals("superJump", charged.animation, "a charged crouch shows the super jump pose");

		// Releasing down fires the charge as an upward launch.
		var beforeY = charged.y;
		player.step(new LocalPlayerInput());
		var launched = player.stateSnapshot();
		assertEquals(false, launched.grounded, "releasing a charged super jump leaves the ground");
		assertBelow(launched.vy, -5, "super jump launches with the Flash -crouchCharge*0.24 impulse");
		assertBelow(launched.y, beforeY, "super jump moves the player upward");
		var events = player.consumeBlockVisualEvents();
		assertEquals(1, events.length, "charged super jump emits one side-effect event");
		assertEquals("SuperJumpSound", Type.enumConstructor(events[0].kind), "charged super jump emits the Flash sound event");
	}

	private static function testIceBlockReducesNextFrameAcceleration():Void {
		var normal = new LocalCharacter(singleBlockLevel(BlockType.Basic));
		var icy = new LocalCharacter(singleBlockLevel(BlockType.Ice));

		normal.step(new LocalPlayerInput(false, true));
		icy.step(new LocalPlayerInput(false, true));

		assertBelow(icy.stateSnapshot().vx, normal.stateSnapshot().vx * 0.2, "ice applies AS3 low accelFactor on next frame");
	}

	private static function testSantaHatFreezesSafeStandBlock():Void {
		var normal = new LocalCharacter(singleBlockLevel(BlockType.Basic));
		var santa = new LocalCharacter(singleBlockLevel(BlockType.Basic));
		santa.setHats([7, 0xFFFFFF, -1]);

		normal.step(new LocalPlayerInput());
		santa.step(new LocalPlayerInput());
		assertClose(0.975, santa.controller.blockIceOverlayAlphaAt(2, 3), "santa stand adds fading ice overlay");

		normal.step(new LocalPlayerInput(false, true));
		santa.step(new LocalPlayerInput(false, true));

		assertBelow(santa.stateSnapshot().vx, normal.stateSnapshot().vx * 0.3, "santa-frozen block applies ice acceleration");

		santa.setHats([]);
		for (_ in 0...38) {
			santa.step(new LocalPlayerInput());
		}
		assertEquals(0.0, santa.controller.blockIceOverlayAlphaAt(2, 3), "santa ice overlay thaws after Flash fade");
	}

	private static function testFrozenMineSuppressesHit():Void {
		var player = new LocalCharacter(delayedMineBlockLevel());
		player.controller.freezeBlockForTest(2, 3);

		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
			if (player.stateSnapshot().touchedBlockType == "mine") {
				break;
			}
		}

		assertEquals("mine", player.stateSnapshot().touchedBlockType, "player touches frozen mine");
		assertEquals("land", player.stateSnapshot().mode, "frozen mine does not hurt player");
		assertClose(1, player.blockAlphaAt(2, 3), "frozen mine is not removed");
		assertEquals(0, player.consumeBlockVisualEvents().length, "frozen mine emits no activation visuals");
	}

	private static function testFrozenPushBlockSuppressesMovement():Void {
		var level = lowItemCeilingLevel(BlockType.Push);
		var player = new LocalCharacter(level);
		player.controller.freezeBlockForTest(2, 8);

		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}
		player.step(new LocalPlayerInput(false, false, true));

		assertEquals(BlockType.Push, level.blockAt(2, 8).type, "frozen push block stays in place");
		assertEquals(null, level.blockAt(2, 7), "frozen push block does not move to destination");
		assertEquals(1, player.consumeBlockVisualEvents().length, "frozen push block only emits base bump sound");
	}

	private static function testFrozenRotateBlockSuppressesRotation():Void {
		var player = new LocalCharacter(rotateBlockLevel(BlockType.RotateRight));
		player.controller.freezeBlockForTest(2, 1);

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().touchedBlockType == "rotate_right") {
				break;
			}
		}

		assertEquals("rotate_right", player.stateSnapshot().touchedBlockType, "player bumps frozen rotate block");
		assertEquals("land", player.stateSnapshot().mode, "frozen rotate block does not freeze player");
		assertEquals(0, player.stateSnapshot().courseRotation, "frozen rotate block does not start course rotation");
	}

	private static function testFrozenSafetyBlockSuppressesReturn():Void {
		var player = new LocalCharacter(safetyDropLevel());
		for (tileX in 5...9) {
			player.controller.freezeBlockForTest(tileX, 7, 0);
		}
		var touchedSafety = false;

		for (_ in 0...120) {
			player.step(new LocalPlayerInput(false, true));
			if (player.stateSnapshot().touchedBlockType == "safety") {
				touchedSafety = true;
				break;
			}
		}

		assertEquals(true, touchedSafety, "player touches frozen safety block");
		assertClose(210, player.stateSnapshot().y, "frozen safety block is a solid floor at its top edge");
		assertClose(0, player.stateSnapshot().vy, "frozen safety block cancels downward velocity as a solid");
		assertEquals(true, player.stateSnapshot().grounded, "frozen safety block supports the player");
		assertClose(75, player.lastSafeX, "frozen safety block does not replace the last safe x");
		assertClose(90, player.lastSafeY, "frozen safety block does not replace the last safe y");
	}

	private static function testFrozenSupplyBlockSuppressesUse():Void {
		var player = new LocalCharacter(lowItemCeilingLevel(BlockType.Item, "3"));
		player.controller.freezeBlockForTest(2, 8);
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		player.step(new LocalPlayerInput(false, false, true));
		var events = player.consumeBlockVisualEvents();
		assertEquals(null, player.stateSnapshot().itemId, "frozen item block grants no item");
		assertClose(1, player.blockColorMultiplierAt(2, 8), "frozen item block does not deplete");
		assertEquals(1, events.length, "frozen item block only emits the base bump");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "frozen item block suppresses item sound");
	}

	private static function testRecoveryAllowsStackedHitImpulses():Void {
		var player = newPlayer();
		player.controller.receiveHit(10, 0);
		var first = player.stateSnapshot();

		player.controller.receiveHit(10, 0);
		var second = player.stateSnapshot();

		assertAbove(second.vx, first.vx, "hurt recovery still accepts stacked horizontal hit impulse");
		assertEquals("hurt", second.mode, "player remains in hurt recovery");
	}

	private static function testArrowStandEffectsMatchAs3Deltas():Void {
		var up = new LocalCharacter(singleBlockLevel(BlockType.ArrowUp));
		assertClose(-10, up.stateSnapshot().vy, "up arrow stand launches upward");
		var events = up.consumeBlockVisualEvents();
		assertEquals(1, events.length, "arrow stand emits one visual activation");
		assertEquals("ArrowAnimate", Type.enumConstructor(events[0].kind), "arrow stand emits authored animation event");
		assertClose(5, new LocalCharacter(singleBlockLevel(BlockType.ArrowDown)).stateSnapshot().vy, "down arrow stand pushes down");
		assertClose(-3, new LocalCharacter(singleBlockLevel(BlockType.ArrowLeft)).stateSnapshot().vx, "left arrow stand pushes left");
		assertClose(3, new LocalCharacter(singleBlockLevel(BlockType.ArrowRight)).stateSnapshot().vx, "right arrow stand pushes right");
	}

	private static function testFallingIntoWaterEntersSwimMode():Void {
		var player = new LocalCharacter(waterPoolLevel());
		var enteredWater = false;

		for (_ in 0...40) {
			player.step(new LocalPlayerInput());
			if (player.stateSnapshot().mode == "water") {
				enteredWater = true;
				break;
			}
		}

		var state = player.stateSnapshot();
		assertEquals(true, enteredWater, "falling into water enters swim mode");
		assertEquals("water", state.mode, "debug state reports water mode");
		assertEquals("swim", state.animation, "swim animation while in water");
		assertEquals(false, state.grounded, "submerged player is not grounded");
	}

	private static function testWaterTouchEmitsRippleVisual():Void {
		var player = new LocalCharacter(waterPoolLevel());
		var emittedRipple = false;

		for (_ in 0...40) {
			player.step(new LocalPlayerInput());
			for (event in player.consumeBlockVisualEvents()) {
				if (Type.enumConstructor(event.kind) == "WaterRipple") {
					emittedRipple = true;
					assertEquals(2, event.tileX, "water ripple event uses touched tile x");
					assertEquals(true, event.tileY >= 2 && event.tileY < 10, "water ripple event uses a water tile y");
					break;
				}
			}
			if (emittedRipple) {
				break;
			}
		}

		assertEquals(true, emittedRipple, "touching water emits the block fade/ripple event");
	}

	private static function testWaterDampsSinkingAndPaddlesUp():Void {
		var sinking = new LocalCharacter(waterPoolLevel());
		for (_ in 0...40) {
			sinking.step(new LocalPlayerInput());
		}
		var sinkState = sinking.stateSnapshot();
		assertEquals("water", sinkState.mode, "idle player stays submerged");
		assertBelow(sinkState.vy, 5, "water damps sinking speed far below free-fall");
		assertBelow(0, sinkState.vy, "idle player still drifts downward");

		var paddling = new LocalCharacter(waterPoolLevel());
		var minVy = 1e9;
		for (_ in 0...40) {
			paddling.step(new LocalPlayerInput(false, false, true));
			var vy = paddling.stateSnapshot().vy;
			if (vy < minVy) {
				minVy = vy;
			}
		}
		assertBelow(minVy, 0, "holding jump paddles the swimmer upward");
	}

	private static function testLeavingWaterReturnsToLand():Void {
		var player = new LocalCharacter(waterPoolLevel());
		var enteredWater = false;
		var returnedToLand = false;

		for (_ in 0...120) {
			player.step(new LocalPlayerInput(false, false, true));
			var mode = player.stateSnapshot().mode;
			if (mode == "water") {
				enteredWater = true;
			} else if (enteredWater && mode == "land") {
				returnedToLand = true;
				break;
			}
		}

		assertEquals(true, enteredWater, "player enters water before exiting");
		assertEquals(true, returnedToLand, "swimming up out of water returns to land mode");
	}

	private static function testSafetyBlockReturnsPlayerToLastSafeSpot():Void {
		var player = new LocalCharacter(safetyDropLevel());
		@:privateAccess player.controller.vx = 6;
		@:privateAccess player.controller.targetVelX = 8;
		var touchedSafety = false;

		for (_ in 0...120) {
			player.step(new LocalPlayerInput(false, true));
			if (player.stateSnapshot().touchedBlockType == "safety") {
				touchedSafety = true;
				break;
			}
		}

		var state = player.stateSnapshot();
		assertEquals(true, touchedSafety, "falling player touches safety block");
		assertClose(75, state.x, "safety block restores last safe x");
		assertClose(90, state.y, "safety block restores last safe y");
		assertClose(0, state.vx, "safety block clears raw horizontal velocity");
		assertClose(0, state.vy, "safety block clears vertical velocity");
		assertEquals(false, state.grounded, "safety return preserves the pre-return grounded state");
		@:privateAccess assertAbove(player.controller.targetVelX, 0, "safety block preserves accumulated horizontal target velocity");
		@:privateAccess assertClose(60, player.controller.hurtFramesRemaining, "safety block starts Flash's bump cooldown");
		@:privateAccess assertClose(65, player.recoveryFrames, "safety block starts Flash's alpha recovery");

		player.step(new LocalPlayerInput(false, true));
		assertAbove(player.stateSnapshot().x, 75, "preserved horizontal target resumes rightward movement next frame");
		assertClose(0, player.stateSnapshot().vy, "safe floor cancels the next frame's gravity without restoring the old fall speed");
	}

	private static function testSafetyAboveCurrentFloorIsIgnored():Void {
		var player = new LocalCharacter(safetyOverFloorLevel());
		var touchedSafety = false;

		for (_ in 0...120) {
			player.step(new LocalPlayerInput(false, true));
			if (player.stateSnapshot().touchedBlockType == "safety") {
				touchedSafety = true;
				break;
			}
		}

		assertEquals(true, touchedSafety, "player reaches safety net above the current floor column");
		assertAbove(player.stateSnapshot().vx, 0, "same-column safety exception does not clear horizontal velocity");
		@:privateAccess assertEquals(true, player.controller.hurtFramesRemaining <= 0, "ignored same-column safety does not start bump cooldown");
		@:privateAccess assertClose(0, player.recoveryFrames, "ignored same-column safety does not start alpha recovery");
	}

	private static function testSafetyBlockDoesNotEmitTeleportPoof():Void {
		var player = new LocalCharacter(safetyDropLevel());

		for (_ in 0...120) {
			player.step(new LocalPlayerInput(false, true));
			if (player.stateSnapshot().touchedBlockType == "safety") {
				break;
			}
		}

		assertEquals(0, player.consumeBlockVisualEvents().length, "safety return does not emit a teleport poof or sound");
	}

	private static function testDeathmatchSafetyReturnRemovesLifeAndFinishesAtZero():Void {
		var player = new LocalCharacter(safetyDropLevel());
		player.setGameMode("deathmatch");
		player.setLife(1);

		for (_ in 0...120) {
			player.step(new LocalPlayerInput(false, true));
			if (player.stateSnapshot().touchedBlockType == "safety") {
				break;
			}
		}

		assertEquals(0, player.stateSnapshot().lives, "deathmatch safety return removes one life");
		assertEquals(true, player.stateSnapshot().finished, "deathmatch safety return finishes the player at zero lives");
	}

	private static function testFallingPastMapReturnsPlayerToLastSafeSpot():Void {
		var player = newPlayer();
		var safeX = player.lastSafeX;
		var safeY = player.lastSafeY;
		@:privateAccess player.controller.targetVelX = 7;
		@:privateAccess player.controller.vx = 4;
		@:privateAccess player.controller.vy = 12;
		player.setControllerPosition(safeX, 10000);
		player.step(new LocalPlayerInput(false, true));

		var state = player.stateSnapshot();
		assertClose(safeX, state.x, "falling 500px past the map restores last safe x");
		assertClose(safeY, state.y, "falling 500px past the map restores last safe y");
		assertClose(0, state.vx, "map return clears raw horizontal velocity");
		assertClose(0, state.vy, "map return clears falling velocity");
		@:privateAccess assertAbove(player.controller.targetVelX, 0, "map return preserves the friction-adjusted horizontal target");
		@:privateAccess assertClose(60, player.controller.hurtFramesRemaining, "map return starts the same bump cooldown as safety");
		assertEquals(0, player.consumeBlockVisualEvents().length, "map return does not emit a teleport poof");
	}

	private static function testHighImpactFallBreaksCrumbleBlock():Void {
		var level = crumbleDropLevel();
		var player = new LocalCharacter(level);
		var touchedCrumble = false;
		var framesAfterCrumble = 0;

		for (_ in 0...120) {
			player.step(new LocalPlayerInput());
			var state = player.stateSnapshot();
			if (state.touchedBlockType == "crumble") {
				touchedCrumble = true;
			}
			if (touchedCrumble) {
				framesAfterCrumble++;
				if (framesAfterCrumble >= 7) {
					break;
				}
			}
		}

		var state = player.stateSnapshot();
		assertEquals(true, touchedCrumble, "falling player touches crumble platform");
		assertEquals(false, state.grounded, "broken crumble block no longer supports the player");
		var crumbleActivate:Null<BlockVisualEvent> = null;
		for (event in player.consumeBlockVisualEvents()) {
			if (Type.enumConstructor(event.kind) == "LocalActivate" && event.tileX == 2 && event.tileY == 12) {
				crumbleActivate = event;
				break;
			}
		}
		assertEquals(true, crumbleActivate != null, "crumble impact emits Flash localActivate event");
		assertEquals(true, crumbleActivate.activationPayload != "", "crumble localActivate preserves force payload");
		assertEquals(null, level.blockAt(2, 12), "spent crumble is evicted from the live map");
	}

	private static function testSettledCrumbleStandDoesNotEmitPieces():Void {
		var level = new Level(
			"settled-crumble",
			"Settled Crumble",
			6,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(4, 4),
			[new LevelBlock(2, 3, BlockType.Crumble), new LevelBlock(4, 4, BlockType.Finish)]
		);
		var player = new LocalCharacter(level);
		for (_ in 0...8) {
			player.step(new LocalPlayerInput());
		}
		player.consumeBlockVisualEvents();
		for (_ in 0...10) {
			player.step(new LocalPlayerInput());
		}
		var pieceEvents = 0;
		var activationEvents = 0;
		for (event in player.consumeBlockVisualEvents()) {
			if (Type.enumConstructor(event.kind) == "CrumblePieces") {
				pieceEvents++;
			}
			if (Type.enumConstructor(event.kind) == "LocalActivate") {
				activationEvents++;
			}
		}
		assertEquals(0, pieceEvents, "settled crumble contact emits no particle showers");
		assertEquals(0, activationEvents, "settled crumble contact emits no redundant network activations");
		assertClose(1, player.blockAlphaAt(2, 3), "settled crumble contact does not consume block life");
	}

	private static function testCheeseHatDoublesStandingCrumbleForce():Void {
		var normal = new LocalCharacter(crumbleDropLevel());
		var cheese = new LocalCharacter(crumbleDropLevel());
		cheese.setHats([16, 0xC8B040, -1]);

		var normalPayload = firstCrumbleActivationPayload(normal, 2, 12);
		var cheesePayload = firstCrumbleActivationPayload(cheese, 2, 12);

		assertEquals(Std.parseInt(normalPayload) * 2, Std.parseInt(cheesePayload), "cheese doubles standing crumble force payload");
	}

	private static function testCheeseHatForcesBumpCrumbleDamage():Void {
		var player = new LocalCharacter(supplyBlockLevel(BlockType.Crumble));
		player.setHats([16, 0xC8B040, -1]);
		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().touchedBlockType == "crumble") break;
		}

		assertEquals("50", crumbleActivationPayload(player.consumeBlockVisualEvents(), 2, 1), "cheese bump crumble force is forced to 50");
	}

	private static function testCheeseHatBreaksAdjacentHeadLevelCrumbleOnSideHit():Void {
		var player = new LocalCharacter(cheeseSideCrumbleLevel());
		player.setHats([16, 0xC8B040, -1]);
		for (_ in 0...80) {
			player.step(new LocalPlayerInput(false, true));
			if (player.stateSnapshot().touchedBlockType == "crumble") break;
		}

		var events = player.consumeBlockVisualEvents();
		assertEquals("50", crumbleActivationPayload(events, 4, 4), "cheese side-hit crumble force is forced to 50");
		assertEquals("50", crumbleActivationPayload(events, 4, 3), "cheese side-hit breaks adjacent head-level crumble");
		assertEquals(0.0, player.controller.blockAlphaAt(4, 3), "adjacent head-level crumble is removed from collision visuals");
	}

	private static function firstCrumbleActivationPayload(player:LocalCharacter, tileX:Int, tileY:Int):String {
		for (_ in 0...120) {
			player.step(new LocalPlayerInput());
			var payload = crumbleActivationPayload(player.consumeBlockVisualEvents(), tileX, tileY);
			if (payload != null) {
				return payload;
			}
		}
		throw 'crumble activation not emitted at $tileX,$tileY';
	}

	private static function crumbleActivationPayload(events:Array<BlockVisualEvent>, tileX:Int, tileY:Int):Null<String> {
		for (event in events) {
			if (Type.enumConstructor(event.kind) == "LocalActivate" && event.tileX == tileX && event.tileY == tileY) {
				return event.activationPayload;
			}
		}
		return null;
	}

	private static function testStandingOnVanishBlockFallsThroughAfterFadeOut():Void {
		var player = new LocalCharacter(singleBlockLevel(BlockType.Vanish));

		assertClose(1, player.blockAlphaAt(2, 3), "vanish block starts opaque");
		player.step(new LocalPlayerInput());
		assertClose(1, player.blockAlphaAt(2, 3), "vanish block stays opaque until the next frame");
		player.step(new LocalPlayerInput());
		assertClose(0.9, player.blockAlphaAt(2, 3), "vanish block fades by one tenth per frame");

		for (_ in 0...9) {
			player.step(new LocalPlayerInput());
		}
		assertEquals(true, player.stateSnapshot().grounded, "vanish block remains solid while fading");
		assertClose(0, player.blockAlphaAt(2, 3), "vanish block is invisible at fade-out");

		player.step(new LocalPlayerInput());
		var state = player.stateSnapshot();
		assertEquals(false, state.grounded, "vanish block becomes inactive after fade-out");
		assertBelow(90, state.y, "player starts falling through inactive vanish block");
	}

	private static function testVanishBlockReappearsAfterDelayWhenUnoccupied():Void {
		var player = new LocalCharacter(vanishReappearLevel());

		for (_ in 0...12) {
			player.step(new LocalPlayerInput());
		}
		assertEquals(false, player.stateSnapshot().grounded, "vanish block is inactive after fade-out");

		var reappeared = false;
		for (_ in 0...80) {
			player.step(new LocalPlayerInput());
			if (player.blockAlphaAt(2, 3) > 0) {
				reappeared = true;
				break;
			}
		}
		assertEquals(true, reappeared, "vanish block reappears after its delay");
		assertClose(0.2, player.blockAlphaAt(2, 3), "vanish block reappears at one fifth alpha");
		player.step(new LocalPlayerInput());
		assertClose(0.3, player.blockAlphaAt(2, 3), "vanish block fades back in by one tenth per frame");

		for (_ in 0...30) {
			player.step(new LocalPlayerInput());
		}
		assertEquals(true, player.stateSnapshot().grounded, "player lands below the inactive vanish block");

		for (_ in 0...54) {
			player.step(new LocalPlayerInput());
		}
		var bumpedVanish = false;
		for (_ in 0...25) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().touchedBlockType == "vanish") {
				bumpedVanish = true;
				break;
			}
		}
		assertEquals(true, bumpedVanish, "reappeared vanish block collides again");
	}

	private static function testVanishCeilingReappearsWhileChargingSuperJump():Void {
		var player = new LocalCharacter(lowItemCeilingLevel(BlockType.Vanish));
		assertEquals(true, player.stateSnapshot().crouching, "vanish ceiling initially forces crouch");

		player.step(new LocalPlayerInput(false, false, true));
		for (_ in 0...11) {
			player.step(new LocalPlayerInput());
		}
		assertClose(0, player.blockAlphaAt(2, 8), "bumped vanish ceiling fades out");
		assertEquals(false, player.stateSnapshot().crouching, "removed vanish ceiling releases crouch");

		for (_ in 0...15) {
			player.step(new LocalPlayerInput(false, false, false, true));
		}
		assertEquals("superJump", player.stateSnapshot().animation, "holding down starts charging a super jump");

		var reappeared = false;
		for (_ in 0...55) {
			player.step(new LocalPlayerInput(false, false, false, true));
			if (player.blockAlphaAt(2, 8) > 0) {
				reappeared = true;
				break;
			}
		}
		assertEquals(true, reappeared, "Flash segment occupancy lets a vanish ceiling reappear during super-jump charge");
		assertClose(0.2, player.blockAlphaAt(2, 8), "vanish ceiling restarts at one fifth alpha");
	}

	private static function testMineBlockLaunchesPlayerAndRemovesItself():Void {
		var level = mineBlockLevel();
		var player = new LocalCharacter(level);
		var initialState = player.stateSnapshot();

		assertEquals("mine", initialState.touchedBlockType, "standing on mine reports touched block");
		assertClose(0, initialState.vx, "centered mine hit has no horizontal launch");
		assertClose(-50, initialState.vy, "mine hit launches away from block center with AS3 speed");
		assertEquals("hurt", initialState.mode, "mine hit enters hurt recovery mode");
		assertEquals("bumped", initialState.animation, "mine hit exposes bumped animation");
		var visualEvents = player.consumeBlockVisualEvents();
		assertEquals(3, visualEvents.length, "mine hit emits local activation, pieces, and explosion");
		assertEquals("LocalActivate", Std.string(visualEvents[0].kind), "mine hit emits Flash localActivate event");
		assertEquals("", visualEvents[0].activationPayload, "mine localActivate payload is empty");
		assertEquals("MinePieces", Std.string(visualEvents[1].kind), "mine hit emits authored pieces");
		assertEquals(10, visualEvents[1].count, "mine hit emits ten pieces");
		assertEquals("MineExplode", Std.string(visualEvents[2].kind), "mine hit emits explosion event");
		assertEquals(0, player.consumeBlockVisualEvents().length, "visual events are consumed once");
		assertEquals(null, level.blockAt(2, 3), "exploded mine is evicted from the live map");

		for (_ in 0...60) {
			player.step(new LocalPlayerInput());
		}
		assertEquals("land", player.stateSnapshot().mode, "hurt recovery returns to land mode");

		for (_ in 0...160) {
			player.step(new LocalPlayerInput());
		}
		var state = player.stateSnapshot();
		assertEquals(false, state.grounded, "removed mine no longer supports player");
		assertBelow(90, state.y, "player falls through removed mine block");
	}

	private static function testDontMoveSpawnMarkerOverlapPreservesMineAndTeleport():Void {
		// Don't Move JV relies on Flash Map.attachObject keeping the start marker
		// out of blockArray: a teleport occupies the start tile while a mine sits
		// directly above the spawned character. Neither may be consumed before the
		// Course moves the controller onto the selected start marker.
		var start = LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_START1, 60, 90);
		var mine = LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_MINE, 60, 60);
		var sourceTeleport = LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_TELEPORT, 60, 90, "16777215");
		var destinationTeleport = LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_TELEPORT, 150, 150, "16777215");
		var level = Level.fromDecoded(0xFFFFFF, [start, mine, sourceTeleport, destinationTeleport]);
		var player = new LocalPlayerController(level, new BlockController(level));

		assertEquals(mine, level.blockAt(mine.x, mine.y), "course construction does not consume the spawn mine before start placement");
		player.resetPreRacePosition(start.worldX + 15, start.worldY + 15);

		player.step(new LocalPlayerInput());
		var state = player.stateSnapshot();

		assertEquals(mine, level.blockAt(mine.x, mine.y), "spawn mine remains available after the start-tile teleport");
		assertAbove(state.x, start.worldX + 15, "start-tile teleport moves the player despite overlapping the spawn marker");
	}

	private static function testDeathmatchMineHitRemovesLifeAndFinishesAtZero():Void {
		var player = new LocalPlayerController(delayedMineBlockLevel());
		player.setGameMode("deathmatch");
		player.setLife(1);

		var hitMine = false;
		for (_ in 0...40) {
			player.step(new LocalPlayerInput());
			if (player.stateSnapshot().touchedBlockType == "mine") {
				hitMine = true;
				break;
			}
		}

		var state = player.stateSnapshot();
		assertEquals(true, hitMine, "deathmatch player reaches mine");
		assertEquals(0, state.lives, "deathmatch hurt removes one life");
		assertEquals(true, state.finished, "deathmatch zero lives finishes the player");
	}

	private static function testBumpingItemBlockGrantsConfiguredItem():Void {
		var player = new LocalCharacter(itemBlockLevel(BlockType.Item));
		var grantedItem = false;

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().itemId == 4) {
				grantedItem = true;
				break;
			}
		}

		var state = player.stateSnapshot();
		assertEquals(true, grantedItem, "jumping player bumps item block");
		assertEquals(4, state.itemId, "configured item id is granted");
		assertEquals("item", state.touchedBlockType, "debug state reports item block touch");
	}

	private static function testBumpingItemBlockEmitsStarSound():Void {
		var player = new LocalCharacter(lowItemCeilingLevel(BlockType.Item, "none"));
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		player.step(new LocalPlayerInput(false, false, true));
		var events = player.consumeBlockVisualEvents();
		assertEquals(2, events.length, "used item block emits thump then item sound events");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "item block first uses base ThumpSound event");
		assertEquals("ItemBlockSound", Std.string(events[1].kind), "item block then uses StarSound event");

		player.step(new LocalPlayerInput(false, false, true));
		var depletedEvents = player.consumeBlockVisualEvents();
		assertEquals(1, depletedEvents.length, "depleted item block still emits base thump");
		assertEquals("BlockBumpSound", Std.string(depletedEvents[0].kind), "depleted item block does not replay StarSound");
	}

	// An item block with empty options means "any of the level's allowed items"
	// (ItemBlock.useSupply). Regression: the port previously treated empty options
	// as "no item", so the common item block handed out nothing.
	private static function testEmptyOptionsItemBlockGrantsAllowedItem():Void {
		var player = new LocalCharacter(lowItemCeilingLevel(BlockType.Item, ""));
		player.setAllowedItems([7]);
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		assertEquals(null, player.stateSnapshot().itemId, "empty-options block grants nothing before the bump");
		player.step(new LocalPlayerInput(false, false, true));
		assertEquals(7, player.stateSnapshot().itemId, "empty options draws from the level's allowed item pool");

		var noneAllowed = new LocalCharacter(lowItemCeilingLevel(BlockType.Item, ""));
		noneAllowed.setAllowedItems([]);
		for (_ in 0...20) {
			noneAllowed.step(new LocalPlayerInput());
		}
		noneAllowed.step(new LocalPlayerInput(false, false, true));
		assertEquals(null, noneAllowed.stateSnapshot().itemId, "a level with no allowed items grants nothing");
	}

	private static function testItemBlockUsesRuntimeRandom():Void {
		var lowRoll = new LocalCharacter(lowItemCeilingLevel(BlockType.Item, "2-4"));
		@:privateAccess lowRoll.controller.setItemRandomForTest(function() return 0.25);
		var highRoll = new LocalCharacter(lowItemCeilingLevel(BlockType.Item, "2-4"));
		@:privateAccess highRoll.controller.setItemRandomForTest(function() return 0.75);

		for (_ in 0...20) {
			lowRoll.step(new LocalPlayerInput());
			highRoll.step(new LocalPlayerInput());
		}
		lowRoll.step(new LocalPlayerInput(false, false, true));
		highRoll.step(new LocalPlayerInput(false, false, true));

		assertEquals(2, lowRoll.stateSnapshot().itemId, "low runtime random roll selects the first candidate");
		assertEquals(4, highRoll.stateSnapshot().itemId, "high runtime random roll selects the second candidate");
	}

	private static function testItemBlockRandomnessDoesNotAffectMoveBlocks():Void {
		var untouched = new LocalCharacter(itemAndRandomMoveBlockLevel());
		var itemUser = new LocalCharacter(itemAndRandomMoveBlockLevel());

		for (_ in 0...20) {
			untouched.step(new LocalPlayerInput());
			itemUser.step(new LocalPlayerInput());
		}
		itemUser.step(new LocalPlayerInput(false, false, true));
		assertEquals(true, itemUser.stateSnapshot().itemId != null, "multi-candidate item block grants an item");

		for (_ in 0...142) {
			untouched.step(new LocalPlayerInput());
			itemUser.step(new LocalPlayerInput());
		}

		var untouchedDirections = untouched.activeMoveBlockDirections();
		var itemUserDirections = itemUser.activeMoveBlockDirections();
		for (key in ["1,1", "2,1", "3,1", "4,1", "5,1"]) {
			assertEquals(untouchedDirections.get(key), itemUserDirections.get(key), 'item random must not advance move random for $key');
		}
	}

	private static function testRegularItemBlockDepletesAfterFirstUse():Void {
		var player = new LocalCharacter(lowItemCeilingLevel(BlockType.Item, "3"));
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		player.step(new LocalPlayerInput(false, false, true));
		assertEquals(3, player.stateSnapshot().itemId, "first regular item bump grants the configured item");
		assertClose(0.5, player.blockColorMultiplierAt(2, 8), "depleted item block uses SupplyBlock grey transform");

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(null, player.stateSnapshot().itemId, "lightning item consumes before the second bump");
		player.step(new LocalPlayerInput(false, false, true));
		assertEquals(null, player.stateSnapshot().itemId, "depleted regular item block does not grant again");

		var infinite = new LocalCharacter(lowItemCeilingLevel(BlockType.InfiniteItem, "3"));
		for (_ in 0...20) {
			infinite.step(new LocalPlayerInput());
		}
		infinite.step(new LocalPlayerInput(false, false, true));
		assertClose(1, infinite.blockColorMultiplierAt(2, 8), "infinite item block does not deplete visually");
	}

	private static function testNewlyCollectedItemRequiresReleaseBeforeUse():Void {
		var player = collectItem(heldItemLevel(3), 3);

		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(3, player.stateSnapshot().itemId, "newly collected item does not fire before a key-up frame");
		assertEquals(null, player.stateSnapshot().lastItemEffect, "blocked first press emits no item effect");

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(null, player.stateSnapshot().itemId, "item fires after the key has been released");
		assertEquals("zap`", player.stateSnapshot().lastItemEffect, "released lightning emits the Flash payload");
	}

	private static function testSuperJumpItemLaunchesPlayerAndConsumesItem():Void {
		var player = new LocalCharacter(superJumpItemLevel());
		var grantedItem = false;

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().itemId == 5) {
				grantedItem = true;
				break;
			}
		}

		assertEquals(true, grantedItem, "jumping player bumps super jump item block");
		player.consumeBlockVisualEvents();
		for (_ in 0...70) {
			player.step(new LocalPlayerInput(false, true));
			if (player.stateSnapshot().x > 105) {
				break;
			}
		}
		var beforeUse = player.stateSnapshot();

		makeItemAvailable(player);
		beforeUse = player.stateSnapshot();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var afterUse = player.stateSnapshot();

		assertEquals(null, afterUse.itemId, "super jump consumes the held item");
		assertBelow(afterUse.vy, beforeUse.vy - 20, "super jump applies the Flash upward impulse");
		assertBelow(afterUse.y, beforeUse.y, "super jump moves the player upward on use");
		var events = player.consumeBlockVisualEvents();
		assertEquals(1, events.length, "super jump item emits one side-effect event");
		assertEquals("SuperJumpSound", Type.enumConstructor(events[0].kind), "super jump item emits the Flash sound event");
	}

	private static function testSuperJumpItemDoesNothingWhileCrouching():Void {
		var player = new LocalCharacter(lowItemCeilingLevel(BlockType.Item, "5"));
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		player.step(new LocalPlayerInput(false, false, true));
		var beforeUse = player.stateSnapshot();

		makeItemAvailable(player);
		beforeUse = player.stateSnapshot();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var afterUse = player.stateSnapshot();

		assertEquals(true, beforeUse.crouching, "low ceiling forces crouch before super jump item use");
		assertEquals(5, beforeUse.itemId, "bumping low item block grants the super jump item");
		assertEquals(5, afterUse.itemId, "crouched super jump item use keeps the held item");
		assertClose(beforeUse.vy, afterUse.vy, "crouched super jump item use does not apply impulse");
		assertEquals(null, afterUse.lastItemEffect, "crouched super jump item use emits no effect");
	}

	private static function testSuperJumpItemClipsThroughBlockAboveWater():Void {
		var player = new LocalCharacter(superJumpWaterClipLevel());
		player.controller.setPosition(75, 145);
		player.grantItemForDebug(5);

		player.step(new LocalPlayerInput(false, false, true));
		assertEquals("water", player.stateSnapshot().mode, "pressing up beneath the block enters water mode");
		for (_ in 0...8) {
			player.step(new LocalPlayerInput(false, false, true));
		}
		var beforeUse = player.stateSnapshot();
		assertEquals(true, beforeUse.y > 60, "swimming and block bounce alone leave the player below the block");
		assertEquals(5, beforeUse.itemId, "super jump remains held while building upward swim velocity");
		player.step(new LocalPlayerInput(false, false, true, false, true));
		for (_ in 0...8) {
			player.step(new LocalPlayerInput(false, false, true));
		}

		var afterClip = player.stateSnapshot();
		assertEquals(null, afterClip.itemId, "water super jump consumes the held item");
		assertEquals(true, afterClip.y <= 60, "water super jump clips through and lands above the block");
	}

	private static function testTeleportItemMovesPlayerForwardAndConsumesItem():Void {
		var player = new LocalCharacter(teleportItemLevel(false));
		var grantedItem = false;

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().itemId == 4) {
				grantedItem = true;
				break;
			}
		}

		assertEquals(true, grantedItem, "jumping player bumps teleport item block");
		for (_ in 0...70) {
			player.step(new LocalPlayerInput(false, true));
			if (player.stateSnapshot().x > 105) {
				break;
			}
		}
		var beforeUse = player.stateSnapshot();

		makeItemAvailable(player);
		beforeUse = player.stateSnapshot();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var afterUse = player.stateSnapshot();

		assertEquals(null, afterUse.itemId, "teleport item consumes after a clear teleport");
		assertClose(120, afterUse.x - afterUse.vx - Math.round(beforeUse.x), "teleport item moves 120 px in facing direction");
		var expectedTeleportX = flashCoordinate(beforeUse.x + 120);
		assertEquals(
			"teleport:" + Std.int(beforeUse.x) + "," + Std.int(beforeUse.y - 25) + ":" + Std.int(expectedTeleportX) + "," + Std.int(beforeUse.y - 25),
			afterUse.lastItemEffect,
			"teleport item emits Flash start and end pop effect positions"
		);
	}

	private static function testTeleportItemBlockedBySolidDestination():Void {
		var player = new LocalCharacter(teleportItemLevel(true));

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().itemId == 4) {
				break;
			}
		}
		for (_ in 0...70) {
			player.step(new LocalPlayerInput(false, true));
			if (player.stateSnapshot().x > 105) {
				break;
			}
		}
		var beforeUse = player.stateSnapshot();

		makeItemAvailable(player);
		beforeUse = player.stateSnapshot();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var afterUse = player.stateSnapshot();

		assertEquals(4, afterUse.itemId, "blocked teleport keeps held item");
		assertClose(0, afterUse.x - afterUse.vx - Math.round(beforeUse.x), "blocked teleport does not apply item movement");
		assertEquals(null, afterUse.lastItemEffect, "blocked teleport does not emit pop effects");
	}

	private static function testSpeedBurstBoostsMovementThenExpires():Void {
		var boosted = collectItem(speedBurstItemLevel(), 7);
		var normal = new LocalCharacter(speedBurstComparisonLevel());

		makeItemAvailable(boosted);
		boosted.step(new LocalPlayerInput(false, false, false, false, true));
		var active = boosted.stateSnapshot();
		assertEquals(7, active.itemId, "speed burst stays held while active");

		for (_ in 0...24) {
			boosted.step(new LocalPlayerInput(false, true));
			normal.step(new LocalPlayerInput(false, true));
		}

		assertBelow(normal.stateSnapshot().vx * 1.4, boosted.stateSnapshot().vx, "speed burst doubles movement acceleration");

		for (_ in 0...110) {
			boosted.step(new LocalPlayerInput(false, true));
		}

		assertEquals(null, boosted.stateSnapshot().itemId, "speed burst expires after five seconds");
		assertClose(50, boosted.stateSnapshot().speedStat, "speed burst expiry restores speed stat");
		assertClose(50, boosted.stateSnapshot().accelerationStat, "speed burst expiry restores acceleration stat");
		assertClose(50, boosted.stateSnapshot().jumpStat, "speed burst expiry preserves jump stat");
	}

	private static function testJetPackLiftsPlayerThenExpires():Void {
		var boosted = collectItem(jetPackItemLevel(), 6);
		var normal = new LocalCharacter(jetPackComparisonLevel());

		for (_ in 0...70) {
			boosted.step(new LocalPlayerInput(false, true));
			normal.step(new LocalPlayerInput(false, true));
			if (boosted.stateSnapshot().x > 105) {
				break;
			}
		}

		boosted.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(6, boosted.stateSnapshot().itemId, "jet pack stays held while active");
		assertEquals(3, boosted.stateSnapshot().itemUses, "jet pack starts with three fuel pips");

		for (_ in 0...24) {
			boosted.step(new LocalPlayerInput(false, false, false, false, true));
			normal.step(new LocalPlayerInput());
		}

		assertBelow(boosted.stateSnapshot().y, normal.stateSnapshot().y - 20, "jet pack thrust lifts the player");
		assertBelow(boosted.stateSnapshot().vy, normal.stateSnapshot().vy, "jet pack counters gravity while active");

		for (_ in 0...42) {
			boosted.step(new LocalPlayerInput(false, false, false, false, true));
		}
		assertEquals(2, boosted.stateSnapshot().itemUses, "jet pack ammo drops after one third of the fuel is spent");

		for (_ in 0...133) {
			boosted.step(new LocalPlayerInput(false, false, false, false, true));
		}

		assertEquals(null, boosted.stateSnapshot().itemId, "jet pack expires after 200 fuel frames");
	}

	private static function testGroundJumpStacksWithJetPackThrust():Void {
		var player = new LocalCharacter(jetPackComparisonLevel());
		player.grantItemForDebug(6);

		player.step(new LocalPlayerInput(false, false, true, false, true));
		player.step(new LocalPlayerInput(false, false, true, false, true));

		assertClose(-7.6, player.stateSnapshot().vy, "held ground jump keeps its diminishing boost while Jet Pack thrust is active");
	}

	private static function testLaserGunReloadTiming():Void {
		var player = collectItem(heldItemLevel(1), 1);
		var beforeUse = player.stateSnapshot();

		makeItemAvailable(player);
		beforeUse = player.stateSnapshot();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var firstShot = player.stateSnapshot();
		assertEquals(1, firstShot.itemId, "laser remains held after first shot");
		assertEquals(2, firstShot.itemUses, "laser consumes one of three shots");
		assertEquals("laser:right", firstShot.lastItemEffect, "laser emits a right-facing shot");
		assertBelow(firstShot.vx, beforeUse.vx, "laser applies backwards recoil");

		var leftFacing = collectItem(heldItemLevel(1), 1);
		leftFacing.step(new LocalPlayerInput(true));
		var beforeLeftUse = leftFacing.stateSnapshot();
		makeItemAvailable(leftFacing);
		beforeLeftUse = leftFacing.stateSnapshot();
		leftFacing.step(new LocalPlayerInput(false, false, false, false, true));
		var leftShot = leftFacing.stateSnapshot();
		assertEquals("laser:left", leftShot.lastItemEffect, "laser emits a left-facing shot");
		assertBelow(beforeLeftUse.vx, leftShot.vx, "left-facing laser recoils right like Flash");

		for (_ in 0...21) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
			assertEquals(2, player.stateSnapshot().itemUses, "laser cannot fire during its 800ms reload");
		}
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(1, player.stateSnapshot().itemUses, "held laser fires again after 22 frames");
		for (_ in 0...22) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
		}
		assertEquals(null, player.stateSnapshot().itemId, "laser is consumed after three shots");
	}

	private static function testLaserGunShotAnimatesBlockFromSide():Void {
		var player = collectItem(heldItemWithTargetBlockLevel(1), 1);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();
		assertEquals(0, events.length, "laser shot does not damage distant blocks on the firing frame");

		stepFrames(player, 2);
		events = player.consumeBlockVisualEvents();
		assertEquals(1, events.length, "laser shot side-hit emits one block visual event");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "laser side-hit uses block bump animation event");
		assertEquals(4, events[0].tileX, "laser side-hit targets the first solid block in the shot path");
		assertEquals(5, events[0].tileY, "laser side-hit targets the shot-height block row");
		assertEquals(20, events[0].hitX, "right-facing laser bumps the block with Flash's clamped impulse");
		assertEquals(0, events[0].hitY, "side shot does not use the upward bump impulse");
	}

	private static function testLaserGunDamageBreaksBrickBlock():Void {
		var level = heldItemWithTargetBlockLevel(1, BlockType.Brick);
		var player = collectItem(level, 1);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();
		assertEquals(0, events.length, "laser shot does not break a distant brick on the firing frame");

		stepFrames(player, 2);
		events = player.consumeBlockVisualEvents();
		assertEquals(3, events.length, "laser-damaged brick emits bump, activation, and pieces");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "laser damage still bumps the brick");
		assertEquals("LocalActivate", Std.string(events[1].kind), "laser damage activates the brick");
		assertEquals("BrickPieces", Std.string(events[2].kind), "laser damage spawns brick pieces");
		assertEquals(0.0, player.blockAlphaAt(4, 5), "laser-damaged brick is removed");
		assertEquals(null, level.blockAt(4, 5), "laser-damaged brick is evicted from the live map");
	}

	private static function testLaserSkipsPreviouslyDestroyedBrick():Void {
		var level = heldItemWithTargetBlockLevel(1, BlockType.Brick, 3);
		level.blocks.push(new LevelBlock(5, 5, BlockType.Brick));
		var player = collectItem(level, 1);
		assertEquals(true, player.applyRemoteBlockActivation(3, 5), "first brick can be destroyed before firing");
		assertEquals(null, level.blockAt(3, 5), "destroyed first brick leaves an empty map tile");
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		stepFrames(player, 3);

		assertEquals(null, level.blockAt(5, 5), "laser travels through the vacated tile and destroys the later brick");
		var bumpTiles:Array<Int> = [];
		for (event in player.consumeBlockVisualEvents()) {
			if (event.kind == BlockBumpSound) {
				bumpTiles.push(event.tileX);
			}
		}
		assertEquals("5", [for (tile in bumpTiles) Std.string(tile)].join(","), "laser impacts only the occupied tile");
	}

	private static function testTopHatLaserDamagesVanishBlock():Void {
		var level = heldItemWithTargetBlockLevel(1, BlockType.Vanish, 3);
		level.blocks.push(new LevelBlock(4, 5, BlockType.Brick));
		var player = collectItem(level, 1);
		player.setHats([9, 0xFFFFFF, -1]);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		stepFrames(player, 2);
		var events = player.consumeBlockVisualEvents();

		assertEquals(1, events.length, "top-hat laser damages only the vanish block");
		assertEquals(3, events[0].tileX, "top-hat laser damage stops at the vanish block");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "top-hat laser bumps the vanish block");
		assertBelow(player.blockAlphaAt(3, 5), 1.0, "top-hat laser starts fading the vanish block");
		assertEquals(1.0, player.blockAlphaAt(4, 5), "brick behind the vanish block remains undamaged");
	}

	private static function testMineItemPlacesMineAndConsumesItem():Void {
		var level = heldItemLevel(2);
		var player = collectItem(level, 2);

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var state = player.stateSnapshot();

		assertEquals(null, state.itemId, "mine item consumes after placing mine");
		assertEquals(0, Lambda.count(level.blocks, function(block) return block.type == BlockType.Mine), "mine item waits for appear animation");
		assertEquals("mine:105,165:0", state.lastItemEffect, "mine item emits centered mine effect");
		stepFrames(player, 32);
		assertEquals(0, Lambda.count(level.blocks, function(block) return block.type == BlockType.Mine), "mine does not place before frame 33");
		player.step(new LocalPlayerInput());
		var mine = Lambda.find(level.blocks, function(block) return block.type == BlockType.Mine);
		assertEquals(true, mine != null, "mine item places a mine block after appear animation");
		assertEquals("mine:105,165:0", 'mine:${mine.x * 30 + 15},${mine.y * 30 + 15}:0', "placed mine matches effect center");
	}

	private static function testMineItemBlockedByOccupiedTile():Void {
		var level = blockedMineItemLevel();
		var player = collectItem(level, 2);

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var state = player.stateSnapshot();

		assertEquals(2, state.itemId, "blocked mine placement keeps held item");
		assertEquals(null, state.lastItemEffect, "blocked mine placement emits no effect");
		var mineCount = Lambda.count(level.blocks, function(block) return block.type == BlockType.Mine);
		assertEquals(0, mineCount, "blocked mine placement does not add a mine block");
	}

	private static function testMineAppearSkipsPlacementWhenTileBecomesOccupied():Void {
		var level = heldItemLevel(2);
		var player = collectItem(level, 2);

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		level.blocks.push(new LevelBlock(3, 5, BlockType.Solid));
		stepFrames(player, 33);

		var mineCount = Lambda.count(level.blocks, function(block) return block.type == BlockType.Mine);
		assertEquals(0, mineCount, "mine appear skips placement if target tile becomes occupied");
	}

	private static function testMineItemReusesDestroyedBrickTile():Void {
		var level = heldItemLevel(2);
		level.blocks.push(new LevelBlock(3, 5, BlockType.Brick));
		var player = collectItem(level, 2);
		assertEquals(true, player.applyRemoteBlockActivation(3, 5), "brick at mine target can be destroyed");
		assertEquals(null, level.blockAt(3, 5), "destroyed brick vacates the mine target");
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		stepFrames(player, 33);

		var replacement = level.blockAt(3, 5);
		assertEquals(BlockType.Mine, replacement == null ? null : replacement.type, "mine can be placed in the vacated tile");
		assertEquals(1.0, player.blockAlphaAt(3, 5), "replacement mine does not inherit the brick's removed state");
	}

	private static function testLightningEmitsZapAndConsumesItem():Void {
		var player = collectItem(heldItemLevel(3), 3);

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var state = player.stateSnapshot();

		assertEquals(null, state.itemId, "lightning consumes on use");
		assertEquals("zap`", state.lastItemEffect, "lightning emits Flash's zap command payload");
	}

	private static function testReloadableItemReleaseGateThenHeldRefire():Void {
		var player = collectItem(heldItemLevel(1), 1);
		assertEquals(3.0, SecureData.getNumber("uses"), "collecting laser writes Flash SecureData uses");
		assertEquals(800.0, SecureData.getNumber("reloadTime"), "collecting laser writes Flash SecureData reloadTime");

		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(3, player.stateSnapshot().itemUses, "fresh reloadable item ignores held item key before first release");
		assertEquals(3.0, SecureData.getNumber("uses"), "blocked first press leaves SecureData uses unchanged");
		assertEquals(null, player.stateSnapshot().lastItemEffect, "fresh reloadable item emits no effect before first release");

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(2, player.stateSnapshot().itemUses, "released reloadable item fires on the next item press");
		assertEquals(2.0, SecureData.getNumber("uses"), "first shot decrements SecureData uses");

		for (_ in 0...21) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
		}
		assertEquals(2, player.stateSnapshot().itemUses, "held reloadable item waits through its reload timer");
		assertEquals(2.0, SecureData.getNumber("uses"), "reload wait leaves SecureData uses unchanged");

		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(1, player.stateSnapshot().itemUses, "held reloadable item refires when reload completes without another release");
		assertEquals(1.0, SecureData.getNumber("uses"), "held refire decrements SecureData uses again");
	}

	private static function testSwordReloadTiming():Void {
		var player = collectItem(heldItemLevel(8), 8);
		var beforeUse = player.stateSnapshot();

		makeItemAvailable(player);
		beforeUse = player.stateSnapshot();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var firstSwing = player.stateSnapshot();
		assertEquals(8, firstSwing.itemId, "sword remains held after first swing");
		assertEquals(2, firstSwing.itemUses, "sword consumes one of three swings");
		assertEquals("slash:right", firstSwing.lastItemEffect, "sword emits a right-facing slash");
		assertBelow(beforeUse.vx, firstSwing.vx, "sword lunges in the facing direction");

		var leftFacing = collectItem(heldItemLevel(8), 8);
		leftFacing.step(new LocalPlayerInput(true));
		var beforeLeftUse = leftFacing.stateSnapshot();
		makeItemAvailable(leftFacing);
		beforeLeftUse = leftFacing.stateSnapshot();
		leftFacing.step(new LocalPlayerInput(false, false, false, false, true));
		var leftSwing = leftFacing.stateSnapshot();
		assertEquals("slash:left", leftSwing.lastItemEffect, "sword emits a left-facing slash");
		assertBelow(leftSwing.vx, beforeLeftUse.vx, "left-facing sword lunges left like Flash");

		for (_ in 0...21) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
			assertEquals(2, player.stateSnapshot().itemUses, "sword cannot swing during its 800ms reload");
		}
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(1, player.stateSnapshot().itemUses, "held sword swings again after 22 frames");
		for (_ in 0...22) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
		}
		assertEquals(null, player.stateSnapshot().itemId, "sword is consumed after three swings");
	}

	private static function testSwordDamageActivatesVanishBlock():Void {
		var player = collectItem(heldItemWithTargetBlockLevel(8, BlockType.Vanish, 3), 8);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();
		assertEquals(1, events.length, "slash-damaged vanish block emits the base bump event");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "slash damage bumps the vanish block");
		assertClose(1, player.blockAlphaAt(3, 5), "slash-damaged vanish block waits until the next frame to fade");
		player.step(new LocalPlayerInput());
		assertClose(0.9, player.blockAlphaAt(3, 5), "slash-damaged vanish block fades like contact activation");
	}

	private static function testSwordDamageBreaksTwoByTwoBrickGrid():Void {
		var level = heldItemLevel(8);
		level.blocks.push(new LevelBlock(3, 4, BlockType.Brick));
		level.blocks.push(new LevelBlock(4, 4, BlockType.Brick));
		level.blocks.push(new LevelBlock(3, 5, BlockType.Brick));
		level.blocks.push(new LevelBlock(4, 5, BlockType.Brick));
		var player = collectItem(level, 8);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));

		assertClose(0, player.blockAlphaAt(3, 4), "sword breaks the upper-near brick");
		assertClose(0, player.blockAlphaAt(4, 4), "sword breaks the upper-far brick");
		assertClose(0, player.blockAlphaAt(3, 5), "sword breaks the lower-near brick");
		assertClose(0, player.blockAlphaAt(4, 5), "sword breaks the lower-far brick");
	}

	private static function testIceWaveReloadTiming():Void {
		var player = collectItem(heldItemLevel(9), 9);

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var firstWave = player.stateSnapshot();
		assertEquals(9, firstWave.itemId, "ice wave remains held after first wave");
		assertEquals(2, firstWave.itemUses, "ice wave consumes one of three waves");
		assertEquals("ice_wave:right", firstWave.lastItemEffect, "ice wave emits a right-facing wave");

		var leftFacing = collectItem(heldItemLevel(9), 9);
		leftFacing.step(new LocalPlayerInput(true));
		makeItemAvailable(leftFacing);
		leftFacing.step(new LocalPlayerInput(false, false, false, false, true));
		var leftWave = leftFacing.stateSnapshot();
		assertEquals("ice_wave:left", leftWave.lastItemEffect, "ice wave emits a left-facing wave");

		for (_ in 0...26) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
			assertEquals(2, player.stateSnapshot().itemUses, "ice wave cannot fire during its 1000ms reload");
		}
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(1, player.stateSnapshot().itemUses, "held ice wave fires again after 27 frames");
		for (_ in 0...27) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
		}
		assertEquals(null, player.stateSnapshot().itemId, "ice wave is consumed after three waves");
	}

	private static function testIceWaveShotAnimatesBlockFromSide():Void {
		var player = collectItem(heldItemWithTargetBlockLevel(9), 9);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();

		assertEquals(0, events.length, "ice wave freezes instead of damaging the first block in its path");
		assertEquals(0.975, player.blockIceOverlayAlphaAt(4, 5), "ice wave gives the target block a fading ice overlay");
	}

	private static function testIceWaveDamageExplodesMineBlock():Void {
		var player = collectItem(heldItemWithTargetBlockLevel(9, BlockType.Mine), 9);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();

		assertEquals(0, events.length, "ice wave freezes a mine without activating it");
		assertEquals(0.975, player.blockIceOverlayAlphaAt(4, 5), "ice wave gives the mine a fading ice overlay");
		assertEquals(1.0, player.blockAlphaAt(4, 5), "ice-wave-frozen mine remains in place");
	}

	private static function testLaserGunDamageChipsCrumbleBlock():Void {
		var player = collectItem(heldItemWithTargetBlockLevel(1, BlockType.Crumble), 1);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();
		assertEquals(0, events.length, "laser shot does not chip a distant crumble block on the firing frame");

		stepFrames(player, 2);
		events = player.consumeBlockVisualEvents();
		assertEquals(3, events.length, "laser-damaged crumble emits bump, activation, and chip pieces");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "laser damage bumps the crumble block");
		assertEquals("LocalActivate", Std.string(events[1].kind), "laser damage activates the crumble block");
		assertEquals("5", events[1].activationPayload, "crumble onDamage uses Flash force payload 5");
		assertEquals("CrumblePieces", Std.string(events[2].kind), "laser damage chips crumble pieces");
		assertEquals(2, events[2].count, "crumble onDamage force 5 removes one life and emits two pieces");
		assertClose(1, player.blockAlphaAt(4, 5), "single crumble damage hit does not remove the block");
	}

	private static function testFrozenSolidDisablesMovementAndThaws():Void {
		var player = newPlayer();
		var startX = player.stateSnapshot().x;
		player.freeze();

		assertEquals(true, player.isFrozen(), "freeze marks player frozen");
		assertEquals("frozenSolid", player.stateSnapshot().mode, "freeze enters frozen-solid mode");
		assertEquals("freeze", player.stateSnapshot().animation, "frozen-solid mode uses frozen animation");

		for (_ in 0...53) {
			player.step(new LocalPlayerInput(false, true));
		}
		assertEquals(true, player.isFrozen(), "player remains frozen before two seconds elapse");
		assertClose(startX, player.stateSnapshot().x, "frozen player ignores horizontal input");

		player.step(new LocalPlayerInput(false, true));
		assertEquals(false, player.isFrozen(), "player thaws after two seconds");
		assertEquals("land", player.stateSnapshot().mode, "thaw returns player to land mode");
	}

	private static function testBumpingCustomStatsBlockAppliesConfiguredStats():Void {
		var player = new LocalCharacter(customStatsBlockLevel("100-0-80"));

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().touchedBlockType == "custom_stats") {
				break;
			}
		}

		var state = player.stateSnapshot();
		assertEquals("custom_stats", state.touchedBlockType, "debug state reports custom stats block touch");
		assertClose(100, state.speedStat, "custom stats block applies speed stat");
		assertClose(0, state.accelerationStat, "custom stats block applies acceleration stat");
		assertClose(80, state.jumpStat, "custom stats block applies jump stat");
		assertClose(0.5, player.blockColorMultiplierAt(2, 1), "depleted custom stats block uses SupplyBlock grey transform");
		assertEquals(true, player.consumeStatsSelectSyncRequest(), "custom stats block requests TestCourse StatsSelect sync");
		assertEquals(false, player.consumeStatsSelectSyncRequest(), "custom stats sync request is consumed once");
	}

	private static function testBumpingResetCustomStatsBlockRestoresStartingStats():Void {
		var player = new LocalCharacter(customStatsResetLevel());

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().touchedBlockType == "custom_stats") {
				break;
			}
		}

		var state = player.stateSnapshot();
		assertEquals("custom_stats", state.touchedBlockType, "debug state reports reset custom stats block touch");
		assertClose(70, state.speedStat, "reset custom stats block restores starting speed stat");
		assertClose(40, state.accelerationStat, "reset custom stats block restores starting acceleration stat");
		assertClose(20, state.jumpStat, "reset custom stats block restores starting jump stat");
		assertClose(0.5, player.blockColorMultiplierAt(2, 1), "depleted reset custom stats block uses SupplyBlock grey transform");
		assertEquals(true, player.consumeStatsSelectSyncRequest(), "reset custom stats block requests TestCourse StatsSelect sync");
	}

	private static function testBumpingBrickBlockBreaksIt():Void {
		var level = supplyBlockLevel(BlockType.Brick);
		var player = bumpSupply(level, BlockType.Brick);
		var visualEvents = player.consumeBlockVisualEvents();
		assertEquals(3, visualEvents.length, "broken brick emits thump, activation, and piece events");
		assertEquals("BlockBumpSound", Std.string(visualEvents[0].kind), "broken brick uses base ThumpSound event");
		assertEquals("LocalActivate", Std.string(visualEvents[1].kind), "broken brick emits Flash localActivate event");
		assertEquals("", visualEvents[1].activationPayload, "brick localActivate payload is empty");
		assertEquals("BrickPieces", Std.string(visualEvents[2].kind), "broken brick uses brick pieces");
		assertEquals(6, visualEvents[2].count, "broken brick emits six pieces");
		player.step(new LocalPlayerInput(false, false, true));
		assertEquals(false, player.stateSnapshot().touchedBlockType == "brick", "broken brick no longer collides");
	}

	private static function testBumpingHappyBlockRaisesStats():Void {
		var player = bumpSupply(supplyBlockLevel(BlockType.Happy, "20"), BlockType.Happy);
		var state = player.stateSnapshot();
		assertClose(70, state.speedStat, "happy block raises speed by configured amount");
		assertClose(70, state.accelerationStat, "happy block raises acceleration");
		assertClose(70, state.jumpStat, "happy block raises jumping");
		assertClose(0.5, player.blockColorMultiplierAt(2, 1), "depleted happy block uses SupplyBlock grey transform");
		assertEquals(true, player.consumeStatsSelectSyncRequest(), "happy block requests TestCourse StatsSelect sync");
		var events = player.consumeBlockVisualEvents();
		assertEquals(2, events.length, "happy block emits thump and stat sound events");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "happy block keeps base ThumpSound event");
		assertEquals("HappyBlockSound", Std.string(events[1].kind), "happy block emits BumpHappySound event");
		player.step(new LocalPlayerInput(false, false, true));
		assertEquals(0, player.consumeBlockVisualEvents().length, "depleted happy block does not replay sound");
	}

	private static function testBumpingSadBlockLowersStats():Void {
		var player = bumpSupply(supplyBlockLevel(BlockType.Sad, "-20"), BlockType.Sad);
		var state = player.stateSnapshot();
		assertClose(30, state.speedStat, "sad block lowers speed by configured amount");
		assertClose(30, state.accelerationStat, "sad block lowers acceleration");
		assertClose(30, state.jumpStat, "sad block lowers jumping");
		assertClose(0.5, player.blockColorMultiplierAt(2, 1), "depleted sad block uses SupplyBlock grey transform");
		assertEquals(true, player.consumeStatsSelectSyncRequest(), "sad block requests TestCourse StatsSelect sync");
		var events = player.consumeBlockVisualEvents();
		assertEquals(2, events.length, "sad block emits thump and stat sound events");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "sad block keeps base ThumpSound event");
		assertEquals("SadBlockSound", Std.string(events[1].kind), "sad block emits BumpSadSound event");
		player.step(new LocalPlayerInput(false, false, true));
		assertEquals(0, player.consumeBlockVisualEvents().length, "depleted sad block does not replay sound");
	}

	private static function testBumpingHeartBlockAddsCappedLife():Void {
		var player = bumpSupply(supplyBlockLevel(BlockType.Heart), BlockType.Heart);
		assertEquals(4, player.stateSnapshot().lives, "heart block adds one life");
		assertClose(0.5, player.blockColorMultiplierAt(2, 1), "depleted heart block uses SupplyBlock grey transform");
	}

	private static function testBumpingTimeBlockAddsTenSeconds():Void {
		var player = bumpSupply(supplyBlockLevel(BlockType.Time), BlockType.Time);
		assertEquals(130, player.stateSnapshot().courseTime, "time block adds ten seconds");
		assertClose(0.5, player.blockColorMultiplierAt(2, 1), "depleted time block uses SupplyBlock grey transform");
		var events = player.consumeBlockVisualEvents();
		assertEquals(2, events.length, "time block emits thump and tick-tock sound events");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "time block keeps base ThumpSound event");
		assertEquals("TimeBlockSound", Std.string(events[1].kind), "time block emits TickTockSound event");
		player.step(new LocalPlayerInput(false, false, true));
		assertEquals(0, player.consumeBlockVisualEvents().length, "depleted time block does not replay TickTockSound");
	}

	private static function bumpSupply(level:Level, type:BlockType):LocalCharacter {
		var player = new LocalCharacter(level);
		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().touchedBlockType == type) break;
		}
		assertEquals(type, player.stateSnapshot().touchedBlockType, '$type block is bumped');
		return player;
	}

	private static function testTeleportBlockMovesPlayerToNextSameColorBlock():Void {
		var player = new LocalCharacter(teleportPairLevel());
		var state = player.stateSnapshot();

		assertEquals("teleport", state.touchedBlockType, "standing on teleport reports touched block");
		assertClose(135, state.x, "teleport moves player by matching block delta");
		assertClose(90, state.y, "teleport preserves feet offset relative to block");
		assertEquals(true, state.grounded, "player remains grounded after teleport");
	}

	private static function testTeleportBlockEmitsStartAndDestinationPops():Void {
		var player = new LocalCharacter(teleportPairLevel());
		var events = player.consumeBlockVisualEvents();
		var pops:Array<BlockVisualEvent> = [];
		for (event in events) {
			if (event.kind == TeleportBlockPop) {
				pops.push(event);
			}
		}

		assertEquals(2, pops.length, "teleport block emits start and destination pop events");
		assertClose(75, pops[0].hitX, "start teleport pop uses pre-teleport player x");
		assertClose(65, pops[0].hitY, "start teleport pop uses Flash y-25 offset");
		assertClose(135, pops[1].hitX, "destination teleport pop uses post-teleport player x");
		assertClose(65, pops[1].hitY, "destination teleport pop preserves Flash y-25 offset");
	}

	private static function testCrouchingTeleportBlockBumpPreservesPreBumpY():Void {
		var player = new LocalCharacter(lowTeleportCeilingLevel());
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}
		var crouched = player.stateSnapshot();
		assertEquals(true, crouched.crouching, "teleport ceiling block forces crouch before bump");
		assertClose(300, crouched.y, "crouched player starts with feet on the floor");

		player.step(new LocalPlayerInput(false, false, true));
		var teleported = player.stateSnapshot();

		assertEquals("teleport", teleported.touchedBlockType, "pressing up bumps the teleport ceiling block");
		assertClose(135, teleported.x, "crouched teleport bump moves to the paired block");
		assertClose(300, teleported.y, "crouched teleport bump restores pre-bump y before teleporting");
	}

	private static function testTeleportCooldownPreventsImmediateReturn():Void {
		var player = new LocalCharacter(teleportPairLevel());

		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}
		var state = player.stateSnapshot();

		assertClose(135, state.x, "teleport color cooldown prevents immediate return teleport");
		assertClose(90, state.y, "cooldown leaves player standing on destination block");
		assertEquals(true, state.grounded, "destination teleport supports player during cooldown");
	}

	private static function testTeleportCooldownTintsAndResetsSameColorBlocks():Void {
		var player = new LocalCharacter(teleportPairLevel());

		assertClose(0.5, player.blockColorMultiplierAt(2, 3), "used teleport tints during cooldown");
		assertClose(0.5, player.blockColorMultiplierAt(4, 3), "same-color destination teleport tints during cooldown");
		for (_ in 0...80) {
			player.step(new LocalPlayerInput());
		}
		assertClose(0.5, player.blockColorMultiplierAt(2, 3), "teleport cooldown stays tinted before reset");
		player.step(new LocalPlayerInput());
		assertClose(1, player.blockColorMultiplierAt(2, 3), "teleport cooldown reset clears used tint");
		assertClose(1, player.blockColorMultiplierAt(4, 3), "teleport cooldown reset clears destination tint");
	}

	private static function testTeleportDefaultColorOptionsMatchEmptyOptions():Void {
		var player = new LocalCharacter(teleportDefaultColorPairLevel());
		var state = player.stateSnapshot();

		assertEquals("teleport", state.touchedBlockType, "standing on empty-option teleport reports touched block");
		assertClose(135, state.x, "empty and explicit default-color teleports are paired");
		assertClose(0.5, player.blockColorMultiplierAt(2, 3), "empty default-color teleport tints during cooldown");
		assertClose(0.5, player.blockColorMultiplierAt(4, 3), "explicit default-color teleport tints during cooldown");
	}

	private static function testPreRacePositionResetClearsConstructorTeleportCooldown():Void {
		var player = new LocalCharacter(teleportPairLevel());
		player.resetControllerForRaceStart(75, 90);

		player.step(new LocalPlayerInput());
		var state = player.stateSnapshot();

		assertEquals("teleport", state.touchedBlockType, "pre-race reset lets the start teleport fire during gameplay");
		assertClose(135, state.x, "pre-race reset clears constructor-time teleport cooldown");
		assertClose(90, state.y, "teleport stand snaps feet to the block top");
	}

	private static function testStandingOnPushBlockMovesItDown():Void {
		var level = pushBlockLevel();
		var player = new LocalCharacter(level);
		var state = player.stateSnapshot();

		assertEquals("push", state.touchedBlockType, "standing on push block reports touched block");
		assertEquals(null, level.blockAt(2, 3), "push block leaves original tile");
		assertEquals(BlockType.Push, level.blockAt(2, 4).type, "push block moves one tile down");
		var events = player.consumeBlockVisualEvents();
		assertEquals(2, events.length, "push block emits activation and display movement events");
		assertEquals("LocalActivate", Type.enumConstructor(events[0].kind), "push block emits Flash localActivate event");
		assertEquals("down", events[0].activationPayload, "standing push payload is down");
		assertEquals("PushBlockMove", Type.enumConstructor(events[1].kind), "push block emits display movement event");
		assertEquals(2, events[1].tileX, "push block display event records source x");
		assertEquals(3, events[1].tileY, "push block display event records source y");
		assertEquals(2, events[1].toTileX, "push block display event records destination x");
		assertEquals(4, events[1].toTileY, "push block display event records destination y");
	}

	private static function testPushBlockMovesIntoDestroyedBrickTile():Void {
		var level = emptyLevel(1);
		var player = new LocalCharacter(level);
		var push = new LevelBlock(2, 3, BlockType.Push);
		level.blocks.push(push);
		level.blocks.push(new LevelBlock(3, 3, BlockType.Brick));
		assertEquals(true, player.applyRemoteBlockActivation(3, 3), "brick in front of push block can be destroyed");

		@:privateAccess player.controller.pushBlock(push, 1, 0);

		assertEquals(null, level.blockAt(2, 3), "push block leaves its source after destruction opens the destination");
		assertEquals(BlockType.Push, level.blockAt(3, 3).type, "push block enters the physically vacated tile");
	}

	private static function testPushBlockRecursivelyMovesDestinationPushBlock():Void {
		var level = pushBlockChainLevel();
		var player = new LocalCharacter(level);

		assertEquals("push", player.stateSnapshot().touchedBlockType, "standing on push-chain source reports touched block");
		assertEquals(null, level.blockAt(2, 3), "source push block leaves original tile");
		assertEquals(BlockType.Push, level.blockAt(2, 4).type, "source push block moves into destination push tile");
		assertEquals(BlockType.Push, level.blockAt(2, 5).type, "destination push block recursively moves first");
		var events = player.consumeBlockVisualEvents();
		assertEquals(3, events.length, "push chain emits activation plus both display movements");
		assertEquals("LocalActivate", Type.enumConstructor(events[0].kind), "push chain emits source localActivate first");
		assertEquals("PushBlockMove", Type.enumConstructor(events[1].kind), "push chain moves destination push block");
		assertEquals(2, events[1].tileX, "destination push display event records source x");
		assertEquals(4, events[1].tileY, "destination push display event records source y");
		assertEquals(2, events[1].toTileX, "destination push display event records destination x");
		assertEquals(5, events[1].toTileY, "destination push display event records destination y");
		assertEquals("PushBlockMove", Type.enumConstructor(events[2].kind), "push chain moves original push block after destination");
		assertEquals(2, events[2].tileX, "source push display event records source x");
		assertEquals(3, events[2].tileY, "source push display event records source y");
		assertEquals(2, events[2].toTileX, "source push display event records destination x");
		assertEquals(4, events[2].toTileY, "source push display event records destination y");
	}

	private static function testTimedMoveBlockShiftsAfterPreview():Void {
		var level = timedMoveBlockLevel("right", false);
		var harness = timedMoveHarness(level);
		var player = harness.player;

		harness.clock.advance(999);
		player.step(new LocalPlayerInput());
		assertEquals(BlockType.Move, level.blockAt(2, 3).type, "move block waits through arrow preview");

		harness.clock.advance(1);
		player.step(new LocalPlayerInput());
		assertEquals(null, level.blockAt(2, 3), "move block leaves original tile after one second");
		assertEquals(BlockType.Move, level.blockAt(3, 3).type, "move block shifts one tile in chosen direction");
	}

	private static function testTimedMoveBlockRecursivelyMovesDestinationPushBlock():Void {
		var level = timedMovePushChainLevel();
		var harness = timedMoveHarness(level);
		var player = harness.player;

		harness.clock.advance(1000);
		player.step(new LocalPlayerInput());

		assertEquals(null, level.blockAt(2, 3), "move block leaves original tile after pushing chain");
		assertEquals(BlockType.Move, level.blockAt(3, 3).type, "move block moves into destination push tile");
		assertEquals(BlockType.Push, level.blockAt(4, 3).type, "destination push block moves one tile right");
		var events = player.consumeBlockVisualEvents();
		assertEquals(2, events.length, "Flash move chain emits only the two display movements");
		assertEquals("PushBlockMove", Type.enumConstructor(events[0].kind), "move block chain moves push block first");
		assertEquals(3, events[0].tileX, "move-block destination push source x");
		assertEquals(3, events[0].tileY, "move-block destination push source y");
		assertEquals(4, events[0].toTileX, "move-block destination push target x");
		assertEquals(3, events[0].toTileY, "move-block destination push target y");
		assertEquals("PushBlockMove", Type.enumConstructor(events[1].kind), "move block chain moves original move block second");
		assertEquals(2, events[1].tileX, "move-block source x");
		assertEquals(3, events[1].tileY, "move-block source y");
		assertEquals(3, events[1].toTileX, "move-block target x");
		assertEquals(3, events[1].toTileY, "move-block target y");
	}

	private static function testTimedMoveBlockPreviewDirections():Void {
		var level = timedMoveBlockLevel("right", false);
		var harness = timedMoveHarness(level);
		var player = harness.player;

		assertEquals(2, player.activeMoveBlockDirections().get("2,3"), "move block exposes right arrow during preview");
		harness.clock.advance(1000);
		player.step(new LocalPlayerInput());
		assertEquals(false, player.activeMoveBlockDirections().exists("2,3"), "move block arrow clears after shifting");

		harness.clock.advance(4999);
		player.step(new LocalPlayerInput());
		assertEquals(false, player.activeMoveBlockDirections().exists("3,3"), "move block keeps its arrow hidden for five seconds after shifting");
		harness.clock.advance(1);
		player.step(new LocalPlayerInput());
		assertEquals(false, player.activeMoveBlockDirections().exists("3,3"), "Flash's clamped cadence correction keeps the arrow hidden for one extra millisecond");
		harness.clock.advance(1);
		player.step(new LocalPlayerInput());
		assertEquals(2, player.activeMoveBlockDirections().get("3,3"), "move block exposes arrow again after reselect");
	}

	private static function testUnconfiguredMoveBlocksUseFlashRandomDirections():Void {
		var player = new LocalCharacter(randomMoveBlockLevel());
		var directions = player.activeMoveBlockDirections();

		assertEquals(0, directions.get("1,1"), "first random move block uses Flash seed");
		assertEquals(0, directions.get("2,1"), "second random move block uses Flash seed");
		assertEquals(1, directions.get("3,1"), "third random move block uses Flash seed");
		assertEquals(3, directions.get("4,1"), "fourth random move block uses Flash seed");
		assertEquals(2, directions.get("5,1"), "fifth random move block uses Flash seed");
	}

	private static function testTimedMoveBlockWaitsWhenDestinationBlocked():Void {
		var level = timedMoveBlockLevel("right", true);
		var harness = timedMoveHarness(level);
		var player = harness.player;

		harness.clock.advance(1000);
		player.step(new LocalPlayerInput());

		assertEquals(BlockType.Move, level.blockAt(2, 3).type, "blocked move block stays in place");
		assertEquals(BlockType.Solid, level.blockAt(3, 3).type, "blocking tile remains occupied");
	}

	private static function testTimedMoveBlockWaitsWhenDestinationOccupied():Void {
		var level = timedMoveBlockLevel("up", false);
		var harness = timedMoveHarness(level);
		var player = harness.player;

		harness.clock.advance(1000);
		player.step(new LocalPlayerInput());

		assertEquals(BlockType.Move, level.blockAt(2, 3).type, "move block does not shift into the player");
		assertEquals(null, level.blockAt(2, 2), "occupied destination stays free of moving blocks");
	}

	private static function testBumpingRotateBlockPutsPlayerInFreezeState():Void {
		var player = new LocalCharacter(rotateBlockLevel(BlockType.RotateRight));

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().mode == "freeze") {
				break;
			}
		}

		var state = player.stateSnapshot();
		assertEquals("rotate_right", state.touchedBlockType, "debug state reports rotate block touch");
		assertEquals("freeze", state.mode, "rotate block bump pauses character physics");
		assertEquals("jump", state.animation, "rotate pause preserves the pre-bump animation instead of showing freeze-ray ice");
		assertClose(0, state.vx, "rotate block clears horizontal velocity");
		assertClose(0, state.vy, "rotate block clears vertical velocity");
	}

	private static function testWaterTouchDoesNotCancelRotation():Void {
		var level = rotateBlockLevel(BlockType.RotateLeft);
		level.blocks.push(new LevelBlock(2, 2, BlockType.Water));
		level.blocks.push(new LevelBlock(2, 3, BlockType.Water));
		var player = new LocalCharacter(level);
		player.setControllerPosition(75, 120);
		@:privateAccess player.controller.vy = -10;

		player.step(new LocalPlayerInput());
		assertEquals("water", player.stateSnapshot().touchedBlockType, "regression frame includes the adjacent water touch");
		assertEquals("freeze", player.stateSnapshot().mode, "same-frame water touch preserves rotate pause");

		for (_ in 0...30) {
			player.step(new LocalPlayerInput());
		}
		assertEquals(-90, player.stateSnapshot().courseRotation, "water-backed rotate block completes its rotation");
		assertEquals("land", player.stateSnapshot().mode, "completed water-backed rotation resumes land physics");
	}

	private static function testWaterBelowGapDoesNotStrandRotation():Void {
		var level = rotateBlockLevel(BlockType.RotateRight);
		// Rotate block at y=1, empty y=2, water at y=3: the player swims upward
		// through the gap and reaches the rotate block as the water linger expires.
		level.blocks.splice(1, 1); // remove the helper fixture's solid below the water
		level.blocks.push(new LevelBlock(2, 3, BlockType.Water));
		var player = new LocalCharacter(level);
		var bumped = false;
		for (_ in 0...60) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().mode == "freeze") {
				bumped = true;
				break;
			}
		}
		assertEquals(true, bumped, "water-gap setup reaches the rotate block");
		assertEquals("freeze", player.stateSnapshot().mode, "expiring water linger cannot cancel the rotate pause");
		assertEquals("swim", player.stateSnapshot().animation, "water-gap rotate pause does not borrow the freeze-ray animation");

		for (_ in 0...30) player.step(new LocalPlayerInput());
		assertEquals(90, player.stateSnapshot().courseRotation, "water-gap rotation completes instead of leaving a stale rotation lock");
		@:privateAccess assertEquals(0, player.controller.rotateFramesRemaining, "completed water-gap rotation allows later rotate blocks");
	}

	private static function testRotateRightCompletesCourseRotation():Void {
		var player = bumpRotateBlock(BlockType.RotateRight);
		var frozen = player.stateSnapshot();

		for (_ in 0...29) {
			player.step(new LocalPlayerInput());
		}
		assertEquals("freeze", player.stateSnapshot().mode, "right rotation keeps player paused before final frame");

		player.step(new LocalPlayerInput());
		var state = player.stateSnapshot();
		assertEquals("land", state.mode, "right rotation returns player to land mode");
		assertEquals(90, state.courseRotation, "right rotation advances course rotation");
		assertClose(-frozen.y, state.x, "right rotation maps x from frozen y");
		assertClose(frozen.x, state.y, "right rotation maps y from frozen x");
	}

	private static function testRotateLeftCompletesCourseRotation():Void {
		var player = bumpRotateBlock(BlockType.RotateLeft);
		var frozen = player.stateSnapshot();

		for (_ in 0...30) {
			player.step(new LocalPlayerInput());
		}

		var state = player.stateSnapshot();
		assertEquals("land", state.mode, "left rotation returns player to land mode");
		assertEquals(-90, state.courseRotation, "left rotation decreases course rotation");
		assertClose(frozen.y, state.x, "left rotation maps x from frozen y");
		assertClose(-frozen.x, state.y, "left rotation maps y from frozen x");
	}

	private static function testRotationTweenMatchesCourseFrames():Void {
		var player = bumpRotateBlock(BlockType.RotateRight);
		player.step(new LocalPlayerInput());
		assertEquals(3, player.courseTweenRotation, "course tween advances three degrees per frame");
		assertEquals(-3, player.characterRotation, "character counters the course tween");

		for (_ in 0...28) {
			player.step(new LocalPlayerInput());
		}
		assertEquals(87, player.courseTweenRotation, "course reaches 87 degrees before the final frame");
		assertEquals(-87, player.characterRotation, "character counter-rotation reaches -87 degrees");

		player.step(new LocalPlayerInput());
		assertEquals(0, player.courseTweenRotation, "completed tween resets the course container");
		assertEquals(0, player.characterRotation, "completed tween resets character rotMod");
	}

	private static function testRotationMapsSafePosition():Void {
		var player = bumpRotateBlock(BlockType.RotateRight);
		var initialSafeX = player.lastSafeX;
		var initialSafeY = player.lastSafeY;
		for (_ in 0...30) {
			player.step(new LocalPlayerInput());
		}
		assertClose(-initialSafeY, player.lastSafeX, "right rotation maps the last-safe x coordinate");
		assertClose(initialSafeX, player.lastSafeY, "right rotation maps the last-safe y coordinate");
	}

	private static function testRotatedSafeSpotUsesDisplayedBlockPosition():Void {
		var level = rotatedRecoveryLevel();
		var player = new LocalCharacter(level);
		@:privateAccess player.controller.courseRotation = 90;

		var floor = level.blockAt(2, 4);
		@:privateAccess player.controller.updateSafeSpot(floor, false);
		assertClose(-135, player.lastSafeX, "rotated solid saves the center of its displayed top edge");
		assertClose(60, player.lastSafeY, "rotated solid saves its displayed top edge");

		var water = level.blockAt(1, 2);
		@:privateAccess player.controller.updateSafeSpot(water, true);
		assertClose(-75, player.lastSafeX, "rotated water saves its displayed center x");
		assertClose(45, player.lastSafeY, "rotated water saves its displayed center y");
	}

	private static function testRotatedSafetyAndMapReturnsUseRotatedSafeSpot():Void {
		var level = rotatedRecoveryLevel();
		var player = new LocalCharacter(level);
		@:privateAccess player.controller.courseRotation = 90;
		@:privateAccess player.controller.updateSafeSpot(level.blockAt(2, 4), false);

		@:privateAccess player.controller.touchAt(-105, 105, "rotatedSafetyTest");
		var state = player.stateSnapshot();
		assertClose(-135, state.x, "rotated safety net restores displayed checkpoint x");
		assertClose(60, state.y, "rotated safety net restores displayed checkpoint y");

		player.setControllerPosition(-135, 10000);
		player.step(new LocalPlayerInput());
		state = player.stateSnapshot();
		assertClose(-135, state.x, "rotated map return restores displayed checkpoint x");
		assertClose(60, state.y, "rotated map return restores displayed checkpoint y");
	}

	private static function testCollisionSnapsAgainstRotatedCeiling():Void {
		var level = rotateBlockLevel(BlockType.RotateRight);
		level.blocks.push(new LevelBlock(4, 3, BlockType.Solid));
		level.blocks.push(new LevelBlock(1, 3, BlockType.Solid));
		var player = new LocalCharacter(level);

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().mode == "freeze") {
				break;
			}
		}
		for (_ in 0...60) {
			player.step(new LocalPlayerInput());
			if (player.stateSnapshot().grounded) {
				break;
			}
		}

		var bumped = false;
		for (_ in 0...30) {
			player.step(new LocalPlayerInput(false, false, true));
			var state = player.stateSnapshot();
			if (state.touchedBlockType == "solid" && state.y > 100) {
				bumped = true;
				assertClose(115, state.y, "rotated ceiling bump snaps below its displayed edge");
				break;
			}
		}
		assertEquals(true, bumped, "player bumps the ceiling after course rotation");
	}

	private static function testCollisionStopsLeftMovementAfterRotation():Void {
		var level = rotateBlockLevel(BlockType.RotateRight);
		for (tileX in 3...12) {
			level.blocks.push(new LevelBlock(tileX, 4, BlockType.Solid));
		}
		var player = new LocalCharacter(level);

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().mode == "freeze") {
				break;
			}
		}
		for (_ in 0...30) {
			player.step(new LocalPlayerInput());
		}

		for (_ in 0...20) {
			player.step(new LocalPlayerInput(true));
		}

		var state = player.stateSnapshot();
		assertBelow(-111, state.x, "rotated wall stops left movement at its displayed edge");
	}

	private static function testArrowPushUsesRotatedCourseDirection():Void {
		var level = rotateBlockLevel(BlockType.RotateRight);
		level.blocks.push(new LevelBlock(3, 4, BlockType.ArrowRight));
		var player = new LocalCharacter(level);

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().mode == "freeze") {
				break;
			}
		}
		for (_ in 0...30) {
			player.step(new LocalPlayerInput());
		}

		for (_ in 0...30) {
			player.step(new LocalPlayerInput(true));
			if (player.stateSnapshot().touchedBlockType == "arrow_right") {
				break;
			}
		}

		var state = player.stateSnapshot();
		assertEquals("arrow_right", state.touchedBlockType, "scripted run reaches rotated arrow block");
		assertBelow(-state.vy, -5, "right arrow rotated 90 degrees pushes down like Flash");
		assertBelow(state.vx, 1, "rotated right arrow no longer pushes along unrotated right");
	}

	private static function testPushBlockUsesRotatedCourseDirection():Void {
		var level = rotateBlockLevel(BlockType.RotateRight);
		level.blocks.push(new LevelBlock(3, 4, BlockType.Push));
		var player = new LocalCharacter(level);

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().mode == "freeze") {
				break;
			}
		}
		var pushEvent:Null<BlockVisualEvent> = null;
		for (_ in 0...30) {
			player.step(new LocalPlayerInput());
		}
		for (_ in 0...30) {
			player.step(new LocalPlayerInput(true));
			for (event in player.consumeBlockVisualEvents()) {
				if (Type.enumConstructor(event.kind) == "PushBlockMove") {
					pushEvent = event;
					break;
				}
			}
			if (pushEvent != null) {
				break;
			}
		}

		assertEquals(90, player.stateSnapshot().courseRotation, "test course is rotated right");
		assertEquals("PushBlockMove", Type.enumConstructor(pushEvent.kind), "rotated push block emits movement");
		assertEquals(3, pushEvent.tileX, "rotated push block source x");
		assertEquals(4, pushEvent.tileY, "rotated push block source y");
		assertEquals(3, pushEvent.toTileX, "right-rotated left push keeps x");
		assertEquals(5, pushEvent.toTileY, "right-rotated left push maps to +y");
	}

	private static function bumpRotateBlock(type:BlockType):LocalCharacter {
		var player = new LocalCharacter(rotateBlockLevel(type));
		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().mode == "freeze") {
				return player;
			}
		}
		throw "rotate block was not bumped";
	}

	private static function newPlayer():LocalCharacter {
		return new LocalCharacter(LevelParser.parse(File.getContent("test/fixtures/flat-level.json")));
	}

	private static function collectItem(level:Level, itemId:Int):LocalCharacter {
		var player = new LocalCharacter(level);
		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.stateSnapshot().itemId == itemId) {
				return player;
			}
		}
		throw 'item $itemId was not collected';
	}

	private static function makeItemAvailable(player:LocalCharacter):Void {
		player.step(new LocalPlayerInput());
	}

	private static function stepFrames(player:LocalCharacter, frames:Int):Void {
		for (_ in 0...frames) {
			player.step(new LocalPlayerInput());
		}
	}

	// Start tile is in open air above a deep water column on a solid floor, so a
	// dropped player falls in, swims, and can paddle back out the top.
	private static function waterPoolLevel():Level {
		var blocks:Array<LevelBlock> = [];
		for (tileY in 2...10) {
			blocks.push(new LevelBlock(2, tileY, BlockType.Water));
		}
		blocks.push(new LevelBlock(2, 10, BlockType.Solid));
		return new Level(
			"water-pool",
			"Water Pool",
			6,
			13,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 0),
			new TilePosition(5, 11),
			blocks
		);
	}

	private static function emptyLevel(gravity:Float):Level {
		return new Level(
			"empty",
			"Empty",
			10,
			10,
			30,
			gravity,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(8, 8),
			[]
		);
	}

	private static function singleBlockLevel(type:BlockType):Level {
		return new Level(
			"single-block",
			"Single Block",
			5,
			5,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(3, 2),
			[
				new LevelBlock(2, 3, type),
				new LevelBlock(3, 3, BlockType.Finish)
			]
		);
	}

	private static function lowCeilingLevel():Level {
		return new Level(
			"low-ceiling",
			"Low Ceiling",
			6,
			13,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 9),
			new TilePosition(4, 9),
			[
				new LevelBlock(2, 8, BlockType.Basic),
				new LevelBlock(0, 10, BlockType.Basic),
				new LevelBlock(1, 10, BlockType.Basic),
				new LevelBlock(2, 10, BlockType.Basic),
				new LevelBlock(3, 10, BlockType.Basic),
				new LevelBlock(4, 10, BlockType.Basic),
				new LevelBlock(5, 10, BlockType.Basic),
				new LevelBlock(4, 9, BlockType.Finish)
			]
		);
	}

	private static function lowItemCeilingLevel(type:BlockType = BlockType.Item, options:String = "4"):Level {
		return new Level(
			"low-item-ceiling",
			"Low Item Ceiling",
			6,
			13,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 9),
			new TilePosition(4, 9),
			[
				new LevelBlock(2, 8, type, options),
				new LevelBlock(0, 10, BlockType.Basic),
				new LevelBlock(1, 10, BlockType.Basic),
				new LevelBlock(2, 10, BlockType.Basic),
				new LevelBlock(3, 10, BlockType.Basic),
				new LevelBlock(4, 10, BlockType.Basic),
				new LevelBlock(5, 10, BlockType.Basic),
				new LevelBlock(4, 9, BlockType.Finish)
			]
		);
	}

	private static function lowTeleportCeilingLevel():Level {
		return new Level(
			"low-teleport-ceiling",
			"Low Teleport Ceiling",
			6,
			13,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 9),
			new TilePosition(5, 9),
			[
				new LevelBlock(2, 8, BlockType.Teleport, "255"),
				new LevelBlock(4, 8, BlockType.Teleport, "255"),
				new LevelBlock(0, 10, BlockType.Basic),
				new LevelBlock(1, 10, BlockType.Basic),
				new LevelBlock(2, 10, BlockType.Basic),
				new LevelBlock(3, 10, BlockType.Basic),
				new LevelBlock(4, 10, BlockType.Basic),
				new LevelBlock(5, 10, BlockType.Basic),
				new LevelBlock(5, 9, BlockType.Finish)
			]
		);
	}

	private static function mineBlockLevel():Level {
		return new Level(
			"mine-block",
			"Mine Block",
			5,
			5,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(3, 2),
			[
				new LevelBlock(2, 3, BlockType.Mine),
				new LevelBlock(3, 3, BlockType.Finish)
			]
		);
	}

	private static function delayedMineBlockLevel():Level {
		return new Level(
			"delayed-mine-block",
			"Delayed Mine Block",
			5,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 1),
			new TilePosition(3, 4),
			[
				new LevelBlock(2, 3, BlockType.Mine),
				new LevelBlock(3, 4, BlockType.Finish)
			]
		);
	}

	private static function safetyDropLevel():Level {
		return new Level(
			"safety-drop",
			"Safety Drop",
			10,
			13,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(4, 10),
			[
				new LevelBlock(2, 3, BlockType.Solid),
				new LevelBlock(5, 7, BlockType.Safety),
				new LevelBlock(6, 7, BlockType.Safety),
				new LevelBlock(7, 7, BlockType.Safety),
				new LevelBlock(8, 7, BlockType.Safety),
				new LevelBlock(4, 10, BlockType.Finish)
			]
		);
	}

	private static function safetyOverFloorLevel():Level {
		return new Level(
			"safety-over-floor",
			"Safety Over Floor",
			10,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 4),
			new TilePosition(8, 4),
			[
				new LevelBlock(1, 5, BlockType.Solid),
				new LevelBlock(2, 5, BlockType.Solid),
				new LevelBlock(3, 5, BlockType.Solid),
				new LevelBlock(4, 5, BlockType.Solid),
				new LevelBlock(5, 5, BlockType.Solid),
				new LevelBlock(6, 5, BlockType.Solid),
				new LevelBlock(7, 5, BlockType.Solid),
				new LevelBlock(8, 5, BlockType.Solid),
				new LevelBlock(5, 4, BlockType.Safety),
				new LevelBlock(5, 3, BlockType.Safety)
			]
		);
	}

	private static function itemBlockLevel(type:BlockType):Level {
		return new Level(
			"item-block",
			"Item Block",
			5,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 3),
			new TilePosition(4, 4),
			[
				new LevelBlock(2, 1, type, "4"),
				new LevelBlock(2, 4, BlockType.Solid),
				new LevelBlock(4, 4, BlockType.Finish)
			]
		);
	}

	private static function superJumpItemLevel():Level {
		return new Level(
			"super-jump-item",
			"Super Jump Item",
			5,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 5),
			new TilePosition(4, 6),
			[
				new LevelBlock(2, 3, BlockType.Item, "5"),
				new LevelBlock(2, 6, BlockType.Solid),
				new LevelBlock(3, 6, BlockType.Solid),
				new LevelBlock(4, 6, BlockType.Finish)
			]
		);
	}

	private static function superJumpWaterClipLevel():Level {
		return new Level(
			"super-jump-water-clip",
			"Super Jump Water Clip",
			5,
			7,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 5),
			new TilePosition(4, 5),
			[
				new LevelBlock(2, 2, BlockType.Basic),
				new LevelBlock(2, 3, BlockType.Water),
				new LevelBlock(4, 5, BlockType.Finish)
			]
		);
	}

	private static function teleportItemLevel(blocked:Bool):Level {
		var blocks:Array<LevelBlock> = [
			new LevelBlock(2, 3, BlockType.Item, "4"),
			new LevelBlock(2, 6, BlockType.Solid),
			new LevelBlock(3, 6, BlockType.Solid),
			new LevelBlock(4, 6, BlockType.Solid),
			new LevelBlock(5, 6, BlockType.Solid),
			new LevelBlock(6, 6, BlockType.Solid),
			new LevelBlock(8, 6, BlockType.Finish)
		];
		if (blocked) {
			blocks.push(new LevelBlock(7, 5, BlockType.Solid));
		}
		return new Level(
			"teleport-item",
			"Teleport Item",
			10,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 5),
			new TilePosition(8, 6),
			blocks
		);
	}

	private static function speedBurstItemLevel():Level {
		return new Level(
			"speed-burst-item",
			"Speed Burst Item",
			12,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 5),
			new TilePosition(10, 6),
			[
				new LevelBlock(2, 3, BlockType.Item, "7"),
				new LevelBlock(2, 6, BlockType.Solid),
				new LevelBlock(3, 6, BlockType.Solid),
				new LevelBlock(4, 6, BlockType.Solid),
				new LevelBlock(5, 6, BlockType.Solid),
				new LevelBlock(6, 6, BlockType.Solid),
				new LevelBlock(7, 6, BlockType.Solid),
				new LevelBlock(8, 6, BlockType.Solid),
				new LevelBlock(9, 6, BlockType.Solid),
				new LevelBlock(10, 6, BlockType.Finish)
			]
		);
	}

	private static function speedBurstComparisonLevel():Level {
		return new Level(
			"speed-burst-comparison",
			"Speed Burst Comparison",
			12,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 5),
			new TilePosition(10, 6),
			[
				new LevelBlock(2, 6, BlockType.Solid),
				new LevelBlock(3, 6, BlockType.Solid),
				new LevelBlock(4, 6, BlockType.Solid),
				new LevelBlock(5, 6, BlockType.Solid),
				new LevelBlock(6, 6, BlockType.Solid),
				new LevelBlock(7, 6, BlockType.Solid),
				new LevelBlock(8, 6, BlockType.Solid),
				new LevelBlock(9, 6, BlockType.Solid),
				new LevelBlock(10, 6, BlockType.Finish)
			]
		);
	}

	private static function jetPackItemLevel():Level {
		return new Level(
			"jet-pack-item",
			"Jet Pack Item",
			6,
			12,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 8),
			new TilePosition(5, 10),
			[
				new LevelBlock(2, 6, BlockType.Item, "6"),
				new LevelBlock(2, 9, BlockType.Solid),
				new LevelBlock(3, 9, BlockType.Solid),
				new LevelBlock(5, 10, BlockType.Finish)
			]
		);
	}

	private static function heldItemLevel(itemId:Int):Level {
		return new Level(
			'held-item-$itemId',
			'Held Item $itemId',
			8,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 5),
			new TilePosition(7, 6),
			[
				new LevelBlock(2, 3, BlockType.Item, Std.string(itemId)),
				new LevelBlock(2, 6, BlockType.Solid),
				new LevelBlock(3, 6, BlockType.Solid),
				new LevelBlock(4, 6, BlockType.Solid),
				new LevelBlock(5, 6, BlockType.Solid),
				new LevelBlock(6, 6, BlockType.Solid),
				new LevelBlock(7, 6, BlockType.Finish)
			]
		);
	}

	private static function heldItemWithTargetBlockLevel(itemId:Int, targetType:BlockType = BlockType.Solid, targetX:Int = 4):Level {
		var level = heldItemLevel(itemId);
		level.blocks.push(new LevelBlock(targetX, 5, targetType));
		return level;
	}

	private static function blockedMineItemLevel():Level {
		var level = heldItemLevel(2);
		level.blocks.push(new LevelBlock(3, 4, BlockType.Solid));
		level.blocks.push(new LevelBlock(3, 5, BlockType.Solid));
		return level;
	}

	private static function jetPackComparisonLevel():Level {
		return new Level(
			"jet-pack-comparison",
			"Jet Pack Comparison",
			6,
			12,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 8),
			new TilePosition(5, 10),
			[
				new LevelBlock(2, 9, BlockType.Solid),
				new LevelBlock(3, 9, BlockType.Solid),
				new LevelBlock(5, 10, BlockType.Finish)
			]
		);
	}

	private static function customStatsBlockLevel(options:String):Level {
		return new Level(
			"custom-stats-block",
			"Custom Stats Block",
			5,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 3),
			new TilePosition(4, 4),
			[
				new LevelBlock(2, 1, BlockType.CustomStats, options),
				new LevelBlock(2, 4, BlockType.Solid),
				new LevelBlock(4, 4, BlockType.Finish)
			]
		);
	}

	private static function supplyBlockLevel(type:BlockType, options:String = ""):Level {
		return new Level(
			"supply-block",
			"Supply Block",
			5,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 3),
			new TilePosition(4, 4),
			[
				new LevelBlock(2, 1, type, options),
				new LevelBlock(2, 4, BlockType.Solid),
				new LevelBlock(4, 4, BlockType.Finish)
			]
		);
	}

	private static function finishBumpLevel():Level {
		return new Level(
			"finish-bump",
			"Finish Bump",
			6,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(3, 3),
			new TilePosition(3, 1),
			[
				new LevelBlock(3, 1, BlockType.Finish),
				new LevelBlock(3, 4, BlockType.Solid)
			]
		);
	}

	private static function customStatsResetLevel():Level {
		return new Level(
			"custom-stats-reset",
			"Custom Stats Reset",
			5,
			6,
			30,
			1,
			new StatDefaults(70, 0.2 + 40 / 60, 2 + 20 / 40),
			new TilePosition(2, 3),
			new TilePosition(4, 4),
			[
				new LevelBlock(2, 1, BlockType.CustomStats, "reset"),
				new LevelBlock(2, 4, BlockType.Solid),
				new LevelBlock(4, 4, BlockType.Finish)
			]
		);
	}

	private static function teleportPairLevel():Level {
		return new Level(
			"teleport-pair",
			"Teleport Pair",
			7,
			5,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 2),
			[
				new LevelBlock(2, 3, BlockType.Teleport, "255"),
				new LevelBlock(4, 3, BlockType.Teleport, "255"),
				new LevelBlock(6, 3, BlockType.Finish)
			]
		);
	}

	private static function teleportDefaultColorPairLevel():Level {
		return new Level(
			"teleport-default-color-pair",
			"Teleport Default Color Pair",
			7,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 2),
			[
				new LevelBlock(2, 3, BlockType.Teleport, ""),
				new LevelBlock(4, 3, BlockType.Teleport, "16744272"),
				new LevelBlock(6, 3, BlockType.Finish)
			]
		);
	}

	private static function pushBlockLevel():Level {
		return new Level(
			"push-block",
			"Push Block",
			5,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(4, 4),
			[
				new LevelBlock(2, 3, BlockType.Push),
				new LevelBlock(4, 4, BlockType.Finish)
			]
		);
	}

	private static function pushBlockChainLevel():Level {
		return new Level(
			"push-block-chain",
			"Push Block Chain",
			5,
			7,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(4, 5),
			[
				new LevelBlock(2, 3, BlockType.Push),
				new LevelBlock(2, 4, BlockType.Push),
				new LevelBlock(4, 5, BlockType.Finish)
			]
		);
	}

	private static function timedMoveBlockLevel(direction:String, blocked:Bool):Level {
		var blocks:Array<LevelBlock> = [
			new LevelBlock(2, 3, BlockType.Move, direction),
			new LevelBlock(4, 4, BlockType.Finish)
		];
		if (blocked) {
			blocks.push(new LevelBlock(3, 3, BlockType.Solid));
		}
		return new Level(
			"timed-move-block",
			"Timed Move Block",
			6,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(4, 4),
			blocks
		);
	}

	private static function timedMoveHarness(level:Level):{player:LocalCharacter, clock:ManualClock} {
		var clock = new ManualClock();
		var blockController = new BlockController(level, clock.read);
		var player = new LocalCharacter(level, 1, 1, 1, 1, blockController);
		blockController.startGameplay();
		return {player: player, clock: clock};
	}

	private static function timedMovePushChainLevel():Level {
		return new Level(
			"timed-move-push-chain",
			"Timed Move Push Chain",
			6,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(1, 2),
			new TilePosition(5, 4),
			[
				new LevelBlock(2, 3, BlockType.Move, "right"),
				new LevelBlock(3, 3, BlockType.Push),
				new LevelBlock(5, 4, BlockType.Finish)
			]
		);
	}

	private static function randomMoveBlockLevel():Level {
		return new Level(
			"random-move-blocks",
			"Random Move Blocks",
			8,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 4),
			[
				new LevelBlock(1, 1, BlockType.Move),
				new LevelBlock(2, 1, BlockType.Move),
				new LevelBlock(3, 1, BlockType.Move),
				new LevelBlock(4, 1, BlockType.Move),
				new LevelBlock(5, 1, BlockType.Move),
				new LevelBlock(6, 4, BlockType.Finish)
			]
		);
	}

	private static function itemAndRandomMoveBlockLevel():Level {
		return new Level(
			"item-and-random-move-blocks",
			"Item And Random Move Blocks",
			8,
			13,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 9),
			new TilePosition(6, 10),
			[
				new LevelBlock(1, 1, BlockType.Move),
				new LevelBlock(2, 1, BlockType.Move),
				new LevelBlock(3, 1, BlockType.Move),
				new LevelBlock(4, 1, BlockType.Move),
				new LevelBlock(5, 1, BlockType.Move),
				new LevelBlock(2, 8, BlockType.Item, "3-4-5"),
				new LevelBlock(0, 10, BlockType.Basic),
				new LevelBlock(1, 10, BlockType.Basic),
				new LevelBlock(2, 10, BlockType.Basic),
				new LevelBlock(3, 10, BlockType.Basic),
				new LevelBlock(4, 10, BlockType.Basic),
				new LevelBlock(5, 10, BlockType.Basic),
				new LevelBlock(6, 10, BlockType.Finish)
			]
		);
	}

	private static function rotateBlockLevel(type:BlockType):Level {
		return new Level(
			"rotate-block",
			"Rotate Block",
			5,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 3),
			new TilePosition(4, 4),
			[
				new LevelBlock(2, 1, type),
				new LevelBlock(2, 4, BlockType.Solid),
				new LevelBlock(4, 4, BlockType.Finish)
			]
		);
	}

	private static function rotatedRecoveryLevel():Level {
		return new Level(
			"rotated-recovery",
			"Rotated Recovery",
			6,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 3),
			new TilePosition(5, 5),
			[
				new LevelBlock(2, 4, BlockType.Solid),
				new LevelBlock(1, 2, BlockType.Water),
				new LevelBlock(3, 3, BlockType.Safety)
			]
		);
	}

	private static function crumbleDropLevel():Level {
		return new Level(
			"crumble-drop",
			"Crumble Drop",
			5,
			17,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 0),
			new TilePosition(4, 12),
			[
				new LevelBlock(2, 12, BlockType.Crumble),
				new LevelBlock(2, 13, BlockType.Solid)
			]
		);
	}

	private static function cheeseSideCrumbleLevel():Level {
		return new Level(
			"cheese-side-crumble",
			"Cheese Side Crumble",
			7,
			7,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 4),
			new TilePosition(6, 5),
			[
				new LevelBlock(2, 5, BlockType.Solid),
				new LevelBlock(3, 5, BlockType.Solid),
				new LevelBlock(4, 3, BlockType.Crumble),
				new LevelBlock(4, 4, BlockType.Crumble),
				new LevelBlock(4, 5, BlockType.Solid),
				new LevelBlock(6, 5, BlockType.Finish)
			]
		);
	}

	private static function vanishReappearLevel():Level {
		return new Level(
			"vanish-reappear",
			"Vanish Reappear",
			5,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(4, 6),
			[
				new LevelBlock(2, 3, BlockType.Vanish),
				new LevelBlock(2, 6, BlockType.Solid)
			]
		);
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertClose(expected:Float, actual:Float, message:String, tolerance:Float = 0.001):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function flashCoordinate(value:Float):Float {
		return Math.floor(value * 20) / 20;
	}

	private static function assertBelow(actual:Float, maximum:Float, message:String):Void {
		assertions++;
		if (actual >= maximum) {
			throw '$message: expected $actual below $maximum';
		}
	}

	private static function assertAbove(actual:Float, minimum:Float, message:String):Void {
		assertions++;
		if (actual <= minimum) {
			throw '$message: expected $actual above $minimum';
		}
	}
}

private class ManualClock {
	private var nowMs:Float = 0;

	public function new() {}

	public function read():Float {
		return nowMs;
	}

	public function advance(milliseconds:Float):Void {
		nowMs += milliseconds;
	}
}
