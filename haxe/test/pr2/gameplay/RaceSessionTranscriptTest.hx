package pr2.gameplay;

import openfl.display.InteractiveObject;
import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.gameplay.LevelEntry.LevelEntryState;
import pr2.level.LevelDecoder;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.level.LevelItem;
import pr2.lobby.level.LevelListingState;
import pr2.net.CampaignLevelInfo;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerLevelData;
import pr2.page.GamePage;
import pr2.page.LobbyPage;
import pr2.page.PageHolder;
import pr2.util.TestDisplayUtil as DisplayUtil;

/**
	Deterministic transcript of one full real-server race session, from the
	lobby join through the in-race sync to the finish/quit and the return to the
	lobby — the CI-runnable counterpart of the live two-instance acceptance
	(`tools/race_session.py`).

	It drives the production objects the live run drives — `LevelItem` for the
	slot join, `GamePage` for the level-entry/race/quit lifecycle (including the
	`pendingLocalInit`/`pendingBeginRace` queueing that buffers the server's
	character/begin frames until the HTTP level payload arrives) — and asserts
	both the ordered wire-command transcript every step emits and the
	level-entry / race-phase state at each transition. The level payload is fed
	in-memory through `GamePage.onLevelData` so no network fetch is needed; the
	server character/begin/remote frames are dispatched through the same global
	`CommandHandler` the live socket feeds.
**/
@:access(pr2.page.GamePage)
class RaceSessionTranscriptTest {
	private static var assertions:Int = 0;

	private static inline final LEVEL_ID = 99;
	private static inline final VERSION = 3;
	// A minimal one-row level: enough for Course to decode, mount and run a race.
	private static inline final DATA = "m3`ffffff`0;0;11,1;0;8,0;1;0";

	public static function main():Void {
		LobbySession.begin("Tester", 1);
		LevelListingState.currentPageNum = 1;
		LobbySocket.resetSent();
		var handler = CommandHandler.commandHandler;

		// ---- 1. Lobby join: fill a slot, then confirm it ----------------------
		var item = new LevelItem(levelInfo());
		item.sendFillSlot(0);
		assertEquals("fill_slot`" + LEVEL_ID + "_" + VERSION + "`0`1", LobbySocket.lastSent(),
			"slot fill reports the level, slot and listing page");
		if (pr2.DeterministicTestMode.finishSmokeSuite("RaceSessionTranscriptTest")) return;
		item.sendConfirmSlot();
		assertEquals("confirm_slot`", LobbySocket.lastSent(), "confirm launches the joined race");
		item.remove();

		// ---- 2. Level entry: server startGame -> GamePage, frames queue -------
		var holder = new PageHolder();
		var game = new GamePage(LEVEL_ID, VERSION);
		holder.changePage(game);
		assertTrue(isLoading(game.entry.state), "entry is loading the payload after startGame");

		// The server pushes the local character and the race start before the
		// HTTP payload lands; GamePage must buffer them until the course exists.
		handler.dispatch("createLocalCharacter",
			["7", "80", "70", "60", "101", "102", "103", "104", "2", "3", "4", "5", "201", "202", "203", "204", "g"]);
		handler.dispatch("beginRace", []);
		assertEquals(true, game.course == null, "course not built until the payload arrives");
		assertTrue(game.pendingLocalInit != null, "local character frame buffered while loading");
		assertEquals(true, game.pendingBeginRace, "begin-race frame buffered while loading");

		// The payload arrives: the course mounts and the buffered frames apply.
		game.onLevelData(levelData());
		assertTrue(game.course != null, "payload mounts the course");
		var course = game.course;
		assertTrue(isReady(game.entry.state), "entry is ready once the payload validates");
		assertTrue(course.localCharacter != null, "buffered local character applied on mount");
		assertEquals(7, course.localCharacter.tempID, "buffered local character keeps its temp id");
		assertEquals(false, course.raceStarted, "race waits for the countdown");
		assertTrue(course.countdown != null, "begin-race mounts the countdown");
		var startPos = course.localCharacter.getPos();
		var startPositionCommand = 'exact_pos`${Math.round(startPos.x)}`${Math.round(startPos.y)}';
		assertEquals(startPositionCommand, LobbySocket.lastSent(), "begin-race emits the starting position");

		// ---- 3. Countdown -> racing ------------------------------------------
		while (course.countdown != null && course.countdown.parent != null) {
			course.countdown.advance();
		}
		assertEquals(true, course.raceStarted, "countdown finish starts the race");
		assertEquals("p`0`0", LobbySocket.lastSent(), "race start initializes network position emission");

		// ---- 4. Remote sync: the co-joined player appears --------------------
		assertEquals(0, course.remoteCharacterCount(), "no remotes before the server announces them");
		handler.dispatch("createRemoteCharacter",
			["9", "Rival", "111", "112", "113", "114", "6", "7", "8", "9", "211", "212", "213", "214", "mod"]);
		assertEquals(1, course.remoteCharacterCount(), "remote player synced into the race");
		assertEquals("Rival", course.getRemoteCharacter(9).userName, "remote player keeps its name");

		// ---- 5. Finish/quit: the quit button ends the local race ------------
		quitButton(game).dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
		assertEquals("quit_race`", LobbySocket.lastSent(), "quitting emits the Flash quit command");
		assertEquals(true, game.playerDone, "quit marks the local player done");
		assertEquals(true, course.raceEnded, "quit tells the course the race is over");
		var finish = Std.downcast(Popup.getOpen()[0], FinishedPage);
		assertTrue(finish != null, "quitting opens the finish overlay");

		// ---- 6. Return to lobby without a reload ----------------------------
		LobbySocket.simulateOpenForTests();
		returnButton(finish).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertTrue(LobbySocket.sentCommands.indexOf("set_game_room`none") >= 0, "return clears the game room");
		assertEquals(true, Std.isOfType(holder.getCurrentPage(), LobbyPage), "return restores the lobby page");
		// Rebuilding the lobby re-opens its level listing, which re-announces the
		// listing room. Other lobby tabs may refresh data asynchronously.
		assertEquals("set_right_room`none", LobbySocket.lastSent(), "restored lobby re-announces its listing room");

		// ---- Whole-session transcript ----------------------------------------
		var expected = [
			"fill_slot`" + LEVEL_ID + "_" + VERSION + "`0`1",
			"confirm_slot`",
			startPositionCommand,
			"p`0`0",
			"quit_race`",
			"set_game_room`none",
			"set_right_room`none"
		];
		assertEquals(expected.join(" | "), sessionTranscriptCommands().join(" | "),
			"full session emits the join -> race -> quit -> return transcript in order");

		holder.getCurrentPage().remove();
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
		trace('RaceSessionTranscriptTest passed $assertions assertions');
	}

