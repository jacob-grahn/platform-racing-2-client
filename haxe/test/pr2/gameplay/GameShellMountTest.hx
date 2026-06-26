package pr2.gameplay;

import pr2.level.ServerLevelDecoder;
import pr2.net.ServerLevelData;

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
		assertEquals(true, course.localCharacter != null, "local character bridge mounted");
		assertEquals(course.localCharacter, course.characterLayer.getChildAt(0), "local character owns display-list slot");

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

		trace('GameShellMountTest passed $assertions assertions');
	}

	private static function buildCourse():Course {
		var dataString = "m3`e0c8b8`334;335;11,1;0;12,0;1;0,1;0";
		var level = ServerLevelDecoder.decode(dataString);

		var vars:Map<String, String> = new Map();
		vars.set("level_id", "42");
		vars.set("title", "Mount Test");
		vars.set("song", "song1");
		vars.set("gravity", "2.5");
		vars.set("max_time", "120");
		vars.set("gameMode", "race");
		vars.set("items", "all");
		vars.set("data", dataString);

		var data = new ServerLevelData(vars, true);
		var config = LevelConfig.fromServerData(data);
		return new Course(level, data, config);
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
}
