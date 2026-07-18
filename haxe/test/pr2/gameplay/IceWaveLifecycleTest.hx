package pr2.gameplay;

import openfl.display.Shape;
import openfl.display.Sprite;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevel;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.net.CommandHandler;

@:access(pr2.gameplay.EggRound)
class IceWaveLifecycleTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testAuthoredSpawnAndTravel();
		if (pr2.DeterministicTestMode.finishSmokeSuite("IceWaveLifecycleTest")) return;
		testBranchingAndLifetimeInheritance();
		testBranchBoundsAndActiveGuard();
		testIceBlocksAndTeardown();
		trace('IceWaveLifecycleTest passed $assertions assertions');
	}

	private static function testAuthoredSpawnAndTravel():Void {
		var layer = new Sprite();
		var round = createRound(layer);
		round.mountAttackVisual("IceWave`0`15`0`0`7");
		assertEquals(3, round.activeAttackVisualCount(), "IceWave command creates the authored three-shot fan");
		var straight = @:privateAccess round.attackVisuals[0];
		assertNear(30, straight.posX, 0.001, "skipPastSpawn advances internal x by 30 before the first frame");
		assertNear(15, straight.posY, 0.001, "straight skipPastSpawn preserves y");
		assertNear(0, straight.display.x, 0.001, "skipPastSpawn does not reposition the display until the first frame");
		var art = Std.downcast(straight.display.getChildByName("iceWaveCore"), Shape);
		assertTrue(art != null && art.width > 75 && art.height > 65, "IceWave renders the exact authored XFL silhouette");

		round.step(new ServerLevel(0xffffff, []));
		assertNear(35, straight.display.x, 0.001, "first frame continues from the skipped position at speed five");
		assertEquals(74, straight.life, "IceWave lifetime decrements after movement and collision checks");
		round.clear();
	}

	private static function testBranchingAndLifetimeInheritance():Void {
		var layer = new Sprite();
		var frozen = 0;
		var round = createRound(layer, function(_):Void frozen++);
		var parent = @:privateAccess round.addIceWaveVisual(0, 15, 0, 0, 7, 0, 75);
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 30, 0);
		round.step(new ServerLevel(0xffffff, [block]));

		assertEquals(1, frozen, "non-ice block collision freezes the block");
		assertEquals(3, round.activeAttackVisualCount(), "block collision creates both bounded child waves");
		assertEquals(69, parent.life, "branching costs five life before the normal frame decrement");
		assertNear(65, parent.posX, 0.001, "parent immediately skips another 30 units after branching");
		assertNear(35, parent.display.x, 0.001, "continued skip keeps the impact frame visible until the next tick");
		var children = [for (visual in @:privateAccess round.attackVisuals) if (visual != parent) visual];
		assertEquals(37, children[0].life, "child inherits the parent's pre-cost half-life");
		assertEquals(37, children[1].life, "both children inherit the same half-life");
		assertNear(30, children[0].angle, 0.001, "upper child branches by 30 degrees");
		assertNear(-30, children[1].angle, 0.001, "lower child branches by 30 degrees");

		round.step(new ServerLevel(0xffffff, []));
		assertNear(70, parent.display.x, 0.001, "parent continues travelling after its block branch");
		round.clear();
	}

	private static function testBranchBoundsAndActiveGuard():Void {
		assertAngles([30.0], EggRound.iceBranchAngles(60, 0), "upper bound suppresses a duplicate +60 child");
		assertAngles([-30.0], EggRound.iceBranchAngles(-60, 0), "lower bound suppresses a duplicate -60 child");
		assertAngles([60.0, 0.0], EggRound.iceBranchAngles(30, 0), "interior branch produces both children");

		var layer = new Sprite();
		var round = createRound(layer);
		for (_ in 0...9) @:privateAccess round.addIceWaveVisual(0, 15, 0, 0, 7, 0, 75);
		round.step(new ServerLevel(0xffffff, [new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 30, 0)]));
		assertEquals(11, round.activeAttackVisualCount(),
			"active-count guard matches Flash by allowing the triggering wave's pair before suppressing later branches");
		var inherited = 0;
		for (visual in @:privateAccess round.attackVisuals) if (visual.life == 37) inherited++;
		assertEquals(2, inherited, "only the first wave below the active-count guard creates children");
		round.clear();
	}

	private static function testIceBlocksAndTeardown():Void {
		var layer = new Sprite();
		var frozen = 0;
		var round = createRound(layer, function(_):Void frozen++);
		var visual = @:privateAccess round.addIceWaveVisual(0, 15, 0, 0, 7, 0, 75);
		round.step(new ServerLevel(0xffffff, [new DecodedBlock(ObjectCodes.BLOCK_ICE, 30, 0)]));
		assertEquals(0, frozen, "existing ice blocks are not frozen again");
		assertEquals(1, round.activeAttackVisualCount(), "ice blocks do not branch the wave");
		assertEquals(74, visual.life, "ice-block pass-through only costs the normal frame life");

		visual.life = 1;
		round.step(new ServerLevel(0xffffff, []));
		assertEquals(0, round.activeAttackVisualCount(), "life exhaustion removes the wave from active tracking");
		assertEquals(null, visual.display.parent, "life exhaustion detaches the authored art");
		assertEquals(0, layer.numChildren, "IceWave teardown leaves no display children");
	}

	private static function createRound(layer:Sprite, ?onFreeze:DecodedBlock->Void):EggRound {
		return new EggRound(new CommandHandler(), function(_):Void {}, layer, null, function(_, _):Void {}, function():Float return 0.5,
			null, onFreeze);
	}

	private static function assertAngles(expected:Array<Float>, actual:Array<Float>, message:String):Void {
		assertEquals(expected.length, actual.length, message + " count");
		for (index in 0...expected.length) assertNear(expected[index], actual[index], 0.001, message + ' angle $index');
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) throw message;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertNear(expected:Float, actual:Float, tolerance:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) throw '$message: expected $expected +/- $tolerance, got $actual';
	}
}