	private static function levelInfo():CampaignLevelInfo {
		return new CampaignLevelInfo(LEVEL_ID, VERSION, "Transcript Level", "Tester", 0, 5, 0);
	}

	private static function levelData():ServerLevelData {
		var vars:Map<String, String> = new Map();
		vars.set("level_id", Std.string(LEVEL_ID));
		vars.set("version", Std.string(VERSION));
		vars.set("title", "Transcript Level");
		vars.set("song", "song1");
		vars.set("gravity", "1");
		vars.set("max_time", "120");
		vars.set("gameMode", "race");
		vars.set("items", "all");
		vars.set("data", DATA);
		return new ServerLevelData(vars, true);
	}

	private static function quitButton(game:GamePage):InteractiveObject {
		return Std.downcast(DisplayUtil.findByName(game, "quit_bt"), InteractiveObject);
	}

	private static function returnButton(finish:FinishedPage):InteractiveObject {
		return Std.downcast(DisplayUtil.findByName(finish, "return_bt"), InteractiveObject);
	}

	private static function sessionTranscriptCommands():Array<String> {
		return LobbySocket.sentCommands.filter(function(command:String):Bool {
			return StringTools.startsWith(command, "fill_slot`")
				|| command == "confirm_slot`"
				|| StringTools.startsWith(command, "exact_pos`")
				|| StringTools.startsWith(command, "p`")
				|| command == "quit_race`"
				|| command == "set_game_room`none"
				|| command == "set_right_room`none";
		});
	}

	private static function isLoading(state:LevelEntryState):Bool {
		return switch (state) {
			case Loading(_, _): true;
			default: false;
		}
	}

	private static function isReady(state:LevelEntryState):Bool {
		return switch (state) {
			case Ready(_, _): true;
			default: false;
		}
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
