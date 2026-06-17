package pr2.harness;

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
		testInitialStateIsGroundedOnStartBlock();
		testRunRightTouchesFinishBlock();
		testJumpAndLandOnFlatFixture();
		testCrouchOnlyWhileGrounded();
		testIceBlockReducesNextFrameAcceleration();
		testArrowStandEffectsMatchAs3Deltas();
		testFallingIntoWaterEntersSwimMode();
		testWaterDampsSinkingAndPaddlesUp();
		testLeavingWaterReturnsToLand();
		trace('LocalPlayerControllerTest passed $assertions assertions');
	}

	private static function testInitialStateIsGroundedOnStartBlock():Void {
		var player = newPlayer();
		var state = player.debugState();

		assertClose(75, state.x, "initial x centers player in start tile");
		assertClose(270, state.y, "initial y stands on start block");
		assertEquals(true, state.grounded, "initial grounded");
		assertEquals("stand", state.animation, "initial animation");
	}

	private static function testRunRightTouchesFinishBlock():Void {
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
	}

	private static function testJumpAndLandOnFlatFixture():Void {
		var player = newPlayer();

		player.step(new LocalPlayerInput(false, false, true));
		var jumpState = player.debugState();
		assertEquals(false, jumpState.grounded, "jump leaves ground");
		assertEquals("jump", jumpState.animation, "jump animation");
		assertBelow(jumpState.y, 270, "jump moves player up");

		for (_ in 0...40) {
			player.step(new LocalPlayerInput());
		}

		var landedState = player.debugState();
		assertEquals(true, landedState.grounded, "scripted jump lands");
		assertClose(270, landedState.y, "jump lands back on start block");
		assertEquals("stand", landedState.animation, "landed animation");
	}

	private static function testCrouchOnlyWhileGrounded():Void {
		var player = newPlayer();

		player.step(new LocalPlayerInput(false, false, false, true));
		var crouchState = player.debugState();
		assertEquals(true, crouchState.crouching, "down crouches while grounded");
		assertEquals("crouch", crouchState.animation, "crouch animation");
		assertClose(270, crouchState.y, "crouch preserves feet position");

		player.step(new LocalPlayerInput(false, false, true, true));
		assertEquals(true, player.debugState().crouching, "crouching blocks jump");
	}

	private static function testIceBlockReducesNextFrameAcceleration():Void {
		var normal = new LocalPlayerController(singleBlockLevel(BlockType.Basic));
		var icy = new LocalPlayerController(singleBlockLevel(BlockType.Ice));

		normal.step(new LocalPlayerInput(false, true));
		icy.step(new LocalPlayerInput(false, true));

		assertBelow(icy.debugState().vx, normal.debugState().vx * 0.2, "ice applies AS3 low accelFactor on next frame");
	}

	private static function testArrowStandEffectsMatchAs3Deltas():Void {
		assertClose(-10, new LocalPlayerController(singleBlockLevel(BlockType.ArrowUp)).debugState().vy, "up arrow stand launches upward");
		assertClose(5, new LocalPlayerController(singleBlockLevel(BlockType.ArrowDown)).debugState().vy, "down arrow stand pushes down");
		assertClose(-3, new LocalPlayerController(singleBlockLevel(BlockType.ArrowLeft)).debugState().vx, "left arrow stand pushes left");
		assertClose(3, new LocalPlayerController(singleBlockLevel(BlockType.ArrowRight)).debugState().vx, "right arrow stand pushes right");
	}

	private static function testFallingIntoWaterEntersSwimMode():Void {
		var player = new LocalPlayerController(waterPoolLevel());
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

	private static function testWaterDampsSinkingAndPaddlesUp():Void {
		var sinking = new LocalPlayerController(waterPoolLevel());
		for (_ in 0...40) {
			sinking.step(new LocalPlayerInput());
		}
		var sinkState = sinking.debugState();
		assertEquals("water", sinkState.mode, "idle player stays submerged");
		assertBelow(sinkState.vy, 5, "water damps sinking speed far below free-fall");
		assertBelow(0, sinkState.vy, "idle player still drifts downward");

		var paddling = new LocalPlayerController(waterPoolLevel());
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
		var player = new LocalPlayerController(waterPoolLevel());
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

	private static function newPlayer():LocalPlayerController {
		return new LocalPlayerController(LevelFixtureParser.parse(File.getContent("assets/fixtures/flat-level.json")));
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
			27,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 0),
			new TilePosition(5, 11),
			blocks
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
