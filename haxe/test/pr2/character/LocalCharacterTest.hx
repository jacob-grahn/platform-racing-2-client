package pr2.character;

import pr2.gameplay.player.LocalPlayerController;
import pr2.gameplay.player.LocalPlayerInput;
import pr2.level.BlockType;
import pr2.level.WorldLevel;
import pr2.level.WorldLevel.LevelBlock;
import pr2.level.WorldLevel.StatDefaults;
import pr2.level.WorldLevel.TilePosition;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;

class LocalCharacterTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testDelegatesPhysicsAndMirrorsCharacterState();
		if (pr2.DeterministicTestMode.finishSmokeSuite("LocalCharacterTest")) return;
		testPropellerHatSlowsFallWhenHoldingJump();
		testCowboyHatBoostsStatsAndForcesAirborneWaterModeUntilRemoved();
		testMoonHatReducesGravityUntilRemoved();
		testSantaHatStandsOnWaterAndSafetyAndRaisesSpeedCapUntilRemoved();
		testPartyHatIgnoresStingAndZapHurtReactions();
		testTopHatPassesThroughVanishBlocks();
		testCrownHatIgnoresMineHitsExceptDeathmatch();
		testJumpStartHatGrantsTwoSecondSpeedBurstOnEquip();
		testArtifactHatGrantsThirtySecondBurstAndReversesControlsUntilRemoved();
		testAprilFirstReversesControlsUntilArtifactRemoved();
		testJiggminHatSquashesRemotePlayersWhileFalling();
		testJellyfishHatStingsNearbyRemotePlayersAndIgnoresStingHurt();
		testCheeseHatIsCosmeticOnly();
		testHatAttackHitDropsHighestHat();
		trace('LocalCharacterTest passed $assertions assertions');
	}

	private static function testDelegatesPhysicsAndMirrorsCharacterState():Void {
		var level = flatLevel();
		var controller = new LocalPlayerController(level);
		var character = new LocalCharacter(level);
		assertSameState(controller, character, "initial sync");
		assertEquals("local", character.type, "local character type");

		var inputs = [
			new LocalPlayerInput(),
			new LocalPlayerInput(false, true),
			new LocalPlayerInput(false, true),
			new LocalPlayerInput(false, false, true),
			new LocalPlayerInput(false, false, true),
			new LocalPlayerInput(),
			new LocalPlayerInput(true, false),
			new LocalPlayerInput()
		];

		for (i in 0...inputs.length) {
			controller.step(inputs[i]);
			character.step(inputs[i].copy());
			assertSameState(controller, character, 'frame $i');
		}

		character.setGravity(2.5);
		controller.setGravity(2.5);
		controller.step(new LocalPlayerInput());
		character.step(new LocalPlayerInput());
		assertSameState(controller, character, "runtime gravity sync");
	}

	private static function testPropellerHatSlowsFallWhenHoldingJump():Void {
		var normal = new LocalCharacter(airborneLevel());
		var propeller = new LocalCharacter(airborneLevel());
		propeller.setHats([4, 0xFFFFFF, -1]);

		normal.step(new LocalPlayerInput(false, false, true));
		propeller.step(new LocalPlayerInput(false, false, true));
		assertClose(normal.stateSnapshot().vy * 0.85, propeller.stateSnapshot().vy, "propeller slows falling while jump is held");

		var notHeld = new LocalCharacter(airborneLevel());
		notHeld.setHats([4, 0xFFFFFF, -1]);
		notHeld.step(new LocalPlayerInput());
		assertClose(normal.stateSnapshot().vy, notHeld.stateSnapshot().vy, "propeller does not slow falling without jump held");
	}

	private static function testCowboyHatBoostsStatsAndForcesAirborneWaterModeUntilRemoved():Void {
		var cowboy = new LocalCharacter(airborneLevel());
		cowboy.setHats([5, 0xFFFFFF, -1]);

		var equipped = cowboy.stateSnapshot();
		assertClose(100, equipped.speedStat, "cowboy hat raises speed to Flash minimum");
		assertClose(99.6, equipped.accelerationStat, "cowboy hat raises acceleration to Flash minimum");
		assertClose(100, equipped.jumpStat, "cowboy hat raises jump to Flash minimum");

		cowboy.step(new LocalPlayerInput());
		var swimming = cowboy.stateSnapshot();
		assertEquals("water", swimming.mode, "cowboy hat forces airborne water mode");
		assertEquals("swim", swimming.animation, "cowboy airborne mode uses swim animation");

		cowboy.setHats([]);
		var removed = cowboy.stateSnapshot();
		assertClose(50, removed.speedStat, "cowboy hat removal restores starting speed");
		assertClose(50, removed.accelerationStat, "cowboy hat removal restores starting acceleration");
		assertClose(50, removed.jumpStat, "cowboy hat removal restores starting jump");
	}

	private static function testMoonHatReducesGravityUntilRemoved():Void {
		var normal = new LocalCharacter(heavyGravityAirborneLevel());
		var moon = new LocalCharacter(heavyGravityAirborneLevel());
		moon.setHats([11, 0xFFFFFF, -1]);

		normal.step(new LocalPlayerInput());
		moon.step(new LocalPlayerInput());
		assertClose(normal.stateSnapshot().vy * 0.85, moon.stateSnapshot().vy, "moon hat applies low gravity");

		var removed = new LocalCharacter(heavyGravityAirborneLevel());
		removed.setHats([11, 0xFFFFFF, -1]);
		removed.setHats([]);
		removed.step(new LocalPlayerInput());
		assertClose(normal.stateSnapshot().vy, removed.stateSnapshot().vy, "moon hat removal restores level gravity");
	}

	private static function testSantaHatStandsOnWaterAndSafetyAndRaisesSpeedCapUntilRemoved():Void {
		var normalWater = new LocalCharacter(nonSolidFloorLevel(BlockType.Water));
		var santaWater = new LocalCharacter(nonSolidFloorLevel(BlockType.Water));
		santaWater.setHats([7, 0xFFFFFF, -1]);

		normalWater.step(new LocalPlayerInput());
		santaWater.step(new LocalPlayerInput());
		assertEquals(false, normalWater.stateSnapshot().grounded, "water remains non-solid without santa hat");
		assertEquals(true, santaWater.stateSnapshot().grounded, "santa hat stands on water");
		assertClose(90, santaWater.stateSnapshot().y, "santa water stand snaps to block top");

		var santaSafety = new LocalCharacter(nonSolidFloorLevel(BlockType.Safety));
		santaSafety.setHats([7, 0xFFFFFF, -1]);
		santaSafety.step(new LocalPlayerInput());
		assertEquals(true, santaSafety.stateSnapshot().grounded, "santa hat stands on safety blocks");
		assertClose(90, santaSafety.stateSnapshot().y, "santa safety stand snaps to block top");

		var normal = new LocalCharacter(longFlatLevel());
		var santa = new LocalCharacter(longFlatLevel());
		santa.setHats([7, 0xFFFFFF, -1]);
		for (_ in 0...90) {
			normal.step(new LocalPlayerInput(false, true));
			santa.step(new LocalPlayerInput(false, true));
		}
		assertAbove(santa.stateSnapshot().vx, normal.stateSnapshot().vx + 0.5, "santa hat raises max horizontal velocity");

		var removed = new LocalCharacter(longFlatLevel());
		removed.setHats([7, 0xFFFFFF, -1]);
		removed.setHats([]);
		for (_ in 0...90) {
			removed.step(new LocalPlayerInput(false, true));
		}
		assertClose(normal.stateSnapshot().vx, removed.stateSnapshot().vx, "santa hat removal restores max horizontal velocity");
	}

	private static function testPartyHatIgnoresStingAndZapHurtReactions():Void {
		var stung = new LocalCharacter(flatLevel());
		stung.receiveSting();
		assertEquals("hurt", stung.stateSnapshot().mode, "sting puts an unprotected local character in hurt mode");

		var partyStung = new LocalCharacter(flatLevel());
		partyStung.setHats([8, 0xFFFFFF, -1]);
		partyStung.receiveSting();
		assertEquals("land", partyStung.stateSnapshot().mode, "party hat ignores sting hurt reaction");

		var zapped = new LocalCharacter(flatLevel());
		zapped.receiveZap();
		assertEquals("hurt", zapped.stateSnapshot().mode, "zap puts an unprotected local character in hurt mode");

		var partyZapped = new LocalCharacter(flatLevel());
		partyZapped.setHats([8, 0xFFFFFF, -1]);
		partyZapped.receiveZap();
		assertEquals("land", partyZapped.stateSnapshot().mode, "party hat ignores zap hurt reaction");
	}

	private static function testTopHatPassesThroughVanishBlocks():Void {
		var normal = new LocalCharacter(vanishWallLevel());
		var top = new LocalCharacter(vanishWallLevel());
		top.setHats([9, 0xFFFFFF, -1]);

		for (_ in 0...8) {
			normal.step(new LocalPlayerInput(false, true));
			top.step(new LocalPlayerInput(false, true));
		}

		assertClose(80, normal.stateSnapshot().x, "vanish wall stops a character without top hat");
		assertAbove(top.stateSnapshot().x, 86, "top hat passes through vanish wall");
	}

	private static function testCrownHatIgnoresMineHitsExceptDeathmatch():Void {
		var normal = new LocalCharacter(delayedMineBlockLevel());
		var crown = new LocalCharacter(delayedMineBlockLevel());
		crown.setHats([6, 0xFFFFFF, -1]);

		for (_ in 0...40) {
			normal.step(new LocalPlayerInput());
			crown.step(new LocalPlayerInput());
			if (normal.stateSnapshot().touchedBlockType == "mine") {
				break;
			}
		}

		assertEquals("hurt", normal.stateSnapshot().mode, "mine hit hurts an unprotected character");
		assertEquals("land", crown.stateSnapshot().mode, "crown hat ignores mine hurt in race mode");
		assertClose(0, crown.stateSnapshot().vy, "crown hat ignores mine knockback in race mode");

		var deathmatchCrown = new LocalCharacter(delayedMineBlockLevel());
		deathmatchCrown.setGameMode("deathmatch");
		deathmatchCrown.setHats([6, 0xFFFFFF, -1]);
		for (_ in 0...40) {
			deathmatchCrown.step(new LocalPlayerInput());
			if (deathmatchCrown.stateSnapshot().touchedBlockType == "mine") {
				break;
			}
		}

		assertEquals("hurt", deathmatchCrown.stateSnapshot().mode, "crown hat does not block mine hurt in deathmatch");
		assertClose(-50, deathmatchCrown.stateSnapshot().vy, "deathmatch crown mine hit still applies knockback");
	}

	private static function testJumpStartHatGrantsTwoSecondSpeedBurstOnEquip():Void {
		var normal = new LocalCharacter(longFlatLevel());
		var jumpStart = new LocalCharacter(longFlatLevel());
		jumpStart.setHats([10, 0xFFFFFF, -1]);

		assertEquals(7, jumpStart.stateSnapshot().itemId, "jump-start hat immediately uses a speed burst");
		for (_ in 0...24) {
			normal.step(new LocalPlayerInput(false, true));
			jumpStart.step(new LocalPlayerInput(false, true));
		}
		assertBelow(normal.stateSnapshot().vx * 1.4, jumpStart.stateSnapshot().vx, "jump-start speed burst boosts movement");

		for (_ in 0...30) {
			jumpStart.step(new LocalPlayerInput(false, true));
		}
		assertEquals(null, jumpStart.stateSnapshot().itemId, "jump-start speed burst expires after two seconds");
		assertClose(50, jumpStart.stateSnapshot().speedStat, "jump-start expiry restores speed stat");
		assertClose(50, jumpStart.stateSnapshot().accelerationStat, "jump-start expiry restores acceleration stat");
	}

	private static function testArtifactHatGrantsThirtySecondBurstAndReversesControlsUntilRemoved():Void {
		var artifact = new LocalCharacter(longFlatLevel());
		var sounds:Array<String> = [];
		var musicActivations = 0;
		artifact.onPlayCharacterSound = function(request):Void {
			sounds.push(request.kind + ":" + request.volume);
		};
		artifact.onArtifactHatActivated = function():Void {
			musicActivations++;
		};
		artifact.setHats([14, 0xFFFFFF, -1]);

		assertEquals(7, artifact.stateSnapshot().itemId, "artifact hat immediately uses a speed burst");
		assertEquals(30, artifact.stateSnapshot().courseTime, "artifact hat clamps race timer to thirty seconds");
		assertEquals(true, artifact.artifactControlsReversed, "artifact hat reverses controls on equip");
		assertEquals("artifactYeah:1", sounds.join("|"), "artifact hat emits yeah feedback");
		assertEquals(1, musicActivations, "artifact hat switches to artifact music once");

		for (_ in 0...24) {
			artifact.step(new LocalPlayerInput(false, true));
		}
		assertBelow(artifact.stateSnapshot().vx, -0.1, "artifact reversed controls turn right input into left movement");

		artifact.setHats([]);
		assertEquals(null, artifact.stateSnapshot().itemId, "artifact hat removal clears active speed burst");
		assertEquals(false, artifact.artifactControlsReversed, "artifact hat removal restores controls");

		var restored = new LocalCharacter(longFlatLevel());
		var removedFresh = new LocalCharacter(longFlatLevel());
		removedFresh.setHats([14, 0xFFFFFF, -1]);
		removedFresh.setHats([]);
		removedFresh.step(new LocalPlayerInput(false, true));
		restored.step(new LocalPlayerInput(false, true));
		assertAbove(removedFresh.stateSnapshot().vx, 0, "right input moves right after artifact removal");
		assertClose(restored.stateSnapshot().speedStat, artifact.stateSnapshot().speedStat, "artifact removal restores speed stat");
		assertClose(restored.stateSnapshot().accelerationStat, artifact.stateSnapshot().accelerationStat, "artifact removal restores acceleration stat");
	}

	private static function testAprilFirstReversesControlsUntilArtifactRemoved():Void {
		var originalDateString = Character.dateStringNow;
		Character.dateStringNow = function() return "Apr 1";
		var april = new LocalCharacter(longFlatLevel());

		assertEquals(true, april.dateControlsReversed, "April 1 initializes date-driven reversed controls");
		assertEquals(false, april.artifactControlsReversed, "April 1 reversal is independent of artifact hat state");
		for (_ in 0...24) {
			april.step(new LocalPlayerInput(false, true));
		}
		assertBelow(april.stateSnapshot().vx, -0.1, "April 1 reversed controls turn right input into left movement");

		april.setHats([14, 0xFFFFFF, -1]);
		april.setHats([]);
		assertEquals(false, april.artifactControlsReversed, "artifact removal clears only artifact reversal state");
		for (_ in 0...24) {
			april.step(new LocalPlayerInput(false, true));
		}
		assertBelow(april.stateSnapshot().vx, -0.1, "artifact removal preserves April 1 reversed controls");
		Character.dateStringNow = originalDateString;
	}

	private static function testJiggminHatSquashesRemotePlayersWhileFalling():Void {
		var local = new LocalCharacter(airborneLevel());
		local.setHats([13, 0xFFFFFF, -1]);
		local.step(new LocalPlayerInput());
		var remote = new RemoteCharacter(7, null, "Rival", 1, 1, 1, 1, "0", new CommandHandler());
		remote.setPos(local.x + 5, local.y + 50);
		remote.changeState("stand");
		var sounds:Array<String> = [];
		local.onPlayCharacterSound = function(request):Void {
			sounds.push(request.kind + ":" + request.volume + ":" + Math.round(request.x) + ":" + Math.round(request.y));
		};
		LobbySocket.resetSent();

		assertEquals(true, local.maybeSquash([local, remote]), "jiggmin hat squashes a remote below while falling");
		assertEquals("crouch", remote.state, "squashed remote predicts crouch state");
		assertClose(-3, local.stateSnapshot().vy, "squash bounce sets upward velocity");
		assertEquals(true, local.stateSnapshot().grounded, "squash bounce marks the local character grounded");
		assertEquals("squash:0.66:" + Math.round(local.x) + ":" + Math.round(local.y), sounds.join("|"), "squash sound hook fires at local position");
		assertEquals("squash`7`" + Math.round(local.x) + "`" + Math.round(local.y), LobbySocket.lastSent(), "squash emits remote id and local coordinates");

		var noHat = new LocalCharacter(airborneLevel());
		noHat.step(new LocalPlayerInput());
		var untouched = new RemoteCharacter(8, null, "Other", 1, 1, 1, 1, "0", new CommandHandler());
		untouched.setPos(noHat.x + 5, noHat.y + 50);
		untouched.changeState("stand");
		LobbySocket.resetSent();
		assertEquals(false, noHat.maybeSquash([untouched]), "missing jiggmin hat does not squash");
		assertEquals("stand", untouched.state, "remote stays standing without jiggmin hat");
		assertEquals(0, LobbySocket.sentCommands.length, "no squash command without jiggmin hat");

		remote.remove();
		untouched.remove();
	}

	private static function testJellyfishHatStingsNearbyRemotePlayersAndIgnoresStingHurt():Void {
		var jellyfish = new LocalCharacter(flatLevel());
		jellyfish.setHats([15, 0xFFFFFF, -1]);
		jellyfish.receiveSting();
		assertEquals("land", jellyfish.stateSnapshot().mode, "jellyfish hat ignores sting hurt reaction");

		var remote = new RemoteCharacter(9, null, "Rival", 1, 1, 1, 1, "0", new CommandHandler());
		remote.setPos(jellyfish.x + 30, jellyfish.y + 20);
		remote.changeState("stand");
		LobbySocket.resetSent();

		assertEquals(true, jellyfish.tickJellyfishSting([jellyfish, remote], 1), "jellyfish roll stings a nearby remote");
		assertEquals("sting`9`" + Math.round(jellyfish.x) + "`" + Math.round(jellyfish.y), LobbySocket.lastSent(), "jellyfish sting emits remote id and local coordinates");
		assertEquals(135, jellyfish.stingCooldown, "jellyfish sting starts five-second cooldown");

		LobbySocket.resetSent();
		assertEquals(false, jellyfish.tickJellyfishSting([remote], 1), "jellyfish cooldown blocks immediate repeat sting");
		assertEquals(134, jellyfish.stingCooldown, "jellyfish cooldown decrements each tick");
		assertEquals(0, LobbySocket.sentCommands.length, "cooldown suppresses sting command");

		var noHat = new LocalCharacter(flatLevel());
		LobbySocket.resetSent();
		assertEquals(false, noHat.tickJellyfishSting([remote], 1), "missing jellyfish hat does not sting");
		assertEquals(0, LobbySocket.sentCommands.length, "no sting command without jellyfish hat");

		var far = new RemoteCharacter(10, null, "Far", 1, 1, 1, 1, "0", new CommandHandler());
		far.setPos(jellyfish.x + 90, jellyfish.y);
		for (_ in 0...134) {
			jellyfish.tickJellyfishSting([remote], 2);
		}
		LobbySocket.resetSent();
		assertEquals(false, jellyfish.tickJellyfishSting([far], 1), "jellyfish hat only stings nearby remotes");
		assertEquals(0, LobbySocket.sentCommands.length, "out-of-range remote is not stung");

		remote.remove();
		far.remove();
	}

	private static function testCheeseHatIsCosmeticOnly():Void {
		var normal = new LocalCharacter(longFlatLevel());
		var cheese = new LocalCharacter(longFlatLevel());
		cheese.setHats([16, 0xC8B040, -1]);
		assertEquals(true, cheese.hasHatFlag(Character.CHEESE), "cheese hat flag is set for cosmetic rendering");

		for (_ in 0...30) {
			normal.step(new LocalPlayerInput(false, true));
			cheese.step(new LocalPlayerInput(false, true));
		}
		assertEquals(normal.stateSnapshot().serialize(), cheese.stateSnapshot().serialize(), "cheese hat does not change land movement");

		var normalFall = new LocalCharacter(airborneLevel());
		var cheeseFall = new LocalCharacter(airborneLevel());
		cheeseFall.setHats([16, 0xC8B040, -1]);
		normalFall.step(new LocalPlayerInput(false, false, true));
		cheeseFall.step(new LocalPlayerInput(false, false, true));
		assertEquals(normalFall.stateSnapshot().serialize(), cheeseFall.stateSnapshot().serialize(), "cheese hat does not change falling movement");

		var stung = new LocalCharacter(flatLevel());
		var cheeseStung = new LocalCharacter(flatLevel());
		cheeseStung.setHats([16, 0xC8B040, -1]);
		stung.receiveSting();
		cheeseStung.receiveSting();
		assertEquals(stung.stateSnapshot().serialize(), cheeseStung.stateSnapshot().serialize(), "cheese hat does not block sting hurt");
	}

	private static function testHatAttackHitDropsHighestHat():Void {
		var local = new LocalCharacter(delayedMineBlockLevel());
		local.setGameMode("hat");
		local.setHats([6, 0xFF0000, -1, 9, 0x00FF00, 0]);
		LobbySocket.resetSent();

		for (_ in 0...40) {
			local.step(new LocalPlayerInput());
			if (local.stateSnapshot().touchedBlockType == "mine") {
				break;
			}
		}

		assertEquals("hurt", local.stateSnapshot().mode, "hat attack mine hit hurts the local character");
		assertEquals("loose_hat`75`40`0", LobbySocket.lastSent(), "hat attack hit emits Flash loose-hat drop");
		assertEquals(6, local.hat1, "lower hat remains equipped after top hat drops");
		assertEquals(1, local.hat2, "highest occupied slot is cleared after drop");

		LobbySocket.resetSent();
		for (_ in 0...5) {
			local.step(new LocalPlayerInput());
		}
		assertEquals("", LobbySocket.lastSent(), "hurt recovery frames do not drop more hats");
	}

	private static function assertSameState(controller:LocalPlayerController, character:LocalCharacter, label:String):Void {
		var expected = controller.stateSnapshot();
		var actual = character.stateSnapshot();
		assertEquals(expected.serialize(), actual.serialize(), '$label debug state');
		assertClose(expected.x, character.x, '$label x');
		assertClose(expected.y, character.y, '$label y');
		assertClose(expected.vx, character.velX, '$label velX');
		assertClose(expected.vy, character.velY, '$label velY');
		assertEquals(expected.grounded, character.grounded, '$label grounded');
		assertEquals(expected.crouching, character.crouching, '$label crouching');
		assertEquals(expected.animation, character.state, '$label animation state');
		assertClose(0.9 * controller.facingScaleX, character.display.scaleX, '$label facing scale');
	}

	private static function flatLevel():WorldLevel {
		return new WorldLevel(
			"local-character-flat",
			"Local Character Flat",
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

	private static function airborneLevel():WorldLevel {
		return new WorldLevel(
			"local-character-airborne",
			"Local Character Airborne",
			8,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 6),
			[]
		);
	}

	private static function heavyGravityAirborneLevel():WorldLevel {
		return new WorldLevel(
			"local-character-heavy-airborne",
			"Local Character Heavy Airborne",
			8,
			8,
			30,
			2,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 6),
			[]
		);
	}

	private static function nonSolidFloorLevel(type:BlockType):WorldLevel {
		return new WorldLevel(
			"local-character-non-solid-floor",
			"Local Character Non-solid Floor",
			8,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 6),
			[new LevelBlock(2, 3, type)]
		);
	}

	private static function longFlatLevel():WorldLevel {
		var blocks:Array<LevelBlock> = [];
		for (tileX in 0...38) {
			blocks.push(new LevelBlock(tileX, 4, BlockType.Basic));
		}
		return new WorldLevel(
			"local-character-long-flat",
			"Local Character Long Flat",
			40,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(38, 6),
			blocks
		);
	}

	private static function vanishWallLevel():WorldLevel {
		return new WorldLevel(
			"local-character-vanish-wall",
			"Local Character Vanish Wall",
			8,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 6),
			[
				new LevelBlock(1, 3, BlockType.Basic),
				new LevelBlock(2, 3, BlockType.Basic),
				new LevelBlock(3, 3, BlockType.Basic),
				new LevelBlock(4, 3, BlockType.Basic),
				new LevelBlock(3, 2, BlockType.Vanish)
			]
		);
	}

	private static function delayedMineBlockLevel():WorldLevel {
		return new WorldLevel(
			"local-character-delayed-mine-block",
			"Local Character Delayed Mine Block",
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

	private static function assertEquals<T>(expected:T, actual:T, label:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$label expected $expected but was $actual';
		}
	}

	private static function assertClose(expected:Float, actual:Float, label:String, epsilon:Float = 0.001):Void {
		assertions++;
		if (Math.abs(expected - actual) > epsilon) {
			throw '$label expected $expected but was $actual';
		}
	}

	private static function assertAbove(actual:Float, minimum:Float, label:String):Void {
		assertions++;
		if (actual <= minimum) {
			throw '$label expected above $minimum but was $actual';
		}
	}

	private static function assertBelow(actual:Float, maximum:Float, label:String):Void {
		assertions++;
		if (actual >= maximum) {
			throw '$label expected below $maximum but was $actual';
		}
	}
}
