package pr2.lobby.level;

import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.net.LevelListClient;
import pr2.net.LevelListClient.LevelListResult;
import pr2.net.LobbySocket;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

/** Transport and collection memory; independent of either listing presentation. */
class LevelBrowserData {
	public static var fetchFactory:String->Int->(LevelListResult->Void)->(String->Void)->AsyncRemovable = LevelListClient.fetch;
	public static var favoritesFactory:Int->Int->String->(LevelListResult->Void)->(String->Void)->AsyncRemovable = LevelListClient.fetchFavorites;
	public static var searchFactory:Map<String,String>->(LevelListResult->Void)->(String->Void)->AsyncRemovable = LevelListClient.search;
	public static function initialPage(mode:String):Int {
		var fallback = 1;
		if (mode == "campaign") {
			fallback = LevelListClient.campaignPage(LobbySession.server == null ? 0 : LobbySession.server.serverId, Std.int(LobbySession.lastAuthTime.getDay()));
			LobbySocket.campaignPage = fallback;
		}
		var remembered = Memory.getInt("coursePageNum" + mode, 0);
		return remembered > 0 ? remembered : fallback;
	}
	public static function pageCount(mode:String):Int return mode == "campaign" ? 6 : 9;
}
