package pr2.lobby.level;

import pr2.net.CommandHandler;
import pr2.page.GamePage;
import pr2.page.PageHolder;

/**
	Persistent level-entry coordinator. The local slot identifies the selected
	level, but only the gameserver's `startGame` command may change pages.
**/
class LevelLaunch {
	/** Last accepted server launch as "levelId`version" — inspected by tests. */
	public static var lastLaunch:String = "";
	public static var handler:Null<(Int, Int) -> Void> = null;
	private static var selectedLevelId:Null<Int>;
	private static var selectedVersion:Null<Int>;
	private static var pageHolder:Null<PageHolder>;

	private function new() {}

	public static function install(holder:PageHolder):Void {
		pageHolder = holder;
		CommandHandler.commandHandler.defineCommand("startGame", startGame);
	}

	public static function select(levelId:Int, version:Int):Void {
		selectedLevelId = levelId;
		selectedVersion = version;
	}

	public static function clear(levelId:Int, version:Int):Void {
		if (selectedLevelId == levelId && selectedVersion == version) {
			selectedLevelId = null;
			selectedVersion = null;
		}
	}

	public static function startGame(args:Array<String>):Void {
		var levelId = args.length > 0 ? Std.parseInt(args[0]) : null;
		if (levelId == null || levelId != selectedLevelId || selectedVersion == null) {
			return;
		}
		var version = selectedVersion;
		lastLaunch = levelId + "`" + version;
		selectedLevelId = null;
		selectedVersion = null;
		if (handler != null) {
			handler(levelId, version);
			return;
		}
		if (pageHolder != null) {
			pageHolder.changePage(new GamePage(levelId, version));
		}
	}
}
