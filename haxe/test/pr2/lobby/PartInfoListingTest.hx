package pr2.lobby;

import openfl.events.MouseEvent;
import openfl.display.Sprite;
import openfl.text.TextField;
import pr2.lobby.account.AccountCharacter;
import pr2.lobby.account.PartInfoListing;
import pr2.lobby.account.PartPopup;
import pr2.lobby.dialogs.Popup;
import pr2.util.TestDisplayUtil as DisplayUtil;

class PartInfoListingTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var listing = new PartInfoListing("HEAD", 1, "Classic", "Rock it old school.", "Starter", true, true);
		var bg = DisplayUtil.findByName(listing, "bg");
		var guide = DisplayUtil.findByName(listing, "previewGuide");
		var cover = DisplayUtil.findByName(listing, "cover");
		var title = Std.downcast(DisplayUtil.findByName(listing, "titleBox"), TextField);
		var owned = Std.downcast(DisplayUtil.findByName(listing, "ownedBox"), TextField);
		var epic = Std.downcast(DisplayUtil.findByName(listing, "epicBox"), TextField);
		var desc = Std.downcast(DisplayUtil.findByName(listing, "descBox"), TextField);
		assertClose(122 * 1.04917907714844, bg.width, "listing background keeps authored horizontal scale");
		assertClose(140 * 1.1142578125, bg.height, "listing background keeps authored vertical scale");
		assertEquals(false, bg.visible, "listing background starts hidden like Flash");
		assertClose(8, guide.x, "preview guide keeps XFL X");
		assertClose(21.5, guide.y, "preview guide keeps XFL Y");
		assertClose(122 * 1.04917907714844, cover.width, "listing hit cover keeps authored width");
		assertClose(140 * 0.67132568359375, cover.height, "listing hit cover keeps authored height");
		assertClose(10.05, title.x, "listing title keeps XFL X");
		assertClose(5, title.y, "listing title keeps XFL Y");
		assertEquals("Classic Head", title.text, "listing title keeps AS3 composition");
		assertClose(10, owned.x, "owned label keeps XFL X");
		assertClose(23.55, owned.y, "owned label keeps AS3 adjusted Y");
		assertEquals(true, owned.visible, "owned listing shows owned label");
		assertClose(62.05, epic.x, "upgraded label keeps XFL X");
		assertClose(75.35, epic.y, "upgraded label keeps AS3 adjusted Y");
		assertEquals("Upgraded!", epic.text, "owned epic listing uses AS3 upgraded copy");
		assertClose(10, desc.x, "description keeps XFL X");
		assertClose(96, desc.y, "description keeps XFL Y");
		assertClose(65.65, desc.height, "description keeps authored height");
		cover.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals(true, bg.visible, "hover shows authored listing background");
		cover.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(false, bg.visible, "hover out hides authored listing background");
		listing.remove();
		testExactPartPopup();
		for (popup in Popup.getOpen().copy()) popup.remove();
		trace('PartInfoListingTest passed $assertions assertions');
	}

	private static function testExactPartPopup():Void {
		var popup = new PartPopup("HEAD", 1, "Classic", "Rock it old school.", "Starter", true, false);
		var panel = DisplayUtil.findByName(popup, "panel");
		var title = Std.downcast(DisplayUtil.findByName(popup, "titleBox"), TextField);
		var desc = Std.downcast(DisplayUtil.findByName(popup, "descBox"), TextField);
		var owned = Std.downcast(DisplayUtil.findByName(popup, "ownedBox"), TextField);
		var epic = Std.downcast(DisplayUtil.findByName(popup, "epicBox"), TextField);
		var obtain = Std.downcast(DisplayUtil.findByName(popup, "obtainBox"), TextField);
		var equip = DisplayUtil.findByName(popup, "equip_bt");
		var close = DisplayUtil.findByName(popup, "close_bt");
		assertClose(-198.95, panel.x, "part popup ShadowBG keeps XFL X");
		assertClose(-98.65, panel.y, "part popup ShadowBG keeps XFL Y");
		assertClose(1.47056579589844, panel.scaleX, "part popup ShadowBG keeps XFL horizontal scale");
		assertClose(1.04719543457031, panel.scaleY, "part popup ShadowBG keeps XFL vertical scale");
		assertClose(-175.95, title.x, "part popup title keeps XFL X");
		assertClose(-85, title.y, "part popup title keeps XFL Y");
		assertClose(-180.95, desc.x, "part popup description keeps XFL X");
		assertClose(-66.45, desc.y, "part popup description keeps XFL Y");
		assertClose(-46.3, owned.x, "part ownership keeps XFL X");
		assertClose(-43.75, owned.y, "part ownership keeps XFL Y");
		assertClose(-25.2, epic.y, "epic ownership keeps XFL Y");
		assertClose(-7.85, obtain.y, "obtain copy keeps XFL Y");
		assertClose(47.65, obtain.height, "obtain copy keeps authored height");
		assertClose(-103, equip.x, "Equip keeps XFL X");
		assertClose(61.5, equip.y, "Equip keeps XFL Y");
		assertClose(7, close.x, "Close keeps XFL X");
		assertClose(61.5, close.y, "Close keeps XFL Y");
		var preview = popup.targetForTests();
		assertClose(-130, preview.x, "detail preview uses authored left registration");
		var rigRoot = Std.downcast(preview.character.display.getChildByName("rigRoot"), Sprite);
		assertEquals(true, rigRoot.getChildByName("head").visible, "head detail keeps head channel visible");
		assertEquals(false, rigRoot.getChildByName("body").visible, "head detail hides body channel");
		assertEquals(false, rigRoot.getChildByName("frontFoot").visible, "head detail hides front foot channel");
		assertEquals(false, rigRoot.getChildByName("backFoot").visible, "head detail hides back foot channel");
		popup.remove();
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
