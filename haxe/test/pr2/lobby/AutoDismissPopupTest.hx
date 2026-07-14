package pr2.lobby;

import openfl.display.Sprite;
import pr2.lobby.dialogs.AutoDismissController;
import pr2.lobby.dialogs.AutoDismissPopup;
import pr2.ui.StageFocus;

class AutoDismissPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testHitTestDismissal();
		if (pr2.DeterministicTestMode.finishSmokeSuite("AutoDismissPopupTest")) return;
		testCleanupIsIdempotent();
		testPopupRemoveResetsFocus();
		StageFocus.resetHooks();
		trace('AutoDismissPopupTest passed $assertions assertions');
	}

	private static function testHitTestDismissal():Void {
		var owner = new HitTestOwner();
		var removed = false;
		var autoDismiss = new AutoDismissController(owner, function():Void removed = true);

		autoDismiss.stageMouseDownForTests(20, 20);
		assertEquals(false, removed, "inside click stays open");

		autoDismiss.stageMouseDownForTests(100, 100);
		assertEquals(true, removed, "outside click dismisses");
		autoDismiss.remove();
	}

	private static function testCleanupIsIdempotent():Void {
		var owner = new Sprite();
		var autoDismiss = new AutoDismissController(owner, function():Void {});
		autoDismiss.remove();
		autoDismiss.remove();
		assertEquals(true, true, "auto-dismiss cleanup is idempotent");
	}

	private static function testPopupRemoveResetsFocus():Void {
		var focusResets = 0;
		StageFocus.resetHook = function():Void focusResets++;
		var popup = new AutoDismissPopup();
		popup.remove();
		assertEquals(1, focusResets, "popup remove resets stage focus");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}

private class HitTestOwner extends Sprite {
	override public function hitTestPoint(x:Float, y:Float, shapeFlag:Bool = false):Bool {
		return shapeFlag && x >= 10 && x <= 40 && y >= 10 && y <= 40;
	}
}
