package pr2.lobby;

import openfl.events.MouseEvent;
import pr2.lobby.level.CourseMenu;
import pr2.lobby.level.CourseMenuView;
import pr2.lobby.level.Slot;
import pr2.net.LobbySocket;

class CourseMenuTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var slot = new Slot(0, null);
		var menu = new CourseMenu(slot);
		var view = findView(menu);
		assertNear(0.514739990234375, view.panel.scaleX, "ShadowBG keeps XFL horizontal scale");
		assertNear(0.308868408203125, view.panel.scaleY, "ShadowBG keeps XFL vertical scale");
		assertNear(33.6, view.countdown.x, "countdown keeps XFL X");
		assertNear(39.05, view.countdown.y, "countdown keeps XFL Y");
		assertEquals("--", view.countdown.text, "countdown starts with authored wait copy");
		if (pr2.DeterministicTestMode.finishSmokeSuite("CourseMenuTest")) return;
		assertNear(6, view.cancelButton.x, "Cancel keeps XFL X");
		assertNear(6, view.cancelButton.y, "Cancel keeps XFL Y");
		assertNear(72.9, view.playButton.x, "Play keeps XFL X");
		assertNear(6, view.playButton.y, "Play keeps XFL Y");
		assertNear(60.0021362304688, view.playButton.width, "buttons keep XFL horizontal scale");

		view.playButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		@:privateAccess assertEquals(true, menu.confirmed, "Play enters the server-confirmation wait state");
		assertEquals(menu, CourseMenu.instance, "Play waits for the server instead of dismissing locally");
		menu.forceTime(["-1"]);
		assertEquals("--", view.countdown.text, "negative forceTime restores indefinite wait copy");
		LobbySocket.resetSent();
		menu.forceTime(["15"]);
		assertEquals("0", view.countdown.text, "forceTime immediately performs the authored first tick");
		@:privateAccess menu.decrementTimer();
		assertEquals("force_start`", LobbySocket.lastSent(), "countdown expiry requests the real force-start command");
		menu.remoteRemove([]);
		assertEquals(null, CourseMenu.instance, "server removal clears singleton state");

		var cancelMenu = new CourseMenu(slot);
		findView(cancelMenu).cancelButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(null, CourseMenu.instance, "Cancel closes the course menu");
		slot.remove();
		trace('CourseMenuTest passed $assertions assertions');
	}

	private static function findView(menu:CourseMenu):CourseMenuView {
		for (index in 0...menu.numChildren) {
			var view = Std.downcast(menu.getChildAt(index), CourseMenuView);
			if (view != null) return view;
		}
		throw "CourseMenuView missing";
	}

	private static function assertNear(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
