package pr2.net;

/**
	Port of the Flash `com.jiggmin.data.CommandHandler` socket-command dispatcher.

	The gameserver pushes backtick-delimited frames. Pages register named handlers
	via `defineCommand` while they are on screen and clear them (pass `null`) on
	removal, exactly as the AS3 pages did. `LobbySocket` extracts the command name
	and arguments from each incoming frame and routes them here.
**/
class CommandHandler {
	public static var commandHandler(get, never):CommandHandler;
	private static var sharedInstance:Null<CommandHandler>;

	private static function get_commandHandler():CommandHandler {
		if (sharedInstance == null) {
			sharedInstance = new CommandHandler();
		}
		return sharedInstance;
	}

	private var commands:Map<String, Array<String>->Void> = new Map();

	public function new() {}

	/** Register (or, with `handler == null`, clear) the handler for a command. */
	public function defineCommand(name:String, handler:Null<Array<String>->Void>):Void {
		if (handler == null) {
			commands.remove(name);
		} else {
			commands.set(name, handler);
		}
	}

	public function hasCommand(name:String):Bool {
		return commands.exists(name);
	}

	/** Invoke the handler for `name` with `args`. Returns true if one was registered. */
	public function dispatch(name:String, args:Array<String>):Bool {
		var handler = commands.get(name);
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
		return dispatch(parts[2], parts.slice(3));
	}

	/** Test/teardown helper: drop all registered handlers. */
	public function clearAll():Void {
		commands = new Map();
	}
}
