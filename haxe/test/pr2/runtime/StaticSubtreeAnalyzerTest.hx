package pr2.runtime;

import pr2.generated.assets.AssetTypes.DisplayElementDef;
import pr2.generated.assets.AssetTypes.FrameDef;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;

class StaticSubtreeAnalyzerTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testLeafShapesAreStatic();
		if (pr2.DeterministicTestMode.finishSmokeSuite("StaticSubtreeAnalyzerTest")) return;
		testMultiKeyframeLayerIsAnimated();
		testHeldKeyframeAcrossFramesIsStatic();
		testComponentInstanceIsAnimated();
		testAutoPlayedMultiFrameChildIsAnimated();
		testSingleFramePinFreezesAnimatedChild();
		testSingleFramePinOntoAnimatedPoseStaysAnimated();
		testNestedStaticSymbolIsStatic();
		testReferenceCycleResolvesWithoutHanging();
		testBakedSymbolIsStatic();
		trace('StaticSubtreeAnalyzerTest passed $assertions assertions');
	}

	private static function testLeafShapesAreStatic():Void {
		var symbol = symbolWithFrames("Leaf", [
			heldFrame(0, 1, [shape("a"), staticText("label")])
		]);
		assertStatic(symbol, true, "a single held keyframe of leaf shapes/text is static");
	}

	private static function testMultiKeyframeLayerIsAnimated():Void {
		// Two keyframes on one layer means the drawn elements change over time.
		var symbol = symbolWithFrames("Animated", [
			heldFrame(0, 1, [shape("a")]),
			heldFrame(1, 1, [shape("b")])
		]);
		assertStatic(symbol, false, "a layer with two keyframes is animated");
	}

	private static function testHeldKeyframeAcrossFramesIsStatic():Void {
		// One keyframe spanning many frames renders identically each frame.
		var symbol = symbolWithFrames("Held", [
			heldFrame(0, 30, [shape("a")])
		]);
		symbol.timelines[0].frameCount = 30;
		assertStatic(symbol, true, "one keyframe held across 30 frames is static");
	}

	private static function testComponentInstanceIsAnimated():Void {
		var component:DisplayElementDef = {type: "DOMComponentInstance", name: "input"};
		var symbol = symbolWithFrames("WithComponent", [heldFrame(0, 1, [component])]);
		assertStatic(symbol, false, "an interactive component instance is never static");
	}

	private static function testAutoPlayedMultiFrameChildIsAnimated():Void {
		var child = symbolWithFrames("Spinner", [
			heldFrame(0, 1, [shape("a")]),
			heldFrame(1, 1, [shape("b")])
		]);
		var parent = symbolWithFrames("Holder", [
			heldFrame(0, 1, [instance("spinner", "Spinner", null, 0)])
		]);
		assertStaticWith(parent, ["Spinner" => child], false,
			"a default-loop instance of a multi-frame child auto-plays, so the parent is animated");
	}

	private static function testSingleFramePinFreezesAnimatedChild():Void {
		// The child animates on its own, but the instance pins one static pose.
		var child = symbolWithFrames("Poses", [
			heldFrame(0, 1, [shape("poseA")]),
			heldFrame(1, 1, [shape("poseB")])
		]);
		var parent = symbolWithFrames("PinnedHolder", [
			heldFrame(0, 1, [instance("pose", "Poses", "single frame", 1)])
		]);
		assertStaticWith(parent, ["Poses" => child], true,
			"a single-frame pin onto a static pose freezes the animated child");
	}

	private static function testSingleFramePinOntoAnimatedPoseStaysAnimated():Void {
		var grandchild = symbolWithFrames("InnerSpin", [
			heldFrame(0, 1, [shape("x")]),
			heldFrame(1, 1, [shape("y")])
		]);
		// The pinned frame itself contains an auto-playing multi-frame instance.
		var child = symbolWithFrames("OuterPoses", [
			heldFrame(0, 1, [shape("poseA")]),
			heldFrame(1, 1, [instance("spin", "InnerSpin", null, 0)])
		]);
		var parent = symbolWithFrames("PinnedHolder2", [
			heldFrame(0, 1, [instance("pose", "OuterPoses", "single frame", 1)])
		]);
		assertStaticWith(parent, ["OuterPoses" => child, "InnerSpin" => grandchild], false,
			"a single-frame pin onto a pose that contains an auto-playing clip is still animated");
	}

	private static function testNestedStaticSymbolIsStatic():Void {
		var child = symbolWithFrames("StaticChild", [heldFrame(0, 1, [shape("a")])]);
		var parent = symbolWithFrames("StaticParent", [
			heldFrame(0, 1, [instance("c", "StaticChild", null, 0)])
		]);
		assertStaticWith(parent, ["StaticChild" => child], true,
			"a single-frame static child does not animate when nested");
	}

	private static function testReferenceCycleResolvesWithoutHanging():Void {
		// A references B, B references A — both single-frame pins of leaf shapes.
		var a = symbolWithFrames("CycleA", [
			heldFrame(0, 1, [shape("leafA"), instance("b", "CycleB", "single frame", 0)])
		]);
		var b = symbolWithFrames("CycleB", [
			heldFrame(0, 1, [shape("leafB"), instance("a", "CycleA", "single frame", 0)])
		]);
		assertStaticWith(a, ["CycleA" => a, "CycleB" => b], true,
			"a reference cycle of static symbols resolves to static without hanging");
	}

	private static function testBakedSymbolIsStatic():Void {
		// A symbol the BakedSymbolAtlas replaces with a single Bitmap, referenced
		// here with a loop mode that would otherwise auto-play.
		var parent = symbolWithFrames("IntroHolder", [
			heldFrame(0, 1, [instance("logo", "MovieClips/Symbol 27", "loop", 0)])
		]);
		// No resolver entry: the baked check must short-circuit before resolution.
		assertStaticWith(parent, new Map(), true,
			"a baked-atlas symbol counts as a single static quad regardless of loop mode");
	}

	// --- fixtures -----------------------------------------------------------

	private static function shape(name:String):DisplayElementDef {
		return {type: "DOMShape", name: name, bounds: {left: 0, top: 0, right: 10, bottom: 10}};
	}

	private static function staticText(name:String):DisplayElementDef {
		return {type: "DOMStaticText", name: name, text: "hello"};
	}

	private static function instance(name:String, libraryItemName:String, loop:Null<String>, firstFrame:Int):DisplayElementDef {
		return {
			type: "DOMSymbolInstance",
			name: name,
			libraryItemName: libraryItemName,
			loop: loop,
			firstFrame: firstFrame
		};
	}

	private static function heldFrame(index:Int, duration:Int, elements:Array<DisplayElementDef>):FrameDef {
		return {
			index: index,
			duration: duration,
			elementCount: elements.length,
			elementTypes: [for (element in elements) element.type],
			elements: elements
		};
	}

	private static function symbolWithFrames(name:String, frames:Array<FrameDef>):SymbolAssetDef {
		var frameCount = 1;
		for (frame in frames) {
			var end = frame.index + frame.duration;
			if (end > frameCount) {
				frameCount = end;
			}
		}
		return {
			href: name + ".xml",
			type: "movie clip",
			name: name,
			linkageClassName: name,
			linkageIdentifier: name,
			timelines: [{
				name: name,
				layerCount: 1,
				frameCount: frameCount,
				labels: [],
				layers: [{
					index: 0,
					name: "Layer 1",
					visible: true,
					locked: false,
					layerType: "normal",
					frameCount: frames.length,
					frames: frames
				}]
			}]
		};
	}

	private static function assertStatic(symbol:SymbolAssetDef, expected:Bool, message:String):Void {
		assertStaticWith(symbol, new Map(), expected, message);
	}

	private static function assertStaticWith(symbol:SymbolAssetDef, byName:Map<String, SymbolAssetDef>, expected:Bool, message:String):Void {
		var analyzer = new StaticSubtreeAnalyzer(function(name) return byName.get(name));
		assertEquals(expected, analyzer.isStaticSymbol(symbol), message);
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw 'StaticSubtreeAnalyzerTest failed: $message (expected $expected, got $actual)';
		}
	}
}
