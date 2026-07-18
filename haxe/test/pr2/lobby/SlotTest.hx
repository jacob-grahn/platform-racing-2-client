package pr2.lobby;

import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.level.Slot;
import pr2.lobby.level.SlotView.SlotBackground;
import pr2.util.TestDisplayUtil as DisplayUtil;

class SlotTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var slot = new Slot(2, null);
		var background = Std.downcast(DisplayUtil.findByName(slot, "bg"), SlotBackground);
		var rank = Std.downcast(DisplayUtil.findByName(slot, "rankBox"), TextField);
		var name = Std.downcast(DisplayUtil.findByName(slot, "nameBox"), TextField);
		assertNotNull(background, "slot owns authored background state clip");
		assertEquals("emptyUp", background.currentState, "slot starts on authored emptyUp frame");
		assertNear(1, background.y, "background keeps XFL Y");
		assertNear(3, rank.x, "rank field keeps XFL X");
		assertNear(14, rank.width, "rank field keeps XFL width");
		if (pr2.DeterministicTestMode.finishSmokeSuite("SlotTest")) return;
		assertNear(21, name.x, "name field keeps XFL X");
		assertNear(76, name.width, "name field keeps XFL width");
		assertNear(1.00311279296875, name.scaleY, "name field keeps XFL vertical scale");

		slot.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals("emptyOver", background.currentState, "empty hover uses authored emptyOver frame");
		slot.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals("emptyUp", background.currentState, "mouse-out restores authored emptyUp frame");
		slot.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals("pending", background.currentState, "empty click uses authored pending frame");

		slot.fillSlot("Runner", 12.9, "other");
		assertEquals("Runner", name.text, "server fill populates player name");
		assertEquals("12", rank.text, "server fill truncates rank like AS3 int conversion");
		assertEquals("filledUp", background.currentState, "server fill uses authored filledUp frame");
		slot.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals("filledOver", background.currentState, "filled hover uses authored filledOver frame");
		slot.confirmSlot();
		assertEquals("confirmedUp", background.currentState, "server confirmation uses authored confirmedUp frame");
		slot.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals("confirmedOver", background.currentState, "confirmed hover uses authored confirmedOver frame");
		slot.clearSlot();
		assertEquals("", name.text, "server clear empties player name");
		assertEquals("", rank.text, "server clear empties rank");
		assertEquals("emptyUp", background.currentState, "server clear restores authored emptyUp frame");
		slot.remove();
		trace('SlotTest passed $assertions assertions');
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
