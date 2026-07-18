package pr2.gameplay;

import openfl.events.Event;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.Popup;
import pr2.ui.RatingSelect;
import pr2.util.TestDisplayUtil as DisplayUtil;

/**
	Covers the finished-race popup the way Flash `gameplay.FinishedPage`,
	`gameplay.ExpGain`, and `ui.RatingSelect` behaved: award lines fill in order
	and cap at five, the exp total reads `+ delta`, the exp bar eases across 45
	frames with the AS3 clamping, and the rating-offset mapping clamps to 1-5.
**/
class FinishedPageTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testAwardsAndExpTotal();
		if (pr2.DeterministicTestMode.finishSmokeSuite("FinishedPageTest")) return;
		testExpGainAnimation();
		testExpGainClamp();
		testRatingFromOffset();
		testNativeRatingMeter();
		closeAll();
		trace('FinishedPageTest passed $assertions assertions');
	}

	private static function testAwardsAndExpTotal():Void {
		var page = new FinishedPage(12345);
		assertEquals("assets/svg/effects/finished_page_01.svg", FinishedPageView.SHELL_ASSET,
			"finished page uses the exact authored XFL shell and static copy");
		assertEquals(true, DisplayUtil.findByName(page, "exactShell").width > 280,
			"authored finished-page shell renders");
		assertNear(-127.95, LobbyArt.text(page, "bonus1").x, 0.001, "award column preserves authored x");
		assertNear(-100.5, LobbyArt.text(page, "bonus1").y, 0.001, "first award preserves authored y");
		assertNear(50.25, LobbyArt.text(page, "exp1").x, 0.001, "experience column preserves authored x");
		assertNear(-111, DisplayUtil.findByName(page, "close_bt").x, 0.001, "close button preserves authored x");
		assertNear(8, DisplayUtil.findByName(page, "return_bt").x, 0.001, "return button preserves authored x");

		page.award("First Place", "+50");
		page.award("Speed Bonus", "+20");
		assertEquals("First Place", LobbyArt.text(page, "bonus1").text, "first award fills bonus1");
		assertEquals("+50", LobbyArt.text(page, "exp1").text, "first award fills exp1");
		assertEquals("Speed Bonus", LobbyArt.text(page, "bonus2").text, "second award fills bonus2");

		// Only five lines exist; a sixth award is dropped without error.
		page.award("3", "+1");
		page.award("4", "+1");
		page.award("5", "+1");
		page.award("6 (dropped)", "+1");
		assertEquals("5", LobbyArt.text(page, "bonus5").text, "fifth award fills bonus5");

		var submitted:Array<String> = [];
		FinishedPage.kongStatSubmit = function(name:String, value:Int):Void {
			submitted.push(name + ":" + value);
		};
		page.setExpGain(10, 60, 100);
		assertEquals("+ 50", LobbyArt.text(page, "expTotal").text, "exp total is the gain delta");
		assertEquals("Exp Gained at Once:50", submitted.join("|"), "finished page submits Kong exp gain stat");
		FinishedPage.kongStatSubmit = null;

		// The rating control is added as a child.
		var hasStars = false;
		for (i in 0...page.numChildren) {
			if (Std.isOfType(page.getChildAt(i), RatingSelect)) {
				hasStars = true;
			}
		}
		assertEquals(true, hasStars, "rating control is attached");

		page.remove();
	}

	private static function testExpGainAnimation():Void {
		var exp = new ExpGain();
		assertEquals("assets/svg/effects/exp_progress_track_01.svg", ExpGain.TRACK_ASSET,
			"experience bar uses exact authored XFL track");
		assertEquals("assets/svg/effects/exp_progress_fill_01.svg", ExpGain.FILL_ASSET,
			"experience bar uses exact authored XFL fill");
		assertEquals(1, Math.round(exp.fillWidthForTests()), "experience fill starts at Flash's one-pixel width");
		var geometry = exp.textGeometryForTests();
		assertEquals(-9275, Math.round(geometry[0] * 100), "experience text preserves authored x");
		assertEquals(1395, Math.round(geometry[1] * 100), "experience text preserves authored y");
		assertEquals(18545, Math.round(geometry[2] * 100), "experience text preserves authored width");
		exp.start(0, 90, 100);
		// expStep = 90/45 = 2 per frame; readout uses floor(expStart).
		exp.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals("2 / 100", LobbyArt.text(exp, "textBox").text, "first frame steps by 2");
		for (_ in 0...44) {
			exp.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals("90 / 100", LobbyArt.text(exp, "textBox").text, "settles at expEnd after 45 frames");
		assertEquals(180, Math.round(exp.fillWidthForTests()), "fill settles at 200 times the authored rank ratio");
		exp.remove();
	}

	private static function testExpGainClamp():Void {
		var exp = new ExpGain();
		// Both ends past the rank cap collapse to the cap (AS3 clamps each end).
		exp.start(150, 200, 100);
		exp.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals("100 / 100", LobbyArt.text(exp, "textBox").text, "values past the cap clamp to to-rank");
		exp.remove();
	}

	private static function testRatingFromOffset():Void {
		// art width 100 at scale 1.5 => 150px wide control, five 30px bands.
		assertEquals(1.0, RatingSelect.ratingFromOffset(0, 100, 1.5), "left edge clamps up to 1");
		assertEquals(1.0, RatingSelect.ratingFromOffset(-20, 100, 1.5), "negative offset clamps to 1");
		assertEquals(3.0, RatingSelect.ratingFromOffset(75, 100, 1.5), "midpoint ceils to 3");
		assertEquals(5.0, RatingSelect.ratingFromOffset(150, 100, 1.5), "right edge is 5");
		assertEquals(5.0, RatingSelect.ratingFromOffset(999, 100, 1.5), "past the edge clamps to 5");
		assertEquals(1.0, RatingSelect.ratingFromOffset(50, 0, 1.5), "zero width falls back to 1");
	}

	private static function testNativeRatingMeter():Void {
		var rating = new RatingSelect(12345);
		assertEquals(3312, Math.round(rating.meterFillWidthForTests() * 100), "native star meter begins at the authored three-star width");
		assertEquals(false, rating.hoverVisibleForTests(), "native hover star begins off");
		assertEquals(1070, Math.round(rating.meterBackgroundHeightForTests() * 100),
			"rating background uses the 10.7px star geometry instead of an opaque 11px strip");
		rating.remove();
	}

	private static function closeAll():Void {
		FinishedPage.kongStatSubmit = null;
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertNear(expected:Float, actual:Float, tolerance:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) throw '$message: expected $expected +/- $tolerance, got $actual';
	}
}
