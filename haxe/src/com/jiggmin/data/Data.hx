package com.jiggmin.data;

import haxe.crypto.Md5;
import openfl.display.DisplayObject;
import openfl.geom.Point;

typedef ExpBounds = {
	var lowExp:Float;
	var highExp:Float;
}

class Data {
	public static final RAD_DEG:Float = 180 / Math.PI;
	public static final DEG_RAD:Float = Math.PI / 180;

	private static final groupColors:Array<Array<String>> = [
		["676666"],
		["047B7B", "BC9055"],
		["006400", "0092FF", "1C369F"],
		["870A6F"]
	];
	private static final damnArray = ["dang", "dingy-goo", "condemnation"];
	private static final fuckArray = ["fooey", "fingilly", "funk-master", "freak monster", "jiminy cricket"];
	private static final shitArray = ["shoot", "shewet"];
	private static final niggaArray = ["someone cooler than me", "ladies magnet", "cooler race"];
	private static final bitchArray = ["cooler gender", "female dog"];
	private static final monthArray = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
	private static final randomChars = "0123456789_!@#$%&*()-=+/abcdfghjkmnpqrstvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_!@#$%&*()-=+/";

	public static function aOrAn(s:String):String {
		var ret = "a";
		if (s != null && s.length > 0) {
			var startsWith = s.charAt(0).toLowerCase();
			if (startsWith == "a" || startsWith == "e" || startsWith == "i" || startsWith == "o" || startsWith == "u") {
				ret = "an";
			}
		}
		return ret;
	}

	public static function ucfirst(s:String):String {
		return s.substr(0, 1).toUpperCase() + s.substr(1, s.length).toLowerCase();
	}

	public static function getMS():Float {
		return Date.now().getTime();
	}

	public static function getTimestamp():Float {
		return Math.round(getMS() / 1000);
	}

	public static function formatNumber(num:Float):String {
		var source = Std.string(num);
		var sign = "";
		if (StringTools.startsWith(source, "-")) {
			sign = "-";
			source = source.substr(1);
		}
		var suffix = "";
		var dot = source.indexOf(".");
		if (dot >= 0) {
			suffix = source.substr(dot);
			source = source.substr(0, dot);
		}
		var out = "";
		while (source.length > 3) {
			var group = source.substr(source.length - 3);
			source = source.substr(0, source.length - 3);
			out = "," + group + out;
		}
		if (source.length > 0) {
			out = source + out;
		}
		return sign + out + suffix;
	}

	public static function hash(s:String):String {
		return Md5.encode(s);
	}

	public static function getDateStr(t:Float):String {
		var date = Date.fromTime(t);
		return getMonthStr(date.getMonth()) + " " + date.getDate();
	}

	private static function getMonthStr(m:Int):String {
		return monthArray[m];
	}

	public static function getShortDateStr(t:Float):String {
		var date = Date.fromTime(t * 1000);
		return date.getDate() + "/" + getMonthStr(date.getMonth()) + "/" + date.getFullYear();
	}

	public static function getDateTimeStr(t:Float, ?customStyle:Array<String>):String {
		var date = Date.fromTime(t * 1000);
		var month = getMonthStr(date.getMonth());
		var hour = date.getHours();
		var minutes = padString(2, "0", Std.string(date.getMinutes()));
		return month + " " + date.getDate() + ", " + date.getFullYear() + " " + hour + ":" + minutes;
	}

	public static function getLocale():String {
		return "en-US";
	}

	public static function formatTime(timeInput:Float, mode:String = "seconds"):String {
		var mins = Math.floor(timeInput / 60);
		var secs = Math.floor(timeInput % 60);
		var deci = Math.round((timeInput % 1) * 100);
		var minsStr = padString(1, "0", Std.string(mins));
		var secsStr = padString(2, "0", Std.string(secs));
		var deciStr = padString(2, "0", Std.string(deci));
		var str = minsStr + ":" + secsStr;
		if (mode == "decimal") {
			str += "." + deciStr;
		}
		return str;
	}

	public static function padString(minPlaces:Float, paddingChar:String, str:String):String {
		while (str.length < minPlaces) {
			str = paddingChar + str;
		}
		return str;
	}

	public static function escapeAndFilterString(s:String):String {
		if (s != null) {
			s = trimWhitespace(s);
			s = cleanHTML(s);
			s = filterSwears(s);
		}
		return s;
	}

