package pr2.gameplay;

import openfl.events.Event;
import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.ui.Keyboard;
import pr2.character.Character;
import pr2.display.Removable;
import pr2.effects.Effect;
import pr2.effects.LaserShotView;
import pr2.effects.Slash;
import pr2.effects.StingEffect;
import pr2.effects.ZapEffect;
import pr2.level.ObjectCodes;
import pr2.level.BlockType;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;
import pr2.level.LevelDecoder;
import pr2.effects.MineAppear;
import pr2.effects.TeleportPop;
import pr2.gameplay.GameCommandShell.GameCommandDelegate;
import pr2.gameplay.GameCommandShell.LocalCharacterInit;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.gameplay.player.BlockVisualEvent;
import pr2.gameplay.player.BlockVisualEvent.BlockVisualEventKind;
import pr2.gameplay.player.LocalPlayerInput;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerLevelData;
import pr2.lobby.account.Settings;
import pr2.util.TestDisplayUtil as DisplayUtil;

@:access(pr2.gameplay.Course)
@:access(pr2.level.LevelRenderer)
class CharacterLifecycleTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		Settings.disablePersistenceForTests();
		pr2.DeterministicTestMode.runTest("CharacterLifecycleTest.testLaserStopsOnBlockAndPlaysHitSound", testLaserStopsOnBlockAndPlaysHitSound);
		if (pr2.DeterministicTestMode.finishSmokeSuite("CharacterLifecycleTest")) return;
		pr2.DeterministicTestMode.runTest("CharacterLifecycleTest.testProjectileUsesSenderAndReceiverRotations",
			testProjectileUsesSenderAndReceiverRotations);
		trace('CharacterLifecycleTest passed $assertions assertions');
	}

	private static function testProjectileUsesSenderAndReceiverRotations():Void {
		var unrotatedLayer = new Sprite();
		var unrotatedRound = new EggRound(new CommandHandler(), function(_):Void {}, unrotatedLayer);
		unrotatedRound.mountAttackVisual("Laser`-165`75`right`90`7", 0);
		var unrotatedLaser = unrotatedLayer.getChildAt(0);
		assertEquals(75.0, unrotatedLaser.x, "unrotated receiver restores projectile canonical x from a 90-degree sender");
		assertEquals(165.0, unrotatedLaser.y, "unrotated receiver restores projectile canonical y from a 90-degree sender");
		assertEquals(-90.0, unrotatedLaser.rotation, "projectile artwork accounts for sender and receiver rotations");
		unrotatedRound.step(Level.fromDecoded(0xFFFFFF, []), 0);
		assertEquals(75.0, unrotatedLaser.x, "cross-rotation projectile keeps transformed x while moving");
		assertEquals(136.0, unrotatedLaser.y, "cross-rotation projectile advances in the transformed direction");

		var rotatedLayer = new Sprite();
		var rotatedRound = new EggRound(new CommandHandler(), function(_):Void {}, rotatedLayer);
		rotatedRound.mountAttackVisual("Laser`-165`75`right`90`7", 90);
		var rotatedLaser = rotatedLayer.getChildAt(0);
		assertEquals(-165.0, rotatedLaser.x, "equally rotated receiver keeps projectile packet x");
		assertEquals(75.0, rotatedLaser.y, "equally rotated receiver keeps projectile packet y");
		assertEquals(0.0, rotatedLaser.rotation, "equally rotated receiver keeps projectile artwork upright");
		unrotatedRound.clear();
		rotatedRound.clear();
	}

	private static function testLaserStopsOnBlockAndPlaysHitSound():Void {
		var layer = new Sprite();
		var hitSounds:Array<String> = [];
		var round = new EggRound(new CommandHandler(), function(_):Void {}, layer, null, function(_, _):Void {}, null, null, null,
			function(x:Int, y:Int):Void hitSounds.push('$x,$y'));
		var level = Level.fromDecoded(0xffffff, [LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 30, 0)]);
		round.mountAttackVisual("Laser`0`15`right`0`7");
		var laser = Std.downcast(layer.getChildAt(0), LaserShotView);

		round.step(level);
		assertEquals(29.0, laser.x, "laser continues travelling before reaching a block");
		assertEquals(0, hitSounds.length, "laser does not play its hit sound before impact");
		round.step(level);
		assertEquals(58.0, laser.x, "laser stops at its detected block impact position");
		assertTrue(laser.currentFrame > 2, "laser starts the authored hit animation on block impact");
		assertEquals("58,15", hitSounds[0], "laser block impact plays Flash's hit sound at the collision position");

		round.step(level);
		assertEquals(58.0, laser.x, "laser remains stopped while its hit animation finishes");
		assertEquals(1, hitSounds.length, "laser hit sound only plays once");
		for (_ in 0...15) {
			round.step(level);
		}
		assertEquals(1, round.activeAttackVisualCount(), "laser impact remains mounted through Flash's 18-frame timeout");
		round.step(level);
		assertEquals(0, round.activeAttackVisualCount(), "laser impact is removed after Flash's 18-frame timeout");
		assertTrue(laser.parent == null, "removed laser impact leaves the effect layer");
	}

	private static function assertEggAttackVisual(seed:Int, expectedType:String, expectedCount:Int, message:String):Void {
		var layer = new Sprite();
		var round = new EggRound(new CommandHandler(), function(_):Void {}, layer, null, function(_, _):Void {});
		round.initRound(seed);
		round.addEggs(1, Level.fromDecoded(0xffffff, []));
		var egg = round.egg(1);
		assertTrue(egg != null, '$message: egg spawned');
		egg.posX = 100;
		egg.posY = 100;
		egg.velX = 0;
		egg.velY = 0;
		var probe = RotationMath.rotatePoint(150, 100, -RotationMath.normalizeDisplayRotation(-egg.rot));
		LobbySocket.resetSent();
		round.step(Level.fromDecoded(0xffffff, []), 0, probe.x, probe.y + 20, false, false);
		assertTrue(LobbySocket.lastSent().indexOf('add_effect`$expectedType`') == 0, '$message: expected payload type');
		assertEquals(expectedCount, round.activeAttackVisualCount(), message);
		assertEquals(expectedCount + 1, layer.numChildren, '$message: visuals share the egg display layer');
		var visual = layer.getChildAt(1);
		var laserClip = Std.downcast(visual, LaserShotView);
		if (expectedType == "Laser") {
			assertEquals(2, laserClip.currentFrame, "laser attack visual starts stopped on idle frame 2");
			laserClip.dispatchEvent(new Event(Event.ENTER_FRAME));
			assertEquals(2, laserClip.currentFrame, "laser attack visual does not auto-play while idle");
			laserClip.playHit();
			for (_ in 0...20) {
				laserClip.dispatchEvent(new Event(Event.ENTER_FRAME));
			}
			assertEquals(18, laserClip.currentFrame, "laser hit animation stops on authored frame 18");
		}
		var initialX = visual.x;
		round.step(Level.fromDecoded(0xffffff, []), 0, probe.x, probe.y + 20, false, false);
		assertTrue(visual.x != initialX || expectedType == "Slash", '$message: projectile visuals advance after mounting');
		round.clear();
		assertEquals(0, layer.numChildren, '$message: clear removes mounted visuals');
	}

	private static function assertEggFoot(display:EggView, name:String, expectedColor:Int):Void {
		var foot = Std.downcast(DisplayUtil.findByName(display, name), pr2.gameplay.EggView.EggPartView);
		assertTrue(foot != null, '$name foot exists');
		assertEquals(1, foot.currentFrame, '$name foot stops on frame 1');
		var colorMC = Std.downcast(DisplayUtil.findByName(foot, "colorMC"), pr2.gameplay.EggView.EggPartChannel);
		assertTrue(colorMC != null, '$name colorMC exists');
		assertEquals(1, colorMC.currentFrame, '$name colorMC stops on frame 1');
		assertEquals(expectedColor, colorMC.transform.colorTransform.color, '$name colorMC uses first random color');
		var colorMC2 = Std.downcast(DisplayUtil.findByName(foot, "colorMC2"), pr2.gameplay.EggView.EggPartChannel);
		assertTrue(colorMC2 != null, '$name colorMC2 exists');
		assertEquals(1, colorMC2.currentFrame, '$name colorMC2 stops on frame 1');
		assertEquals(false, colorMC2.visible, '$name colorMC2 is hidden');
	}

	private static function assertDisplayColor(target:DisplayObject, expectedColor:Int, message:String):Void {
		assertTrue(target != null, message + " target exists");
		assertEquals(expectedColor, target.transform.colorTransform.color, message);
	}

	private static function countLooseHats(course:Course):Int {
		var count = 0;
		for (_ in course.looseHats.keys()) {
			count++;
		}
		return count;
	}

	private static function finishDrawing(course:Course):Void {
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
	}

	private static function finishCountdown(course:Course):Void {
		while (course.countdown != null && course.countdown.parent != null) {
			course.countdown.advance();
		}
	}

	private static function collectAndUseLocalItem(itemId:Int):Course {
		var course = buildCourse(new CommandHandler(), "race", 'm4`ffffff`2;5;11,0;-2;10;$itemId,0;3;0,1;0;0,1;0;0,1;0;0');
		finishDrawing(course);
		course.beginRace();
		finishCountdown(course);
		course.setKey(Keyboard.UP, true);
		for (_ in 0...40) {
			course.onEnterFrame(new Event(Event.ENTER_FRAME));
			if (course.localCharacter.stateSnapshot().itemId == itemId) {
				break;
			}
		}
		course.setKey(Keyboard.UP, false);
		assertEquals(itemId, course.localCharacter.stateSnapshot().itemId, 'local player collects item $itemId');

		LobbySocket.resetSent();
		course.onEnterFrame(new Event(Event.ENTER_FRAME));
		course.setKey(Keyboard.SPACE, true);
		course.onEnterFrame(new Event(Event.ENTER_FRAME));
		course.setKey(Keyboard.SPACE, false);
		return course;
	}

	private static function buildCourse(handler:CommandHandler, gameMode:String = "race", ?dataString:String):Course {
		if (dataString == null) {
			dataString = "m3`ffffff`0;0;11,1;0;8,0;1;0";
		}
		var level = LevelDecoder.decode(dataString);

		var vars:Map<String, String> = new Map();
		vars.set("level_id", "99");
		vars.set("title", "Lifecycle Test");
		vars.set("song", "song1");
		vars.set("gravity", "1");
		vars.set("max_time", "120");
		vars.set("gameMode", gameMode);
		vars.set("items", "all");
		vars.set("data", dataString);

		var data = new ServerLevelData(vars, true);
		return new Course(level, data, LevelConfig.fromServerData(data), null, null, handler);
	}

	private static function localInit(tempId:Int):LocalCharacterInit {
		return {
			tempId: tempId,
			speed: 80, accel: 70, jump: 60,
			hatColor: 0xFFFFFF, headColor: 0xFFFFFF, bodyColor: 0xFFFFFF, feetColor: 0xFFFFFF,
			hatId: 1, headId: 1, bodyId: 1, feetId: 1,
			hatColor2: -1, headColor2: -1, bodyColor2: -1, feetColor2: -1,
			group: "0"
		};
	}

	private static function remoteInit(tempId:Int):RemoteCharacterInit {
		return {
			tempId: tempId,
			userName: "Rival",
			hatColor: 0xFFFFFF, headColor: 0xFFFFFF, bodyColor: 0xFFFFFF, feetColor: 0xFFFFFF,
			hatId: 1, headId: 1, bodyId: 1, feetId: 1,
			hatColor2: -1, headColor2: -1, bodyColor2: -1, feetColor2: -1,
			group: "0"
		};
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
}

