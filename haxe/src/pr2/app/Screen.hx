package pr2.app;

import StringTools;

/**
	Which screen the client boots into. The Flash client always started at the
	intro; here a `?screen=` flag can jump straight to supported screens to make
	development and automated harness testing easier. The `campaign` screen is
	debug-only now that the real `GamePage` owns level entry.
**/
enum abstract Screen(String) from String to String {
	var Intro = "intro";
	var Login = "login";
	var Lobby = "lobby";
	var Campaign = "campaign";
	var Symbol = "symbol";
	var CustomizeCharacter = "customize_character";
	var PopupPreview = "popup";

	public static function fromQuery(query:Null<String>):Screen {
		var value = QueryParams.get(query, "screen");
		var normalized = value == null ? "" : StringTools.trim(value).toLowerCase();
		return switch (normalized) {
			case "campaign" if (allowsCampaignHarness(query)): Campaign;
			case "login": Login;
			case "lobby": Lobby;
			case "symbol": Symbol;
			case "customize_character": CustomizeCharacter;
			case "popup": PopupPreview;
			default: Intro;
		}
	}

	public static function allowsCampaignHarness(query:Null<String>):Bool {
		var debug = QueryParams.get(query, "debug");
		if (debug == null) {
			return false;
		}
		var normalized = StringTools.trim(debug).toLowerCase();
		return normalized == "1" || normalized == "true" || normalized == "campaign";
	}
}
