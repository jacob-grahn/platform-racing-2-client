package pr2.character;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.gameplay.MiniMapDot;
import pr2.gameplay.RemoteBlockActivation;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevel;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevelFixtureAdapter;
import pr2.level.ServerLevelRenderer;
import pr2.net.CommandHandler;

class RemoteCharacterConsumeTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testRegistersAndTearsDownTempCommands();
		testConsumesPositionVarsAndExactPosition();
		testCatchupClampAndBlockTouches();
		testRemoteBlockTouchesActivateRealMapEffects();
		testHeartStingAndHatCommands();
		trace('RemoteCharacterConsumeTest passed $assertions assertions');
	}

	private static function testRegistersAndTearsDownTempCommands():Void {
		var handler = new CommandHandler();
		var dot = new MiniMapDot();
		var remote = new RemoteCharacter(2, dot, "Racer", 1, 2, 3, 4, "g", handler);

		for (name in ["p2", "var2", "exactPos2", "setHats2", "heart2", "sting2"]) {
			assertTrue(handler.hasCommand(name), '$name command registered');
		}

		remote.remove();
		for (name in ["p2", "var2", "exactPos2", "setHats2", "heart2", "sting2"]) {
			assertTrue(!handler.hasCommand(name), '$name command removed');
		}
		assertEquals(null, remote.mapDot, "remove clears minimap dot reference");
	}

	private static function testConsumesPositionVarsAndExactPosition():Void {
		var handler = new CommandHandler();
		var dot = new MiniMapDot();
		var remote = new RemoteCharacter(1, dot, "Remote", 1, 1, 1, 1, "0", handler);
		var parents:Array<String> = [];
		var sparkles:Array<Bool> = [];
		var jets:Array<Bool> = [];
		remote.onParentChange = parents.push;
		remote.onSparklesChange = sparkles.push;
		remote.onJetChange = jets.push;

		assertTrue(handler.dispatch("p1", ["50", "25"]), "position command dispatches");
		assertEquals(5, remote.updateQueueLength, "p command pads the update interval");
		handler.dispatch("var1", ["state", "run"]);
		handler.dispatch("var1", ["scaleX", "-1"]);
		handler.dispatch("var1", ["parent", "frontBackground"]);
		handler.dispatch("var1", ["item", "6"]);
		handler.dispatch("var1", ["sparkle", "1"]);
		handler.dispatch("var1", ["jet", "1"]);
		handler.dispatch("exactPos1", ["100", "200"]);

		for (_ in 0...5) {
			remote.stepFrame();
		}

		assertClose(50, remote.x, "remote converges to delta x");
		assertClose(25, remote.y, "remote converges to delta y");
		assertClose(50, dot.x, "minimap dot follows unrotated x");
		assertClose(25, dot.y, "minimap dot follows unrotated y");
		assertEquals("run", remote.state, "queued state var applies");
		assertClose(-1, remote.scaleX, "queued scaleX var applies");
		assertEquals("Jet Pack", remote.itemFrameName, "queued item var applies");
		assertEquals(100.0, remote.posX, "exactPos x is latched after interpolation update");
		assertEquals(200.0, remote.posY, "exactPos y is latched after interpolation update");
		assertEquals("frontBackground", parents.join(","), "parent hook receives queued parent");
		assertEquals("true", [for (v in sparkles) Std.string(v)].join(","), "sparkle hook receives true");
		assertEquals("true", [for (v in jets) Std.string(v)].join(","), "jet hook receives true");
		assertEquals(6, remote.jetPackForState("runAnim").currentFrame, "remote jet var switches active Jet Pack flame on");

		handler.dispatch("p1", ["0", "0"]);
		handler.dispatch("var1", ["jet", "0"]);
		for (_ in 0...5) {
			remote.stepFrame();
		}
		assertEquals(1, remote.jetPackForState("runAnim").currentFrame, "remote jet var switches Jet Pack flame off");
	}

	private static function testCatchupClampAndBlockTouches():Void {
		var remote = new RemoteCharacter(0, null, "Remote", 1, 1, 1, 1, "0", new CommandHandler());
		var touches:Array<String> = [];
		remote.onBlockTouch = function(x, y) touches.push('$x,$y');
		remote.setPos(30, 60);
		remote.mapRotation = 90;
		remote.stepFrame();
		assertEquals("2,-1|1,-1", touches.join("|"), "block touches rotate into map segments");

		for (_ in 0...120) {
			remote.stepFrame();
		}
		assertClose(10, remote.catchupRate, "empty queue catchup clamps at 10");

		remote.pos(["", "999"]);
		assertEquals(5, remote.updateQueueLength, "empty delta p still queues interval updates");
		remote.stepFrame();
		assertClose(30, remote.posX, "empty first delta x leaves position unchanged");
		assertClose(60, remote.posY, "empty first delta y leaves position unchanged");
		assertTrue(remote.catchupRate < 10, "consuming an update lowers catchup");
	}

	private static function testHeartStingAndHatCommands():Void {
		var handler = new CommandHandler();
		var remote = new RemoteCharacter(3, null, "Remote", 1, 1, 1, 1, "0", handler);
		var hearts = 0;
		var sounds:Array<String> = [];
		var stingArgs = "";
		remote.onHeartGain = function() hearts++;
		remote.onPlayCharacterSound = function(request) sounds.push(request.kind + ":" + request.volume);
		remote.onSting = function(args) stingArgs = args.join(",");

		handler.dispatch("heart3", []);
		handler.dispatch("sting3", ["1", "70", "90"]);
		handler.dispatch("setHats3", ["6", "16711680", "-1"]);

		assertEquals(1, hearts, "heart command reaches hook");
		assertEquals("bumpHappy:0.75", sounds.join(","), "heart command plays Flash heart sound");
		assertEquals("1,70,90", stingArgs, "sting command reaches hook args");
		assertEquals(6, remote.hat1, "setHats command applies hat stack");
		assertTrue(remote.hasHatFlag(Character.CROWN), "setHats command raises special hat flags");
	}

	private static function testRemoteBlockTouchesActivateRealMapEffects():Void {
		var arrow = new DecodedBlock(ObjectCodes.BLOCK_ARROW_RIGHT, 0, 0);
		var vanish = new DecodedBlock(ObjectCodes.BLOCK_VANISH, 30, 0);
		var water = new DecodedBlock(ObjectCodes.BLOCK_WATER, 60, 0);
		var level = new ServerLevel(0xFFFFFF, [arrow, vanish, water]);
		var fixture = ServerLevelFixtureAdapter.convert(level, 0.7);
		var renderer = new ServerLevelRenderer(level, arrow);
		var activation = new RemoteBlockActivation(fixture, renderer);

		var remote = new RemoteCharacter(4, null, "Remote", 1, 1, 1, 1, "0", new CommandHandler());
		remote.onBlockTouch = activation.touch;

		remote.setPos((fixture.originTileX * -1) * 30 + 15, (fixture.originTileY * -1) * 30 - 1);
		remote.stepFrame();
		assertEquals(2, renderer.arrowFrameAt(arrow.x, arrow.y), "remote touch animates arrow block");
		var world = Std.downcast(renderer.getChildAt(1), Sprite);
		var blockLayer = Std.downcast(world.getChildAt(0), Sprite);
		var blockDisplay = Std.downcast(blockLayer.getChildAt(0), Sprite);
		var pivot = Std.downcast(blockDisplay.getChildAt(1), Sprite);
		var arrowTimeline = pivot.getChildAt(0);
		for (_ in 0...7) {
			arrowTimeline.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(null, renderer.arrowFrameAt(arrow.x, arrow.y), "remote arrow activation removes the arrow overlay");

		remote.setPos((fixture.originTileX * -1 + 1) * 30 + 15, (fixture.originTileY * -1) * 30 - 1);
		remote.stepFrame();
		assertEquals(0.0, renderer.blockAlphaAt(vanish.x, vanish.y), "remote touch activates vanish block");

		remote.setPos((fixture.originTileX * -1 + 2) * 30 + 15, (fixture.originTileY * -1) * 30 - 1);
		remote.stepFrame();
		assertClose(0.9, renderer.blockAlphaAt(water.x, water.y), "remote touch triggers water ripple");
	}

	private static function assertEquals<T>(expected:T, actual:T, message:String):Void {
		assertions++;
		if (actual != expected) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) {
			throw 'assertion failed: $message';
		}
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.0001) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