	public static function escapeString(s:String, preserveNewLine:Bool = false):String {
		s = trimWhitespace(s, preserveNewLine);
		return cleanHTML(s);
	}

	public static function cleanHTML(s:String):String {
		s = StringTools.replace(s, "&", "&amp;");
		s = StringTools.replace(s, ">", "&gt;");
		s = StringTools.replace(s, "<", "&lt;");
		s = StringTools.replace(s, "'", "&apos;");
		s = StringTools.replace(s, "\"", "&quot;");
		return s;
	}

	public static function trimWhitespace(s:String, keepNL:Bool = false):String {
		s = s == null ? "" : ~/^\s+|\s+$/g.replace(s, "");
		s = StringTools.replace(s, "\t", " ");
		s = StringTools.replace(s, String.fromCharCode(12), " ");
		if (!keepNL) {
			s = StringTools.replace(s, "\n", " ");
			s = StringTools.replace(s, "\r", " ");
		}
		return s;
	}

	public static function filterSwears(s:String):String {
		s = ~/damn/gi.replace(s, randArrayKey(damnArray));
		s = ~/fuck/gi.replace(s, randArrayKey(fuckArray));
		s = ~/\b(nig(?:g(?:a|er)?)?(?:s)?)\b/gi.replace(s, randArrayKey(niggaArray));
		s = ~/\b(spic)\b/gi.replace(s, randArrayKey(niggaArray));
		s = ~/shit/gi.replace(s, randArrayKey(shitArray));
		s = ~/bitch/gi.replace(s, randArrayKey(bitchArray));
		s = ~/cunt/gi.replace(s, randArrayKey(bitchArray));
		s = ~/whore/gi.replace(s, randArrayKey(bitchArray));
		return s;
	}

	public static function randArrayKey(a:Array<String>):String {
		return a[Math.floor(Math.random() * a.length)];
	}

	public static function rand(lowerLim:Int, higherLim:Int):Int {
		return lowerLim + Math.floor(Math.random() * (higherLim - lowerLim + 1));
	}

