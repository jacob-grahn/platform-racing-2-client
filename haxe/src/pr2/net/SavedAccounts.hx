package pr2.net;

typedef SavedAccount = {
	var name:String;
	var token:String;
}

/**
	Persistent remembered-login tokens, ported from Flash `SavedAccounts`.
	Passwords are never stored; the server-issued token is sent as the separate
	`token` form field used by Flash's authenticated `SuperLoader`.
**/
class SavedAccounts {
	private static inline var PROD_STORE_ID = "pr2hub_logged_in";
	private static inline var DEV_STORE_ID = "pr2hub_dev_logged_in";
	private static var cookieId:String = PROD_STORE_ID;
	private static var accounts:Array<SavedAccount> = [];
	private static var loaded:Bool = false;
	private static var persistenceEnabled:Bool = true;
	private static var memoryStoresForTests:Null<Map<String, Dynamic>>;

	private function new() {}

	public static function init(?baseURL:String):Void {
		cookieId = storeIdForBaseUrl(baseURL);
		getCookie();
		loaded = true;
	}

	public static function getAll():Array<SavedAccount> {
		ensureLoaded();
		return accounts;
	}

	public static function getByName(name:String):Null<SavedAccount> {
		ensureLoaded();
		var index = getArrayPos(name);
		return index > -1 ? accounts[index] : null;
	}

	public static function add(name:String, token:String):Void {
		ensureLoaded();
		name = trim(name);
		if (name == "") return;
		if (getByName(name) != null) {
			updateToken(name, token);
			moveToTop(name);
			return;
		}
		accounts.unshift({name: name, token: token});
		persist();
	}

	public static function deleteAccount(value:String, mode:Dynamic = "name"):Bool {
		ensureLoaded();
		var index = getArrayPos(value, mode);
		if (index < 0) return false;
		accounts.splice(index, 1);
		persist();
		return true;
	}

	public static function disablePersistenceForTests():Void {
		persistenceEnabled = false;
		memoryStoresForTests = null;
		accounts = [];
		loaded = true;
	}

	public static function useMemoryStoreForTests(?baseURL:String):Void {
		persistenceEnabled = true;
		memoryStoresForTests = [];
		loaded = false;
		init(baseURL);
	}

	public static function setRawAccountsForTests(raw:Dynamic, ?baseURL:String):Void {
		persistenceEnabled = true;
		memoryStoresForTests = [];
		memoryStoresForTests.set(storeIdForBaseUrl(baseURL), raw);
		loaded = false;
		init(baseURL);
	}

	public static function rawAccountsForTests(?baseURL:String):Dynamic {
		if (memoryStoresForTests == null) return null;
		return memoryStoresForTests.get(storeIdForBaseUrl(baseURL));
	}

	public static function storeIdForTests(?baseURL:String):String {
		return storeIdForBaseUrl(baseURL);
	}

	private static function getArrayPos(value:String, mode:Dynamic = "name"):Int {
		var deleteByToken = mode == true || mode == "token";
		var normalized = trim(value).toLowerCase();
		for (i in 0...accounts.length) {
			if (deleteByToken ? accounts[i].token == value : accounts[i].name.toLowerCase() == normalized) return i;
		}
		return -1;
	}

	private static function ensureLoaded():Void {
		if (loaded) return;
		init();
	}

	private static function getCookie():Void {
		accounts = [];
		try {
			var raw = readRawAccounts();
			var parsed = normalizeRawAccounts(raw);
			if (parsed == null) return;
			for (entry in parsed) addLoadedAccount(entry);
		} catch (_:Dynamic) {}
	}

	private static function persist():Void {
		if (!persistenceEnabled) return;
		try {
			setCookie();
		} catch (_:Dynamic) {}
	}

	private static function setCookie():Void {
		writeRawAccounts([for (account in accounts) {name: account.name, token: account.token}]);
		getCookie();
	}

	private static function updateToken(name:String, token:String):Bool {
		var index = getArrayPos(name);
		if (index == -1) return false;
		accounts[index].token = token;
		persist();
		return true;
	}

	private static function moveToTop(name:String):Bool {
		var index = getArrayPos(name);
		if (index <= -1) return false;
		accounts.unshift(accounts.splice(index, 1)[0]);
		persist();
		return true;
	}

	private static function readRawAccounts():Dynamic {
		if (memoryStoresForTests != null) return memoryStoresForTests.get(cookieId);
		var store = openfl.net.SharedObject.getLocal(cookieId);
		return Reflect.field(store.data, "accounts");
	}

	private static function writeRawAccounts(raw:Array<Dynamic>):Void {
		if (memoryStoresForTests != null) {
			memoryStoresForTests.set(cookieId, raw);
			return;
		}
		var store = openfl.net.SharedObject.getLocal(cookieId);
		Reflect.setField(store.data, "accounts", raw);
		store.flush();
	}

	private static function normalizeRawAccounts(raw:Dynamic):Null<Array<Dynamic>> {
		if (raw == null) return null;
		if (Std.isOfType(raw, Array)) return cast raw;
		try {
			var parsed:Dynamic = haxe.Json.parse(Std.string(raw));
			return Std.isOfType(parsed, Array) ? cast parsed : null;
		} catch (_:Dynamic) {
			return null;
		}
	}

	private static function addLoadedAccount(entry:Dynamic):Void {
		var name = trim(Reflect.field(entry, "name"));
		if (name == "") return;
		var token:Dynamic = Reflect.field(entry, "token");
		accounts.push({name: name, token: token});
	}

	private static function storeIdForBaseUrl(?baseURL:String):String {
		var source = baseURL == null ? ServerConfig.getHost() : baseURL;
		return StringTools.endsWith(trim(source), "dev") ? DEV_STORE_ID : PROD_STORE_ID;
	}

	private static function trim(value:Dynamic):String {
		return value == null ? "" : StringTools.trim(Std.string(value));
	}
}
