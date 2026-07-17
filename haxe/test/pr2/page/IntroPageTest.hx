package pr2.page;

import openfl.events.Event;
import openfl.events.MouseEvent;

class IntroPageTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testNativeShell();
		if (pr2.DeterministicTestMode.finishSmokeSuite("IntroPageTest")) return;
		testSiteQueues();
		testAnimationCompletionFrames();
		testSkipIsIdempotent();
		trace('IntroPageTest passed $assertions assertions');
	}

	private static function testNativeShell():Void {
		var view = new IntroPageView();
		assertEquals("introHolder", view.introHolder.name, "intro holder is explicitly named");
		assertEquals(2, view.numChildren, "native intro shell contains holder and skip prompt");
		assertEquals("skipPrompt", view.getChildAt(1).name, "skip prompt is explicitly named");
		view.dispose();
	}

	private static function testSiteQueues():Void {
		assertQueue("inXile", "1");
		assertQueue("bubbleBox", "1,3");
		assertQueue("armorGames", "1,2");
		assertQueue("kongregate", "1,4");

		var single = new IntroPage("kongregate", "bubblebox");
		@:privateAccess assertEquals("3", single.toPlay.join(","), "single-intro override selects requested intro");
		single.remove();
	}

	private static function assertQueue(site:String, expected:String):Void {
		var page = new IntroPage(site);
		@:privateAccess assertEquals(expected, page.toPlay.join(","), '$site intro queue');
		@:privateAccess assertEquals("skipHitArea", page.skipHitArea.name, "full-stage skip target is explicitly named");
		page.remove();
	}

	private static function testAnimationCompletionFrames():Void {
		assertCompletesAt("jiggmin", 249, 231);
		assertCompletesAt("kongregate", 153, 153);
		assertCompletesAt("armor", 218, 218);
		assertCompletesAt("bubblebox", 117, 117);
	}

	private static function assertCompletesAt(kind:String, totalFrames:Int, completeFrame:Int):Void {
		var animation = new IntroAnimationView(kind, totalFrames, completeFrame);
		var completes = 0;
		animation.addEventListener(Event.COMPLETE, function(_:Event):Void completes++);
		for (_ in 0...(completeFrame - 2)) animation.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(completeFrame - 1, animation.currentFrame, '$kind waits until its archival completion frame');
		assertEquals(0, completes, '$kind has not completed early');
		animation.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(completeFrame, animation.currentFrame, '$kind reaches its archival completion frame');
		assertEquals(1, completes, '$kind completes once');
		animation.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, completes, '$kind remains stopped after completion');
		animation.dispose();
	}

	private static function testSkipIsIdempotent():Void {
		var page = new IntroPage("armorGames");
		@:privateAccess page.skipHitArea.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		@:privateAccess assertEquals(true, page.ended, "clicking full-stage hit area ends intro");
		@:privateAccess page.endIntro();
		@:privateAccess assertEquals(true, page.ended, "repeated skip remains safely ended");
		page.remove();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
