package pr2.gameplay;

import pr2.gameplay.LevelEntry.LevelEntryState;
import pr2.net.LevelDataClient;

/**
	A4 coverage: the level-entry handshake transitions exactly as Flash drives it
	across the lobby selection (`LevelLaunch`) and the in-game load
	(`Game.loadHandler`).

	Verifies, from a server-frame transcript:
	- a slot fill records the selection; an unrelated `startGame` is ignored;
	  the matching `startGame` advances to `Loading`;
	- a valid payload reaches `Ready` and enables spectate;
	- a corrupted hash and an empty payload yield the two distinct Flash error
	  strings, and both block spectate.
**/
class LevelEntryStateTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testSelectionHandoff();
		testReadyEnablesSpectate();
		testDownloadCorruptionError();
		testEmptyPayloadError();
		testTooShortPayloadIsDownloadError();
		trace('LevelEntryStateTest passed $assertions assertions');
	}

	private static function testSelectionHandoff():Void {
		var entry = new LevelEntry();
		assertState(Idle, entry.state, "starts idle");

		entry.select(4271, 9);
		assertState(Selected(4271, 9), entry.state, "slot fill records selection");

		// An unrelated launch must not change the page (LevelLaunch parity).
		entry.startGame(9999);
		assertState(Selected(4271, 9), entry.state, "unrelated startGame ignored");

		entry.startGame(4271);
		assertState(Loading(4271, 9), entry.state, "matching startGame begins loading");

		// A second startGame for the same id no longer matters (already loading).
		entry.startGame(4271);
		assertState(Loading(4271, 9), entry.state, "startGame while loading is a no-op");
	}

	private static function testReadyEnablesSpectate():Void {
		var entry = loadingEntry(4271, 9);
		assertEquals(false, entry.spectatePossible, "spectate disabled while loading");

		var levelTxt = signed("data=m1`0`0`0", 9, 4271);
		var result = entry.onLevelText(levelTxt);
		assertState(Ready(4271, 9), result, "valid payload reaches Ready");
		assertState(Ready(4271, 9), entry.state, "Ready is retained as the machine state");
		assertEquals(true, entry.spectatePossible, "Ready enables spectate");
	}

	private static function testDownloadCorruptionError():Void {
		var entry = loadingEntry(4271, 9);
		// A payload whose appended hash does not match the body.
		var corrupted = "data=m1`0`0`0" + "00000000000000000000000000000000";
		var result = entry.onLevelText(corrupted);
		assertState(Failed(LevelEntry.DOWNLOAD_ERROR), result, "hash mismatch => download error");
		assertEquals(false, entry.spectatePossible, "download error blocks spectate");
	}

	private static function testEmptyPayloadError():Void {
		var entry = loadingEntry(4271, 9);
		// A correctly-hashed but empty body: hash check passes, payload is empty.
		var emptyHash = LevelDataClient.computeHash(9, 4271, "");
		var result = entry.onLevelText(emptyHash);
		assertState(Failed(LevelEntry.LOAD_ERROR), result, "empty payload => load error");
		assertEquals(false, entry.spectatePossible, "load error blocks spectate");
	}

	private static function testTooShortPayloadIsDownloadError():Void {
		var entry = loadingEntry(4271, 9);
		var result = entry.onLevelText("nope");
		assertState(Failed(LevelEntry.DOWNLOAD_ERROR), result, "truncated payload => download error");
	}

	// ---- helpers ---------------------------------------------------------

	private static function loadingEntry(id:Int, v:Int):LevelEntry {
		var entry = new LevelEntry();
		entry.select(id, v);
		entry.startGame(id);
		return entry;
	}

	/** Append the `Game.loadHandler` MD5 so `onLevelText` accepts the body. */
	private static function signed(levelData:String, version:Int, levelId:Int):String {
		return levelData + LevelDataClient.computeHash(version, levelId, levelData);
	}

	private static function assertState(expected:LevelEntryState, actual:LevelEntryState, message:String):Void {
		assertions++;
		if (!Type.enumEq(expected, actual)) {
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
