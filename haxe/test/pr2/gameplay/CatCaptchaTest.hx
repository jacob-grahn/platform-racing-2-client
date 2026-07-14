package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import pr2.gameplay.CatCaptcha.CaptchaAnswer;
import pr2.lobby.dialogs.Popup;

class CatCaptchaTest {
	private static var assertions:Int = 0;
	private static var submitted:Array<Int> = [];
	private static final originalLoad = CatCaptcha.loadFactory;
	private static final originalSubmit = CatCaptcha.submitFactory;
	private static final originalImage = CatCaptcha.imageFactory;

	public static function main():Void {
		testChallengeShowsTwoAnswers();
		if (pr2.DeterministicTestMode.finishSmokeSuite("CatCaptchaTest")) return;
		testClickSubmitsAndFades();
		restoreFactories();
		trace('CatCaptchaTest passed $assertions assertions');
	}

	private static function testChallengeShowsTwoAnswers():Void {
		resetFactories();
		CatCaptcha.loadFactory = function(onReady, _):Void onReady();
		CatCaptcha.imageFactory = function(id:Int):CaptchaAnswer return new FakeAnswer(id);

		var popup = new CatCaptcha();
		assertEquals(2, countAnswers(popup), "challenge creates two answer images");
		var first = answerAt(popup, 0);
		var second = answerAt(popup, 1);
		assertEquals(-215.0, first.x, "first answer x");
		assertEquals(-91.0, first.y, "first answer y");
		assertEquals(5.0, second.x, "second answer x");
		assertEquals(-91.0, second.y, "second answer y");
		popup.remove();
	}

	private static function testClickSubmitsAndFades():Void {
		resetFactories();
		CatCaptcha.loadFactory = function(onReady, _):Void onReady();
		CatCaptcha.imageFactory = function(id:Int):CaptchaAnswer return new FakeAnswer(id);
		CatCaptcha.submitFactory = function(answer:Int, onDone, _):Void {
			submitted.push(answer);
			onDone();
		};

		var popup = new CatCaptcha();
		answerAt(popup, 1).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, submitted.length, "one answer submitted");
		assertEquals(1, submitted[0], "clicked answer id submitted");
		assertEquals(true, popup.fadeOutStarted, "submit starts fade out");
		answerAt(popup, 0).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, submitted.length, "fade-out ignores later clicks");
		popup.remove();
	}

	private static function countAnswers(popup:CatCaptcha):Int {
		var count = 0;
		for (i in 0...popup.numChildren) {
			var child = popup.getChildAt(i);
			if (Std.isOfType(child, FakeAnswerSprite)) {
				count++;
			}
			if (Std.isOfType(child, openfl.display.DisplayObjectContainer)) {
				var container:openfl.display.DisplayObjectContainer = cast child;
				for (j in 0...container.numChildren) {
					if (Std.isOfType(container.getChildAt(j), FakeAnswerSprite)) {
						count++;
					}
				}
			}
		}
		return count;
	}

	private static function answerAt(popup:CatCaptcha, index:Int):DisplayObject {
		var seen = 0;
		for (i in 0...popup.numChildren) {
			var child = popup.getChildAt(i);
			if (Std.isOfType(child, openfl.display.DisplayObjectContainer)) {
				var container:openfl.display.DisplayObjectContainer = cast child;
				for (j in 0...container.numChildren) {
					var candidate = container.getChildAt(j);
					if (Std.isOfType(candidate, FakeAnswerSprite)) {
						if (seen == index) {
							return candidate;
						}
						seen++;
					}
				}
			}
		}
		throw 'answer $index not found';
	}

	private static function resetFactories():Void {
		submitted.resize(0);
		CatCaptcha.loadFactory = function(_, onError):Void onError();
		CatCaptcha.submitFactory = function(_, _, onError):Void onError();
		CatCaptcha.imageFactory = function(id:Int):CaptchaAnswer return new FakeAnswer(id);
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function restoreFactories():Void {
		resetFactories();
		CatCaptcha.loadFactory = originalLoad;
		CatCaptcha.submitFactory = originalSubmit;
		CatCaptcha.imageFactory = originalImage;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}

private class FakeAnswer implements CaptchaAnswer {
	public var id(default, null):Int;
	public var display(default, null):DisplayObject;

	public function new(id:Int) {
		this.id = id;
		display = new FakeAnswerSprite();
	}

	public function remove():Void {
		if (display.parent != null) {
			display.parent.removeChild(display);
		}
	}
}

private class FakeAnswerSprite extends Sprite {
	public function new() {
		super();
	}
}
