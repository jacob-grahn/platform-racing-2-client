package pr2.gameplay;

import pr2.harness.LocalPlayerController;
import pr2.harness.LocalPlayerInput;
import pr2.level.BlockType;
import pr2.level.FixtureLevel;
import pr2.level.FixtureLevel.LevelBlock;
import pr2.level.FixtureLevel.StatDefaults;
import pr2.level.FixtureLevel.TilePosition;

class RoguelikeModeTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testInitialStateAndHeartCap();
		testConfigurationBansEveryHat();
		testNinthFinishWinsBeforeLastHeartDeath();
		testDeathResetsProgressionResources();
		testCombatDamageRestartsRun();
		trace('RoguelikeModeTest passed $assertions assertions');
	}

	private static function testInitialStateAndHeartCap():Void {
		var player = new LocalPlayerController(level());
		player.setGameMode(Modes.roguelike);
		var state = player.debugState();
		assertEquals(0, state.speedStat, "zero starting speed");
		assertEquals(0, state.accelerationStat, "zero starting acceleration");
		assertEquals(0, state.jumpStat, "zero starting jump");
		assertEquals(1, state.lives, "one starting heart");
		player.setLife(99);
		assertEquals(10, player.debugState().lives, "ten-heart cap");
	}

	private static function testConfigurationBansEveryHat():Void {
		var config = new LevelConfig();
		config.setGameMode(Modes.roguelike);
		config.setBadHats("");
		assertEquals(15, config.badHats.length, "roguelike bans every selectable hat");
		assertEquals(2, config.badHats[0], "roguelike ban list starts at the first real hat");
		assertEquals(16, config.badHats[config.badHats.length - 1], "roguelike ban list includes the final hat");
	}

	private static function testNinthFinishWinsBeforeLastHeartDeath():Void {
		var fixture = level();
		var player = new LocalPlayerController(fixture);
		player.setGameMode(Modes.roguelike);
		player.setLife(9);
		var finish = fixture.blocks[4];
		for (hit in 1...LocalPlayerController.ROGUELIKE_REQUIRED_FINISH_HITS) {
			@:privateAccess player.finish(finish);
			assertEquals(hit, player.debugState().roguelikeFinishHits, 'finish hit $hit counted');
			assertEquals(false, player.debugState().finished, 'finish hit $hit is non-terminal');
		}
		@:privateAccess player.finish(finish);
		var state = player.debugState();
		assertEquals(9, state.roguelikeFinishHits, "ninth finish counted");
		assertEquals(true, state.finished, "ninth finish is terminal");
		assertEquals(0, state.lives, "ninth finish consumes last heart without restarting");
	}

	private static function testDeathResetsProgressionResources():Void {
		var fixture = level();
		var player = new LocalPlayerController(fixture);
		player.setGameMode(Modes.roguelike);
		@:privateAccess player.useStatSupply(fixture.blocks[0], false);
		@:privateAccess player.useSupply(fixture.blocks[1]);
		@:privateAccess player.useItemBlock(fixture.blocks[2]);
		@:privateAccess player.useCustomStatsBlock(fixture.blocks[3]);
		player.setLife(2);
		@:privateAccess player.finish(fixture.blocks[4]);
		@:privateAccess player.resetRoguelikeRun();
		var state = player.debugState();
		assertEquals(0, state.roguelikeFinishHits, "death clears finish progress");
		assertEquals(1, state.lives, "death restores one heart");
		assertEquals(0, state.speedStat, "death restores zero stats");
		assertEquals(null, state.itemId, "death clears held item");
		for (i in 0...4) {
			var block = fixture.blocks[i];
			assertEquals(1.0, player.blockColorMultiplierAt(block.x, block.y), 'death resets progression block $i');
		}
	}

	private static function testCombatDamageRestartsRun():Void {
		var player = new LocalPlayerController(level());
		player.setGameMode(Modes.roguelike);
		player.setLife(2);
		player.receiveHit();
		assertEquals(1, player.debugState().lives, "combat consumes one heart");
		for (_ in 0...60) player.step(new LocalPlayerInput());
		player.receiveHit();
		assertEquals(1, player.debugState().lives, "lethal combat restarts with one heart");
		assertEquals(false, player.debugState().finished, "lethal combat is not a race finish");
	}

	private static function level():FixtureLevel {
		return new FixtureLevel(
			"roguelike",
			"Roguelike",
			8,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(1, 3),
			new TilePosition(6, 1),
			[
				new LevelBlock(1, 1, BlockType.Happy, "20"),
				new LevelBlock(2, 1, BlockType.Heart),
				new LevelBlock(3, 1, BlockType.Item, "4"),
				new LevelBlock(4, 1, BlockType.CustomStats, "80-80-80"),
				new LevelBlock(6, 1, BlockType.Finish),
				new LevelBlock(1, 4, BlockType.Solid)
			]
		);
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
