package pr2.app;

import StringTools;

/**
	Which screen the client boots into. The Flash client always started at the
	intro; here a `?screen=` flag can jump straight to any screen to make
	development and automated harness testing easier.
**/
enum abstract Screen(String) from String to String {
	var Intro = "intro";
	var Login = "login";
	var Harness = "harness";
	var Campaign = "campaign";

	public static function fromQuery(query:Null<String>):Screen {
		var value = QueryParams.get(query, "screen");
		var normalized = value == null ? "" : StringTools.trim(value).toLowerCase();
		return switch (normalized) {
			case "harness": Harness;
			case "campaign": Campaign;
			case "login": Login;
			default: Intro;
		}
	}
}
