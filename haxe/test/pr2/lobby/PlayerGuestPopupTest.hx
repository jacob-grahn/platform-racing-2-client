package pr2.lobby;

import openfl.events.MouseEvent;
import pr2.lobby.dialogs.BanMenu;
import pr2.lobby.dialogs.PlayerGuestPopup;
import pr2.lobby.dialogs.PlayerGuestView;

class PlayerGuestPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var savedGroup = LobbySession.group;
		LobbySession.group = 1;
		var popup = new PlayerGuestPopup("Guest Name");
		var view = findView(popup);
		assertEquals("-- Guest Name --", view.nameBox.text, "guest name uses exact AS3 copy");
		assertEquals("Group: Guest", view.groupLabel.text, "guest popup retains authored group copy");
		assertNear(-116.2, view.panel.x, "ShadowBG keeps XFL X");
		assertNear(-65.9, view.panel.y, "ShadowBG keeps XFL Y");
		assertNear(0.854537963867188, view.panel.scaleX, "ShadowBG keeps XFL horizontal scale");
		assertNear(0.68524169921875, view.panel.scaleY, "ShadowBG keeps XFL vertical scale");
		if (pr2.DeterministicTestMode.finishSmokeSuite("PlayerGuestPopupTest")) return;
		assertNear(-94, view.nameBox.x, "name field keeps XFL X");
		assertNear(-52.5, view.nameBox.y, "name field keeps XFL Y");
		assertNear(188.1, view.nameBox.width, "name field keeps XFL width");
		assertNear(-40.85, view.groupLabel.x, "group copy keeps XFL X");
		assertNear(-25.05, view.groupLabel.y, "group copy keeps XFL Y");
		assertNear(-50, view.closeButton.x, "Close keeps XFL X");
		assertNear(30.05, view.closeButton.y, "Close keeps XFL Y");
		view.closeButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, popup.fadeOutStarted, "authored Close button starts popup fade");
		popup.remove();

		LobbySession.group = 2;
		var moderated = new PlayerGuestPopup("Target");
		assertNotNull(findBanMenu(moderated), "moderators receive the real BanMenu beside guest profile");
		assertNotNull(findView(moderated), "moderated guest popup retains the exact guest profile beside BanMenu");
		moderated.remove();
		LobbySession.group = savedGroup;
		trace('PlayerGuestPopupTest passed $assertions assertions');
	}

	private static function findView(popup:PlayerGuestPopup):PlayerGuestView {
		for (index in 0...popup.numChildren) {
			var view = Std.downcast(popup.getChildAt(index), PlayerGuestView);
			if (view != null) return view;
		}
		throw "PlayerGuestView missing";
	}

	private static function findBanMenu(popup:PlayerGuestPopup):BanMenu {
		for (index in 0...popup.numChildren) {
			var menu = Std.downcast(popup.getChildAt(index), BanMenu);
			if (menu != null) return menu;
		}
		return null;
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
