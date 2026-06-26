package pr2.gameplay;

import pr2.net.LevelDataClient;

/** Phases of the level-entry handshake (see `LevelEntry`). */
enum LevelEntryState {
	/** Nothing selected; no pending launch. */
	Idle;
	/** A slot was filled by the local player but the server has not launched yet. */
	Selected(levelId:Int, version:Int);
	/** Server `startGame` accepted; the level payload is being fetched. */
	Loading(levelId:Int, version:Int);
	/** Payload validated and mounted; spectate input is now enabled. */
	Ready(levelId:Int, version:Int);
	/** Entry aborted; `message` is shown to the player verbatim. */
	Failed(message:String);
}

/**
	Pure model of the Flash level-entry handshake, spanning the lobby selection
	(`LevelItem`/`Slot`/`LevelLaunch`) and the in-game load (`Game.loadHandler`).

	The selection half mirrors `LevelLaunch`: a slot fill records the selected
	level, but only the gameserver's `startGame` for that exact level advances to
	`Loading` — an unrelated `startGame` is ignored. The load half mirrors
	`Game.loadHandler`: the trailing 32-char MD5 is checked first (mismatch =>
	`DOWNLOAD_ERROR`), then the stripped payload's emptiness (=> `LOAD_ERROR`),
	otherwise the level is `Ready` and spectate becomes possible.

	This is deliberately display-free so the transitions and the two distinct
	error messages can be verified from a server-frame transcript.
**/
class LevelEntry {
	/** Hash check failed — payload was corrupted in transit. Flash wording. */
	public static inline final DOWNLOAD_ERROR = "Error: The course did not download correctly.";

	/** Hash matched but the payload was empty. Flash wording. */
	public static inline final LOAD_ERROR = "Error: The course did not load.";

	public var state(default, null):LevelEntryState = Idle;

	/** True once a level is `Ready`; gates `SpectatePicker` visibility in Flash. */
	public var spectatePossible(default, null):Bool = false;

	public function new() {}

	/** Local slot fill — record the selection (mirrors `LevelLaunch.select`). */
	public function select(levelId:Int, version:Int):Void {
		state = Selected(levelId, version);
		spectatePossible = false;
	}

	/** Cancel a selection if it matches (mirrors `LevelLaunch.clear`). */
	public function clearSelection(levelId:Int, version:Int):Void {
		switch (state) {
			case Selected(id, v) if (id == levelId && v == version):
				state = Idle;
			default:
		}
	}

	/**
		Server `startGame` for `levelId`. Advances to `Loading` only when it
		matches the current selection; any other launch is ignored, exactly like
		`LevelLaunch.startGame` refusing to change pages for a stale level.
	**/
	public function startGame(levelId:Int):Void {
		switch (state) {
			case Selected(id, v) if (id == levelId):
				state = Loading(id, v);
			default:
		}
	}

	/**
		Outcome of the level fetch as already-derived flags (the form `GamePage`
		has after `LevelDataClient`). Valid only while `Loading`.
	**/
	public function onLoadOutcome(hashValid:Bool, dataEmpty:Bool):LevelEntryState {
		switch (state) {
			case Loading(id, v):
				if (!hashValid) {
					state = Failed(DOWNLOAD_ERROR);
				} else if (dataEmpty) {
					state = Failed(LOAD_ERROR);
				} else {
					state = Ready(id, v);
					spectatePossible = true;
				}
			default:
		}
		return state;
	}

	/**
		Outcome of the level fetch from the raw `.txt` payload, validating exactly
		as `Game.loadHandler` does (strip trailing 32-char hash, recompute MD5).
		Convenience for transcript tests that drive the full server response.
	**/
	public function onLevelText(levelTxt:String):LevelEntryState {
		switch (state) {
			case Loading(id, v):
				if (levelTxt == null || levelTxt.length < 32) {
					// Too short to even contain a hash: treat as a bad download.
					return onLoadOutcome(false, true);
				}
				var hashPos = levelTxt.length - 32;
				var levelData = levelTxt.substr(0, hashPos);
				var levelHash = levelTxt.substr(hashPos);
				var hashValid = LevelDataClient.computeHash(v, id, levelData) == levelHash;
				return onLoadOutcome(hashValid, levelData == "");
			default:
		}
		return state;
	}
}
