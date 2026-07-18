package pr2.lobby;

import openfl.display.DisplayObjectContainer;
import openfl.text.TextField;
import pr2.lobby.tabs.AccountInfoView;
import pr2.util.TestDisplayUtil as DisplayUtil;

class AccountInfoViewTest {
	private static var assertions = 0;

	public static function main():Void {
		var view = new AccountInfoView();
		assertObject(view, "nameBox", 2, 0);
		if (pr2.DeterministicTestMode.finishSmokeSuite("AccountInfoViewTest")) return;
		assertField(view, "nameBox", 156.05, 14.55);
		assertObject(view, "rankBox", 2, 18);
		assertField(view, "rankBox", 176.05, 14.55);
		assertObject(view, "hatBox", 2, 36);
		assertField(view, "hatBox", 176.05, 14.55);
		assertObject(view, "guildBox", 2, 54);
		assertField(view, "guildBox", 176.05, 14.55);
		assertObject(view, "rankTokenUp_bt", 66, 18);
		assertObject(view, "rankTokenDown_bt", 101, 18);
		assertObject(view, "loadouts_bt", 169, 2);
		var rankUp = Std.downcast(DisplayUtil.findByName(view, "rankTokenUp_bt"), DisplayObjectContainer);
		assertEquals("textBox", rankUp.getChildByName("textBox").name, "rank token retains authored textBox child");
		var loadouts = Std.downcast(DisplayUtil.findByName(view, "loadouts_bt"), DisplayObjectContainer);
		assertEquals("", Std.downcast(loadouts.getChildAt(0), TextField).text, "loadouts retains authored FontAwesome save glyph");
		trace('AccountInfoViewTest passed $assertions assertions');
	}

	private static function assertObject(view:AccountInfoView, name:String, x:Float, y:Float):Void {
		var object = DisplayUtil.findByName(view, name);
		assertEquals(x, object.x, '$name X');
		assertEquals(y, object.y, '$name Y');
	}

	private static function assertField(view:AccountInfoView, name:String, width:Float, height:Float):Void {
		var field = Std.downcast(DisplayUtil.findByName(view, name), TextField);
		assertEquals(width, field.width, '$name width');
		assertEquals(height, field.height, '$name height');
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
