package pr2.ui;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import pr2.net.CommandHandler;
import pr2.ui.view.LoadingView;
import pr2.util.TestDisplayUtil as DisplayUtil;

class GpNotificationTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testGpGainCommandMountsAuthoredNotification();
		testLoadingViewUsesAuthoredNestedTimelines();
		if (pr2.DeterministicTestMode.finishSmokeSuite("GpNotificationTest")) return;
		trace('GpNotificationTest passed $assertions assertions');
	}

	private static function testLoadingViewUsesAuthoredNestedTimelines():Void {
		var loading = new LoadingView();
		var label = Std.downcast(DisplayUtil.findByName(loading, "label"), TextField);
		assertNotNull(label, "loading label is named for deterministic parity checks");
		assertEquals("Loading...", label.text, "frame 1 uses the authored three-dot copy");
		assertNear(-34, loading.spinner.transform.matrix.tx, "frame 1 spinner x matches XFL");
		assertNear(-34.05, loading.spinner.transform.matrix.ty, "frame 1 spinner y matches XFL");

		loading.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(2, loading.currentFrame, "nested loading timelines advance one frame");
		assertNear(-15.939651489257824, loading.spinner.transform.matrix.tx, "frame 2 spinner x includes the authored registration compensation");
		assertNear(-45.35734863281249, loading.spinner.transform.matrix.ty, "frame 2 spinner y includes the authored registration compensation");

		for (_ in 0...9) loading.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals("Loading", label.text, "text timeline holds three dots for exactly ten frames");
		for (_ in 0...10) loading.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals("Loading.", label.text, "text timeline advances to one dot after its second ten-frame hold");
	}

	private static function testGpGainCommandMountsAuthoredNotification():Void {
		var holder = new Sprite();
		var handler = new CommandHandler();
		GpNotification.init(holder, handler);

		assertEquals(true, handler.dispatch("gpGain", ["42"]), "gpGain command is registered");
		assertEquals(1, holder.numChildren, "gpGain mounts one notification");

		var notification = Std.downcast(holder.getChildAt(0), GpNotification);
		assertNotNull(notification, "notification uses the Haxe GP wrapper");
		assertEquals(25.0, notification.x, "notification x matches Flash");
		assertEquals(25.0, notification.y, "notification y matches Flash");
		assertEquals("+42 GP", notification.message, "notification message is stored");

		var anim = Std.downcast(DisplayUtil.findByName(notification.art, "anim"), openfl.display.DisplayObjectContainer);
		var textBox = Std.downcast(DisplayUtil.findByName(anim, "textBox"), TextField);
		assertNotNull(textBox, "authored anim.textBox is present");
		assertEquals("+42 GP", textBox.text, "authored text field receives GP copy");
		assertEquals(25.0, notification.anim.y, "frame 1 authored entrance y is exact");
		assertEquals(0.0, notification.anim.alpha, "frame 1 authored entrance alpha is exact");
		assertEquals(255.0, notification.anim.transform.colorTransform.redOffset, "frame 1 authored yellow tint is exact");

		notification.art.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(22.55, notification.anim.y, "frame 2 uses the XFL tween key rather than an approximate easing curve");
		assertEquals(0.1015625, notification.anim.alpha, "frame 2 uses the quantized XFL alpha");
		assertEquals(236.0, notification.anim.transform.colorTransform.greenOffset, "frame 2 uses the quantized XFL tint");

		for (_ in 0...69) {
			notification.art.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(0, holder.numChildren, "frame 71 script removes the notification");
		assertEquals(71, notification.currentFrame, "notification reaches Flash removal frame");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) {
			throw '$message: value was null';
		}
	}

	private static function assertNear(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}
}
