package pr2.lobby;

import openfl.display.DisplayObject;
import openfl.text.TextField;
import pr2.lobby.dialogs.GuildMemberName;
import pr2.util.TestDisplayUtil as DisplayUtil;

class GuildMemberNameTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var member = {name: "Guild Owner", group: "2,1", gp_today: 1234, gp_total: 567890};
		var regular = new GuildMemberName(member, false);
		var regularName = text(regular, "nameBox");
		assertNear(2, regularName.x, "regular name keeps XFL X");
		assertNear(111.95, regularName.width, "regular name keeps XFL width");
		assertEquals("1,234", text(regular, "gpTodayBox").text, "today GP uses Flash number formatting");
		assertEquals("567,890", text(regular, "gpTotalBox").text, "total GP uses Flash number formatting");
		assertEquals(null, DisplayUtil.findByName(regular, "hat"), "non-owner keeps authored hat instance hidden");
		if (pr2.DeterministicTestMode.finishSmokeSuite("GuildMemberNameTest")) return;

		var owner = new GuildMemberName(member, true);
		var ownerName = text(owner, "nameBox");
		assertNear(16, ownerName.x, "owner name shifts by the AS3-authored 14 pixels");
		assertNear(97.95, ownerName.width, "owner name shrinks by the AS3-authored 14 pixels");
		var hat = required(owner, "hat");
		assertNear(0.117431640625, hat.transform.matrix.a, "owner crown keeps XFL matrix a");
		assertNear(0.0137786865234375, hat.transform.matrix.b, "owner crown keeps XFL matrix b");
		assertNear(-0.0137786865234375, hat.transform.matrix.c, "owner crown keeps XFL matrix c");
		assertNear(0.117431640625, hat.transform.matrix.d, "owner crown keeps XFL matrix d");
		assertNear(6, hat.transform.matrix.tx, "owner crown keeps XFL X");
		assertNear(15, hat.transform.matrix.ty, "owner crown keeps XFL Y");
		assertNotNull(DisplayUtil.findByName(owner, "fixed"), "owner crown uses source-derived fixed art");
		assertNotNull(DisplayUtil.findByName(owner, "colorMC"), "owner crown uses source-derived primary art");
		assertNotNull(DisplayUtil.findByName(owner, "colorMC2"), "owner crown uses source-derived secondary art");
		owner.remove();
		assertEquals(null, owner.parent, "remove detaches owner row");
		regular.remove();
		trace('GuildMemberNameTest passed $assertions assertions');
	}

	private static function text(row:GuildMemberName, name:String):TextField {
		var field = Std.downcast(DisplayUtil.findByName(row, name), TextField);
		if (field == null) throw '$name missing';
		return field;
	}

	private static function required(row:GuildMemberName, name:String):DisplayObject {
		var value = DisplayUtil.findByName(row, name);
		if (value == null) throw '$name missing';
		return value;
	}

	private static function assertNear(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw message;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
