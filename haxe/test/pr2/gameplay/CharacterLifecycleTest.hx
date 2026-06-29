package pr2.gameplay;

import openfl.events.Event;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevelDecoder;
import pr2.gameplay.GameCommandShell.GameCommandDelegate;
import pr2.gameplay.GameCommandShell.LocalCharacterInit;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerLevelData;

class CharacterLifecycleTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testLocalAndRemoteLifecycle();
		testEggRoundCommandLifecycle();
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
		assertEquals(1, course.eggRound.count(), "collected egg removed locally");
		assertTrue(first.display.parent == null, "collected egg graphic removed");
		assertTrue(!handler.hasCommand("removeEgg1"), "collected egg unregisters remote remove");

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
	}

	private static function buildCourse(handler:CommandHandler, gameMode:String = "race"):Course {
		var dataString = "m3`ffffff`0;0;11,1;0;8,0;1;0";
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
	public function maybeReturnHatToStart(hatId:Int):Void {}
	public function startHatCountdown():Void {}
	public function cancelHatCountdown():Void {}
	public function forceQuit():Void {}
}
