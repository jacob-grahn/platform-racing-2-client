package pr2.gameplay;

import openfl.events.Event;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.Popup;
import pr2.ui.RatingSelect;

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
		testExpGainAnimation();
		testExpGainClamp();
		testRatingFromOffset();
		closeAll();
		trace('FinishedPageTest passed $assertions assertions');
	}

	private static function testAwardsAndExpTotal():Void {
		var page = new FinishedPage(12345);

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
		exp.start(0, 90, 100);
		// expStep = 90/45 = 2 per frame; readout uses floor(expStart).
		exp.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals("2 / 100", LobbyArt.text(exp, "textBox").text, "first frame steps by 2");
		for (_ in 0...44) {
			exp.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals("90 / 100", LobbyArt.text(exp, "textBox").text, "settles at expEnd after 45 frames");
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
}
