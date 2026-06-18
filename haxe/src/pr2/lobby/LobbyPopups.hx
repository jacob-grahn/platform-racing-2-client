package pr2.lobby;

#if js
import js.Browser;
#end

/**
	Thin wrapper standing in for the Flash `dialogs.*` popup classes that lobby
	chat/link handling reaches for (`PlayerPopup`, `GuildPopup`, `LevelInfoPopup`,
	`SendMessagePopup`, `ExternalLinkPopup`, ...).

	Those popups are large UI subsystems of their own. Until each is ported, this
	hub records the most recent request (so link-handling can be tested) and, for
	external URLs, performs the real navigation. A renderer hook can later replace
	the record-only behavior with the actual popups without touching callers.
**/
class LobbyPopups {
	/** Last popup requested, e.g. "player:Jiggmin" — inspected by tests. */
	public static var lastRequest:String = "";

	private function new() {}

	public static function showPlayer(userName:String):Void {
		lastRequest = 'player:$userName';
	}

	public static function showGuestPlayer(userName:String):Void {
		lastRequest = 'guestPlayer:$userName';
	}

	public static function showGuild(guildId:Int):Void {
		lastRequest = 'guild:$guildId';
	}

	public static function showGuildByName(name:String):Void {
		lastRequest = 'guildName:$name';
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
		#if js
		Browser.window.open(url, "_blank");
		#end
	}
}
