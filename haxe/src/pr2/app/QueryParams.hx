package pr2.app;

import StringTools;

/**
	Small helper for reading the browser query string used by screen routing to
	decode `?key=value&...` flags.
**/
class QueryParams {
	public static function parse(query:Null<String>):Map<String, String> {
		var values:Map<String, String> = new Map();
		if (query == null) {
			return values;
		}

		var trimmed = StringTools.trim(query);
		if (trimmed == "") {
			return values;
		}
		if (StringTools.startsWith(trimmed, "?")) {
			trimmed = trimmed.substr(1);
		}

		for (part in trimmed.split("&")) {
			if (part == "") {
				continue;
			}
			var equals = part.indexOf("=");
			var rawKey = equals < 0 ? part : part.substr(0, equals);
			var rawValue = equals < 0 ? "" : part.substr(equals + 1);
			values.set(StringTools.urlDecode(rawKey).toLowerCase(), StringTools.urlDecode(rawValue));
		}
		return values;
	}

	public static function get(query:Null<String>, key:String):Null<String> {
		return parse(query).get(key.toLowerCase());
	}

	private function new() {}
}
