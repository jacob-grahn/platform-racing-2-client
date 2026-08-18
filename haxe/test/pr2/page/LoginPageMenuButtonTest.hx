package pr2.page;

import openfl.text.TextField;

class LoginPageMenuButtonTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var button = new LoginPageMenuButton("Log In", function():Void {});
		var highlight = Std.downcast(button.getChildAt(0), TextField);
		var foreground = Std.downcast(button.getChildAt(1), TextField);

		assertEquals(0xFFFFFF, highlight.textColor, "login menu highlight uses the authored white");
		assertEquals(0x000000, foreground.textColor, "login menu foreground uses the authored black");
		assertEquals(0.75, button.alpha, "login menu button uses the authored idle alpha");

		button.remove();
		trace('LoginPageMenuButtonTest passed $assertions assertions');
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
