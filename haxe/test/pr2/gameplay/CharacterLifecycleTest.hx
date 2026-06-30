package pr2.gameplay;

import openfl.events.Event;
import openfl.display.Sprite;
import openfl.ui.Keyboard;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevel;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevelDecoder;
import pr2.gameplay.GameCommandShell.GameCommandDelegate;
import pr2.gameplay.GameCommandShell.LocalCharacterInit;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerLevelData;

@:access(pr2.gameplay.Course)
class CharacterLifecycleTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testLocalAndRemoteLifecycle();
		testCountdownLocksLocalMovement();
		testLocalJumpPlaysSound();
		testLocalSwordEmitsSlashEffect();
		testEggRoundCommandLifecycle();
		testHatReturnToStartLifecycle();
		testLooseHatPhysicsAndPickup();
		trace('CharacterLifecycleTest passed $assertions assertions');
	}

	private static function testLocalAndRemoteLifecycle():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler);
		var shell = new GameCommandShell(new CourseDelegate(course), handler);
		shell.install();

		handler.dispatch("createLocalCharacter", ["7", "80", "70", "60", "101", "102", "103", "104", "2", "3", "4", "5", "201", "202", "203", "204", "g"]);
		assertEquals(7, course.localCharacter.tempID, "local temp id applied");
		assertEquals("g", course.localCharacter.groupStr, "local group applied");
		assertEquals(2, course.localCharacter.hat1, "local hat applied");
		assertEquals(3, course.localCharacter.head, "local head applied");
		assertEquals(4, course.localCharacter.body, "local body applied");
		assertEquals(5, course.localCharacter.feet, "local feet applied");
		assertEquals(80.0, course.localCharacter.debugState().speedStat, "local speed stat applied");
		assertEquals(70.0, course.localCharacter.debugState().accelerationStat, "local accel stat applied");
		assertEquals(60.0, course.localCharacter.debugState().jumpStat, "local jump stat applied");

		LobbySocket.resetSent();
		handler.dispatch("beginRace", []);
		assertTrue(course.countdown != null, "beginRace mounts countdown");
		assertEquals(false, course.raceStarted, "race waits for countdown finish");
		assertEquals("exact_pos`135`120", LobbySocket.sentCommands[0], "beginRace emits starting exact position");
		while (course.countdown != null && course.countdown.parent != null) {
			course.countdown.advance();
		}
		assertEquals(true, course.raceStarted, "countdown finish starts race");
		assertEquals("p`0`0", LobbySocket.lastSent(), "countdown finish initializes local network emission");

		handler.dispatch("createRemoteCharacter", ["9", "Rival", "111", "112", "113", "114", "6", "7", "8", "9", "211", "212", "213", "214", "mod"]);
		var remote = course.getRemoteCharacter(9);
		assertTrue(remote != null, "remote stored by temp id");
		assertEquals(2, course.characterLayer.numChildren, "remote added beside local character");
		assertTrue(remote == course.characterLayer.getChildAt(1), "remote owns display-list slot");
		assertEquals("Rival", remote.userName, "remote name applied");
		assertEquals("mod", remote.groupStr, "remote group applied");
		assertEquals(6, remote.hat1, "remote hat applied");
		assertEquals(7, remote.head, "remote head applied");
		assertTrue(handler.hasCommand("p9"), "remote temp position command registered");

		course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		var arrow = course.levelRenderer.arrowFrameAt(30, 0);
		remote.onBlockTouch(5, 4);
		assertTrue(course.levelRenderer.arrowFrameAt(30, 0) != arrow, "remote block activation adapter wired");

		course.removeRemoteCharacter(9);
		assertEquals(1, course.characterLayer.numChildren, "remote removed from display list");
		assertEquals(null, course.getRemoteCharacter(9), "remote removed from course map");
		assertTrue(!handler.hasCommand("p9"), "remote temp position command removed");

		handler.dispatch("createRemoteCharacter", ["10", "Other", "1", "1", "1", "1", "1", "1", "1", "1", "-1", "-1", "-1", "-1", "0"]);
		assertEquals(1, course.remoteCharacterCount(), "second remote mounted");
		shell.remove();
		assertTrue(!handler.hasCommand("createRemoteCharacter"), "game command shell removed");
		course.remove();
		assertEquals(0, course.remoteCharacterCount(), "course teardown clears remotes");
		assertEquals(null, course.localCharacter, "course teardown clears local character");
	}

	private static function testCountdownLocksLocalMovement():Void {
		var course = buildCourse(new CommandHandler());
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		LobbySocket.resetSent();
		course.beginRace();
		var startX = course.localCharacter.debugState().x;
		var startY = course.localCharacter.debugState().y;

		course.setKey(Keyboard.RIGHT, true);
		for (_ in 0...5) {
			course.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(startX, course.localCharacter.debugState().x, "countdown blocks local horizontal movement");
		assertEquals(startY, course.localCharacter.debugState().y, "countdown blocks local vertical movement");

		while (course.countdown != null && course.countdown.parent != null) {
			course.countdown.advance();
		}
		assertEquals(true, course.raceStarted, "countdown finish starts race before movement resumes");
		for (_ in 0...10) {
			course.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertTrue(course.localCharacter.debugState().x > startX, "local movement resumes after countdown");
		course.remove();
	}

	private static function testLocalJumpPlaysSound():Void {
		var course = buildCourse(new CommandHandler());
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		var sounds:Array<String> = [];
		course.onPlayJumpSound = function(x:Float, y:Float):Void {
			sounds.push('${Math.round(x)},${Math.round(y)}');
		}
		var start = course.localCharacter.getPos();
		course.localCharacter.velY = 0;
		course.localCharacter.changeState("stand");
		course.localCharacter.changeState("jump");
		assertEquals(1, sounds.length, "entering local jump state plays the local jump sound");
		assertEquals(
			'${Math.round(course.serverFixture.fixturePixelToWorldX(start.x))},${Math.round(course.serverFixture.fixturePixelToWorldY(start.y))}',
			sounds[0],
			"jump sound uses the local character world position"
		);
		course.localCharacter.changeState("jump");
		assertEquals(1, sounds.length, "holding jump does not retrigger the sound every frame");
		course.remove();
	}

	private static function testLocalSwordEmitsSlashEffect():Void {
		var course = buildCourse(new CommandHandler(), "race", "m4`ffffff`2;5;11,0;-2;10;8,0;3;0,1;0;0,1;0;0,1;0;0");
		finishDrawing(course);
		course.beginRace();
		finishCountdown(course);
		course.setKey(Keyboard.UP, true);
		for (_ in 0...40) {
			course.onEnterFrame(new Event(Event.ENTER_FRAME));
			if (course.localCharacter.debugState().itemId == 8) break;
		}
		course.setKey(Keyboard.UP, false);
		assertEquals(8, course.localCharacter.debugState().itemId, "local player collects sword");

		LobbySocket.resetSent();
		course.onEnterFrame(new Event(Event.ENTER_FRAME));
		course.setKey(Keyboard.SPACE, true);
		course.onEnterFrame(new Event(Event.ENTER_FRAME));

		assertTrue(LobbySocket.lastSent().indexOf("add_effect`Slash`") == 0, "sword emits Slash effect command");
		assertTrue(LobbySocket.lastSent().indexOf("`right`0") > 0, "sword Slash payload includes direction and temp id");
		assertEquals(1, course.eggRound.activeAttackVisualCount(), "sword mounts the authored slash visual");
		course.setKey(Keyboard.SPACE, false);
		course.remove();
	}

	private static function testEggRoundCommandLifecycle():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler, "egg");
		var shell = new GameCommandShell(new CourseDelegate(course), handler);
		shell.install();

		LobbySocket.resetSent();
		handler.dispatch("setEggSeed", ["777"]);
		handler.dispatch("addEggs", ["2"]);
		assertEquals(2, course.eggRound.count(), "egg mode spawns requested eggs");
		assertEquals(1, course.eggRound.ids()[0], "egg ids start at one");
		assertEquals(2, course.eggRound.ids()[1], "egg ids increment");
		assertTrue(handler.hasCommand("removeEgg1"), "first egg remote remove command registered");
		assertTrue(handler.hasCommand("removeEgg2"), "second egg remote remove command registered");
		assertEquals(3, course.eggRound.currentMode(), "seeded mode clamps Flash random value");
		var first = course.eggRound.egg(1);
		assertTrue(first != null, "first egg state stored");
		assertEquals(3, course.characterLayer.numChildren, "egg graphics mount beside characters");
		assertTrue(first.display.parent == course.characterLayer, "egg graphic is added to course layer");
		assertEquals(first.x, Std.int(first.display.x), "egg graphic uses seeded x");
		assertEquals(first.y, Std.int(first.display.y), "egg graphic uses seeded y");
		assertEquals(first.rot, Std.int(first.display.rotation), "egg graphic uses seeded rotation");

		assertEquals(true, course.eggRound.collectEgg(1), "collecting active egg succeeds");
		assertEquals("grab_egg`1", LobbySocket.lastSent(), "collecting egg emits grab_egg");
		assertEquals(2, course.eggRound.count(), "collected egg remains during squash animation");
		assertTrue(first.removing, "collected egg enters squash removal state");
		assertEquals(30, first.display.currentFrame, "collected egg starts authored squash animation");
		assertTrue(first.display.parent == course.characterLayer, "collected egg graphic remains during squash animation");
		assertTrue(handler.hasCommand("removeEgg1"), "collected egg keeps remote remove command during squash animation");
		assertEquals(false, course.eggRound.collectEgg(1), "squashing egg cannot be collected twice");
		var lifecycleLevel = ServerLevelDecoder.decode("m3`ffffff`0;0;11,1;0;8,0;1;0");
		for (_ in 0...26) {
			course.eggRound.step(lifecycleLevel);
		}
		assertTrue(first.display.parent == course.characterLayer, "squash animation persists before Flash timeout");
		course.eggRound.step(lifecycleLevel);
		assertEquals(1, course.eggRound.count(), "collected egg removed after squash timeout");
		assertTrue(first.display.parent == null, "squashed egg graphic removed");
		assertTrue(!handler.hasCommand("removeEgg1"), "squashed egg unregisters remote remove");

		var second = course.eggRound.egg(2);
		assertEquals(true, handler.dispatch("removeEgg2", []), "remote remove command dispatches");
		assertEquals(0, course.eggRound.count(), "remote remove clears egg");
		assertTrue(second.display.parent == null, "remote remove clears egg graphic");
		assertTrue(!handler.hasCommand("removeEgg2"), "remote remove unregisters itself");

		handler.dispatch("addEggs", ["1"]);
		assertEquals(1, course.eggRound.count(), "egg mode can spawn after remote remove");
		var third = course.eggRound.egg(3);
		course.remove();
		assertTrue(third.display.parent == null, "course teardown removes egg graphic");
		assertTrue(!handler.hasCommand("removeEgg3"), "course teardown unregisters remaining egg");
		shell.remove();

		var raceCourse = buildCourse(new CommandHandler(), "race");
		raceCourse.addEggs(3);
		assertEquals(0, raceCourse.eggRound.count(), "non-egg game mode ignores addEggs");
		raceCourse.remove();

		var soundPositions:Array<String> = [];
		var soundRound = new EggRound(new CommandHandler(), function(_):Void {}, null, null, function(x:Int, y:Int):Void {
			soundPositions.push('$x,$y');
		});
		soundRound.initRound(777);
		soundRound.addEggs(1, ServerLevelDecoder.decode("m3`ffffff`0;0;11,1;0;8,0;1;0"));
		var soundEgg = soundRound.egg(1);
		assertTrue(soundEgg != null, "sound test egg spawned");
		assertEquals(true, soundRound.collectEgg(1), "sound test egg collects");
		assertEquals('${soundEgg.x},${soundEgg.y}', soundPositions[0], "collecting an egg plays its collection sound at the egg position");

		var physicsRound = new EggRound(new CommandHandler(), function(_):Void {}, null, null, function(_, _):Void {});
		var physicsLevel = new ServerLevel(0xffffff, [
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 0, 0),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 30, -30)
		]);
		physicsRound.initRound(777);
		physicsRound.addEggs(1, physicsLevel);
		var physicsEgg = physicsRound.egg(1);
		assertTrue(physicsEgg != null, "physics test egg spawned");
		physicsEgg.posX = 15;
		physicsEgg.posY = -20;
		physicsEgg.velX = 0;
		physicsEgg.velY = 0;
		physicsRound.step(physicsLevel);
		assertEquals(-19, Std.int(physicsEgg.posY), "egg gravity advances vertical position before landing");
		assertTrue(physicsEgg.display.alpha > 0, "egg fades in during movement step");

		physicsEgg.posX = 15;
		physicsEgg.posY = -1;
		physicsEgg.velY = 1;
		physicsRound.step(physicsLevel);
		assertEquals(0, Std.int(physicsEgg.posY), "egg lands on active block top");
		assertEquals(0, Std.int(physicsEgg.velY), "egg landing clears falling velocity");
		assertTrue(physicsEgg.grounded, "egg landing sets grounded state");

		physicsEgg.posX = 29;
		physicsEgg.posY = 0;
		physicsEgg.velX = 1;
		physicsEgg.velY = 0;
		physicsEgg.grounded = true;
		physicsRound.step(physicsLevel);
		assertEquals(-1, Std.int(physicsEgg.velX), "grounded egg reverses on wall touch");
		assertEquals(29, Std.int(physicsEgg.posX), "wall touch snaps egg beside block");

		physicsEgg.posX = 331;
		physicsEgg.posY = 0;
		physicsEgg.velX = 0;
		physicsEgg.velY = 0;
		physicsRound.step(physicsLevel);
		assertEquals(-300, Std.int(physicsEgg.posX), "egg wraps past level movement max x");

		var collectedIds:Array<Int> = [];
		var touchRound = new EggRound(new CommandHandler(), function(id):Void {
			collectedIds.push(id);
		}, null, null, function(_, _):Void {});
		touchRound.initRound(777);
		touchRound.addEggs(1, physicsLevel);
		var touchEgg = touchRound.egg(1);
		touchEgg.posX = 10;
		touchEgg.posY = 10;
		touchEgg.velX = 0;
		touchEgg.velY = 0;
		touchRound.step(physicsLevel, 0, 10, 20, false, false);
		assertEquals(1, touchRound.count(), "egg movement step starts squash removal near local player");
		assertTrue(touchEgg.removing, "touch-collected egg enters squash removal state");
		assertEquals(1, collectedIds[0], "egg movement step emits collected egg id");
		for (_ in 0...27) {
			touchRound.step(physicsLevel);
		}
		assertEquals(0, touchRound.count(), "touch-collected egg is removed after squash timeout");

		var attackRound = new EggRound(new CommandHandler(), function(_):Void {}, null, null, function(_, _):Void {});
		attackRound.initRound(18);
		assertEquals(0, attackRound.currentMode(), "attack test seed selects ice mode");
		attackRound.addEggs(1, new ServerLevel(0xffffff, []));
		var attackEgg = attackRound.egg(1);
		assertTrue(attackEgg != null, "attack test egg spawned");
		attackEgg.posX = 100;
		attackEgg.posY = 100;
		attackEgg.velX = 0;
		attackEgg.velY = 0;
		LobbySocket.resetSent();
		attackRound.step(new ServerLevel(0xffffff, []), 0, 150, 120, false, false);
		assertEquals("add_effect`IceWave`100`90`180`0`-1", LobbySocket.lastSent(), "egg attack emits Flash add_effect payload");
		assertEquals(120, attackEgg.attackCooldown, "egg attack starts Flash cooldown");
		attackRound.step(new ServerLevel(0xffffff, []), 0, 150, 120, false, false);
		assertEquals(1, LobbySocket.sentCommands.length, "egg attack cooldown suppresses repeat emission");
		assertEquals(119, attackEgg.attackCooldown, "egg attack cooldown ticks down each frame");

		assertEggAttackVisual(14, "IceWave", 3, "ice wave attacks mount three authored shot graphics");
		assertEggAttackVisual(1, "Slash", 1, "slash attacks mount the authored slash animation");
		assertEggAttackVisual(9, "Laser", 1, "laser attacks mount the authored laser shot graphic");
	}

	private static function assertEggAttackVisual(seed:Int, expectedType:String, expectedCount:Int, message:String):Void {
		var layer = new Sprite();
		var round = new EggRound(new CommandHandler(), function(_):Void {}, layer, null, function(_, _):Void {});
		round.initRound(seed);
		round.addEggs(1, new ServerLevel(0xffffff, []));
		var egg = round.egg(1);
		assertTrue(egg != null, '$message: egg spawned');
		egg.posX = 100;
		egg.posY = 100;
		egg.velX = 0;
		egg.velY = 0;
		var probe = RotationMath.rotatePoint(150, 100, -RotationMath.normalizeDisplayRotation(-egg.rot));
		LobbySocket.resetSent();
		round.step(new ServerLevel(0xffffff, []), 0, probe.x, probe.y + 20, false, false);
		assertTrue(LobbySocket.lastSent().indexOf('add_effect`$expectedType`') == 0, '$message: expected payload type');
		assertEquals(expectedCount, round.activeAttackVisualCount(), message);
		assertEquals(expectedCount + 1, layer.numChildren, '$message: visuals share the egg display layer');
		var visual = layer.getChildAt(1);
		var initialX = visual.x;
		round.step(new ServerLevel(0xffffff, []), 0, probe.x, probe.y + 20, false, false);
		assertTrue(visual.x != initialX || expectedType == "Slash", '$message: projectile visuals advance after mounting');
		round.clear();
		assertEquals(0, layer.numChildren, '$message: clear removes mounted visuals');
	}

	private static function testHatReturnToStartLifecycle():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler, "hat", "m3`ffffff`0;0;11,1;0;8,0;1;11,0;2;0,11,0;4;0");
		var shell = new GameCommandShell(new CourseDelegate(course), handler);
		shell.install();

		var hat = course.addLooseHat(15, course.level.maxY + 501, 0, 5, 0x123456, -1, 1);
		assertEquals(1, countLooseHats(course), "loose hat is registered");
		assertTrue(handler.hasCommand("removeHat1"), "loose hat registers remote remove command");
		assertTrue(hat.display.parent == course.characterLayer, "loose hat display mounts to character layer");

		handler.dispatch("maybeReturnHatToStart", ["1"]);
		var returned = course.looseHats.get(1);
		assertTrue(returned != null, "out-of-bounds loose hat respawns at matching start");
		assertTrue(returned != hat, "return to start replaces the old hat instance");
		assertEquals(45, Std.int(returned.posX), "returned hat uses start block center x");
		assertEquals(45, Std.int(returned.posY), "returned hat uses start block center y");
		assertEquals(0, returned.rot, "returned hat resets rotation");
		assertEquals(5, returned.num, "returned hat preserves hat id");
		assertEquals(0x123456, returned.color, "returned hat preserves primary color");
		assertEquals(-1, returned.color2, "returned hat preserves secondary color sentinel");
		assertTrue(hat.display.parent == null, "old loose hat display is removed");
		assertTrue(returned.display.parent == course.characterLayer, "returned loose hat display mounts");
		assertTrue(handler.hasCommand("removeHat1"), "returned hat keeps remote remove command registered");

		handler.dispatch("removeHat1", []);
		assertEquals(0, countLooseHats(course), "remote remove clears returned loose hat");
		assertTrue(returned.display.parent == null, "remote remove detaches returned display");
		assertTrue(!handler.hasCommand("removeHat1"), "remote remove unregisters command");

		course.addLooseHat(20, course.level.maxY + 501, 0, 6, 0xFFFFFF, 0, 4);
		handler.dispatch("maybeReturnHatToStart", ["4"]);
		assertEquals(0, countLooseHats(course), "hat without matching start is removed instead of respawned");

		shell.remove();
		course.remove();
	}

	private static function testLooseHatPhysicsAndPickup():Void {
		var course = buildCourse(new CommandHandler(), "hat", "m3`ffffff`0;0;11,0;1;0");
		finishDrawing(course);

		var falling = course.addLooseHat(15, -45, 0, 5, 0xFFFFFF, -1, 1);
		for (_ in 0...90) {
			falling.step(course.level, 0);
		}
		assertEquals(true, falling.grounded, "loose hat lands on active blocks");
		assertEquals(30, Std.int(falling.posY), "loose hat snaps to the block top");
		assertEquals(30, Std.int(falling.display.y), "loose hat display follows physics position");
		falling.remove();

		var pickup = course.addLooseHat(15, 0, 0, 6, 0x123456, -1, 2);
		LobbySocket.resetSent();
		pickup.step(course.level, 0, 15, 20, false, false, false);
		assertEquals(0, countLooseHats(course), "touching local player removes loose hat");
		assertEquals("get_hat`2", LobbySocket.lastSent(), "touching local player emits get_hat");
		assertTrue(pickup.display.parent == null, "pickup detaches loose hat display");

		var finishedPickup = course.addLooseHat(15, 0, 0, 6, 0x123456, -1, 3);
		LobbySocket.resetSent();
		finishedPickup.step(course.level, 0, 15, 20, false, false, true);
		assertEquals(1, countLooseHats(course), "done-playing local player does not collect loose hat");
		assertEquals("", LobbySocket.lastSent(), "done-playing pickup suppression emits no get_hat");

		course.remove();
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

	private static function buildCourse(handler:CommandHandler, gameMode:String = "race", ?dataString:String):Course {
		if (dataString == null) {
			dataString = "m3`ffffff`0;0;11,1;0;8,0;1;0";
		}
		var level = ServerLevelDecoder.decode(dataString);

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
	public function superBooster(tempId:Int):Void {}
	public function maybeReturnHatToStart(hatId:Int):Void course.maybeReturnHatToStart(hatId);
	public function startHatCountdown():Void {}
	public function cancelHatCountdown():Void {}
	public function forceQuit():Void {}
}
