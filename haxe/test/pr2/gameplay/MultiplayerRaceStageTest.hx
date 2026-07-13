package pr2.gameplay;

import pr2.level.BlockType;

class MultiplayerRaceStageTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testTwoPlayersStandingOnCrumble();
		testRepeatedDamageStopsAfterRemovalAndParticlesExpire();
		trace('MultiplayerRaceStageTest passed $assertions assertions');
	}

	private static function testTwoPlayersStandingOnCrumble():Void {
		var stage = new MultiplayerRaceStage(2, "m3`ffffff`0;0;11,0;1;17");
		stage.placeAllOnFirstBlock(BlockType.Crumble);
		stage.step(120);
		assertEquals(0, stage.activationCommands, "two standing clients emit no network traffic without a crumble state change");
		assertEquals(0, count(stage.activationPayloadCounts, "1"), "harmless force 1 contacts remain local");
		assertEquals(0, stage.maxActivePieces, "settled contacts produce no crumble particles through server echo");
		for (client in stage.clients) {
			assertEquals(0, client.activePieces(), "settled multiplayer stage leaves no active pieces");
		}
		stage.remove();
	}

	private static function testRepeatedDamageStopsAfterRemovalAndParticlesExpire():Void {
		var stage = new MultiplayerRaceStage(2, "m3`ffffff`0;0;11,0;1;17");
		var world = @:privateAccess stage.clients[0].course.worldLevel;
		var crumble = world.blocks[0];
		var segX = crumble.x;
		var segY = crumble.y;
		for (_ in 0...30) {
			stage.broadcastActivate(segX, segY, "20");
		}
		assertEquals(30, stage.activationCommands, "fake server records repeated damaging activations");
		stage.step(25);
		for (client in stage.clients) {
			assertEquals(0, client.activePieces(), "all crumble pieces expire and detach after their 20-frame lifetime");
		}
		stage.remove();
	}

	private static function count(counts:Map<String, Int>, key:String):Int {
		return counts.exists(key) ? counts.get(key) : 0;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
