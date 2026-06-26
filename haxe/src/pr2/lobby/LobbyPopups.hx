package pr2.lobby;

import pr2.lobby.dialogs.ExternalLinkPopup;

/**
	Thin wrapper for the Flash `dialogs.*` popup classes that lobby chat/link
	handling reaches for (`PlayerPopup`, `GuildPopup`, `LevelInfoPopup`,
	`SendMessagePopup`, `ExternalLinkPopup`, ...).

	Implemented routes open their authored popup classes directly. Routes still
	awaiting a full port record the most recent request so link-handling remains
	testable until the real popup replaces the marker.
**/
class LobbyPopups {
	/** Last unported popup/action requested, e.g. "level:123" — inspected by tests. */
	public static var lastRequest:String = "";

	private function new() {}

	public static function showPlayer(userName:String):Void {
		new pr2.lobby.dialogs.PlayerPopup(userName);
	}

	public static function showGuestPlayer(userName:String):Void {
		new pr2.lobby.dialogs.PlayerGuestPopup(userName);
	}

	public static function showGuild(guildId:Int):Void {
		new pr2.lobby.dialogs.GuildPopup(guildId);
	}

	public static function showGuildByName(name:String):Void {
		new pr2.lobby.dialogs.GuildPopup(0, name);
	}

	public static function showLevel(levelId:String):Void {
		lastRequest = 'level:$levelId';
	}

	public static function sendMessage(toUser:String):Void {
		lastRequest = 'sendMessage:$toUser';
		new pr2.lobby.dialogs.SendMessagePopup(toUser);
	}

	public static function openUrl(url:String):Void {
		lastRequest = 'url:$url';
		new ExternalLinkPopup(url);
	}
}
