package pr2.lobby.chat;

/**
	Port of the chat-relevant text helpers from Flash `com.jiggmin.data.Data`:
	HTML escaping, whitespace trimming, and the swear filter toggle. These run on
	every incoming chat line, so they are kept pure and deterministic for testing.
**/
class ChatText {
	private function new() {}

	public static function cleanHTML(s:String):String {
		s = StringTools.replace(s, "&", "&amp;");
		s = StringTools.replace(s, ">", "&gt;");
		s = StringTools.replace(s, "<", "&lt;");
		s = StringTools.replace(s, "'", "&apos;");
		s = StringTools.replace(s, "\"", "&quot;");
		return s;
	}

	public static function trimWhitespace(s:String, keepNL:Bool = false):String {
		if (s == null) {
			return "";
		}
		s = StringTools.trim(s);
		// Collapse the remaining control whitespace to spaces. With keepNL only
		// tabs/form-feeds are replaced; otherwise newlines/returns/vtabs too.
		var pattern = keepNL ? ~/[\t\x0C]/g : ~/[\t\n\r\x0B\x0C]/g;
		return pattern.replace(s, " ");
	}

	public static function escapeString(s:String, preserveNewLine:Bool = false):String {
		return cleanHTML(trimWhitespace(s, preserveNewLine));
	}

	public static function escapeAndFilterString(s:String):String {
		if (s == null) {
			return "";
		}
		return filterSwears(cleanHTML(trimWhitespace(s)));
	}

	// The original substitutes a random themed replacement per matched swear. The
	// random arrays aren't shipped here, so each match collapses to a fixed mask;
	// the matching set is preserved so filtered/unfiltered behavior stays distinct.
	public static function filterSwears(s:String):String {
		var masks = [
			~/damn/gi,
			~/fuck/gi,
			~/\b(nig(?:g(?:a|er)?)?(?:s)?)\b/gi,
			~/\b(spic)\b/gi,
			~/shit/gi,
			~/bitch/gi,
			~/cunt/gi,
			~/whore/gi,
		];
		for (re in masks) {
			s = re.replace(s, "[...]");
		}
		return s;
	}
}
