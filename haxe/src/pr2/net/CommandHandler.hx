package pr2.net;

import haxe.crypto.Md5;
import pr2.gameplay.CatCaptcha;
import pr2.lobby.LobbySession;
import pr2.lobby.SecureData;
import pr2.lobby.account.AccountState;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.level.LevelLaunch;
import pr2.lobby.messages.UnreadNotif;

/**
	Port of the Flash `com.jiggmin.data.CommandHandler` socket-command dispatcher.

	The gameserver pushes backtick-delimited frames. Pages register named handlers
	via `defineCommand` while they are on screen and clear them (pass `null`) on
	removal, exactly as the AS3 pages did. `LobbySocket` extracts the command name
	and arguments from each incoming frame and routes them here.
**/
class CommandHandler {
	public static var commandHandler(get, never):CommandHandler;
	public static inline var END_CHAR:String = "\x04";
	private static var sharedInstance:Null<CommandHandler>;

	private static function get_commandHandler():CommandHandler {
		if (sharedInstance == null) {
			sharedInstance = new CommandHandler();
		}
		return sharedInstance;
	}

	private var commands:Map<String, Array<String>->Void> = new Map();
	private var defaultCommands:Map<String, Array<String>->Void> = new Map();
	private var inBuffer:String = "";
	public var sendNum:Int = -1;
	public var serverId:Int = 0;

	public function new() {
		sharedInstance = this;
		defaultCommands.set("message", message);
		defaultCommands.set("setRank", setRank);
		defaultCommands.set("setGroup", setGroup);
		defaultCommands.set("startGame", startGame);
		defaultCommands.set("resend", resend);
		defaultCommands.set("pmNotify", pmNotify);
		defaultCommands.set("becomeSpecialUser", becomeSpecialUser);
		defaultCommands.set("becomePrizer", becomePrizer);
		defaultCommands.set("demotePrizer", demotePrizer);
		defaultCommands.set("becomeTempMod", becomeTempMod);
		defaultCommands.set("becomeTrialMod", becomeTrialMod);
		defaultCommands.set("becomeFullMod", becomeFullMod);
		defaultCommands.set("demoteMod", demoteMod);
		defaultCommands.set("areYouHuman", areYouHuman);
		defaultCommands.set("tournamentMode", tournamentMode);
		defaultCommands.set("guildChange", guildChange);
		defaultCommands.set("setServerOwner", setServerOwner);
		defaultCommands.set("wearingHat", wearingHat);
	}

	/** Register (or, with `handler == null`, clear) the handler for a command. */
	public function defineCommand(name:String, handler:Null<Array<String>->Void>):Void {
		if (handler == null) {
			commands.remove(name);
		} else {
			commands.set(name, handler);
		}
	}

	public function hasCommand(name:String):Bool {
		return commands.exists(name) || defaultCommands.exists(name);
	}

	/** Invoke the handler for `name` with `args`. Returns true if one was registered. */
	public function dispatch(name:String, args:Array<String>):Bool {
		var handler = commands.get(name);
		if (handler == null) {
			handler = defaultCommands.get(name);
		}
		if (handler == null) {
			return false;
		}
		handler(args);
		return true;
	}

	/**
		Route a raw server frame. The gameserver layout is
		`hash`sendNum`command`arg1`arg2...`, so the command is the third segment
		and the arguments follow it.
	**/
	public function handleServerFrame(frame:String):Bool {
		var parts = frame.split("`");
		if (parts.length > 0 && parts[parts.length - 1] == "") {
			parts.pop();
		}
		if (parts.length < 3) {
			return false;
		}
		var num = Std.parseInt(parts[1]);
		if (num == null || num <= sendNum) {
			return false;
		}
		var command = parts[2];
		var args = parts.slice(3);
		if (parts[0] != hashFor(num, command, args, currentServerId())) {
			return false;
		}
		sendNum = num;
		return dispatch(command, args);
	}

	/** Append raw socket text and process every complete EOL-delimited frame. */
	public function addText(s:String):Int {
		inBuffer += s;
		var handled = 0;
		var endPos = inBuffer.indexOf(END_CHAR);
		while (endPos != -1) {
			var dataStr = inBuffer.substring(0, endPos);
			inBuffer = inBuffer.substr(endPos + 1);
			if (handleServerFrame(dataStr)) {
				handled++;
			}
			endPos = inBuffer.indexOf(END_CHAR);
		}
		return handled;
	}

