package pr2.data;

import com.jiggmin.data.Data;
import openfl.display.Sprite;

class DataCompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testStringAndNumberHelpers();
		if (pr2.DeterministicTestMode.finishSmokeSuite("DataCompatTest")) return;
		testParseLinks();
		testGeometryAndRandomHelpers();
		trace('DataCompatTest passed $assertions assertions');
	}

	private static function testStringAndNumberHelpers():Void {
		assertEquals("an", Data.aOrAn("Apple"), "aOrAn vowel");
		assertEquals("a", Data.aOrAn("Top Hat"), "aOrAn consonant");
		assertEquals("Hello", Data.ucfirst("hELLO"), "ucfirst");
		assertEquals("1,234,567", Data.formatNumber(1234567), "formatNumber groups thousands");
		assertEquals("900150983cd24fb0d6963f7d28e17f72", Data.hash("abc"), "hash MD5");
		assertEquals("1:05", Data.formatTime(65), "formatTime seconds");
		assertEquals("1:05.35", Data.formatTime(65.347, "decimal"), "formatTime decimal");
		assertEquals("007", Data.padString(3, "0", "7"), "padString");
		assertEquals("&lt;&amp;&quot;&apos;&gt;", Data.cleanHTML("<&\"'>"), "cleanHTML");
		assertEquals("hello world", Data.trimWhitespace("\n hello\tworld \r"), "trimWhitespace");
		var filtered = Data.filterSwears("damn");
		assertEquals(false, filtered.toLowerCase().indexOf("damn") >= 0, "filterSwears replaces swear");
		assertEquals('<a href="event:click" target="_blank"><u><font color="#FF0000">Click</font></u></a>', Data.urlify("event:click", "Click", "#FF0000"), "urlify");
	}

	private static function testParseLinks():Void {
		assertEquals(
			"<a href='event:user`2,1`Bob`1'><u><font color='#0092FF'>Bob</font></u></a>",
			Data.parseLinks("[user=2,1]Bob[/user]"),
			"user link group color"
		);
		assertEquals(
			"<a href='event:user`1,*`Jiggmin`1'><u><font color='#83C141'>Jiggmin</font></u></a>",
			Data.parseLinks("[user=1,*]Jiggmin[/user]"),
			"user special color"
		);
		assertEquals(
			"<a href='event:url`https://example.com/a?x=1&y=2'><u><font color='#0000FF'>https://example.com/a?x=1&y=2</font></u></a>",
			Data.parseLinks("[url]https://example.com/a?x=1&amp;y=2[/url]"),
			"url link unescapes ampersands"
		);
		assertEquals("<a href='event:level`123'><u><font color='#0000FF'>Newbieland</font></u></a>", Data.parseLinks("[level=123]Newbieland[/level]"), "level link");
		assertEquals("<a href='event:guild`45'><u><font color='#0000FF'>Guild</font></u></a>", Data.parseLinks("[guild=45]Guild[/guild]"), "guild link");
		assertEquals("<a href='event:invite`45'><u><font color='#0000FF'>Join</font></u></a>", Data.parseLinks("[invite=45]Join[/invite]"), "invite link");
		assertEquals("<a href='event:discordverify`abc'><u><font color='#0000FF'>Verify</font></u></a>", Data.parseLinks("[discordverif=abc]Verify[/discordverif]"), "discord link");
		assertEquals("<font color='#ABCDEF'>Color</font>", Data.parseLinks("[color=#ABCDEF]Color[/color]"), "color tag");
		assertEquals("<b>Bold</b>", Data.parseLinks("[b]Bold[/b]"), "bold tag");
		assertEquals("<i>Italic</i>", Data.parseLinks("[i]Italic[/i]"), "italic tag");
		assertEquals("<u>Under</u>", Data.parseLinks("[u]Under[/u]"), "underline tag");
		assertEquals("<font size='24'>Big</font>", Data.parseLinks("[big]Big[/big]"), "size tag");
	}

	private static function testGeometryAndRandomHelpers():Void {
		assertClose(5, Data.pythag(3, 4), "pythag");
		assertClose(10, Data.numLimit(15, 0, 10), "numLimit high");
		assertClose(0, Data.numLimit(-5, 0, 10), "numLimit low");
		var sprite = new Sprite();
		sprite.graphics.beginFill(0);
		sprite.graphics.drawRect(0, 0, 200, 100);
		sprite.graphics.endFill();
		Data.scaleToFit(sprite, 100, 100);
		assertClose(100, sprite.width, "scaleToFit width");
		assertClose(50, sprite.height, "scaleToFit height");
		var point = Data.rotatePoint(2.8, 3.2, 90);
		assertClose(3, point.x, "rotatePoint x");
		assertClose(-2, point.y, "rotatePoint y");
		var bounds = Data.getExpBounds(30);
		assertClose(25, bounds.lowExp, "exp bounds low");
		assertClose(31.25, bounds.highExp, "exp bounds high");
		var random = Data.randomString(12);
		assertEquals(12, random.length, "randomString length");
		assertEquals(true, ~/^[0123456789_!@#$%&*()\-=\+\/abcdfghjkmnpqrstvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ]+$/.match(random), "randomString charset");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.001) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
