package pr2.lobby;

import openfl.events.Event;
import openfl.filters.GlowFilter;

/** Source-coordinate and authored-timeline coverage for the native lobby shell. */
class LobbyShellParityTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var background = new LobbyBackgroundView();
		assertEquals(1, background.numChildren, "lobby background is one exact source composition");
		assertNear(0, background.getChildAt(0).x, "lobby background keeps authored registration x");
		assertNear(0, background.getChildAt(0).y, "lobby background keeps authored registration y");
		assertNear(1, background.getChildAt(0).scaleX, "lobby background is not resized away from XFL coordinates");

		var footer = new LobbyBottomButtonsView(false);
		assertEquals(6, footer.numChildren, "footer retains all six authored instances");
		assertEquals("Logout", footer.logoutButton.label, "Flash footer label is Logout");
		assertNear(207, footer.creditsButton.x, "sponsored credits x");
		assertNear(369, footer.creditsButton.y, "sponsored credits y");
		assertNear(272, footer.levelEditorButton.x, "sponsored level-editor x");
		assertNear(361, footer.logoutButton.x, "sponsored logout x");
		assertNear(423, footer.optionsButton.x, "sponsored options x");
		assertNear(58.1741333007812, footer.creditsButton.controlWidth, "sponsored credits uses the 100px Flash component width");
		assertNear(81.4407348632812, footer.levelEditorButton.controlWidth, "sponsored level-editor uses the 100px Flash component width");
		assertTrue(footer.creditsButton.x + footer.creditsButton.controlWidth < footer.levelEditorButton.x,
			"sponsored credits and level-editor buttons do not overlap");
		assertTrue(footer.levelEditorButton.x + footer.levelEditorButton.controlWidth < footer.logoutButton.x,
			"sponsored level-editor and logout buttons do not overlap");
		assertTrue(footer.logoutButton.x + footer.logoutButton.controlWidth < footer.optionsButton.x,
			"sponsored logout and options buttons do not overlap");
		assertNear(421, footer.vaultButton.y, "sponsored vault remains authored below the stage clip");
		assertNear(421, footer.moreGamesButton.y, "sponsored Kong button remains authored below the stage clip");

		footer.setMemberVariant(true);
		assertEquals(true, footer.member, "member variant selects kongregateSite frame");
		assertNear(206, footer.vaultButton.x, "member vault x");
		assertNear(366, footer.vaultButton.y, "member vault y");
		assertNear(285, footer.levelEditorButton.x, "member level-editor x");
		assertNear(363, footer.logoutButton.x, "member logout x");
		assertNear(423, footer.optionsButton.x, "member options x");
		assertNear(73.9898681640625, footer.levelEditorButton.controlWidth, "member level-editor uses the 100px Flash component width");
		assertTrue(footer.levelEditorButton.x + footer.levelEditorButton.controlWidth < footer.logoutButton.x,
			"member level-editor and logout buttons do not overlap");
		assertTrue(footer.logoutButton.x + footer.logoutButton.controlWidth < footer.optionsButton.x,
			"member logout and options buttons do not overlap");
		assertNear(435, footer.creditsButton.y, "member credits remains authored below the stage clip");
		assertNear(430, footer.moreGamesButton.y, "member Kong button remains authored below the stage clip");

		assertEquals(41, footer.moreGamesButton.glow.totalFrames, "Kong glow keeps all 41 XFL frames");
		assertEquals(true, footer.moreGamesButton.glow.looping, "Kong glow loops like its MovieClip timeline");
		footer.moreGamesButton.glow.gotoAndStop(11);
		var kongGlow = glowFilter(footer.moreGamesButton.glow.getChildAt(0).filters[0]);
		assertNear(10, kongGlow.blurX, "Kong frame 11 blur x comes from XFL");
		assertNear(10, kongGlow.blurY, "Kong frame 11 blur y comes from XFL");
		assertEquals(3, kongGlow.quality, "Kong glow quality comes from XFL");
		assertEquals(true, kongGlow.knockout, "Kong glow preserves unsupported knockout metadata");
		footer.moreGamesButton.glow.gotoAndStop(41);
		footer.moreGamesButton.glow.play();
		footer.moreGamesButton.glow.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, footer.moreGamesButton.glow.currentFrame, "Kong MovieClip loops frame 41 to frame 1");

		assertEquals(1, footer.vaultButton.glow.totalFrames, "Vault glow is the exact static XFL frame");
		assertEquals(false, footer.vaultButton.glow.looping, "Vault does not invent animation");
		var vaultGlow = glowFilter(footer.vaultButton.glow.getChildAt(0).filters[0]);
		assertNear(0, vaultGlow.blurX, "Vault authored glow blur remains zero");
		assertEquals(true, vaultGlow.knockout, "Vault glow preserves knockout metadata");

		footer.dispose();
		assertEquals(true, footer.disposed, "footer teardown disposes its native ownership root");
		assertEquals(true, footer.moreGamesButton.disposed, "footer teardown disposes Kong animation owner");
		assertEquals(false, footer.moreGamesButton.glow.hasEventListener(Event.ENTER_FRAME), "Kong timeline listener is removed");
		background.dispose();
		trace('LobbyShellParityTest passed $assertions assertions');
	}

	private static function glowFilter(value:Dynamic):GlowFilter {
		var glow = Std.downcast(value, GlowFilter);
		if (glow == null) throw "expected GlowFilter";
		return glow;
	}

	private static function assertNear(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.001) throw '$message: expected $expected, got $actual';
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertTrue(actual:Bool, message:String):Void {
		assertions++;
		if (!actual) throw '$message: expected true, got false';
	}
}
