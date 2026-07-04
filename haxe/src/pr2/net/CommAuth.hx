package pr2.net;

import com.jiggmin.data.SecureStore;

/**
	Socket command hash token lookup from Flash `menu.CommAuth`.
**/
class CommAuth {
	private static inline var COMM_PASS:String = "QHE0NSNwKWZZQVEhU19xMA==";
	private static inline var COMM_PASS_SERVER_10:String = "ayo3JnBGQCZVRiEhVjFAQA==";
	private static inline var DEFAULT_KEY:String = "1";
	private static inline var SERVER_10_KEY:String = "10";

	private static var hashing:SecureStore = new SecureStore();
	private static var initialized:Bool = false;

	public static function init():Void {
		hashing = new SecureStore();
		hashing.initEncryptor(DEFAULT_KEY, COMM_PASS);
		hashing.initEncryptor(SERVER_10_KEY, COMM_PASS_SERVER_10);
		initialized = true;
	}

	public static function getToken(serverId:Int):String {
		ensureInitialized();
		return hashing.getString(serverId == 10 ? SERVER_10_KEY : DEFAULT_KEY);
	}

	public static function resetForTests():Void {
		hashing = new SecureStore();
		initialized = false;
	}

	public static function tokenEntryForTests(key:String):Dynamic {
		return hashing.entryForTests(key);
	}

	private static function ensureInitialized():Void {
		if (!initialized) {
			init();
		}
	}

	private function new() {}
}
