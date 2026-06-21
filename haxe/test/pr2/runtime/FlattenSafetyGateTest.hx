package pr2.runtime;

import pr2.runtime.FlattenSafetyGate.FlattenRisk;
import pr2.generated.assets.AssetTypes.DisplayElementDef;
import pr2.generated.assets.AssetTypes.FilterDef;
import pr2.generated.assets.AssetTypes.FrameDef;
import pr2.generated.assets.AssetTypes.LayerDef;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;

class FlattenSafetyGateTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testPlainSubtreeIsSafe();
		testLayerBlendModeIsSafe();
		testColorBlendModeIsRisk();
		testFilterIsRisk();
		testMaskLayerIsRisk();
		testRiskBubblesUpFromNestedChild();
		testSingleFramePinIgnoresUnpinnedFrameRisk();
		testBakedChildIsNotDescended();
		trace('FlattenSafetyGateTest passed $assertions assertions');
	}

	private static function testPlainSubtreeIsSafe():Void {
		var symbol = symbolWithLayers("Plain", [
			normalLayer(0, [heldFrame(0, 1, [shape("a"), staticText("t")])])
		]);
		assertSafe(symbol, new Map(), "plain shapes/text carry no flatten risk");
	}

	private static function testLayerBlendModeIsSafe():Void {
		var blended = shape("a");
		blended.blendMode = "layer"; // Animate group-compositing, ordinary alpha
		var symbol = symbolWithLayers("LayerBlend", [normalLayer(0, [heldFrame(0, 1, [blended])])]);
		assertSafe(symbol, new Map(), "\"layer\" blend mode is safe to flatten");
	}

	private static function testColorBlendModeIsRisk():Void {
		var blended = shape("a");
		blended.blendMode = "multiply";
		var symbol = symbolWithLayers("Multiply", [normalLayer(0, [heldFrame(0, 1, [blended])])]);
		assertRisks(symbol, new Map(), [DescendantBlendMode], "a color-mixing blend mode is a flatten risk");
	}

	private static function testFilterIsRisk():Void {
		var glow:FilterDef = {type: "GlowFilter", blurX: 4, blurY: 4, strength: 1};
		var filtered = shape("a");
		filtered.filters = [glow];
		var symbol = symbolWithLayers("Filtered", [normalLayer(0, [heldFrame(0, 1, [filtered])])]);
		assertRisks(symbol, new Map(), [DescendantFilter], "a descendant filter is a flatten risk");
	}

	private static function testMaskLayerIsRisk():Void {
		var symbol = symbolWithLayers("Masked", [
			maskLayer(0, [heldFrame(0, 1, [shape("clip")])]),
			normalLayer(1, [heldFrame(0, 1, [shape("content")])])
		]);
		assertRisks(symbol, new Map(), [MaskLayer], "a mask layer is a flatten risk");
	}

	private static function testRiskBubblesUpFromNestedChild():Void {
		var blended = shape("inner");
		blended.blendMode = "screen";
		var child = symbolWithLayers("RiskyChild", [normalLayer(0, [heldFrame(0, 1, [blended])])]);
		var parent = symbolWithLayers("CleanParent", [
			normalLayer(0, [heldFrame(0, 1, [instance("c", "RiskyChild", null, 0)])])
		]);
		assertRisks(parent, ["RiskyChild" => child], [DescendantBlendMode],
			"a risk inside a nested child surfaces at the parent");
	}

	private static function testSingleFramePinIgnoresUnpinnedFrameRisk():Void {
		var risky = shape("poseB");
		risky.blendMode = "overlay";
		// Frame 0 is clean; frame 1 carries the blend. The instance pins frame 0.
		var child = symbolWithLayers("Poses", [
			normalLayer(0, [heldFrame(0, 1, [shape("poseA")]), heldFrame(1, 1, [risky])])
		]);
		var parent = symbolWithLayers("PinHolder", [
			normalLayer(0, [heldFrame(0, 1, [instance("pose", "Poses", "single frame", 0)])])
		]);
		assertSafe(parent, ["Poses" => child], "a single-frame pin ignores risk on frames it does not show");
	}

	private static function testBakedChildIsNotDescended():Void {
		// The baked symbol is a single Bitmap; the gate must not try to resolve or
		// walk into it even though no resolver entry exists.
		var parent = symbolWithLayers("IntroHolder", [
			normalLayer(0, [heldFrame(0, 1, [instance("logo", "MovieClips/Symbol 27", "loop", 0)])])
		]);
		assertSafe(parent, new Map(), "a baked-atlas child is treated as one safe bitmap");
	}

	// --- fixtures -----------------------------------------------------------

	private static function shape(name:String):DisplayElementDef {
		return {type: "DOMShape", name: name, bounds: {left: 0, top: 0, right: 10, bottom: 10}};
	}

	private static function staticText(name:String):DisplayElementDef {
		return {type: "DOMStaticText", name: name, text: "hi"};
	}

	private static function instance(name:String, libraryItemName:String, loop:Null<String>, firstFrame:Int):DisplayElementDef {
		return {type: "DOMSymbolInstance", name: name, libraryItemName: libraryItemName, loop: loop, firstFrame: firstFrame};
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

	private static function normalLayer(index:Int, frames:Array<FrameDef>):LayerDef {
		return layer(index, "normal", frames);
	}

	private static function maskLayer(index:Int, frames:Array<FrameDef>):LayerDef {
		return layer(index, "mask", frames);
	}

	private static function layer(index:Int, layerType:String, frames:Array<FrameDef>):LayerDef {
		return {
			index: index,
			name: "Layer " + index,
			visible: true,
			locked: false,
			layerType: layerType,
			frameCount: frames.length,
			frames: frames
		};
	}

	private static function symbolWithLayers(name:String, layers:Array<LayerDef>):SymbolAssetDef {
		var frameCount = 1;
		for (l in layers) {
			for (frame in l.frames) {
				var end = frame.index + frame.duration;
				if (end > frameCount) {
					frameCount = end;
				}
			}
		}
		return {
			href: name + ".xml",
			type: "movie clip",
			name: name,
			linkageClassName: name,
			linkageIdentifier: name,
			timelines: [{name: name, layerCount: layers.length, frameCount: frameCount, labels: [], layers: layers}]
		};
	}

	private static function gateFor(byName:Map<String, SymbolAssetDef>):FlattenSafetyGate {
		return new FlattenSafetyGate(function(name) return byName.get(name));
	}

	private static function assertSafe(symbol:SymbolAssetDef, byName:Map<String, SymbolAssetDef>, message:String):Void {
		var findings = gateFor(byName).inspect(symbol);
		assertions++;
		if (findings.length != 0) {
			throw 'FlattenSafetyGateTest failed: $message (expected no risks, got ${[for (f in findings) f.detail]})';
		}
	}

	private static function assertRisks(symbol:SymbolAssetDef, byName:Map<String, SymbolAssetDef>, expected:Array<FlattenRisk>, message:String):Void {
		var gate = gateFor(byName);
		assertions++;
		if (gate.isFlattenSafe(symbol)) {
			throw 'FlattenSafetyGateTest failed: $message (expected risks, got none)';
		}
		var got = [for (finding in gate.inspect(symbol)) finding.risk];
		for (risk in expected) {
			if (got.indexOf(risk) < 0) {
				throw 'FlattenSafetyGateTest failed: $message (expected risk $risk, got $got)';
			}
		}
	}
}
