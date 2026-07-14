package pr2.ui;

import openfl.display.Sprite;
import openfl.events.MouseEvent;

class GuildNameTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var savedFactory = GuildName.popupFactory;
		testTextWidthEmblemAndCursor();
		if (pr2.DeterministicTestMode.finishSmokeSuite("GuildNameTest")) return;
		testClickRoutingAndCleanup();
		GuildName.popupFactory = savedFactory;
		trace('GuildNameTest passed $assertions assertions');
	}

	private static function testTextWidthEmblemAndCursor():Void {
		var guild = new GuildName(9, "R&D <Guild>", "emblem.png", true, true);
		assertEquals(true, guild.useHandCursor, "guild name uses hand cursor");
		assertEquals(true, guild.buttonMode, "guild name uses button mode");
		assertEquals(false, guild.mouseChildren, "guild name disables mouse children");
		assertEquals(145.0, guild.nameWidthForTests(), "wide guild name width");
		assertEquals(true, guild.nameHtmlForTests().indexOf("<b>") != -1, "bold guild name uses html text");
		assertEquals(true, guild.nameHtmlForTests().indexOf("&lt;Guild&gt;") != -1, "bold guild name escapes html");
		assertNotNull(guild.emblemForTests(), "guild name creates emblem surface");
		assertEquals("emblem.png", guild.emblemForTests().getFileName(), "guild name loads emblem filename");

		guild.makeWidth(120);
		assertEquals(120.0, guild.nameWidthForTests(), "makeWidth updates authored name field");
		guild.remove();
	}

	private static function testClickRoutingAndCleanup():Void {
		var opened:Array<Int> = [];
		GuildName.popupFactory = function(id:Int):Void opened.push(id);
		var holder = new Sprite();
		var guild = new GuildName(42, "Speed", "", false, false);
		holder.addChild(guild);
		assertEquals(110.0, guild.nameWidthForTests(), "default guild name width");
		guild.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, opened.length, "guild click opens popup once");
		assertEquals(42, opened[0], "guild click routes guild id");

		guild.remove();
		guild.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, opened.length, "removed guild name detaches click listener");
		assertEquals(true, guild.isRemoved(), "guild name remove is idempotent removable cleanup");
		assertEquals(false, holder.contains(guild), "guild name removed from parent");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw message;
	}
}