	public static function parseLinks(s:String):String {
		s = parseUser(s);
		s = parseURL(s);
		s = ~/(\[level=)(\d{1,8})(\])(.+)(\[\/level\])/gi.replace(s, "<a href='event:level`$2'><u><font color='#0000FF'>$4</font></u></a>");
		s = ~/(\[guild=)(\d{1,6})(\])(.+)(\[\/guild\])/gi.replace(s, "<a href='event:guild`$2'><u><font color='#0000FF'>$4</font></u></a>");
		s = ~/(\[guildlink=)(\d{1,6})(\])(.+)(\[\/guildlink\])/gi.replace(s, "<a href='event:guild`$2'><u><font color='#0000FF'>$4</font></u></a>");
		s = ~/(\[invite=)(\d+)(\])(.+)(\[\/invite\])/gi.replace(s, "<a href='event:invite`$2'><u><font color='#0000FF'>$4</font></u></a>");
		s = ~/(\[invitelink=)(\d+)(\])(.+)(\[\/invitelink\])/gi.replace(s, "<a href='event:invite`$2'><u><font color='#0000FF'>$4</font></u></a>");
		s = ~/(\[discordverif=)(.+)(\])(.+)(\[\/discordverif\])/gi.replace(s, "<a href='event:discordverify`$2'><u><font color='#0000FF'>$4</font></u></a>");
		s = ~/(\[color=)(#[0-9a-fA-F]{6})(\])(.+)(\[\/color\])/gi.replace(s, "<font color='$2'>$4</font>");
		s = ~/(\[b\])(.+)(\[\/b\])/gi.replace(s, "<b>$2</b>");
		s = ~/(\[bold\])(.+)(\[\/bold\])/gi.replace(s, "<b>$2</b>");
		s = ~/(\[i\])(.+)(\[\/i\])/gi.replace(s, "<i>$2</i>");
		s = ~/(\[em\])(.+)(\[\/em\])/gi.replace(s, "<i>$2</i>");
		s = ~/(\[u\])(.+)(\[\/u\])/gi.replace(s, "<u>$2</u>");
		s = ~/(\[tiny\])(.+)(\[\/tiny\])/gi.replace(s, "<font size='6'>$2</font>");
		s = ~/(\[small\])(.+)(\[\/small\])/gi.replace(s, "<font size='9'>$2</font>");
		s = ~/(\[medium\])(.+)(\[\/medium\])/gi.replace(s, "<font size='12'>$2</font>");
		s = ~/(\[large\])(.+)(\[\/large\])/gi.replace(s, "<font size='24'>$2</font>");
		s = ~/(\[big\])(.+)(\[\/big\])/gi.replace(s, "<font size='24'>$2</font>");
		return s;
	}

	private static function parseUser(s:String):String {
		var re = ~/\[user=(\d{1}(?:,((\d{1}){0,1}|\*))?)\]([a-zA-Z0-9-.:;=?~!()@*,+$#% ]+)\[\/user\]/gi;
		return re.map(s, function(r:EReg):String {
			var groupSpec = r.matched(1);
			var display = r.matched(4);
			return "<a href='event:user`" + groupSpec + "`" + display + "`1'><u><font color='" + userColor(groupSpec) + "'>" + display + "</font></u></a>";
		});
	}

	private static function userColor(groupSpec:String):String {
		var vars = groupSpec.split(",");
		if (vars.length > 1 && vars[1] == "*") {
			return "#83C141";
		}
		var group = clampInt(Std.parseInt(vars[0]), 0, groupColors.length - 1);
		var colors = groupColors[group];
		var power = vars.length > 1 ? clampInt(Std.parseInt(vars[1]), 0, colors.length - 1) : 0;
		return "#" + colors[power];
	}

	private static function parseURL(s:String):String {
		var re1 = ~/\[[uU][rR][lL]\](https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,4}\b(((?:&amp;)|[-a-zA-Z0-9@:%_\+.~#?&\/=])*))\[\/[uU][rR][lL]\]/g;
		s = re1.map(s, function(r:EReg):String {
			var link = StringTools.replace(r.matched(1), "&amp;", "&");
			return "<a href='event:url`" + link + "'><u><font color='#0000FF'>" + link + "</font></u></a>";
		});
		var re2 = ~/\[[uU][rR][lL]=(https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,4}\b(((?:&amp;)|[-a-zA-Z0-9@:%_\+.~#?&\/=])*))\](.+?)\[\/[uU][rR][lL]\]/g;
		return re2.replace(s, "<a href='event:url`$1'><u><font color='#0000FF'>$5</font></u></a>");
	}

	public static function urlify(link:String, disp:String, color:String = "#0000FF"):String {
		link = escapeString(link);
		disp = escapeString(disp);
		return '<a href="' + link + '" target="_blank"><u><font color="' + color + '">' + disp + "</font></u></a>";
	}

	public static function pythag(xDist:Float, yDist:Float):Float {
		return Math.sqrt(xDist * xDist + yDist * yDist);
	}

	public static function numLimit(value:Float, minimum:Float, maximum:Float):Float {
		if (value > maximum) {
			value = maximum;
		} else if (value < minimum) {
			value = minimum;
		}
		return value;
	}

	public static function scaleToFit(d:DisplayObject, maxWidth:Float, maxHeight:Float):Void {
		var widthScale = maxWidth / d.width;
		var heightScale = maxHeight / d.height;
		var scale = widthScale < heightScale ? widthScale : heightScale;
		if (scale < 1) {
			d.width *= scale;
			d.height *= scale;
		}
	}

	public static function rotatePoint(posX:Float, posY:Float, rot:Float):Point {
		var x = Std.int(posX);
		var y = Std.int(posY);
		if (rot > 180) {
			rot = -360 + rot;
		} else if (rot < -180) {
			rot = 360 + rot;
		}
		if (rot == 90) {
			x = Std.int(posY);
			y = Std.int(-posX);
		} else if (Math.abs(rot) == 180) {
			x = Std.int(-posX);
			y = Std.int(-posY);
		} else if (rot == -90) {
			x = Std.int(-posY);
			y = Std.int(posX);
		}
		return new Point(x, y);
	}

	public static function getExpBounds(exp:Int):ExpBounds {
		var upper:Float = 25;
		if (exp < upper) {
			return {lowExp: 0, highExp: upper};
		}
		while (upper < exp) {
			upper *= 1.25;
		}
		return {lowExp: upper * (1 / 1.25), highExp: upper};
	}

	public static function randomString(length:Int = 8):String {
		var out = "";
		for (_ in 0...length) {
			var index = Std.int(Math.floor(Math.random() * randomChars.length));
			out += randomChars.substr(index, 1);
		}
		return out;
	}

	private static function clampInt(value:Null<Int>, min:Int, max:Int):Int {
		var v = value == null ? 0 : value;
		if (v < min) return min;
		if (v > max) return max;
		return v;
	}
}
