package pr2.gameplay;

import openfl.ui.Keyboard;
import pr2.lobby.LobbySession;
import pr2.level.ServerLevelDecoder;
import pr2.net.ServerLevelData;
import pr2.gameplay.SpecialEvent.PlaceArtifactRequest;

class SpecialEventTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testPermissions();
		if (pr2.DeterministicTestMode.finishSmokeSuite("SpecialEventTest")) return;
		testPlaceArtifactHotkey();
		testArtifactPlacementCoordinates();
		testCancelPrizeHotkey();
		trace('SpecialEventTest passed $assertions assertions');
	}

	private static function testPermissions():Void {
		LobbySession.clear();
		LobbySession.group = 1;
		assertEquals(false, SpecialEvent.canUse(), "members cannot use special-event hotkeys");
		LobbySession.group = 2;
		assertEquals(true, SpecialEvent.canUse(), "permanent moderators can use special-event hotkeys");
		LobbySession.isTempMod = true;
		assertEquals(false, SpecialEvent.canUse(), "temp moderators cannot use special-event hotkeys");
		LobbySession.isTempMod = false;
		LobbySession.isTrialMod = true;
		assertEquals(false, SpecialEvent.canUse(), "trial moderators cannot use special-event hotkeys");
		LobbySession.group = 0;
		LobbySession.isTrialMod = false;
		LobbySession.isPrizer = true;
		assertEquals(true, SpecialEvent.canUse(), "prizers can use special-event hotkeys");
		LobbySession.isPrizer = false;
		LobbySession.isSpecialUser = true;
		assertEquals(true, SpecialEvent.canUse(), "special users can use special-event hotkeys");
		LobbySession.clear();
	}

	private static function testPlaceArtifactHotkey():Void {
		LobbySession.clear();
		LobbySession.group = 3;
		var expected:PlaceArtifactRequest = {levelId: 42, x: 600, y: 800, rot: 90};
		var opened:Array<PlaceArtifactRequest> = [];
		var special = new SpecialEvent(null, function(request) opened.push(request), function(_, _, _) return expected);
		special.keyDown(Keyboard.G);
		special.keyDown(Keyboard.C);
		var action = special.click(200, 300, null, null);

		assertEquals(1, opened.length, "G+C click opens artifact prompt");
		assertEquals(expected, opened[0], "G+C click forwards the resolved placement request");
		switch (action) {
			case PlaceArtifactAction(request):
				assertEquals(expected, request, "action returns placement request");
			default:
				throw "expected PlaceArtifactAction";
		}
		LobbySession.clear();
	}

	private static function testArtifactPlacementCoordinates():Void {
		var course = buildCourse();
		course.x = 10;
		course.y = 20;
		course.levelRenderer.setCameraOffset(-400, -500);
		course.levelRenderer.rotation = 90;
		var request = course.artifactPlacementAt(210, 320);

		assertEquals(42, request.levelId, "placement uses course id");
		assertEquals(600, request.x, "placement converts stage x with explicit course and camera offsets");
		assertEquals(800, request.y, "placement converts stage y with explicit course and camera offsets");
		assertEquals(90, request.rot, "placement carries block-layer rotation");
		course.remove();
	}

	private static function testCancelPrizeHotkey():Void {
		LobbySession.clear();
		LobbySession.group = 3;
		var sent:Array<String> = [];
		var special = new SpecialEvent(function(command) sent.push(command), null);
		special.keyDown(Keyboard.C);
		special.keyDown(Keyboard.X);
		switch (special.click(0, 0, null, {type: "hat"})) {
			case CancelPrizeAction:
				assertions++;
			default:
				throw "expected CancelPrizeAction";
		}
		assertEquals("cancel_prize`", sent[0], "cancel command emitted");
		LobbySession.clear();
	}

	private static function buildCourse():Course {
		var dataString = "m3`e0c8b8`334;335;11,1;0;12,0;1;0,1;0";
		var level = ServerLevelDecoder.decode(dataString);
		var vars:Map<String, String> = new Map();
		vars.set("level_id", "42");
		vars.set("title", "Special Event Test");
		vars.set("song", "song1");
		vars.set("gravity", "1");
		vars.set("max_time", "120");
		vars.set("gameMode", "race");
		vars.set("items", "all");
		vars.set("data", dataString);
		var data = new ServerLevelData(vars, true);
		return new Course(level, data, LevelConfig.fromServerData(data));
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
