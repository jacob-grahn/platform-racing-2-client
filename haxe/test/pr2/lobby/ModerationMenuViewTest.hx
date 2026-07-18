package pr2.lobby;

import openfl.display.DisplayObjectContainer;
import pr2.lobby.dialogs.AdminMenu;
import pr2.lobby.dialogs.ModerationMenuView;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.TempModMenu;

class ModerationMenuViewTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var target = new Popup();
		var admin = new AdminMenu("Target", target);
		var adminView = view(admin);
		assertEquals("-- Admin --", adminView.heading.text, "admin menu keeps exact authored heading");
		assertNear(-50, adminView.panel.x, "admin ShadowBG keeps XFL X");
		assertNear(-75, adminView.panel.y, "admin ShadowBG keeps XFL Y");
		assertNear(0.367599487304688, adminView.panel.scaleX, "admin ShadowBG keeps XFL horizontal scale");
		assertNear(0.785232543945312, adminView.panel.scaleY, "admin ShadowBG keeps XFL vertical scale");
		assertEquals("Temp Mod", adminView.buttons.get("tempMod_bt").label, "admin temporary button keeps exact copy");
		if (pr2.DeterministicTestMode.finishSmokeSuite("ModerationMenuViewTest")) return;
		assertNear(-35, adminView.buttons.get("tempMod_bt").x, "admin buttons keep XFL X");
		assertNear(-43, adminView.buttons.get("tempMod_bt").y, "Temp Mod keeps XFL Y");
		assertNear(-16, adminView.buttons.get("trialMod_bt").y, "Trial Mod keeps XFL Y");
		assertNear(11, adminView.buttons.get("permaMod_bt").y, "Mod keeps XFL Y");
		assertNear(38, adminView.buttons.get("demote_bt").y, "De-Mod keeps XFL Y");
		assertEquals("De-Mod", adminView.buttons.get("demote_bt").label, "admin demotion button keeps exact copy");
		admin.remove();

		var temp = new TempModMenu("Target", target);
		var tempView = view(temp);
		assertEquals("-- Mod --", tempView.heading.text, "temporary moderator menu keeps exact authored heading");
		assertNear(-86, tempView.panel.x, "temporary moderator ShadowBG keeps XFL X");
		assertNear(-99, tempView.panel.y, "temporary moderator ShadowBG keeps XFL Y");
		assertNear(0.632369995117188, tempView.panel.scaleX, "temporary moderator ShadowBG keeps XFL horizontal scale");
		assertNear(1.03675842285156, tempView.panel.scaleY, "temporary moderator ShadowBG keeps XFL vertical scale");
		assertNear(-60, tempView.buttons.get("warning1Button").y, "Warning 1 keeps XFL Y");
		assertNear(-34, tempView.buttons.get("warning2Button").y, "Warning 2 keeps XFL Y");
		assertNear(-8, tempView.buttons.get("warning3Button").y, "Warning 3 keeps XFL Y");
		assertNear(55, tempView.buttons.get("kickButton").y, "kick keeps XFL Y");
		assertEquals("30 Minute Kick", tempView.buttons.get("kickButton").label, "kick button keeps exact authored copy");
		temp.remove();
		target.remove();
		trace('ModerationMenuViewTest passed $assertions assertions');
	}

	private static function view(container:DisplayObjectContainer):ModerationMenuView {
		for (index in 0...container.numChildren) {
			var value = Std.downcast(container.getChildAt(index), ModerationMenuView);
			if (value != null) return value;
		}
		throw "ModerationMenuView missing";
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
