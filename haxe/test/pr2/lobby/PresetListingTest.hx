package pr2.lobby;

import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.account.LoadoutsPopup;
import pr2.lobby.account.Presets;
import pr2.lobby.account.Settings;
import pr2.lobby.dialogs.Popup;
import pr2.util.TestDisplayUtil as DisplayUtil;

class PresetListingTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		Settings.disablePersistenceForTests();
		Settings.init("PresetParity");
		Settings.setValue(Settings.PRESETS, [{
			num: 1, speed: 40, acceleration: 50, jumping: 60,
			hat: 1, head: 1, body: 1, feet: 1,
			hatColor: 1, headColor: 2, bodyColor: 3, feetColor: 4,
			hatColor2: -1, headColor2: -1, bodyColor2: -1, feetColor2: -1
		}]);
		Presets.resetForTests();
		var popup = new LoadoutsPopup(null, null, null);
		var art = popup.listingArtForTests()[0];
		var background = DisplayUtil.findByName(art, "stateBackground");
		var number = Std.downcast(DisplayUtil.findByName(art, "loadoutNum"), TextField);
		var speed = Std.downcast(DisplayUtil.findByName(art, "loadoutSpeed"), TextField);
		var accel = Std.downcast(DisplayUtil.findByName(art, "loadoutAccel"), TextField);
		var jump = Std.downcast(DisplayUtil.findByName(art, "loadoutJump"), TextField);
		assertClose(248, background.width, "preset up state keeps authored width");
		assertClose(67, background.height, "preset up state keeps authored height");
		assertClose(1, background.getBounds(background).y, "preset up state keeps authored top edge");
		assertClose(10, number.x, "preset number keeps XFL X");
		assertClose(25, number.y, "preset number keeps XFL Y");
		assertClose(23.5, number.width, "preset number keeps authored width");
		assertClose(19.45, number.height, "preset number keeps authored height");
		assertEquals("1", number.text, "preset number is normalized to its loadout slot");
		assertClose(92, speed.x, "preset speed keeps XFL X");
		assertClose(7, speed.y, "preset speed keeps XFL Y");
		assertClose(14.55, speed.height, "preset speed keeps authored height");
		assertEquals("Speed: 40", speed.text, "preset speed uses AS3 copy");
		assertEquals("Acceleration: 50", accel.text, "preset acceleration uses AS3 copy");
		assertEquals("Jumping: 60", jump.text, "preset jumping uses AS3 copy");
		assertEquals(0x333333, popup.listingFillForTests(0), "preset up state uses authored fill");
		art.parent.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
		assertEquals(0xCCCCCC, popup.listingFillForTests(0), "preset over state uses authored fill");
		art.parent.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
		assertEquals(0x333333, popup.listingFillForTests(0), "preset out restores authored fill");
		popup.selectListingForTests(0);
		assertEquals(0x42D75F, popup.listingFillForTests(0), "preset selected state uses authored green fill");
		var preview = popup.previewsForTests()[0];
		assertClose(58, preview.x, "preset character keeps AS3 X");
		assertClose(61, preview.y, "preset character keeps AS3 Y");
		assertClose(0.13 * (1 / 0.15), preview.scaleX, "preset character compensates authored rig scale");
		popup.remove();
		for (open in Popup.getOpen().copy()) open.remove();
		Settings.disablePersistenceForTests();
		Presets.resetForTests();
		trace('PresetListingTest passed $assertions assertions');
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}
}
