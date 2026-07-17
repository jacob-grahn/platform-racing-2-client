package pr2.ui;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import pr2.net.CommandHandler;
import pr2.util.DisplayUtil;

class GpNotificationTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testGpGainCommandMountsAuthoredNotification();
		if (pr2.DeterministicTestMode.finishSmokeSuite("GpNotificationTest")) return;
		trace('GpNotificationTest passed $assertions assertions');
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

		for (_ in 0...70) {
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
}
