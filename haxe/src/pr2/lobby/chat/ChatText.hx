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

	public static function parseLinks(s:String):String {
		s = parseUser(s);
		s = parseUrl(s);
		s = ~/\[level=(\d{1,8})\](.+)\[\/level\]/gi.replace(s,
			"<a href='event:level`$1'><u><font color='#0000FF'>$2</font></u></a>");
		s = ~/\[guild=(\d{1,6})\](.+)\[\/guild\]/gi.replace(s,
			"<a href='event:guild`$1'><u><font color='#0000FF'>$2</font></u></a>");
		s = ~/\[guildlink=(\d{1,6})\](.+)\[\/guildlink\]/gi.replace(s,
			"<a href='event:guild`$1'><u><font color='#0000FF'>$2</font></u></a>");
		s = ~/\[invite=(\d+)\](.+)\[\/invite\]/gi.replace(s,
			"<a href='event:invite`$1'><u><font color='#0000FF'>$2</font></u></a>");
		s = ~/\[invitelink=(\d+)\](.+)\[\/invitelink\]/gi.replace(s,
			"<a href='event:invite`$1'><u><font color='#0000FF'>$2</font></u></a>");
		s = ~/\[discordverif=(.+)\](.+)\[\/discordverif\]/gi.replace(s,
			"<a href='event:discordverify`$1'><u><font color='#0000FF'>$2</font></u></a>");
		s = ~/\[color=(#[0-9a-fA-F]{6})\](.+)\[\/color\]/gi.replace(s, "<font color='$1'>$2</font>");
		s = ~/\[b\](.+)\[\/b\]/gi.replace(s, "<b>$1</b>");
		s = ~/\[bold\](.+)\[\/bold\]/gi.replace(s, "<b>$1</b>");
		s = ~/\[i\](.+)\[\/i\]/gi.replace(s, "<i>$1</i>");
		s = ~/\[em\](.+)\[\/em\]/gi.replace(s, "<i>$1</i>");
		s = ~/\[u\](.+)\[\/u\]/gi.replace(s, "<u>$1</u>");
		s = ~/\[tiny\](.+)\[\/tiny\]/gi.replace(s, "<font size='6'>$1</font>");
		s = ~/\[small\](.+)\[\/small\]/gi.replace(s, "<font size='9'>$1</font>");
		s = ~/\[medium\](.+)\[\/medium\]/gi.replace(s, "<font size='12'>$1</font>");
		s = ~/\[large\](.+)\[\/large\]/gi.replace(s, "<font size='24'>$1</font>");
		s = ~/\[big\](.+)\[\/big\]/gi.replace(s, "<font size='24'>$1</font>");
		return s;
	}

	private static function parseUser(s:String):String {
		var re = ~/\[user=(\d(?:,(\d|\*))?)\]([a-zA-Z0-9\-.:;=?~!()@*,+$#% ]+)\[\/user\]/gi;
		return re.map(s, function(r:EReg):String {
			var group = r.matched(1);
			var name = r.matched(3);
			return "<a href='event:user`" + group + "`" + name + "`1'><u><font color='#" + HtmlNameMaker.groupColor(group) + "'>" + name
				+ "</font></u></a>";
		});
	}

	private static function parseUrl(s:String):String {
		var bare = ~/\[url\](https?:\/\/(www\.)?[-a-zA-Z0-9@:%._+~#=]{2,256}\.[a-z]{2,4}\b(((?:&amp;)|[-a-zA-Z0-9@:%_+.~#?&\/=])*))\[\/url\]/g;
		s = bare.map(s, function(r:EReg):String {
			var url = StringTools.replace(r.matched(1), "&amp;", "&");
			return "<a href='event:url`" + url + "'><u><font color='#0000FF'>" + url + "</font></u></a>";
		});
		var named = ~/\[url=(https?:\/\/(www\.)?[-a-zA-Z0-9@:%._+~#=]{2,256}\.[a-z]{2,4}\b(((?:&amp;)|[-a-zA-Z0-9@:%_+.~#?&\/=])*))\](.+?)\[\/url\]/g;
		return named.map(s, function(r:EReg):String {
			return "<a href='event:url`" + StringTools.replace(r.matched(1), "&amp;", "&") + "'><u><font color='#0000FF'>" + r.matched(5)
				+ "</font></u></a>";
		});
	}
}
