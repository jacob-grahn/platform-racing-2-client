package pr2.character;

import pr2.harness.LocalPlayerInput;
import pr2.level.BlockType;
import pr2.level.FixtureLevel;
import pr2.level.FixtureLevel.LevelBlock;
import pr2.level.FixtureLevel.StatDefaults;
import pr2.level.FixtureLevel.TilePosition;
import pr2.net.LobbySocket;

class LocalCharacterEmitTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testInitAndCadenceGatedPositionEmission();
		testFallbackCadenceWithoutRemotePlayers();
		testTrackedVarAndEventEmission();
		testHeartBlockGainEmitsLocalHeartProtocol();
		trace('LocalCharacterEmitTest passed $assertions assertions');
	}

	private static function testInitAndCadenceGatedPositionEmission():Void {
		var character = new LocalCharacter(flatLevel());
		character.networkPlayerCount = 2;
		LobbySocket.resetSent();
		character.initNetworkEmission();
		assertCommands(["p`0`0"], "init emission");
		character.setControllerPosition(80, 100);

		for (_ in 0...4) {
			character.emitNetworkUpdate("backBackground");
		}
		assertCommands(["p`0`0"], "no position before update interval");

		character.emitNetworkUpdate("backBackground");
		assertCommands([
			"p`0`0",
			"p`80`100",
			"exact_pos`80`100",
			"set_var`scaleX`0.9",
			"set_var`state`stand",
			"set_var`parent`backBackground"
		], "fifth-frame position and vars");
	}

	private static function testFallbackCadenceWithoutRemotePlayers():Void {
		var character = new LocalCharacter(flatLevel());
		character.networkPlayerCount = 1;
		LobbySocket.resetSent();
		character.initNetworkEmission();
		character.setControllerPosition(150, 120);
		for (_ in 0...15) {
			character.emitNetworkUpdate();
		}
		assertEquals(1, countPositionCommands(), "solo frames wait for fallback position");
		assertEquals(false, hasCommandPrefix("exact_pos`"), "solo frames wait for fallback exact position");
		character.emitNetworkUpdate();
		assertEquals("p`150`120", commandWithPrefix("p`", 1), "solo fallback delta");
		assertEquals("exact_pos`150`120", commandWithPrefix("exact_pos`"), "solo fallback exact position");
	}

	private static function testTrackedVarAndEventEmission():Void {
		var character = new LocalCharacter(flatLevel());
		character.networkPlayerCount = 2;
		LobbySocket.resetSent();
		character.initNetworkEmission();
		character.step(new LocalPlayerInput(true));
		character.emitNetworkUpdate();
		character.step(new LocalPlayerInput(true));
		character.emitNetworkUpdate();
		character.step(new LocalPlayerInput(true));
		character.emitNetworkUpdate();
		character.step(new LocalPlayerInput(true));
		character.emitNetworkUpdate();
		character.setItem(4);
		character.step(new LocalPlayerInput(true));
		character.setItem(4);
		character.emitNetworkUpdate("frontBackground");
		assertContains("set_var`scaleX`-0.9", "left-facing scale var");
		assertContains("set_var`state`jump", "jump state var");
		assertContains("set_var`parent`frontBackground", "parent var");
		assertContains("set_var`item`4", "item var");

		LobbySocket.resetSent();
		character.setControllerPosition(70, 100);
		character.setNetworkRotation(90);
		character.beginSparklesNetwork();
		character.endSparklesNetwork();
		character.beginJetNetwork();
		character.endJetNetwork();
		character.emitSquash(7);
		character.emitSting(8);
		character.emitHeart(9);
		character.gainHeart();
		assertEquals(4, character.debugState().lives, "local gainHeart increments local lives");
		character.emitLooseHat(5, 123, 456);
		character.emitHatToStart(5);
		character.emitGrabEgg(3);
		character.emitObjectiveReached(2, 45, 75);
		character.emitFinishRace(1, 15, 30);
		character.emitQuitRace();
		character.emitFinishDrawing("hash", "race", "[1,2]", 1, 25, [4, 6]);
		character.emitCheckHatCountdown();
		character.beginRemove();
		assertCommands([
			"set_var`rotMod`90",
			"set_var`sparkle`1",
			"set_var`sparkle`0",
			"set_var`jet`1",
			"set_var`jet`0",
			"squash`7`70`100",
			"sting`8`70`100",
			"heart`9`70`100",
			"heart`",
			"loose_hat`5`123`456`70`100",
			"hat_to_start`5",
			"grab_egg`3",
			"objective_reached`2`45`75",
			"finish_race`1`15`30",
			"quit_race`",
			"finish_drawing`hash`race`[1,2]`1`25`4,6",
			"check_hat_countdown`",
			"set_var`beginRemove`1"
		], "event command emission");
	}

	private static function testHeartBlockGainEmitsLocalHeartProtocol():Void {
		var character = new LocalCharacter(heartSupplyLevel());
		character.setGameMode("deathmatch");
		LobbySocket.resetSent();
		for (_ in 0...40) {
			character.step(new LocalPlayerInput(false, false, true));
			if (character.debugState().touchedBlockType == "heart") {
				break;
			}
		}
		assertEquals("heart", character.debugState().touchedBlockType, "local player bumps the heart block");
		assertEquals(4, character.debugState().lives, "heart block gain increments local deathmatch lives");
		assertCommands(["heart`"], "heart block gain protocol");
	}

	private static function flatLevel():FixtureLevel {
		return new FixtureLevel(
			"local-character-emit-flat",
			"Local Character Emit Flat",
			8,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 6),
			[
				new LevelBlock(2, 4, BlockType.Basic),
				new LevelBlock(3, 4, BlockType.Basic),
				new LevelBlock(4, 4, BlockType.Basic)
			]
		);
	}

	private static function heartSupplyLevel():FixtureLevel {
		return new FixtureLevel(
			"local-character-heart-supply",
			"Local Character Heart Supply",
			5,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 3),
			new TilePosition(4, 4),
			[
				new LevelBlock(2, 1, BlockType.Heart),
				new LevelBlock(2, 4, BlockType.Solid),
				new LevelBlock(4, 4, BlockType.Finish)
			]
		);
	}

	private static function assertCommands(expected:Array<String>, label:String):Void {
		assertions++;
		var actual = LobbySocket.sentCommands.join("|");
		var exp = expected.join("|");
		if (actual != exp) {
			throw '$label expected $exp but was $actual';
		}
	}

	private static function assertContains(command:String, label:String):Void {
		assertions++;
		if (LobbySocket.sentCommands.indexOf(command) < 0) {
			throw '$label missing $command in ' + LobbySocket.sentCommands.join("|");
		}
	}

	private static function countPositionCommands():Int {
		var count = 0;
		for (command in LobbySocket.sentCommands) {
			if (StringTools.startsWith(command, "p`")) {
				count++;
			}
		}
		return count;
	}

	private static function hasCommandPrefix(prefix:String):Bool {
		for (command in LobbySocket.sentCommands) {
			if (StringTools.startsWith(command, prefix)) {
				return true;
			}
		}
		return false;
	}

	private static function commandWithPrefix(prefix:String, occurrence:Int = 0):String {
		var seen = 0;
		for (command in LobbySocket.sentCommands) {
			if (StringTools.startsWith(command, prefix)) {
				if (seen == occurrence) {
					return command;
				}
				seen++;
			}
		}
		return "";
	}

	private static function assertEquals<T>(expected:T, actual:T, label:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$label expected $expected but was $actual';
		}
	}
}
