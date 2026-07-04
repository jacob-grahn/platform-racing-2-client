package pr2.net;

/**
	Socket command hash token lookup from Flash `menu.CommAuth`.
**/
class CommAuth {
	private static inline var COMM_PASS:String = "QHE0NSNwKWZZQVEhU19xMA==";
	private static inline var COMM_PASS_SERVER_10:String = "ayo3JnBGQCZVRiEhVjFAQA==";

	public static function getToken(serverId:Int):String {
		return serverId == 10 ? COMM_PASS_SERVER_10 : COMM_PASS;
	}

	private function new() {}
}
