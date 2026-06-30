package pr2.gameplay;

import haxe.crypto.Md5;
import openfl.events.Event;
import pr2.character.CharacterState;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.harness.LocalPlayerDebugState;
import pr2.level.ServerLevelDecoder;
import pr2.net.LobbySocket;
import pr2.net.ServerLevelData;
import pr2.net.ServerConfig;

/**
	A3 coverage: the production `Course` shell mounts a decoded level plus the
	authored HUD at Course's verified holder->stage offsets, hosts a character
	layer, and tears everything down on `remove`. Built from a small in-memory m3
	fixture so no network fetch is needed.
**/
class GameShellMountTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var course = buildCourse();

		assertClose(Course.ITEM_X, course.itemDisplay.x, "item display x");
		assertClose(Course.ITEM_Y, course.itemDisplay.y, "item display y");
		assertClose(Course.MINIMAP_X, course.miniMap.x, "minimap x");
		assertClose(Course.MINIMAP_Y, course.miniMap.y, "minimap y");
		assertClose(Course.STATS_X, course.statsDisplay.x, "stats x");
		assertClose(Course.STATS_Y, course.statsDisplay.y, "stats y");
		assertClose(Course.HEARTS_X, course.hearts.x, "hearts x");
		assertClose(Course.HEARTS_Y, course.hearts.y, "hearts y");
		assertEquals(false, course.hearts.visible, "hearts hidden until deathmatch lives reported");
		assertClose(Course.MUSIC_X, course.musicSelection.x, "music x");
		assertClose(Course.MUSIC_Y, course.musicSelection.y, "music y");
		assertClose(Course.CHAT_X, course.raceChat.x, "chat x");
		assertClose(Course.CHAT_Y, course.raceChat.y, "chat y");
		assertClose(Course.DRAWING_X, course.drawingInfo.x, "drawing info x");
		assertClose(Course.DRAWING_Y, course.drawingInfo.y, "drawing info y");

		assertEquals(true, course.levelRenderer != null, "level renderer mounted");
		assertEquals(true, course.characterLayer != null, "character layer present");
		assertEquals(true, course.backCharacterLayer != null, "back character layer present");
		assertEquals(true, course.localCharacter != null, "local character bridge mounted");
		assertEquals(course.localCharacter, course.characterLayer.getChildAt(0), "local character owns display-list slot");
		assertBelow(course.levelRenderer.getChildIndex(course.backCharacterLayer), course.levelRenderer.getChildIndex(course.characterLayer),
			"back character layer renders below front character layer");
		assertBelow(course.levelRenderer.getChildIndex(course.backCharacterLayer), course.levelRenderer.numChildren - 1,
			"back character layer is below the level foreground");
		testRemoteParentLayerSwitch(course);

		// With no chat interceptor supplied, the shell does not swallow chat.
		assertEquals(false, course.handleRaceChatLine("/debug"), "no interceptor leaves chat unhandled");

		course.remove();
		assertEquals(true, course.miniMap == null, "minimap torn down");
		assertEquals(true, course.itemDisplay == null, "item display torn down");
		assertEquals(true, course.statsDisplay == null, "stats display torn down");
		assertEquals(true, course.hearts == null, "hearts torn down");
		assertEquals(true, course.musicSelection == null, "music selection torn down");
		assertEquals(true, course.raceChat == null, "race chat torn down");
		assertEquals(true, course.drawingInfo == null, "drawing info torn down");
		assertEquals(true, course.levelRenderer == null, "level renderer torn down");
		assertEquals(true, course.localCharacter == null, "local character torn down");

		testDeathmatchHeartsShowInitialLives();
		testFinishDrawingReadinessEmission();

		trace('GameShellMountTest passed $assertions assertions');
	}

	private static function testDeathmatchHeartsShowInitialLives():Void {
		var course = buildCourse("deathmatch");
		assertEquals(true, course.hearts.visible, "deathmatch course shows hearts immediately");
		assertEquals(3, course.hearts.getHeartCount(), "deathmatch course starts with three lives");
		LobbySocket.resetSent();
		var zeroLives = new LocalPlayerDebugState(0, 0, 0, 0, false, false, CharacterState.Bumped, null, "hurt", null, null, null, 50, 50,
			50, 0, true, null, null, null, 0);
		@:privateAccess course.maybeHandleLocalFinish(zeroLives);
		assertEquals("finish_race`-1`0`0", LobbySocket.lastSent(), "deathmatch zero lives emits default finish payload");
		course.remove();
	}

	private static function testRemoteParentLayerSwitch(course:Course):Void {
		var remote = course.createRemoteCharacter(remoteInit(9));
		assertEquals(course.characterLayer, remote.parent, "remote character starts in front character layer");
		remote.onParentChange("backBackground");
		assertEquals(course.backCharacterLayer, remote.parent, "remote water parent moves behind blocks");
		remote.onParentChange("frontBackground");
		assertEquals(course.characterLayer, remote.parent, "remote front parent returns above blocks");
		course.removeRemoteCharacter(9);
	}

	private static function remoteInit(tempId:Int):RemoteCharacterInit {
		return {
			tempId: tempId,
			userName: "Remote",
			hatId: 1,
			headId: 1,
			bodyId: 1,
			feetId: 1,
			group: "g",
			hatColor: 1,
			hatColor2: 2,
			headColor: 3,
			headColor2: 4,
			bodyColor: 5,
			bodyColor2: 6,
			feetColor: 7,
			feetColor2: 8
		};
	}

	private static function buildCourse(gameMode:String = "race"):Course {
		var dataString = "m3`e0c8b8`334;335;11,1;0;12,0;1;0,1;0";
		var level = ServerLevelDecoder.decode(dataString);

		var vars:Map<String, String> = new Map();
		vars.set("level_id", "42");
		vars.set("title", "Mount Test");
		vars.set("song", "song1");
		vars.set("gravity", "2.5");
		vars.set("max_time", "120");
		vars.set("gameMode", gameMode);
		vars.set("items", "all");
		vars.set("data", dataString);

		var data = new ServerLevelData(vars, true);
		var config = LevelConfig.fromServerData(data);
		return new Course(level, data, config);
	}

	private static function testFinishDrawingReadinessEmission():Void {
		var dataString = "m3`e0c8b8`0;0;11,1;0;16";
		var level = ServerLevelDecoder.decode(dataString);
		var saveString = "level_id=42&version=7&title=Draw Ready&song=song1&gravity=1&max_time=120&gameMode=race&cowboyChance=25&badHats=4,6&data="
			+ dataString;

		var vars:Map<String, String> = new Map();
		vars.set("level_id", "42");
		vars.set("version", "7");
		vars.set("title", "Draw Ready");
		vars.set("song", "song1");
		vars.set("gravity", "1");
		vars.set("max_time", "120");
		vars.set("gameMode", "race");
		vars.set("cowboyChance", "25");
		vars.set("badHats", "4,6");
		vars.set("data", dataString);

		var data = new ServerLevelData(vars, true, saveString);
		var course = new Course(level, data, LevelConfig.fromServerData(data));
		LobbySocket.resetSent();
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		course.dispatchEvent(new Event(Event.ENTER_FRAME));
		course.dispatchEvent(new Event(Event.ENTER_FRAME));

		var hash = Md5.encode(saveString + "42" + "7" + ServerConfig.LEVEL_HASH_SALT);
		assertEquals(
			'finish_drawing`$hash`race`[{"id":1,"x":45,"y":15}]`1`25`4,6',
			LobbySocket.sentCommands.join("|"),
			"finish_drawing emitted after all drawing completes"
		);
		assertEquals(false, course.drawingInfo.isDrawing(0), "local drawing spinner hidden after readiness emission");
		course.remove();
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.001) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertBelow(actual:Float, expectedUpperBound:Float, message:String):Void {
		assertions++;
		if (!(actual < expectedUpperBound)) {
			throw '$message: expected $actual to be below $expectedUpperBound';
		}
	}
}
