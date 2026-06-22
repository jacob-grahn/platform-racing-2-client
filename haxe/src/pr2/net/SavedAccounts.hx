package pr2.net;

typedef SavedAccount = {
	final name:String;
	final token:String;
}

/**
	Persistent remembered-login tokens, ported from Flash `SavedAccounts`.
	Passwords are never stored; the server-issued token is sent as the separate
	`token` form field used by Flash's authenticated `SuperLoader`.
**/
class SavedAccounts {
	private static inline var STORE_ID = "pr2hub_logged_in";
	private static var accounts:Array<SavedAccount> = [];
	private static var loaded:Bool = false;
	private static var persistenceEnabled:Bool = true;

	private function new() {}

	public static function getAll():Array<SavedAccount> {
		ensureLoaded();
		return accounts.copy();
	}

	public static function add(name:String, token:String):Void {
		ensureLoaded();
		name = StringTools.trim(name);
		if (name == "" || token == "") return;
		var index = find(name, false);
		if (index >= 0) accounts.splice(index, 1);
		accounts.unshift({name: name, token: token});
		persist();
	}

	public static function deleteAccount(value:String, byToken:Bool = false):Bool {
		ensureLoaded();
		var index = find(value, byToken);
		if (index < 0) return false;
		accounts.splice(index, 1);
		persist();
		return true;
	}

	public static function disablePersistenceForTests():Void {
		persistenceEnabled = false;
		accounts = [];
		loaded = true;
	}

	private static function find(value:String, byToken:Bool):Int {
		var normalized = StringTools.trim(value).toLowerCase();
		for (i in 0...accounts.length) {
			if (byToken ? accounts[i].token == value : accounts[i].name.toLowerCase() == normalized) return i;
		}
		return -1;
	}

	private static function ensureLoaded():Void {
		if (loaded) return;
		loaded = true;
		try {
			var store = openfl.net.SharedObject.getLocal(STORE_ID);
			var json:Dynamic = Reflect.field(store.data, "accounts");
			if (json == null) return;
			var parsed:Dynamic = haxe.Json.parse(Std.string(json));
			if (!Std.isOfType(parsed, Array)) return;
			for (entry in (cast parsed:Array<Dynamic>)) {
				var name = StringTools.trim(Std.string(Reflect.field(entry, "name")));
				var token = Std.string(Reflect.field(entry, "token"));
				if (name != "" && token != "null" && token != "") accounts.push({name: name, token: token});
			}
		} catch (_:Dynamic) {}
	}

	private static function persist():Void {
		if (!persistenceEnabled) return;
		try {
			var store = openfl.net.SharedObject.getLocal(STORE_ID);
			Reflect.setField(store.data, "accounts", haxe.Json.stringify(accounts));
			store.flush();
		} catch (_:Dynamic) {}
	}
}
