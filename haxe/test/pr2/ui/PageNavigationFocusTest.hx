package pr2.ui;

import openfl.events.TextEvent;
import openfl.text.TextField;
import pr2.ui.PageNavigation.Paginated;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class PageNavigationFocusTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testLinkClickResetsFocus();
		StageFocus.resetHooks();
		trace('PageNavigationFocusTest passed $assertions assertions');
	}

	private static function testLinkClickResetsFocus():Void {
		var target = new Target();
		var focusResets = 0;
		StageFocus.resetHook = function():Void focusResets++;
		var nav = new PageNavigation(target, "full", 2, 3, 200);
		var next = Std.downcast(nav.getChildAt(nav.numChildren - 1), PR2MovieClip);
		var text = Std.downcast(DisplayUtil.findByName(next, "textBox"), TextField);
		assertNotNull(text, "next link text exists");
		text.dispatchEvent(new TextEvent(TextEvent.LINK, false, false, "3"));
		assertEquals(3, target.page, "link click changes page");
		assertEquals(1, focusResets, "link click resets stage focus");
		nav.remove();
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

private class Target implements Paginated {
	public var page:Int = 0;

	public function new() {}

	public function setPageNum(i:Int):Void {
		page = i;
	}
}
