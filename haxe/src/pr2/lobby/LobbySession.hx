package pr2.lobby;

import com.jiggmin.data.Time;
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
	public static inline var REMEMBER_ME_REQUIRED_COPY:String = "Psst... I won't work if you're not logged in with remember me. Log back in with remember me enabled and click me again! :)";

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
	public static var isSpecialUser:Bool = false;
	public static var isPrizer:Bool = false;
	public static var tournamentMode:Bool = false;
	public static var serverOwner:Int = 0;

	/** Favorited level ids (Flash `Main.favoriteLevels`), used by listings. */
	public static var favoriteLevels:Array<Int> = [];
	public static var lastAuthTime:Time = new Time();

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

	public static function updateAccountState(hasEmail:Bool, token:String, notify:Bool = true):Void {
		LobbySession.hasEmail = hasEmail;
		LobbySession.token = token;
		if (notify) notifyAccountChange();
	}

	public static function updateGuildState(guildId:Int, guildName:String, guildOwner:Bool, ?emblem:String, notify:Bool = true):Void {
		LobbySession.guildId = guildId;
		LobbySession.guildName = guildName;
		LobbySession.guildOwner = guildOwner;
		if (emblem != null) {
			LobbySession.emblem = emblem;
		}
		if (notify) notifyAccountChange();
	}

	public static function updateGuildFromData(data:Dynamic, ?ownerOverride:Null<Bool>, notify:Bool = true, updateEmblem:Bool = true):Void {
		if (data == null) return;
		var owner = ownerOverride == null ? boolAny(data, ["is_owner", "guild_owner", "guildOwner"]) : ownerOverride;
		updateGuildState(intAny(data, ["guild_id", "guildId", "guild"]), strAny(data, ["guild_name", "guildName"]), owner,
			updateEmblem ? strAny(data, ["emblem"]) : null, notify);
	}

	public static function clearGuild(notify:Bool = true):Void {
		updateGuildState(0, "", false, "", notify);
	}

	public static inline function canUseRememberMeAccountAction():Bool {
		return remember;
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
		isSpecialUser = false;
		isPrizer = false;
		tournamentMode = false;
		serverOwner = 0;
		favoriteLevels = [];
		lastAuthTime = new Time();
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

	private static function intAny(data:Dynamic, names:Array<String>):Int {
		for (name in names) {
			var value:Dynamic = Reflect.field(data, name);
			if (value != null) {
				var parsed = Std.parseInt(Std.string(value));
				return parsed == null ? 0 : parsed;
			}
		}
		return 0;
	}

	private static function strAny(data:Dynamic, names:Array<String>):String {
		for (name in names) {
			var value:Dynamic = Reflect.field(data, name);
			if (value != null) return Std.string(value);
		}
		return "";
	}

	private static function boolAny(data:Dynamic, names:Array<String>):Bool {
		for (name in names) {
			var value:Dynamic = Reflect.field(data, name);
			if (value == null) continue;
			if (Std.isOfType(value, Bool)) return value;
			if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) return Std.int(value) != 0;
			var text = Std.string(value).toLowerCase();
			return text == "1" || text == "true" || text == "yes";
		}
		return false;
	}
}