	/** Test/teardown helper: drop all registered handlers. */
	public function clearAll():Void {
		commands = new Map();
	}

	public static function buildServerFrame(num:Int, command:String, args:Array<String>, serverId:Int = 0):String {
		return hashFor(num, command, args, serverId) + "`" + num + "`" + command + (args.length == 0 ? "`" : "`" + args.join("`"));
	}

	private static function hashFor(num:Int, command:String, args:Array<String>, serverId:Int):String {
		return Md5.encode(CommAuth.getToken(serverId) + num + "`" + command + "`" + args.join("`")).substr(0, 3);
	}

	private function currentServerId():Int {
		if (serverId != 0) {
			return serverId;
		}
		return LobbySession.server == null ? 0 : LobbySession.server.serverId;
	}

	private function message(args:Array<String>):Void {
		new MessagePopup(args.length > 0 ? args[0] : "");
	}

	private function setRank(args:Array<String>):Void {
		var rank = args.length > 0 ? Std.parseInt(args[0]) : null;
		SecureData.setNumber("userRank", rank == null ? 0 : rank);
	}

	private function setGroup(args:Array<String>):Void {
		LobbySession.group = intArg(args, 0);
	}

	private function startGame(args:Array<String>):Void {
		LevelLaunch.startGame(args);
	}

	private function resend(args:Array<String>):Void {
		if (LobbySocket.sendNum < intArg(args, 0)) {
			LobbySocket.close();
		}
	}

	private function pmNotify(args:Array<String>):Void {
		UnreadNotif.notifyUser(intArg(args, 0));
	}

	private function becomeSpecialUser(_:Array<String>):Void {
		LobbySession.isSpecialUser = true;
	}

	private function becomePrizer(_:Array<String>):Void {
		LobbySession.isPrizer = true;
	}

	private function demotePrizer(_:Array<String>):Void {
		LobbySession.isPrizer = false;
	}

	private function becomeTempMod(_:Array<String>):Void {
		LobbySession.group = 1;
		LobbySession.isTempMod = true;
		LobbySession.isTrialMod = false;
	}

	private function becomeTrialMod(_:Array<String>):Void {
		LobbySession.group = 2;
		LobbySession.isTempMod = false;
		LobbySession.isTrialMod = true;
	}

	private function becomeFullMod(_:Array<String>):Void {
		LobbySession.group = 2;
		LobbySession.isTempMod = false;
		LobbySession.isTrialMod = false;
	}

	private function demoteMod(_:Array<String>):Void {
		LobbySession.group = 1;
		LobbySession.isTempMod = false;
		LobbySession.isTrialMod = false;
	}

	private function areYouHuman(_:Array<String>):Void {
		new CatCaptcha();
	}

	private function tournamentMode(args:Array<String>):Void {
		LobbySession.tournamentMode = intArg(args, 0) != 0;
	}

	private function guildChange(args:Array<String>):Void {
		if (args.length == 0) {
			return;
		}
		var ret:Dynamic = haxe.Json.parse(args[0]);
		LobbySession.guildId = intField(ret, "guild_id");
		LobbySession.guildName = stringField(ret, "guild_name");
		LobbySession.guildOwner = boolField(ret, "is_owner");
		LobbySession.notifyAccountChange();
	}

	private function setServerOwner(args:Array<String>):Void {
		LobbySession.serverOwner = intArg(args, 0);
	}

	private function wearingHat(args:Array<String>):Void {
		AccountState.currentHat = intArg(args, 0);
		dispatch("testLevelAccess", []);
	}

	private static function intArg(args:Array<String>, index:Int):Int {
		var parsed = args.length > index ? Std.parseInt(args[index]) : null;
		return parsed == null ? 0 : parsed;
	}

	private static function intField(data:Dynamic, name:String):Int {
		var parsed = Std.parseInt(Std.string(Reflect.field(data, name)));
		return parsed == null ? 0 : parsed;
	}

	private static function stringField(data:Dynamic, name:String):String {
		var value = Reflect.field(data, name);
		return value == null ? "" : Std.string(value);
	}

	private static function boolField(data:Dynamic, name:String):Bool {
		var value = Reflect.field(data, name);
		if (Std.isOfType(value, Bool)) {
			return value;
		}
		var s = value == null ? "" : Std.string(value).toLowerCase();
		return s == "1" || s == "true";
	}
}