private class TestSharedEffect extends Effect {
	public function new(startX:Float, startY:Float) {
		super(startX, startY);
	}

	public function armRemoval(frames:Int):Void {
		scheduleRemove(frames);
	}

	public function lastScheduledMs():Int {
		return scheduledRemoveMsForTests();
	}

	public function hasRemoveTimer():Bool {
		return hasScheduledRemoveForTests();
	}
}

private class CourseDelegate implements GameCommandDelegate {
	private final course:Course;

	public function new(course:Course) {
		this.course = course;
	}

	public function createRemoteCharacter(init:RemoteCharacterInit):Void course.createRemoteCharacter(init);
	public function createLocalCharacter(init:LocalCharacterInit):Void course.createLocalCharacter(init);
	public function beginRace():Void course.beginRace();
	public function award(args:Array<String>):Void {}
	public function setExpGain(expOld:Int, expNew:Int, expToRank:Int):Void {}
	public function setLuxGain(amount:Int):Void {}
	public function setPrize(prize:Dynamic):Void {}
	public function cancelPrize(message:String):Void {}
	public function winPrize(prize:Dynamic):Void {}
	public function cowboyMode():Void {}
	public function happyHour():Void {}
	public function setEggSeed(seed:Int):Void course.setEggSeed(seed);
	public function addEggs(count:Int):Void course.addEggs(count);
	public function setLife(lives:Int):Void course.setLife(lives);
	public function superBooster(tempId:Int):Void {}
	public function maybeReturnHatToStart(hatId:Int):Void course.maybeReturnHatToStart(hatId);
	public function startHatCountdown():Void {}
	public function cancelHatCountdown():Void {}
	public function areYouHuman():Void {}
	public function forceQuit():Void {}
}
