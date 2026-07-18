package pr2.lobby;

import pr2.lobby.dialogs.OptionsArtQualityView;
import pr2.lobby.dialogs.OptionsSongsView;

class OptionsSubmenuViewTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var art = new OptionsArtQualityView(true);
		assertNear(-115, art.panel.x, "art-quality ShadowBG keeps XFL X");
		assertNear(-33.95, art.panel.y, "art-quality ShadowBG keeps XFL Y");
		assertNear(0.8455810546875, art.panel.scaleX, "art-quality ShadowBG keeps XFL horizontal scale");
		assertNear(0.83758544921875, art.panel.scaleY, "art-quality ShadowBG keeps XFL vertical scale");
		assertEquals("Lossless (EXPERIMENTAL)", art.losslessCheck.label, "art-quality checkbox keeps exact authored copy");
		assertEquals(true, art.losslessCheck.selected, "art-quality checkbox loads selected state");
		if (pr2.DeterministicTestMode.finishSmokeSuite("OptionsSubmenuViewTest")) return;
		assertNear(-105, art.description.x, "art-quality description keeps authored left bound");
		assertNear(32.5, art.description.y, "art-quality description keeps XFL Y");
		assertNear(212, art.description.width, "art-quality description keeps XFL width");
		assertEquals("-- Art Quality --", art.title.text, "art-quality title keeps exact authored copy");
		art.dispose();

		var songs = new OptionsSongsView(["2", "21"]);
		assertNear(-137.5, songs.panel.x, "songs ShadowBG keeps XFL X");
		assertNear(-125, songs.panel.y, "songs ShadowBG keeps XFL Y");
		assertNear(1.01100158691406, songs.panel.scaleX, "songs ShadowBG keeps XFL horizontal scale");
		assertNear(1.30888366699219, songs.panel.scaleY, "songs ShadowBG keeps XFL vertical scale");
		assertEquals("-- Songs --", songs.title.text, "songs title keeps exact authored copy");
		assertEquals(19, countChecks(songs), "song menu includes every authored checkbox except retired 9 and 16");
		assertNear(-127.95, songs.checks.get(1).x, "left song column keeps XFL X");
		assertNear(-86, songs.checks.get(1).y, "first left song keeps XFL Y");
		assertNear(-127.95, songs.checks.get(11).x, "last left song keeps XFL X");
		assertNear(94, songs.checks.get(11).y, "last left song keeps XFL Y");
		assertNear(5.65, songs.checks.get(12).x, "right song column keeps XFL X");
		assertNear(-86, songs.checks.get(12).y, "first right song keeps XFL Y");
		assertNear(74, songs.checks.get(21).y, "last right song keeps XFL Y");
		assertNear(125, songs.checks.get(21).controlWidth, "song checkboxes keep XFL horizontal scale");
		assertNear(13.7469787597656, songs.checks.get(21).controlHeight, "song checkboxes keep XFL vertical scale");
		assertEquals(false, songs.checks.get(2).selected, "disabled song blacklist clears authored selection");
		assertEquals(true, songs.checks.get(3).selected, "unlisted songs remain selected");
		assertEquals(false, songs.checks.get(21).selected, "disabled final song clears authored selection");
		songs.dispose();
		trace('OptionsSubmenuViewTest passed $assertions assertions');
	}

	private static function countChecks(view:OptionsSongsView):Int {
		var count = 0;
		for (_ in view.checks) count++;
		return count;
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
