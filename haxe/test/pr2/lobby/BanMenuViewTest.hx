package pr2.lobby;

import openfl.display.DisplayObject;
import openfl.text.TextField;
import pr2.lobby.dialogs.BanMenu;
import pr2.lobby.dialogs.Popup;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameSelect;
import pr2.util.TestDisplayUtil as DisplayUtil;

class BanMenuViewTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var savedTrial = LobbySession.isTrialMod;
		LobbySession.isTrialMod = false;
		var target = new Popup(false);
		var menu = new BanMenu("Target", target);
		var panel = required(menu, "panel");
		assertNear(-86, panel.x, "ban ShadowBG keeps XFL X");
		assertNear(-180, panel.y, "ban ShadowBG keeps XFL Y");
		assertNear(0.632369995117188, panel.scaleX, "ban ShadowBG keeps XFL horizontal scale");
		assertNear(1.884765625, panel.scaleY, "ban ShadowBG keeps XFL vertical scale");
		assertEquals("-- Mod --", text(menu, "modTitle").text, "ban menu keeps exact moderator heading");
		assertEquals("-- Ban --", text(menu, "banTitle").text, "ban menu keeps exact ban heading");
		if (pr2.DeterministicTestMode.finishSmokeSuite("BanMenuViewTest")) return;
		assertButton(menu, "warning1Button", "Warning 1", -50, -147);
		assertButton(menu, "warning2Button", "Warning 2", -50, -121);
		assertButton(menu, "warning3Button", "Warning 3", -50, -95);
		assertButton(menu, "kickButton", "30 Minute Kick", -50, -69);
		assertButton(menu, "banButton", "Ban", -50, 140);
		assertButton(menu, "viewPriorsButton", "View Priors", -29, -2.5);
		var reason = text(menu, "reason");
		assertNear(-24, reason.x, "reason input keeps XFL X");
		assertNear(20, reason.y, "reason input keeps XFL Y");
		assertNear(100, reason.width, "reason input keeps component width");
		assertEquals(100, reason.maxChars, "reason input keeps authored maximum length");
		assertEquals("^`", reason.restrict, "reason input excludes the protocol delimiter");
		var duration = select(menu, "duration");
		assertNear(-24, duration.x, "duration keeps XFL X");
		assertNear(105.5, duration.y, "duration keeps XFL Y");
		assertEquals("Choose...", Reflect.field(duration.itemAt(0), "label"), "duration retains authored prompt item");
		assertEquals("One Hour", Reflect.field(duration.itemAt(1), "label"), "duration retains authored one-hour item");
		assertEquals("One Day", Reflect.field(duration.itemAt(2), "label"), "duration retains authored one-day item");
		var type = select(menu, "type");
		assertEquals("Both", Reflect.field(type.itemAt(0), "label"), "type retains exact authored Both copy");
		assertEquals("Account Only", Reflect.field(type.itemAt(1), "label"), "type retains exact authored account copy");
		assertEquals("IP Only", Reflect.field(type.itemAt(2), "label"), "type retains exact authored IP copy");
		var scope = select(menu, "scope");
		assertEquals(true, scope.enabled, "full moderators receive enabled game scope");
		assertEquals("Game", Reflect.field(scope.itemAt(1), "label"), "full moderators receive exact game scope item");
		menu.remove();
		target.remove();
		LobbySession.isTrialMod = savedTrial;
		trace('BanMenuViewTest passed $assertions assertions');
	}

	private static function assertButton(menu:BanMenu, name:String, label:String, x:Float, y:Float):Void {
		var value = Std.downcast(required(menu, name), GameButton);
		assertEquals(label, value.label, name + " keeps exact authored copy");
		assertNear(x, value.x, name + " keeps XFL X");
		assertNear(y, value.y, name + " keeps XFL Y");
	}

	private static function select(menu:BanMenu, name:String):GameSelect<Dynamic> {
		var value = Std.downcast(required(menu, name), GameSelect);
		if (value == null) throw '$name select missing';
		return value;
	}

	private static function text(menu:BanMenu, name:String):TextField {
		var value = Std.downcast(required(menu, name), TextField);
		if (value == null) throw '$name text missing';
		return value;
	}

	private static function required(menu:BanMenu, name:String):DisplayObject {
		var value = DisplayUtil.findByName(menu, name);
		if (value == null) throw '$name missing';
		return value;
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
