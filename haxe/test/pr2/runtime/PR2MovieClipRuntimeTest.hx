package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.events.Event;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;

class PR2MovieClipRuntimeTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testTimelineControls();
		testFrameScriptHooks();
		testNamedChildAccessAndElementProperties();
		trace('PR2MovieClipRuntimeTest passed $assertions assertions');
	}

	private static function testTimelineControls():Void {
		var clip = new PR2MovieClip(makeSymbol());

		assertEquals(1, clip.currentFrame, "constructor starts on frame 1");
		assertEquals(4, clip.totalFrames, "totalFrames expands layer frame durations");
		assertEquals(2, clip.currentLabels.length, "currentLabels exposes timeline labels");
		assertEquals("intro", clip.currentLabels[0].name, "first label name");
		assertEquals(1, clip.currentLabels[0].frame, "first label frame is one-based");
		assertEquals("middle", clip.currentLabels[1].name, "second label name");
		assertEquals(3, clip.currentLabels[1].frame, "second label frame is one-based");

		clip.gotoAndStop(3);
		assertEquals(3, clip.currentFrame, "gotoAndStop accepts numeric frames");
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(3, clip.currentFrame, "stop prevents enter-frame advancement");

		clip.gotoAndStop("intro");
		assertEquals(1, clip.currentFrame, "gotoAndStop resolves labels");

		clip.gotoAndPlay("middle");
		assertEquals(3, clip.currentFrame, "gotoAndPlay resolves labels before playing");
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(4, clip.currentFrame, "play advances on enter-frame");
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, clip.currentFrame, "play wraps after the final frame");

		assertThrows(function() clip.gotoAndStop(0), "frame 0 is rejected");
		assertThrows(function() clip.gotoAndStop(5), "frame past totalFrames is rejected");
		assertThrows(function() clip.gotoAndStop("missing"), "unknown labels are rejected");
	}

	private static function testFrameScriptHooks():Void {
		var clip = new PR2MovieClip(makeSymbol());
		var hits:Array<Int> = [];

		clip.setFrameScript(2, function() hits.push(clip.currentFrame));
		clip.gotoAndStop(3);
		assertEquals("3", hits.join(","), "frame scripts run after gotoAndStop renders target frame");

		clip.gotoAndPlay(2);
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals("3,3", hits.join(","), "frame scripts run during playback");

		clip.setFrameScript(2, null);
		clip.gotoAndStop(3);
		assertEquals("3,3", hits.join(","), "null frame script clears hook");

		assertThrows(function() clip.setFrameScript(-1, function() {}), "negative frame-script indexes are rejected");
		assertThrows(function() clip.setFrameScript(4, function() {}), "frame-script indexes past totalFrames are rejected");
	}

	private static function testNamedChildAccessAndElementProperties():Void {
		var clip = new PR2MovieClip(makeSymbol());

		assertEquals(2, clip.numChildren, "frame 1 renders visible timeline elements");

		var marker = clip.getChildByTimelineName("marker");
		assertNotNull(marker, "named children can be found");
		assertEquals("marker", marker.name, "timeline child name is applied");
		assertClose(12, marker.transform.matrix.tx, "matrix tx is applied");
		assertClose(34, marker.transform.matrix.ty, "matrix ty is applied");
		assertClose(0.5, marker.transform.colorTransform.alphaMultiplier, "color transform is applied");

		var hidden = clip.getChildByTimelineName("hidden");
		assertNotNull(hidden, "invisible named children are still addressable");
		assertEquals(false, hidden.visible, "visible=false is applied");

		clip.gotoAndStop(3);
		assertEquals(null, clip.getChildByTimelineName("marker"), "old frame children are removed");
		assertNotNull(clip.getChildByTimelineName("middleMarker"), "new frame children are rendered");
	}

	private static function makeSymbol():SymbolAssetDef {
		return {
			href: "TestSymbol.xml",
			type: "movie clip",
			name: "TestSymbol",
			linkageClassName: "TestSymbol",
			linkageIdentifier: "TestSymbol",
			timelines: [{
				name: "TestSymbol",
				layerCount: 1,
				frameCount: 4,
				labels: [
					{name: "intro", frame: 0, layer: 0},
					{name: "middle", frame: 2, layer: 0}
				],
				layers: [{
					index: 0,
					name: "Layer 1",
					visible: true,
					locked: false,
					layerType: "normal",
					frameCount: 2,
					frames: [
						{
							index: 0,
							duration: 2,
							elementCount: 2,
							elementTypes: ["DOMShape", "DOMShape"],
							elements: [
								{
									type: "DOMShape",
									name: "marker",
									bounds: {left: 0, top: 0, right: 10, bottom: 10},
									matrix: {tx: 12, ty: 34},
									color: {alphaMultiplier: 0.5}
								},
								{
									type: "DOMShape",
									name: "hidden",
									visible: false,
									bounds: {left: 0, top: 0, right: 5, bottom: 5}
								}
							]
						},
						{
							index: 2,
							duration: 2,
							elementCount: 1,
							elementTypes: ["DOMShape"],
							elements: [{
								type: "DOMShape",
								name: "middleMarker",
								bounds: {left: 0, top: 0, right: 20, bottom: 20}
							}]
						}
					]
				}]
			}]
		};
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) {
			throw message;
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.0001) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertThrows(action:Void->Void, message:String):Void {
		assertions++;
		try {
			action();
		} catch (_:Dynamic) {
			return;
		}
		throw message;
	}
}
