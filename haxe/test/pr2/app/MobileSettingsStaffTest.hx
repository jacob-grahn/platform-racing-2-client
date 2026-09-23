package pr2.app;

import openfl.text.TextField;
import pr2.lobby.LobbySession;
import pr2.lobby.account.Settings;
import pr2.mobile.MobileAuthControls.AuthButton;
import pr2.mobile.MobileOptionsPopup;
import pr2.mobile.MobileStaffPopup;
import pr2.mobile.MobileValueSlider;

@:access(pr2.mobile.MobileOptionsPopup)
@:access(pr2.mobile.MobileStaffPopup)
class MobileSettingsStaffTest {
	public static function main():Void {
		Settings.useMemoryStoreForTests();
		Settings.init("MobileSettingsStaffTest");

		var options = new MobileOptionsPopup();
		options.choose("gameplay");
		button(options.pane.content.controls, "ON").activate();
		check(!Settings.drawArt && button(options.pane.content.controls, "OFF") != null,
			"gameplay switch updates its saved value and visible label");
		button(options.pane.content.controls, "OFF").activate();
		check(Settings.drawArt && button(options.pane.content.controls, "ON") != null,
			"a second tap restores the switch");

		options.choose("songs");
		button(options.pane.content.controls, "✓  Orbital Trance").activate();
		check(Settings.disabledSongs().indexOf("1") >= 0
			&& button(options.pane.content.controls, "○  Orbital Trance") != null,
			"song selection updates the visible choice");
		var raw:Array<Dynamic> = Settings.getValue(Settings.DISABLED_SONGS, []);
		check(raw.indexOf(1) >= 0, "mobile song selection preserves numeric storage");
		button(options.pane.content.controls, "○  Orbital Trance").activate();
		check(Settings.disabledSongs().indexOf("1") < 0,
			"a second song tap restores the selection");

		options.choose("audio");
		var volume:MobileValueSlider = null;
		for (control in options.pane.content.controls) {
			volume = Std.downcast(control, MobileValueSlider);
			if (volume != null) break;
		}
		check(volume != null, "music volume slider exists");
		volume.setValueFromUser(65);
		var labelFound = false;
		for (i in 0...options.pane.content.numChildren) {
			var label = Std.downcast(options.pane.content.getChildAt(i), TextField);
			if (label != null && label.text == "Music volume  65%") labelFound = true;
		}
		check(Settings.musicLevel == 65 && labelFound, "volume label follows the slider");
		options.remove();

		LobbySession.group = 3;
		var staff = new MobileStaffPopup("Example", false);
		check(staff.reason.parent == null, "ban reason is hidden outside the ban form");
		button(staff.pane.content.controls, "Ban options").activate();
		check(staff.reason.parent == staff.pane.content, "ban reason scrolls with the form");
		check(staff.pane.scrollRect.height < staff.pane.content.height,
			"ban form can scroll to its submit action");
		button(staff.view.controls, "Admin").activate();
		check(staff.reason.parent == null, "ban reason is hidden on the admin tab");
		staff.remove();

		Settings.clear();
		LobbySession.clear();
		trace("MobileSettingsStaffTest passed");
	}

	private static function button(controls:Array<pr2.ui.controls.NativeControl>, label:String):AuthButton {
		for (control in controls) {
			var match = Std.downcast(control, AuthButton);
			if (match != null && match.label == label) return match;
		}
		throw "Missing button: " + label;
	}

	private static function check(value:Bool, message:String):Void if (!value) throw message;
}
