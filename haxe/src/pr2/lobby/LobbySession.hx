package pr2.lobby;

import pr2.net.ServerInfo;

/**
	Wrapper for the logged-in user/session metadata that the Flash client kept on
	the `Main` singleton (`Main.group`, `Main.loggedInAs`, `Main.server`, etc.).

	Lobby pages read these statics constantly to decide guest-vs-member behavior,
	build socket commands, and pick which tabs to show. Rather than scatter a
	half-ported `Main` across the codebase, the lobby talks to this one wrapper.
	The login flow populates it on a successful handoff; tests can set it up
	directly to exercise guest/member differences deterministically.
**/
class LobbySession {
	/** Account access group. 0 = guest, 1 = member, >=2 = moderator/admin. */
	public static var group:Int = 0;

	/** Display name (Flash `Main.loggedInAs`). "Guest" for guest sessions. */
	public static var userName:String = "Guest";

	/** Numeric account id, 0 for guests (Flash `Main.userId`). */
	public static var userId:Int = 0;
	public static var hasEmail:Bool = false;
	public static var token:String = "";

	/** Server the session is connected to (Flash `Main.server`). */
	public static var server:Null<ServerInfo> = null;

	/** Guild id / name the player belongs to (0 / "" when guildless). */
	public static var guildId:Int = 0;
	public static var guildName:String = "";
	public static var guildOwner:Bool = false;
	public static var emblem:String = "";

	/** Whether the session was started with "Remember Me" (Flash `Main.remember`). */
	public static var remember:Bool = false;

	/** Temporary/trial moderator flags affecting logout confirmation. */
	public static var isTempMod:Bool = false;
	public static var isTrialMod:Bool = false;

	/** Favorited level ids (Flash `Main.favoriteLevels`), used by listings. */
	public static var favoriteLevels:Array<Int> = [];

	private static var accountChangeListeners:Array<Void->Void> = [];

	private function new() {}

	/** True for any logged-in account (Flash checks `Main.group > 0`). */
	public static inline function isMember():Bool {
		return group > 0;
	}

	public static inline function isGuest():Bool {
		return group <= 0;
	}

	/**
		Populate the session after a successful login handoff. Guests pass
		`group = 0` and an empty/0 user id.
	**/
	public static function begin(userName:String, group:Int, ?server:ServerInfo, userId:Int = 0, remember:Bool = false):Void {
		LobbySession.userName = userName;
		LobbySession.group = group;
		LobbySession.server = server;
		LobbySession.userId = userId;
		LobbySession.remember = remember;
	}

	/** Clear the session on logout (Flash `Main.clearUserData`). */
	public static function clear():Void {
		userName = "Guest";
		group = 0;
		userId = 0;
		hasEmail = false;
		token = "";
		server = null;
		guildId = 0;
		guildName = "";
		guildOwner = false;
		emblem = "";
		remember = false;
		isTempMod = false;
		isTrialMod = false;
		favoriteLevels = [];
		accountChangeListeners = [];
	}

	/** Register a callback fired when account info changes (Flash `Main.accountChange`). */
	public static function onAccountChange(listener:Void->Void):Void {
		accountChangeListeners.push(listener);
	}

	public static function offAccountChange(listener:Void->Void):Void {
		accountChangeListeners.remove(listener);
	}

	/** Notify listeners that account info changed (refresh lobby/player displays). */
	public static function notifyAccountChange():Void {
		for (listener in accountChangeListeners.copy()) {
			listener();
		}
	}

	public static inline function isFavorite(levelId:Int):Bool {
		return favoriteLevels.indexOf(levelId) != -1;
	}
}
