package pr2.gameplay;

import openfl.events.MouseEvent;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.lobby.LobbyArt;
import pr2.level.ServerLevelDecoder;
import pr2.net.ServerLevelData;

class SpectatePickerTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testVisibilityAndSelection();
		trace('SpectatePickerTest passed $assertions assertions');
	}

	private static function testVisibilityAndSelection():Void {
		var course = buildCourse();
		assertEquals(false, course.canSpectate, "spectating disabled at mount");
		assertEquals(false, course.spectatePicker.isArtVisible(), "picker hidden at mount");
		assertEquals("Free Scroll", course.spectatePicker.playerNameHtml(), "free-scroll label at mount");

		course.createRemoteCharacter(remoteInit(1, "Rival", "1"));
		course.createRemoteCharacter(remoteInit(2, "Mod", "2"));
		course.toggleSpectatePossible(true);
		assertEquals(true, course.spectatePicker.isArtVisible(), "picker visible when spectating is possible");
		assertEquals(null, course.playerSpectating, "visibility reset leaves free scroll");

		LobbyArt.findByName(course.spectatePicker, "arrowRight").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(0, course.spectatePicker.pickedID, "right arrow starts at local temp id");
		assertEquals(course.localCharacter, course.playerSpectating, "right arrow selects local character first");

		LobbyArt.findByName(course.spectatePicker, "arrowRight").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, course.spectatePicker.pickedID, "right arrow advances to first remote");
		assertEquals(course.getRemoteCharacter(1), course.playerSpectating, "right arrow selects remote");
		assertContains(course.spectatePicker.playerNameHtml(), "Rival", "selected name rendered");

		LobbyArt.findByName(course.spectatePicker, "arrowRight").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(2, course.spectatePicker.pickedID, "right arrow advances to next remote");
		assertEquals(course.getRemoteCharacter(2), course.playerSpectating, "next remote selected");

		LobbyArt.findByName(course.spectatePicker, "arrowLeft").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, course.spectatePicker.pickedID, "left arrow returns to previous remote");

		course.toggleSpectatePossible(false);
		assertEquals(false, course.spectatePicker.isArtVisible(), "picker hidden when spectating disabled");
		course.toggleSpectatePossible(true);
		assertEquals(-1, course.spectatePicker.pickedID, "showing picker resets selection");
		assertEquals("Free Scroll", course.spectatePicker.playerNameHtml(), "free-scroll label restored");

		course.removeRemoteCharacter(1);
		assertEquals(null, course.getRemoteCharacter(1), "remote removed");
		course.remove();
		assertEquals(null, course.spectatePicker, "picker torn down");
	}

	private static function buildCourse():Course {
		var dataString = "m3`ffffff`0;0;11,1;0;16";
		var level = ServerLevelDecoder.decode(dataString);
		var vars:Map<String, String> = new Map();
		vars.set("level_id", "77");
		vars.set("title", "Spectate Test");
		vars.set("song", "song1");
		vars.set("gravity", "1");
		vars.set("max_time", "120");
		vars.set("gameMode", "race");
		vars.set("items", "all");
		vars.set("data", dataString);
		var data = new ServerLevelData(vars, true);
		return new Course(level, data, LevelConfig.fromServerData(data));
	}

	private static function remoteInit(tempId:Int, name:String, group:String):RemoteCharacterInit {
		return {
			tempId: tempId,
			userName: name,
			hatId: 1,
			headId: 1,
			bodyId: 1,
			feetId: 1,
			hatColor: -1,
			hatColor2: -1,
			headColor: -1,
			headColor2: -1,
			bodyColor: -1,
			bodyColor2: -1,
			feetColor: -1,
			feetColor2: -1,
			group: group
		};
	}

	private static function assertContains(value:String, part:String, message:String):Void {
		assertions++;
		if (value.indexOf(part) < 0) {
			throw '$message: expected "$value" to contain "$part"';
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
