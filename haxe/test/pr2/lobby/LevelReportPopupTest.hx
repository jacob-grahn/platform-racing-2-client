package pr2.lobby;

import openfl.events.MouseEvent;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.LevelReportPopup;
import pr2.lobby.dialogs.LevelReportView;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.net.ServerConfig;
import pr2.util.TestDisplayUtil as DisplayUtil;

class LevelReportPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var savedUpload = LevelReportPopup.uploadFactory;
		var popup = new LevelReportPopup(123, 4);
		var view = findView(popup);
		assertNear(-122.45, view.panel.x, "report ShadowBG keeps XFL X");
		assertNear(-79.15, view.panel.y, "report ShadowBG keeps XFL Y");
		assertNear(0.900650024414062, view.panel.scaleX, "report ShadowBG keeps XFL horizontal scale");
		assertNear(0.837631225585938, view.panel.scaleY, "report ShadowBG keeps XFL vertical scale");
		assertEquals("-- Report Level --", view.title.text, "report title keeps exact authored copy");
		assertEquals("Please let the moderators know what's wrong with this level.", view.prompt.text, "report prompt keeps exact authored copy");
		if (pr2.DeterministicTestMode.finishSmokeSuite("LevelReportPopupTest")) return;
		assertNear(-108, view.title.x, "report title keeps authored left bound");
		assertNear(-107.95, view.prompt.x, "report prompt keeps authored left bound");
		assertNear(-106.63, view.reasonLabel.x, "reason label keeps authored left bound");
		assertNear(-43.5, view.reasonInput.x, "reason input keeps XFL X");
		assertNear(130, view.reasonInput.controlWidth, "reason input keeps XFL horizontal scale");
		assertNear(-80, view.reportButton.x, "Report keeps XFL X");
		assertNear(7, view.cancelButton.x, "Cancel keeps XFL X");

		view.reasonInput.text = "   ";
		view.reportButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertNotNull(lastPopup(MessagePopup), "blank report opens the exact error popup flow");
		closeExcept(popup);

		var captured:Null<{url:String, fields:Map<String, String>, label:String}> = null;
		LevelReportPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String):Null<pr2.lobby.dialogs.UploadingPopup> {
			captured = {url: url, fields: fields, label: label};
			return null;
		};
		view.reasonInput.text = "  inappropriate art  ";
		view.reportButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		var confirm = lastPopup(ConfirmPopup);
		assertNotNull(confirm, "non-empty report opens confirmation");
		DisplayUtil.findByName(confirm, "ok_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(ServerConfig.levelReportUrl(), captured.url, "confirmed report uses real endpoint");
		assertEquals("123", captured.fields.get("level_id"), "confirmed report forwards level id");
		assertEquals("4", captured.fields.get("version"), "confirmed report forwards version");
		assertEquals("  inappropriate art  ", captured.fields.get("reason"), "confirmed report preserves authored input text");
		assertEquals("Reporting level...", captured.label, "confirmed report uses exact upload copy");
		assertEquals(true, popup.fadeOutStarted, "confirmed report fades report popup");
		popup.remove();

		var cancelPopup = new LevelReportPopup();
		findView(cancelPopup).cancelButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, cancelPopup.fadeOutStarted, "Cancel starts popup fade");
		cancelPopup.remove();
		LevelReportPopup.uploadFactory = savedUpload;
		closeAll();
		trace('LevelReportPopupTest passed $assertions assertions');
	}

	private static function findView(popup:LevelReportPopup):LevelReportView {
		for (index in 0...popup.numChildren) {
			var view = Std.downcast(popup.getChildAt(index), LevelReportView);
			if (view != null) return view;
		}
		throw "LevelReportView missing";
	}

	private static function lastPopup<T:Popup>(type:Class<T>):Null<T> {
		var open = Popup.getOpen();
		for (offset in 0...open.length) {
			var value = Std.downcast(open[open.length - 1 - offset], type);
			if (value != null) return value;
		}
		return null;
	}

	private static function closeExcept(keep:Popup):Void {
		for (value in Popup.getOpen().copy()) if (value != keep) value.remove();
	}

	private static function closeAll():Void {
		for (value in Popup.getOpen().copy()) value.remove();
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
