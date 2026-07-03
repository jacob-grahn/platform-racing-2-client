package pr2.app;

class KongAward {
	public static var nextLogin:Bool = false;

	public static function consumeNextLogin():Bool {
		var value = nextLogin;
		nextLogin = false;
		return value;
	}

	private function new() {}
}
