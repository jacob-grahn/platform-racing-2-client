package pr2.page;

import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.animation.LottieTransform;

class IntroPageTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testNativeShell();
		testStandardLottieTransform();
		if (pr2.DeterministicTestMode.finishSmokeSuite("IntroPageTest")) return;
		testSiteQueues();
		testAnimationCompletionFrames();
		testSkipIsIdempotent();
		trace('IntroPageTest passed $assertions assertions');
	}

	private static function testStandardLottieTransform():Void {
		var transform:Dynamic = {
			a: {a: 0, k: [1, 2]},
			p: {a: 0, k: [10, 20]},
			s: {a: 0, k: [200, 300]},
			r: {a: 0, k: 90},
			o: {a: 0, k: 75},
			sk: {a: 0, k: 0},
			sa: {a: 0, k: 0}
		};
		var sample = LottieTransform.sample(transform, 0);
		assertClose(0, sample.matrix.a, "standard Lottie rotation matrix a");
		assertClose(2, sample.matrix.b, "standard Lottie scale matrix b");
		assertClose(-3, sample.matrix.c, "standard Lottie scale matrix c");
		assertClose(0, sample.matrix.d, "standard Lottie rotation matrix d");
		assertClose(16, sample.matrix.tx, "standard Lottie anchor adjusts X translation");
		assertClose(18, sample.matrix.ty, "standard Lottie anchor adjusts Y translation");
		assertClose(0.75, sample.opacity, "standard Lottie opacity is normalized");
	}

	private static function testNativeShell():Void {
		var view = new IntroPageView();
		assertEquals("introHolder", view.introHolder.name, "intro holder is explicitly named");
		assertEquals(2, view.numChildren, "native intro shell contains holder and skip prompt");
		assertEquals("skipPrompt", view.getChildAt(1).name, "skip prompt is explicitly named");
		assertEquals(5.0, view.getChildAt(1).x, "skip prompt retains its XFL left edge");
		assertEquals(381.15, view.getChildAt(1).y, "skip prompt retains its XFL baseline position");
		view.dispose();
	}

	private static function testSiteQueues():Void {
		assertQueue("inXile", "1");
		assertQueue("kongregate", "1,4");

		var single = new IntroPage("kongregate", "kongregate");
		@:privateAccess assertEquals("4", single.toPlay.join(","), "single-intro override selects requested intro");
		single.remove();
	}

	private static function assertQueue(site:String, expected:String):Void {
		var page = new IntroPage(site);
		@:privateAccess assertEquals(expected, page.toPlay.join(","), '$site intro queue');
		@:privateAccess assertEquals("skipHitArea", page.skipHitArea.name, "full-stage skip target is explicitly named");
		page.remove();
	}

	private static function testAnimationCompletionFrames():Void {
		assertSemanticTimeline("jiggmin", 231, 4, true, ["sound:logo_theme"]);
		assertSemanticTimeline("kongregate", 153, 145, false, []);
		testSourceSoundGraphMetadata();
		testAuthoredSoundMarker();
		assertCompletesAt("jiggmin", 231);
		assertCompletesAt("kongregate", 153);
	}

	private static function testSourceSoundGraphMetadata():Void {
		var animation = new IntroAnimationView("jiggmin");
		var metadata:Dynamic = animation.timeline.userMetadata;
		assertEquals("MovieClips/PR2_Graphics_1_Apr_2014_fla/Symbol 80", metadata.sourceSymbol, "Jiggmin metadata names the exported XFL symbol");
		assertEquals(231, metadata.sourceFrameCount, "Jiggmin metadata records the frame-by-frame source span");
		var reachable:Array<Dynamic> = cast metadata.reachableSoundCues;
		assertEquals(1, reachable.length, "only one sound cue is reachable from the exported intro symbol");
		assertEquals("0:logo_theme:true", '${reachable[0].frame}:${reachable[0].asset}:${reachable[0].reachable}', "reachable sound81 remains at XFL frame zero");
		var archival:Array<Dynamic> = cast metadata.archivalUnreachableSoundCues;
		assertEquals(8, archival.length, "all eight triggers across the seven archival sounds are preserved");
		assertEquals("1,1,7,31,36,76,84,84", [for (cue in archival) Std.string(cue.frame)].join(","), "archival sound trigger frames remain exact");
		assertEquals("intro_timeline_sound_01,intro_timeline_sound_02,intro_timeline_sound_03,intro_timeline_sound_04,intro_timeline_sound_05,intro_timeline_sound_01,intro_timeline_sound_06,intro_timeline_sound_07", [for (cue in archival) Std.string(cue.asset)].join(","), "archival sound assets remain mapped to their extracted files");
		assertEquals("4500:13000", '${archival[5].inPoint44}:${archival[5].outPoint44}', "archival repeated sound57 retains its sample trim");
		assertEquals("16236", Std.string(archival[7].envelope[0].level0), "archival sound68 retains its half-volume envelope");
		animation.dispose();
	}

	private static function assertSemanticTimeline(kind:String, totalFrames:Int, layerCount:Int, hasLogoAttachment:Bool, frameOneMarkers:Array<String>):Void {
		var animation = new IntroAnimationView(kind);
		assertEquals('assets/intro/$kind.lottie.json', animation.timeline.sourcePath, '$kind uses semantic Lottie data');
		assertEquals(27.0, animation.timeline.frameRate, '$kind retains the XFL document frame rate');
		assertEquals(totalFrames, animation.totalFrames, '$kind retains its authored duration');
		assertEquals(frameOneMarkers.join(","), animation.timeline.markersAtFrame(1).join(","), '$kind retains its authored frame-one cues');
		assertEquals(layerCount, animation.timeline.numChildren, '$kind builds reusable semantic layers');
		assertEquals(hasLogoAttachment, animation.timeline.attachment("logo_mc") != null, '$kind exposes only authored attachment points');
		if (kind == "jiggmin") assertEquals(true, animation.timeline.getChildByName("logo_backing") != null, "Jiggmin retains Symbol 75 behind the injected pixel effect");
		animation.timeline.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(2, animation.currentFrame, '$kind advances its semantic timeline');
		if (hasLogoAttachment) {
			animation.timeline.gotoAndStop(139);
			var logo = animation.timeline.attachment("logo_mc");
			if (logo == null) throw '$kind is missing its authored logo attachment';
			assertEquals(1, logo.filters.length, '$kind applies exact Flash glow from Lottie user metadata');
		}
		animation.dispose();
	}

	private static function testAuthoredSoundMarker():Void {
		var paths:Array<String> = [];
		var volumes:Array<Float> = [];
		var animation = new IntroAnimationView("jiggmin", function(path:String, volume:Float) {
			paths.push(path);
			volumes.push(volume);
			return null;
		});
		assertEquals("assets/audio/sfx/logo_theme.mp3", paths.join(","), "Jiggmin sound starts from its authored frame-one marker");
		assertEquals(pr2.lobby.account.Settings.soundLevel / 100, volumes[0], "Jiggmin sound honors the saved sound level");
		animation.timeline.gotoAndStop(1);
		assertEquals(2, paths.length, "re-entering the authored sound keyframe retriggers its event sound");
		animation.dispose();
	}

	private static function assertCompletesAt(kind:String, completeFrame:Int):Void {
		var animation = new IntroAnimationView(kind);
		var completes = 0;
		animation.addEventListener(Event.COMPLETE, function(_:Event):Void completes++);
		for (_ in 0...(completeFrame - 2)) animation.timeline.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(completeFrame - 1, animation.currentFrame, '$kind waits until its archival completion frame');
		assertEquals(0, completes, '$kind has not completed early');
		animation.timeline.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(completeFrame, animation.currentFrame, '$kind reaches its archival completion frame');
		assertEquals(1, completes, '$kind completes once');
		animation.timeline.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, completes, '$kind remains stopped after completion');
		animation.dispose();
	}

	private static function testSkipIsIdempotent():Void {
		var page = new IntroPage("inXile");
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

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}
}
