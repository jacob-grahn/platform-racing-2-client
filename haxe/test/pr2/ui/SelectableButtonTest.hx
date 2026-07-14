package pr2.ui;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import pr2.runtime.PR2MovieClip;

class SelectableButtonTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testHoverAndSelectedFrameState();
		if (pr2.DeterministicTestMode.finishSmokeSuite("SelectableButtonTest")) return;
		trace('SelectableButtonTest passed $assertions assertions');
	}

	private static function testHoverAndSelectedFrameState():Void {
		var holder = new Sprite();
		var art = PR2MovieClip.fromLinkage("GetLevelsPopupItemGraphic", {maxNestedDepth: 4});
		var button = new SelectableButton(art);
		holder.addChild(button);
		button.addChild(art);
		assertEquals("up", button.currentSelectableFrameForTests(), "button starts up");
		assertEquals(false, button.getSelected(), "button starts unselected");

		button.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals("over", button.currentSelectableFrameForTests(), "hover switches to over");
		button.setSelected(true);
		assertEquals(true, button.getSelected(), "selected state stored");
		assertEquals("selected", button.currentSelectableFrameForTests(), "selected overrides hover");
		button.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals("selected", button.currentSelectableFrameForTests(), "hover out preserves selected frame");
		button.setSelected(false);
		assertEquals("up", button.currentSelectableFrameForTests(), "unselected non-hover returns up");

		button.remove();
		button.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals("up", button.currentSelectableFrameForTests(), "removed button ignores hover");
		assertEquals(false, holder.contains(button), "remove detaches button from parent");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
