package pr2.harness;

import pr2.character.LocalCharacter;
import pr2.level.LevelFixtureParser;
import pr2.level.BlockType;
import pr2.level.FixtureLevel;
import pr2.level.FixtureLevel.LevelBlock;
import pr2.level.FixtureLevel.StatDefaults;
import pr2.level.FixtureLevel.TilePosition;
import sys.io.File;

class LocalPlayerControllerTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testStartBlockHasNoCollision();
		testSideCollisionDoesNotFinishRace();
		testBumpingFinishBlockFinishesRaceOnce();
		testJumpAndLandOnFlatFixture();
		testGravityUsesFlashMultiplierAndSupportsRuntimeChanges();
		testVelocityIntegrationOrderAndTerminalClamp();
		testFacingFollowsPressedDirection();
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
		testArrowStandEffectsMatchAs3Deltas();
		testFallingIntoWaterEntersSwimMode();
		testWaterTouchEmitsRippleVisual();
		testWaterDampsSinkingAndPaddlesUp();
		testLeavingWaterReturnsToLand();
		testSafetyBlockReturnsPlayerToLastSafeSpot();
		testSafetyBlockEmitsPoofVisual();
		testHighImpactFallBreaksCrumbleBlock();
		testCheeseHatDoublesStandingCrumbleForce();
		testCheeseHatForcesBumpCrumbleDamage();
		testCheeseHatBreaksAdjacentHeadLevelCrumbleOnSideHit();
		testStandingOnVanishBlockFallsThroughAfterFadeOut();
		testVanishBlockReappearsAfterDelayWhenUnoccupied();
		testMineBlockLaunchesPlayerAndRemovesItself();
		testDeathmatchMineHitRemovesLifeAndFinishesAtZero();
		testBumpingItemBlockGrantsConfiguredItem();
		testBumpingItemBlockEmitsStarSound();
		testEmptyOptionsItemBlockGrantsAllowedItem();
		testItemBlockRandomnessDoesNotAffectMoveBlocks();
		testRegularItemBlockDepletesAfterFirstUse();
		testNewlyCollectedItemRequiresReleaseBeforeUse();
		testSuperJumpItemLaunchesPlayerAndConsumesItem();
		testSuperJumpItemDoesNothingWhileCrouching();
		testTeleportItemMovesPlayerForwardAndConsumesItem();
		testTeleportItemBlockedBySolidDestination();
		testSpeedBurstBoostsMovementThenExpires();
		testJetPackLiftsPlayerThenExpires();
		testLaserGunReloadTiming();
		testLaserGunShotAnimatesBlockFromSide();
		testLaserGunDamageBreaksBrickBlock();
		testMineItemPlacesMineAndConsumesItem();
		testMineItemBlockedByOccupiedTile();
		testMineAppearSkipsPlacementWhenTileBecomesOccupied();
		testLightningEmitsZapAndConsumesItem();
		testReloadableItemReleaseGateThenHeldRefire();
		testSwordReloadTiming();
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
		testTeleportCooldownPreventsImmediateReturn();
		testStandingOnPushBlockMovesItDown();
		testPushBlockRecursivelyMovesDestinationPushBlock();
		testUnconfiguredMoveBlocksUseFlashRandomDirections();
		testTimedMoveBlockPreviewDirections();
		testTimedMoveBlockShiftsAfterPreview();
		testTimedMoveBlockRecursivelyMovesDestinationPushBlock();
		testTimedMoveBlockWaitsWhenDestinationBlocked();
		testTimedMoveBlockWaitsWhenDestinationOccupied();
		testBumpingRotateBlockFreezesPlayer();
		testRotateRightCompletesCourseRotation();
		testRotateLeftCompletesCourseRotation();
		testRotationTweenMatchesCourseFrames();
		testRotationMapsSafePosition();
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

	private static function testAnimationFollowsDirectionalInput():Void {
		var player = newPlayer();
		for (_ in 0...40) {
			player.step(new LocalPlayerInput());
		}

		player.step(new LocalPlayerInput(false, true));
		assertEquals("run", player.debugState().animation, "held direction runs like LocalCharacter");

		player.step(new LocalPlayerInput());
		assertEquals("stand", player.debugState().animation, "coasting without input stands like LocalCharacter");

		player.step(new LocalPlayerInput(false, false, false, true));
		player.step(new LocalPlayerInput(false, true, false, true));
		assertEquals("run", player.debugState().animation, "down on flat ground charges, not crouches: held direction still runs");

		player.step(new LocalPlayerInput(false, false, false, true));
		assertEquals("stand", player.debugState().animation, "down on flat ground does not crouch: released direction stands while charging");
	}

	private static function testStartBlockHasNoCollision():Void {
		var player = newPlayer();
		var state = player.debugState();

		assertClose(75, state.x, "initial x centers player in start tile");
		assertClose(270, state.y, "initial feet align with start block top");
		assertEquals(false, state.grounded, "start block does not ground player");

		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}
		state = player.debugState();
		assertClose(300, state.y, "player falls through start block to solid floor");
		assertEquals(true, state.grounded, "solid floor grounds player");
	}

	private static function testSideCollisionDoesNotFinishRace():Void {
		var player = newPlayer();
		var input = new LocalPlayerInput(false, true);
		var touchedFinish = false;

		for (_ in 0...120) {
			player.step(input);
			var state = player.debugState();
			if (state.touchedBlockType == "finish") {
				touchedFinish = true;
				break;
			}
		}

		var state = player.debugState();
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
			if (player.debugState().finished) {
				break;
			}
		}

		var state = player.debugState();
		assertEquals(true, state.finished, "bumping finish block completes race");
		assertEquals(1, state.finishBlockId, "finish reports Flash-style one-based block id");
		assertEquals(105, state.finishX, "finish reports block center x");
		assertEquals(45, state.finishY, "finish reports block center y");
		assertClose(0.5, player.blockColorMultiplierAt(3, 1), "depleted finish block uses SupplyBlock grey transform");

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
		}
		assertEquals(1, player.debugState().finishBlockId, "finish supply remains latched after first use");
	}

	private static function testJumpAndLandOnFlatFixture():Void {
		var player = newPlayer();
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		player.step(new LocalPlayerInput(false, false, true));
		var jumpState = player.debugState();
		assertEquals(false, jumpState.grounded, "jump leaves ground");
		assertEquals("jump", jumpState.animation, "jump animation");
		assertBelow(jumpState.y, 300, "jump moves player up");

		for (_ in 0...40) {
			player.step(new LocalPlayerInput());
		}

		var landedState = player.debugState();
		assertEquals(true, landedState.grounded, "scripted jump lands");
		assertClose(300, landedState.y, "jump lands back on solid floor");
		assertEquals("stand", landedState.animation, "landed animation");
	}

	private static function testGravityUsesFlashMultiplierAndSupportsRuntimeChanges():Void {
		var player = new LocalCharacter(emptyLevel(2.5));
		player.step(new LocalPlayerInput());
		assertClose(1.75, player.debugState().vy, "gravity is Flash's 0.7 times the level multiplier");

		player.setGravity(0.5);
		player.step(new LocalPlayerInput());
		assertClose(2.1, player.debugState().vy, "runtime gravity changes replace the active multiplier");
	}

	private static function testVelocityIntegrationOrderAndTerminalClamp():Void {
		var player = new LocalCharacter(emptyLevel(1));
		player.step(new LocalPlayerInput(false, true));
		var state = player.debugState();
		var acceleration = 0.2 + 50 / 60;
		var expectedVx = acceleration * 0.985 * 0.35;
		assertClose(expectedVx, state.vx, "horizontal integration applies input, friction, then acceleration factor");
		assertClose(75 + expectedVx, state.x, "horizontal position uses the integrated velocity");
		assertClose(0.7, state.vy, "vertical integration applies gravity before movement");
		assertClose(90.7, state.y, "vertical position uses velocity after gravity");

		player = new LocalCharacter(emptyLevel(100));
		player.step(new LocalPlayerInput());
		state = player.debugState();
		assertClose(28, state.vy, "positive velocity is clamped to Flash's terminal speed");
		assertClose(118, state.y, "terminal velocity is clamped before position integration");

		player.setGravity(-100);
		player.step(new LocalPlayerInput());
		state = player.debugState();
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

		var crouchState = player.debugState();
		assertEquals(true, crouchState.crouching, "a low ceiling forces the character to crouch");
		assertEquals("crouch", crouchState.animation, "forced crouch shows the crouch animation");
		assertClose(300, crouchState.y, "crouch preserves feet position on the floor");

		player.step(new LocalPlayerInput(false, false, true, false));
		var jumpState = player.debugState();
		assertEquals(true, jumpState.crouching, "the low ceiling keeps the character crouched");
		assertEquals(true, jumpState.grounded, "crouching under a ceiling blocks the jump");
	}

	private static function testPressingUpUnderBlockBumpsIt():Void {
		var player = new LocalCharacter(lowItemCeilingLevel());
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		var crouchState = player.debugState();
		assertEquals(true, crouchState.crouching, "the low item block forces crouch before input");
		assertEquals(null, crouchState.itemId, "standing under the item block does not collect it");

		player.step(new LocalPlayerInput(false, false, true));
		var bumpState = player.debugState();
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
		var charged = player.debugState();
		assertEquals(false, charged.crouching, "holding down on open ground never crouches");
		assertEquals(true, charged.grounded, "charging a super jump stays grounded");
		assertEquals("superJump", charged.animation, "a charged crouch shows the super jump pose");

		// Releasing down fires the charge as an upward launch.
		var beforeY = charged.y;
		player.step(new LocalPlayerInput());
		var launched = player.debugState();
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

		assertBelow(icy.debugState().vx, normal.debugState().vx * 0.2, "ice applies AS3 low accelFactor on next frame");
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

		assertBelow(santa.debugState().vx, normal.debugState().vx * 0.3, "santa-frozen block applies ice acceleration");

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
			if (player.debugState().touchedBlockType == "mine") {
				break;
			}
		}

		assertEquals("mine", player.debugState().touchedBlockType, "player touches frozen mine");
		assertEquals("land", player.debugState().mode, "frozen mine does not hurt player");
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
			if (player.debugState().touchedBlockType == "rotate_right") {
				break;
			}
		}

		assertEquals("rotate_right", player.debugState().touchedBlockType, "player bumps frozen rotate block");
		assertEquals("land", player.debugState().mode, "frozen rotate block does not freeze player");
		assertEquals(0, player.debugState().courseRotation, "frozen rotate block does not start course rotation");
	}

	private static function testFrozenSafetyBlockSuppressesReturn():Void {
		var player = new LocalCharacter(safetyDropLevel());
		for (tileX in 5...9) {
			player.controller.freezeBlockForTest(tileX, 7, 0);
		}
		var touchedSafety = false;
		var poofEvents = 0;

		for (_ in 0...120) {
			player.step(new LocalPlayerInput(false, true));
			if (player.debugState().touchedBlockType == "safety") {
				touchedSafety = true;
			}
			for (event in player.consumeBlockVisualEvents()) {
				if (event.kind == SafetyPoof) {
					poofEvents++;
				}
			}
			if (touchedSafety && player.debugState().y > 240) {
				break;
			}
		}

		assertEquals(true, touchedSafety, "player touches frozen safety block");
		assertEquals(0, poofEvents, "frozen safety block does not emit return poof");
		assertEquals(true, player.debugState().y > 200, "frozen safety block does not return player to last safe spot");
	}

	private static function testFrozenSupplyBlockSuppressesUse():Void {
		var player = new LocalCharacter(lowItemCeilingLevel(BlockType.Item, "3"));
		player.controller.freezeBlockForTest(2, 8);
		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}

		player.step(new LocalPlayerInput(false, false, true));
		var events = player.consumeBlockVisualEvents();
		assertEquals(null, player.debugState().itemId, "frozen item block grants no item");
		assertClose(1, player.blockColorMultiplierAt(2, 8), "frozen item block does not deplete");
		assertEquals(1, events.length, "frozen item block only emits the base bump");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "frozen item block suppresses item sound");
	}

	private static function testArrowStandEffectsMatchAs3Deltas():Void {
		var up = new LocalCharacter(singleBlockLevel(BlockType.ArrowUp));
		assertClose(-10, up.debugState().vy, "up arrow stand launches upward");
		var events = up.consumeBlockVisualEvents();
		assertEquals(1, events.length, "arrow stand emits one visual activation");
		assertEquals("ArrowAnimate", Type.enumConstructor(events[0].kind), "arrow stand emits authored animation event");
		assertClose(5, new LocalCharacter(singleBlockLevel(BlockType.ArrowDown)).debugState().vy, "down arrow stand pushes down");
		assertClose(-3, new LocalCharacter(singleBlockLevel(BlockType.ArrowLeft)).debugState().vx, "left arrow stand pushes left");
		assertClose(3, new LocalCharacter(singleBlockLevel(BlockType.ArrowRight)).debugState().vx, "right arrow stand pushes right");
	}

	private static function testFallingIntoWaterEntersSwimMode():Void {
		var player = new LocalCharacter(waterPoolLevel());
		var enteredWater = false;

		for (_ in 0...40) {
			player.step(new LocalPlayerInput());
			if (player.debugState().mode == "water") {
				enteredWater = true;
				break;
			}
		}

		var state = player.debugState();
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
		var sinkState = sinking.debugState();
		assertEquals("water", sinkState.mode, "idle player stays submerged");
		assertBelow(sinkState.vy, 5, "water damps sinking speed far below free-fall");
		assertBelow(0, sinkState.vy, "idle player still drifts downward");

		var paddling = new LocalCharacter(waterPoolLevel());
		var minVy = 1e9;
		for (_ in 0...40) {
			paddling.step(new LocalPlayerInput(false, false, true));
			var vy = paddling.debugState().vy;
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
			var mode = player.debugState().mode;
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
		var touchedSafety = false;

		for (_ in 0...120) {
			player.step(new LocalPlayerInput(false, true));
			if (player.debugState().touchedBlockType == "safety") {
				touchedSafety = true;
				break;
			}
		}

		var state = player.debugState();
		assertEquals(true, touchedSafety, "falling player touches safety block");
		assertClose(75, state.x, "safety block restores last safe x");
		assertClose(90, state.y, "safety block restores last safe y");
		assertClose(0, state.vx, "safety block clears horizontal velocity");
		assertClose(0, state.vy, "safety block clears vertical velocity");
		assertEquals(true, state.grounded, "safety return leaves player grounded");
	}

	private static function testSafetyBlockEmitsPoofVisual():Void {
		var player = new LocalCharacter(safetyDropLevel());
		var poofEvents = 0;

		for (_ in 0...120) {
			player.step(new LocalPlayerInput(false, true));
			for (event in player.consumeBlockVisualEvents()) {
				if (event.kind == SafetyPoof) {
					poofEvents++;
					assertEquals(2, event.tileX, "safety poof appears at last safe tile x");
					assertEquals(3, event.tileY, "safety poof appears at last safe tile y");
				}
			}
			if (player.debugState().touchedBlockType == "safety") {
				break;
			}
		}

		assertEquals(1, poofEvents, "safety return emits one teleport poof visual event");
	}

	private static function testHighImpactFallBreaksCrumbleBlock():Void {
		var player = new LocalCharacter(crumbleDropLevel());
		var touchedCrumble = false;
		var framesAfterCrumble = 0;

		for (_ in 0...120) {
			player.step(new LocalPlayerInput());
			var state = player.debugState();
			if (state.touchedBlockType == "crumble") {
				touchedCrumble = true;
			}
			if (touchedCrumble) {
				framesAfterCrumble++;
				if (framesAfterCrumble >= 6) {
					break;
				}
			}
		}

		var state = player.debugState();
		assertEquals(true, touchedCrumble, "falling player touches crumble platform");
		assertBelow(240, state.y, "broken crumble block is removed from collision");
		assertEquals(false, state.grounded, "player is no longer supported by broken crumble");
		var crumbleActivate:Null<BlockVisualEvent> = null;
		for (event in player.consumeBlockVisualEvents()) {
			if (Type.enumConstructor(event.kind) == "LocalActivate" && event.tileX == 2 && event.tileY == 8) {
				crumbleActivate = event;
				break;
			}
		}
		assertEquals(true, crumbleActivate != null, "crumble impact emits Flash localActivate event");
		assertEquals(true, crumbleActivate.activationPayload != "", "crumble localActivate preserves force payload");
	}

	private static function testCheeseHatDoublesStandingCrumbleForce():Void {
		var normal = new LocalCharacter(crumbleDropLevel());
		var cheese = new LocalCharacter(crumbleDropLevel());
		cheese.setHats([16, 0xC8B040, -1]);

		var normalPayload = firstCrumbleActivationPayload(normal, 2, 8);
		var cheesePayload = firstCrumbleActivationPayload(cheese, 2, 8);

		assertEquals(Std.parseInt(normalPayload) * 2, Std.parseInt(cheesePayload), "cheese doubles standing crumble force payload");
	}

	private static function testCheeseHatForcesBumpCrumbleDamage():Void {
		var player = new LocalCharacter(supplyBlockLevel(BlockType.Crumble));
		player.setHats([16, 0xC8B040, -1]);
		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().touchedBlockType == "crumble") break;
		}

		assertEquals("50", crumbleActivationPayload(player.consumeBlockVisualEvents(), 2, 1), "cheese bump crumble force is forced to 50");
	}

	private static function testCheeseHatBreaksAdjacentHeadLevelCrumbleOnSideHit():Void {
		var player = new LocalCharacter(cheeseSideCrumbleLevel());
		player.setHats([16, 0xC8B040, -1]);
		for (_ in 0...80) {
			player.step(new LocalPlayerInput(false, true));
			if (player.debugState().touchedBlockType == "crumble") break;
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
		assertClose(0.9, player.blockAlphaAt(2, 3), "vanish block fades by one tenth per frame");

		for (_ in 0...9) {
			player.step(new LocalPlayerInput());
		}
		assertEquals(true, player.debugState().grounded, "vanish block remains solid while fading");
		assertClose(0, player.blockAlphaAt(2, 3), "vanish block is invisible at fade-out");

		player.step(new LocalPlayerInput());
		var state = player.debugState();
		assertEquals(false, state.grounded, "vanish block becomes inactive after fade-out");
		assertBelow(90, state.y, "player starts falling through inactive vanish block");
	}

	private static function testVanishBlockReappearsAfterDelayWhenUnoccupied():Void {
		var player = new LocalCharacter(vanishReappearLevel());

		for (_ in 0...11) {
			player.step(new LocalPlayerInput());
		}
		assertEquals(false, player.debugState().grounded, "vanish block is inactive after fade-out");

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
		assertEquals(true, player.debugState().grounded, "player lands below the inactive vanish block");

		for (_ in 0...54) {
			player.step(new LocalPlayerInput());
		}
		var bumpedVanish = false;
		for (_ in 0...25) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().touchedBlockType == "vanish") {
				bumpedVanish = true;
				break;
			}
		}
		assertEquals(true, bumpedVanish, "reappeared vanish block collides again");
	}

	private static function testMineBlockLaunchesPlayerAndRemovesItself():Void {
		var player = new LocalCharacter(mineBlockLevel());
		var initialState = player.debugState();

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

		for (_ in 0...60) {
			player.step(new LocalPlayerInput());
		}
		assertEquals("land", player.debugState().mode, "hurt recovery returns to land mode");

		for (_ in 0...160) {
			player.step(new LocalPlayerInput());
		}
		var state = player.debugState();
		assertEquals(false, state.grounded, "removed mine no longer supports player");
		assertBelow(90, state.y, "player falls through removed mine block");
	}

	private static function testDeathmatchMineHitRemovesLifeAndFinishesAtZero():Void {
		var player = new LocalPlayerController(delayedMineBlockLevel());
		player.setGameMode("deathmatch");
		player.setLife(1);

		var hitMine = false;
		for (_ in 0...40) {
			player.step(new LocalPlayerInput());
			if (player.debugState().touchedBlockType == "mine") {
				hitMine = true;
				break;
			}
		}

		var state = player.debugState();
		assertEquals(true, hitMine, "deathmatch player reaches mine");
		assertEquals(0, state.lives, "deathmatch hurt removes one life");
		assertEquals(true, state.finished, "deathmatch zero lives finishes the player");
	}

	private static function testBumpingItemBlockGrantsConfiguredItem():Void {
		var player = new LocalCharacter(itemBlockLevel(BlockType.Item));
		var grantedItem = false;

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().itemId == 4) {
				grantedItem = true;
				break;
			}
		}

		var state = player.debugState();
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

		assertEquals(null, player.debugState().itemId, "empty-options block grants nothing before the bump");
		player.step(new LocalPlayerInput(false, false, true));
		assertEquals(7, player.debugState().itemId, "empty options draws from the level's allowed item pool");

		var noneAllowed = new LocalCharacter(lowItemCeilingLevel(BlockType.Item, ""));
		noneAllowed.setAllowedItems([]);
		for (_ in 0...20) {
			noneAllowed.step(new LocalPlayerInput());
		}
		noneAllowed.step(new LocalPlayerInput(false, false, true));
		assertEquals(null, noneAllowed.debugState().itemId, "a level with no allowed items grants nothing");
	}

	private static function testItemBlockRandomnessDoesNotAffectMoveBlocks():Void {
		var untouched = new LocalCharacter(itemAndRandomMoveBlockLevel());
		var itemUser = new LocalCharacter(itemAndRandomMoveBlockLevel());

		for (_ in 0...20) {
			untouched.step(new LocalPlayerInput());
			itemUser.step(new LocalPlayerInput());
		}
		itemUser.step(new LocalPlayerInput(false, false, true));
		assertEquals(true, itemUser.debugState().itemId != null, "multi-candidate item block grants an item");

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
		assertEquals(3, player.debugState().itemId, "first regular item bump grants the configured item");
		assertClose(0.5, player.blockColorMultiplierAt(2, 8), "depleted item block uses SupplyBlock grey transform");

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(null, player.debugState().itemId, "lightning item consumes before the second bump");
		player.step(new LocalPlayerInput(false, false, true));
		assertEquals(null, player.debugState().itemId, "depleted regular item block does not grant again");

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
		assertEquals(3, player.debugState().itemId, "newly collected item does not fire before a key-up frame");
		assertEquals(null, player.debugState().lastItemEffect, "blocked first press emits no item effect");

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(null, player.debugState().itemId, "item fires after the key has been released");
		assertEquals("zap`", player.debugState().lastItemEffect, "released lightning emits the Flash payload");
	}

	private static function testSuperJumpItemLaunchesPlayerAndConsumesItem():Void {
		var player = new LocalCharacter(superJumpItemLevel());
		var grantedItem = false;

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().itemId == 5) {
				grantedItem = true;
				break;
			}
		}

		assertEquals(true, grantedItem, "jumping player bumps super jump item block");
		player.consumeBlockVisualEvents();
		for (_ in 0...70) {
			player.step(new LocalPlayerInput(false, true));
			if (player.debugState().x > 105) {
				break;
			}
		}
		var beforeUse = player.debugState();

		makeItemAvailable(player);
		beforeUse = player.debugState();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var afterUse = player.debugState();

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
		var beforeUse = player.debugState();

		makeItemAvailable(player);
		beforeUse = player.debugState();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var afterUse = player.debugState();

		assertEquals(true, beforeUse.crouching, "low ceiling forces crouch before super jump item use");
		assertEquals(5, beforeUse.itemId, "bumping low item block grants the super jump item");
		assertEquals(5, afterUse.itemId, "crouched super jump item use keeps the held item");
		assertClose(beforeUse.vy, afterUse.vy, "crouched super jump item use does not apply impulse");
		assertEquals(null, afterUse.lastItemEffect, "crouched super jump item use emits no effect");
	}

	private static function testTeleportItemMovesPlayerForwardAndConsumesItem():Void {
		var player = new LocalCharacter(teleportItemLevel(false));
		var grantedItem = false;

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().itemId == 4) {
				grantedItem = true;
				break;
			}
		}

		assertEquals(true, grantedItem, "jumping player bumps teleport item block");
		for (_ in 0...70) {
			player.step(new LocalPlayerInput(false, true));
			if (player.debugState().x > 105) {
				break;
			}
		}
		var beforeUse = player.debugState();

		makeItemAvailable(player);
		beforeUse = player.debugState();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var afterUse = player.debugState();

		assertEquals(null, afterUse.itemId, "teleport item consumes after a clear teleport");
		assertClose(120, afterUse.x - beforeUse.x - afterUse.vx, "teleport item moves 120 px in facing direction");
		assertEquals(
			"teleport:" + Std.int(beforeUse.x) + "," + Std.int(beforeUse.y - 25) + ":" + Std.int(afterUse.x - afterUse.vx) + "," + Std.int(beforeUse.y - 25),
			afterUse.lastItemEffect,
			"teleport item emits Flash start and end pop effect positions"
		);
	}

	private static function testTeleportItemBlockedBySolidDestination():Void {
		var player = new LocalCharacter(teleportItemLevel(true));

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().itemId == 4) {
				break;
			}
		}
		for (_ in 0...70) {
			player.step(new LocalPlayerInput(false, true));
			if (player.debugState().x > 105) {
				break;
			}
		}
		var beforeUse = player.debugState();

		makeItemAvailable(player);
		beforeUse = player.debugState();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var afterUse = player.debugState();

		assertEquals(4, afterUse.itemId, "blocked teleport keeps held item");
		assertClose(0, afterUse.x - beforeUse.x - afterUse.vx, "blocked teleport does not apply item movement");
		assertEquals(null, afterUse.lastItemEffect, "blocked teleport does not emit pop effects");
	}

	private static function testSpeedBurstBoostsMovementThenExpires():Void {
		var boosted = collectItem(speedBurstItemLevel(), 7);
		var normal = new LocalCharacter(speedBurstComparisonLevel());

		makeItemAvailable(boosted);
		boosted.step(new LocalPlayerInput(false, false, false, false, true));
		var active = boosted.debugState();
		assertEquals(7, active.itemId, "speed burst stays held while active");

		for (_ in 0...24) {
			boosted.step(new LocalPlayerInput(false, true));
			normal.step(new LocalPlayerInput(false, true));
		}

		assertBelow(normal.debugState().vx * 1.4, boosted.debugState().vx, "speed burst doubles movement acceleration");

		for (_ in 0...110) {
			boosted.step(new LocalPlayerInput(false, true));
		}

		assertEquals(null, boosted.debugState().itemId, "speed burst expires after five seconds");
		assertClose(50, boosted.debugState().speedStat, "speed burst expiry restores speed stat");
		assertClose(50, boosted.debugState().accelerationStat, "speed burst expiry restores acceleration stat");
		assertClose(50, boosted.debugState().jumpStat, "speed burst expiry preserves jump stat");
	}

	private static function testJetPackLiftsPlayerThenExpires():Void {
		var boosted = collectItem(jetPackItemLevel(), 6);
		var normal = new LocalCharacter(jetPackComparisonLevel());

		for (_ in 0...70) {
			boosted.step(new LocalPlayerInput(false, true));
			normal.step(new LocalPlayerInput(false, true));
			if (boosted.debugState().x > 105) {
				break;
			}
		}

		boosted.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(6, boosted.debugState().itemId, "jet pack stays held while active");
		assertEquals(3, boosted.debugState().itemUses, "jet pack starts with three fuel pips");

		for (_ in 0...24) {
			boosted.step(new LocalPlayerInput(false, false, false, false, true));
			normal.step(new LocalPlayerInput());
		}

		assertBelow(boosted.debugState().y, normal.debugState().y - 20, "jet pack thrust lifts the player");
		assertBelow(boosted.debugState().vy, normal.debugState().vy, "jet pack counters gravity while active");

		for (_ in 0...42) {
			boosted.step(new LocalPlayerInput(false, false, false, false, true));
		}
		assertEquals(2, boosted.debugState().itemUses, "jet pack ammo drops after one third of the fuel is spent");

		for (_ in 0...133) {
			boosted.step(new LocalPlayerInput(false, false, false, false, true));
		}

		assertEquals(null, boosted.debugState().itemId, "jet pack expires after 200 fuel frames");
	}

	private static function testLaserGunReloadTiming():Void {
		var player = collectItem(heldItemLevel(1), 1);
		var beforeUse = player.debugState();

		makeItemAvailable(player);
		beforeUse = player.debugState();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var firstShot = player.debugState();
		assertEquals(1, firstShot.itemId, "laser remains held after first shot");
		assertEquals(2, firstShot.itemUses, "laser consumes one of three shots");
		assertEquals("laser:right", firstShot.lastItemEffect, "laser emits a right-facing shot");
		assertBelow(firstShot.vx, beforeUse.vx, "laser applies backwards recoil");

		var leftFacing = collectItem(heldItemLevel(1), 1);
		leftFacing.step(new LocalPlayerInput(true));
		var beforeLeftUse = leftFacing.debugState();
		makeItemAvailable(leftFacing);
		beforeLeftUse = leftFacing.debugState();
		leftFacing.step(new LocalPlayerInput(false, false, false, false, true));
		var leftShot = leftFacing.debugState();
		assertEquals("laser:left", leftShot.lastItemEffect, "laser emits a left-facing shot");
		assertBelow(beforeLeftUse.vx, leftShot.vx, "left-facing laser recoils right like Flash");

		for (_ in 0...21) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
			assertEquals(2, player.debugState().itemUses, "laser cannot fire during its 800ms reload");
		}
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(1, player.debugState().itemUses, "held laser fires again after 22 frames");
		for (_ in 0...22) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
		}
		assertEquals(null, player.debugState().itemId, "laser is consumed after three shots");
	}

	private static function testLaserGunShotAnimatesBlockFromSide():Void {
		var player = collectItem(heldItemWithTargetBlockLevel(1), 1);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();

		assertEquals(1, events.length, "laser shot side-hit emits one block visual event");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "laser side-hit uses block bump animation event");
		assertEquals(4, events[0].tileX, "laser side-hit targets the first solid block in the shot path");
		assertEquals(5, events[0].tileY, "laser side-hit targets the shot-height block row");
		assertEquals(5, events[0].hitX, "right-facing laser bumps the block sideways");
		assertEquals(0, events[0].hitY, "side shot does not use the upward bump impulse");
	}

	private static function testLaserGunDamageBreaksBrickBlock():Void {
		var player = collectItem(heldItemWithTargetBlockLevel(1, BlockType.Brick), 1);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();

		assertEquals(3, events.length, "laser-damaged brick emits bump, activation, and pieces");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "laser damage still bumps the brick");
		assertEquals("LocalActivate", Std.string(events[1].kind), "laser damage activates the brick");
		assertEquals("BrickPieces", Std.string(events[2].kind), "laser damage spawns brick pieces");
		assertEquals(0.0, player.blockAlphaAt(4, 5), "laser-damaged brick is removed");
	}

	private static function testMineItemPlacesMineAndConsumesItem():Void {
		var level = heldItemLevel(2);
		var player = collectItem(level, 2);

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var state = player.debugState();

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
		var state = player.debugState();

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

	private static function testLightningEmitsZapAndConsumesItem():Void {
		var player = collectItem(heldItemLevel(3), 3);

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var state = player.debugState();

		assertEquals(null, state.itemId, "lightning consumes on use");
		assertEquals("zap`", state.lastItemEffect, "lightning emits Flash's zap command payload");
	}

	private static function testReloadableItemReleaseGateThenHeldRefire():Void {
		var player = collectItem(heldItemLevel(1), 1);

		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(3, player.debugState().itemUses, "fresh reloadable item ignores held item key before first release");
		assertEquals(null, player.debugState().lastItemEffect, "fresh reloadable item emits no effect before first release");

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(2, player.debugState().itemUses, "released reloadable item fires on the next item press");

		for (_ in 0...21) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
		}
		assertEquals(2, player.debugState().itemUses, "held reloadable item waits through its reload timer");

		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(1, player.debugState().itemUses, "held reloadable item refires when reload completes without another release");
	}

	private static function testSwordReloadTiming():Void {
		var player = collectItem(heldItemLevel(8), 8);
		var beforeUse = player.debugState();

		makeItemAvailable(player);
		beforeUse = player.debugState();
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var firstSwing = player.debugState();
		assertEquals(8, firstSwing.itemId, "sword remains held after first swing");
		assertEquals(2, firstSwing.itemUses, "sword consumes one of three swings");
		assertEquals("slash:right", firstSwing.lastItemEffect, "sword emits a right-facing slash");
		assertBelow(beforeUse.vx, firstSwing.vx, "sword lunges in the facing direction");

		var leftFacing = collectItem(heldItemLevel(8), 8);
		leftFacing.step(new LocalPlayerInput(true));
		var beforeLeftUse = leftFacing.debugState();
		makeItemAvailable(leftFacing);
		beforeLeftUse = leftFacing.debugState();
		leftFacing.step(new LocalPlayerInput(false, false, false, false, true));
		var leftSwing = leftFacing.debugState();
		assertEquals("slash:left", leftSwing.lastItemEffect, "sword emits a left-facing slash");
		assertBelow(leftSwing.vx, beforeLeftUse.vx, "left-facing sword lunges left like Flash");

		for (_ in 0...21) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
			assertEquals(2, player.debugState().itemUses, "sword cannot swing during its 800ms reload");
		}
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(1, player.debugState().itemUses, "held sword swings again after 22 frames");
		for (_ in 0...22) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
		}
		assertEquals(null, player.debugState().itemId, "sword is consumed after three swings");
	}

	private static function testSwordDamageActivatesVanishBlock():Void {
		var player = collectItem(heldItemWithTargetBlockLevel(8, BlockType.Vanish, 3), 8);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();
		assertEquals(1, events.length, "slash-damaged vanish block emits the base bump event");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "slash damage bumps the vanish block");
		assertClose(0.9, player.blockAlphaAt(3, 5), "slash-damaged vanish block starts fading on the hit frame");
		player.step(new LocalPlayerInput());
		assertClose(0.8, player.blockAlphaAt(3, 5), "slash-damaged vanish block fades like contact activation");
	}

	private static function testIceWaveReloadTiming():Void {
		var player = collectItem(heldItemLevel(9), 9);

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var firstWave = player.debugState();
		assertEquals(9, firstWave.itemId, "ice wave remains held after first wave");
		assertEquals(2, firstWave.itemUses, "ice wave consumes one of three waves");
		assertEquals("ice_wave:right", firstWave.lastItemEffect, "ice wave emits a right-facing wave");

		var leftFacing = collectItem(heldItemLevel(9), 9);
		leftFacing.step(new LocalPlayerInput(true));
		makeItemAvailable(leftFacing);
		leftFacing.step(new LocalPlayerInput(false, false, false, false, true));
		var leftWave = leftFacing.debugState();
		assertEquals("ice_wave:left", leftWave.lastItemEffect, "ice wave emits a left-facing wave");

		for (_ in 0...26) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
			assertEquals(2, player.debugState().itemUses, "ice wave cannot fire during its 1000ms reload");
		}
		player.step(new LocalPlayerInput(false, false, false, false, true));
		assertEquals(1, player.debugState().itemUses, "held ice wave fires again after 27 frames");
		for (_ in 0...27) {
			player.step(new LocalPlayerInput(false, false, false, false, true));
		}
		assertEquals(null, player.debugState().itemId, "ice wave is consumed after three waves");
	}

	private static function testIceWaveShotAnimatesBlockFromSide():Void {
		var player = collectItem(heldItemWithTargetBlockLevel(9), 9);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();

		assertEquals(1, events.length, "ice wave side-hit emits one block visual event");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "ice wave side-hit uses block bump animation event");
		assertEquals(4, events[0].tileX, "ice wave side-hit targets the first solid block in the shot path");
		assertEquals(5, events[0].tileY, "ice wave side-hit targets the shot-height block row");
		assertEquals(5, events[0].hitX, "right-facing ice wave bumps the block sideways");
		assertEquals(0, events[0].hitY, "ice wave side-hit does not use the upward bump impulse");
	}

	private static function testIceWaveDamageExplodesMineBlock():Void {
		var player = collectItem(heldItemWithTargetBlockLevel(9, BlockType.Mine), 9);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();

		assertEquals(4, events.length, "ice-wave-damaged mine emits bump, activation, pieces, and explosion");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "ice wave damage bumps the mine");
		assertEquals("LocalActivate", Std.string(events[1].kind), "ice wave damage activates the mine");
		assertEquals("MinePieces", Std.string(events[2].kind), "ice wave damage spawns mine pieces");
		assertEquals("MineExplode", Std.string(events[3].kind), "ice wave damage spawns mine explosion");
		assertEquals(0.0, player.blockAlphaAt(4, 5), "ice-wave-damaged mine is removed");
	}

	private static function testLaserGunDamageChipsCrumbleBlock():Void {
		var player = collectItem(heldItemWithTargetBlockLevel(1, BlockType.Crumble), 1);
		player.consumeBlockVisualEvents();

		makeItemAvailable(player);
		player.step(new LocalPlayerInput(false, false, false, false, true));
		var events = player.consumeBlockVisualEvents();

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
		var startX = player.debugState().x;
		player.freeze();

		assertEquals(true, player.isFrozen(), "freeze marks player frozen");
		assertEquals("frozenSolid", player.debugState().mode, "freeze enters frozen-solid mode");
		assertEquals("freeze", player.debugState().animation, "frozen-solid mode uses frozen animation");

		for (_ in 0...53) {
			player.step(new LocalPlayerInput(false, true));
		}
		assertEquals(true, player.isFrozen(), "player remains frozen before two seconds elapse");
		assertClose(startX, player.debugState().x, "frozen player ignores horizontal input");

		player.step(new LocalPlayerInput(false, true));
		assertEquals(false, player.isFrozen(), "player thaws after two seconds");
		assertEquals("land", player.debugState().mode, "thaw returns player to land mode");
	}

	private static function testBumpingCustomStatsBlockAppliesConfiguredStats():Void {
		var player = new LocalCharacter(customStatsBlockLevel("100-0-80"));

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().touchedBlockType == "custom_stats") {
				break;
			}
		}

		var state = player.debugState();
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
			if (player.debugState().touchedBlockType == "custom_stats") {
				break;
			}
		}

		var state = player.debugState();
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
		assertEquals(false, player.debugState().touchedBlockType == "brick", "broken brick no longer collides");
	}

	private static function testBumpingHappyBlockRaisesStats():Void {
		var player = bumpSupply(supplyBlockLevel(BlockType.Happy, "20"), BlockType.Happy);
		var state = player.debugState();
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
		var state = player.debugState();
		assertClose(30, state.speedStat, "sad block lowers speed by configured amount");
		assertClose(30, state.accelerationStat, "sad block lowers acceleration");
		assertClose(30, state.jumpStat, "sad block lowers jumping");
		assertClose(0.5, player.blockColorMultiplierAt(2, 1), "depleted sad block uses SupplyBlock grey transform");
		var events = player.consumeBlockVisualEvents();
		assertEquals(2, events.length, "sad block emits thump and stat sound events");
		assertEquals("BlockBumpSound", Std.string(events[0].kind), "sad block keeps base ThumpSound event");
		assertEquals("SadBlockSound", Std.string(events[1].kind), "sad block emits BumpSadSound event");
		player.step(new LocalPlayerInput(false, false, true));
		assertEquals(0, player.consumeBlockVisualEvents().length, "depleted sad block does not replay sound");
	}

	private static function testBumpingHeartBlockAddsCappedLife():Void {
		var player = bumpSupply(supplyBlockLevel(BlockType.Heart), BlockType.Heart);
		assertEquals(4, player.debugState().lives, "heart block adds one life");
		assertClose(0.5, player.blockColorMultiplierAt(2, 1), "depleted heart block uses SupplyBlock grey transform");
	}

	private static function testBumpingTimeBlockAddsTenSeconds():Void {
		var player = bumpSupply(supplyBlockLevel(BlockType.Time), BlockType.Time);
		assertEquals(130, player.debugState().courseTime, "time block adds ten seconds");
		assertClose(0.5, player.blockColorMultiplierAt(2, 1), "depleted time block uses SupplyBlock grey transform");
	}

	private static function bumpSupply(level:FixtureLevel, type:BlockType):LocalCharacter {
		var player = new LocalCharacter(level);
		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().touchedBlockType == type) break;
		}
		assertEquals(type, player.debugState().touchedBlockType, '$type block is bumped');
		return player;
	}

	private static function testTeleportBlockMovesPlayerToNextSameColorBlock():Void {
		var player = new LocalCharacter(teleportPairLevel());
		var state = player.debugState();

		assertEquals("teleport", state.touchedBlockType, "standing on teleport reports touched block");
		assertClose(135, state.x, "teleport moves player by matching block delta");
		assertClose(90, state.y, "teleport preserves feet offset relative to block");
		assertEquals(true, state.grounded, "player remains grounded after teleport");
	}

	private static function testTeleportCooldownPreventsImmediateReturn():Void {
		var player = new LocalCharacter(teleportPairLevel());

		for (_ in 0...20) {
			player.step(new LocalPlayerInput());
		}
		var state = player.debugState();

		assertClose(135, state.x, "teleport color cooldown prevents immediate return teleport");
		assertClose(90, state.y, "cooldown leaves player standing on destination block");
		assertEquals(true, state.grounded, "destination teleport supports player during cooldown");
	}

	private static function testStandingOnPushBlockMovesItDown():Void {
		var level = pushBlockLevel();
		var player = new LocalCharacter(level);
		var state = player.debugState();

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

	private static function testPushBlockRecursivelyMovesDestinationPushBlock():Void {
		var level = pushBlockChainLevel();
		var player = new LocalCharacter(level);

		assertEquals("push", player.debugState().touchedBlockType, "standing on push-chain source reports touched block");
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
		var player = new LocalCharacter(level);

		for (_ in 0...26) {
			player.step(new LocalPlayerInput());
		}
		assertEquals(BlockType.Move, level.blockAt(2, 3).type, "move block waits through arrow preview");

		player.step(new LocalPlayerInput());
		assertEquals(null, level.blockAt(2, 3), "move block leaves original tile after one second");
		assertEquals(BlockType.Move, level.blockAt(3, 3).type, "move block shifts one tile in chosen direction");
	}

	private static function testTimedMoveBlockRecursivelyMovesDestinationPushBlock():Void {
		var level = timedMovePushChainLevel();
		var player = new LocalCharacter(level);

		for (_ in 0...27) {
			player.step(new LocalPlayerInput());
		}

		assertEquals(null, level.blockAt(2, 3), "move block leaves original tile after pushing chain");
		assertEquals(BlockType.Move, level.blockAt(3, 3).type, "move block moves into destination push tile");
		assertEquals(BlockType.Push, level.blockAt(4, 3).type, "destination push block moves one tile right");
		var events = player.consumeBlockVisualEvents();
		assertEquals(3, events.length, "move block chain emits activation plus both display movements");
		assertEquals("LocalActivate", Type.enumConstructor(events[0].kind), "move block chain preserves existing activation event");
		assertEquals("PushBlockMove", Type.enumConstructor(events[1].kind), "move block chain moves push block first");
		assertEquals(3, events[1].tileX, "move-block destination push source x");
		assertEquals(3, events[1].tileY, "move-block destination push source y");
		assertEquals(4, events[1].toTileX, "move-block destination push target x");
		assertEquals(3, events[1].toTileY, "move-block destination push target y");
		assertEquals("PushBlockMove", Type.enumConstructor(events[2].kind), "move block chain moves original move block second");
		assertEquals(2, events[2].tileX, "move-block source x");
		assertEquals(3, events[2].tileY, "move-block source y");
		assertEquals(3, events[2].toTileX, "move-block target x");
		assertEquals(3, events[2].toTileY, "move-block target y");
	}

	private static function testTimedMoveBlockPreviewDirections():Void {
		var level = timedMoveBlockLevel("right", false);
		var player = new LocalCharacter(level);

		assertEquals(2, player.activeMoveBlockDirections().get("2,3"), "move block exposes right arrow during preview");
		for (_ in 0...27) {
			player.step(new LocalPlayerInput());
		}
		assertEquals(false, player.activeMoveBlockDirections().exists("2,3"), "move block arrow clears after shifting");

		for (_ in 0...135) {
			player.step(new LocalPlayerInput());
		}
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
		var player = new LocalCharacter(level);

		for (_ in 0...27) {
			player.step(new LocalPlayerInput());
		}

		assertEquals(BlockType.Move, level.blockAt(2, 3).type, "blocked move block stays in place");
		assertEquals(BlockType.Solid, level.blockAt(3, 3).type, "blocking tile remains occupied");
	}

	private static function testTimedMoveBlockWaitsWhenDestinationOccupied():Void {
		var level = timedMoveBlockLevel("up", false);
		var player = new LocalCharacter(level);

		for (_ in 0...27) {
			player.step(new LocalPlayerInput());
		}

		assertEquals(BlockType.Move, level.blockAt(2, 3).type, "move block does not shift into the player");
		assertEquals(null, level.blockAt(2, 2), "occupied destination stays free of moving blocks");
	}

	private static function testBumpingRotateBlockFreezesPlayer():Void {
		var player = new LocalCharacter(rotateBlockLevel(BlockType.RotateRight));

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().mode == "freeze") {
				break;
			}
		}

		var state = player.debugState();
		assertEquals("rotate_right", state.touchedBlockType, "debug state reports rotate block touch");
		assertEquals("freeze", state.mode, "rotate block bump enters freeze mode");
		assertEquals("freeze", state.animation, "freeze mode exposes freeze animation state");
		assertClose(0, state.vx, "rotate block clears horizontal velocity");
		assertClose(0, state.vy, "rotate block clears vertical velocity");
	}

	private static function testRotateRightCompletesCourseRotation():Void {
		var player = bumpRotateBlock(BlockType.RotateRight);
		var frozen = player.debugState();

		for (_ in 0...29) {
			player.step(new LocalPlayerInput());
		}
		assertEquals("freeze", player.debugState().mode, "right rotation keeps player frozen before final frame");

		player.step(new LocalPlayerInput());
		var state = player.debugState();
		assertEquals("land", state.mode, "right rotation returns player to land mode");
		assertEquals(90, state.courseRotation, "right rotation advances course rotation");
		assertClose(-frozen.y, state.x, "right rotation maps x from frozen y");
		assertClose(frozen.x, state.y, "right rotation maps y from frozen x");
	}

	private static function testRotateLeftCompletesCourseRotation():Void {
		var player = bumpRotateBlock(BlockType.RotateLeft);
		var frozen = player.debugState();

		for (_ in 0...30) {
			player.step(new LocalPlayerInput());
		}

		var state = player.debugState();
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

	private static function testCollisionSnapsAgainstRotatedCeiling():Void {
		var level = rotateBlockLevel(BlockType.RotateRight);
		level.blocks.push(new LevelBlock(4, 3, BlockType.Solid));
		level.blocks.push(new LevelBlock(1, 3, BlockType.Solid));
		var player = new LocalCharacter(level);

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().mode == "freeze") {
				break;
			}
		}
		for (_ in 0...60) {
			player.step(new LocalPlayerInput());
			if (player.debugState().grounded) {
				break;
			}
		}

		var bumped = false;
		for (_ in 0...30) {
			player.step(new LocalPlayerInput(false, false, true));
			var state = player.debugState();
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
			if (player.debugState().mode == "freeze") {
				break;
			}
		}
		for (_ in 0...30) {
			player.step(new LocalPlayerInput());
		}

		for (_ in 0...20) {
			player.step(new LocalPlayerInput(true));
		}

		var state = player.debugState();
		assertBelow(-111, state.x, "rotated wall stops left movement at its displayed edge");
	}

	private static function testArrowPushUsesRotatedCourseDirection():Void {
		var level = rotateBlockLevel(BlockType.RotateRight);
		level.blocks.push(new LevelBlock(3, 4, BlockType.ArrowRight));
		var player = new LocalCharacter(level);

		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().mode == "freeze") {
				break;
			}
		}
		for (_ in 0...30) {
			player.step(new LocalPlayerInput());
		}

		for (_ in 0...30) {
			player.step(new LocalPlayerInput(true));
			if (player.debugState().touchedBlockType == "arrow_right") {
				break;
			}
		}

		var state = player.debugState();
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
			if (player.debugState().mode == "freeze") {
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

		assertEquals(90, player.debugState().courseRotation, "test course is rotated right");
		assertEquals("PushBlockMove", Type.enumConstructor(pushEvent.kind), "rotated push block emits movement");
		assertEquals(3, pushEvent.tileX, "rotated push block source x");
		assertEquals(4, pushEvent.tileY, "rotated push block source y");
		assertEquals(3, pushEvent.toTileX, "right-rotated right push keeps x");
		assertEquals(3, pushEvent.toTileY, "right-rotated right push maps to -y");
	}

	private static function bumpRotateBlock(type:BlockType):LocalCharacter {
		var player = new LocalCharacter(rotateBlockLevel(type));
		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().mode == "freeze") {
				return player;
			}
		}
		throw "rotate block was not bumped";
	}

	private static function newPlayer():LocalCharacter {
		return new LocalCharacter(LevelFixtureParser.parse(File.getContent("assets/fixtures/flat-level.json")));
	}

	private static function collectItem(level:FixtureLevel, itemId:Int):LocalCharacter {
		var player = new LocalCharacter(level);
		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().itemId == itemId) {
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
	private static function waterPoolLevel():FixtureLevel {
		var blocks:Array<LevelBlock> = [];
		for (tileY in 2...10) {
			blocks.push(new LevelBlock(2, tileY, BlockType.Water));
		}
		blocks.push(new LevelBlock(2, 10, BlockType.Solid));
		return new FixtureLevel(
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

	private static function emptyLevel(gravity:Float):FixtureLevel {
		return new FixtureLevel(
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

	private static function singleBlockLevel(type:BlockType):FixtureLevel {
		return new FixtureLevel(
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

	private static function lowCeilingLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function lowItemCeilingLevel(type:BlockType = BlockType.Item, options:String = "4"):FixtureLevel {
		return new FixtureLevel(
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

	private static function mineBlockLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function delayedMineBlockLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function safetyDropLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function itemBlockLevel(type:BlockType):FixtureLevel {
		return new FixtureLevel(
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

	private static function superJumpItemLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function teleportItemLevel(blocked:Bool):FixtureLevel {
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
		return new FixtureLevel(
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

	private static function speedBurstItemLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function speedBurstComparisonLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function jetPackItemLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function heldItemLevel(itemId:Int):FixtureLevel {
		return new FixtureLevel(
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

	private static function heldItemWithTargetBlockLevel(itemId:Int, targetType:BlockType = BlockType.Solid, targetX:Int = 4):FixtureLevel {
		var level = heldItemLevel(itemId);
		level.blocks.push(new LevelBlock(targetX, 5, targetType));
		return level;
	}

	private static function blockedMineItemLevel():FixtureLevel {
		var level = heldItemLevel(2);
		level.blocks.push(new LevelBlock(3, 4, BlockType.Solid));
		level.blocks.push(new LevelBlock(3, 5, BlockType.Solid));
		return level;
	}

	private static function jetPackComparisonLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function customStatsBlockLevel(options:String):FixtureLevel {
		return new FixtureLevel(
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

	private static function supplyBlockLevel(type:BlockType, options:String = ""):FixtureLevel {
		return new FixtureLevel(
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

	private static function finishBumpLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function customStatsResetLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function teleportPairLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function pushBlockLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function pushBlockChainLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function timedMoveBlockLevel(direction:String, blocked:Bool):FixtureLevel {
		var blocks:Array<LevelBlock> = [
			new LevelBlock(2, 3, BlockType.Move, direction),
			new LevelBlock(4, 4, BlockType.Finish)
		];
		if (blocked) {
			blocks.push(new LevelBlock(3, 3, BlockType.Solid));
		}
		return new FixtureLevel(
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

	private static function timedMovePushChainLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function randomMoveBlockLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function itemAndRandomMoveBlockLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function rotateBlockLevel(type:BlockType):FixtureLevel {
		return new FixtureLevel(
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

	private static function crumbleDropLevel():FixtureLevel {
		return new FixtureLevel(
			"crumble-drop",
			"Crumble Drop",
			5,
			13,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 0),
			new TilePosition(4, 8),
			[
				new LevelBlock(2, 8, BlockType.Crumble),
				new LevelBlock(2, 9, BlockType.Solid)
			]
		);
	}

	private static function cheeseSideCrumbleLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function vanishReappearLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function assertBelow(actual:Float, maximum:Float, message:String):Void {
		assertions++;
		if (actual >= maximum) {
			throw '$message: expected $actual below $maximum';
		}
	}
}
