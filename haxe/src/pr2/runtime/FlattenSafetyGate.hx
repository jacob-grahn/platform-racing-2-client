package pr2.runtime;

import haxe.ds.ObjectMap;
import pr2.generated.assets.AssetTypes.DisplayElementDef;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;
import pr2.generated.assets.AssetTypes.TimelineDef;

enum FlattenRisk {
	// A descendant carries a real (color-mixing) blend mode. Flattening the subtree
	// makes that blend composite against its siblings inside the cache bitmap rather
	// than against the stage content behind the subtree, which changes the result.
	DescendantBlendMode;
	// A descendant carries filters. Flattening generally preserves the look, but
	// OpenFL's HTML5 cacheAsBitmap/filter-bounds handling is exactly what the perf
	// TODO flags as needing runtime verification, so surface it for a decision.
	DescendantFilter;
	// The subtree uses Animate mask layers. cacheAsBitmap interacting with masks
	// (and scrollRect) under OpenFL HTML5 is unverified; flag for a runtime check.
	MaskLayer;
}

typedef FlattenRiskFinding = {
	var risk:FlattenRisk;
	var symbol:String; // the symbol the risky node lives in
	var detail:String; // element/layer name + the offending value, for triage
}

/**
	Second gate after `StaticSubtreeAnalyzer`: given a subtree that is provably
	*temporally* static, decides whether flattening it into a single quad (via
	`cacheAsBitmap` or a baked atlas) is *render-safe* under OpenFL's HTML5 path.

	Staticness is necessary but not sufficient: a frozen subtree can still change
	appearance or behavior when collapsed into one bitmap because of blend modes
	that composite against the stage, filters whose bounds OpenFL may mishandle, or
	masks whose cacheAsBitmap interaction is unverified.

	The gate returns the concrete risk findings rather than a bare boolean so the
	caller can decide which risks it tolerates (e.g. accept filters but never masks)
	and so an audit can explain *why* a static candidate was held back. A non-color
	blend value of "layer" — Animate's group-compositing default — is treated as
	safe because it composites with ordinary alpha.

	Interactivity (a flattened `Bitmap` receives no mouse/focus events) is out of
	scope here: it cannot be decided from the symbol def alone, since it depends on
	whether app code wires listeners onto a named descendant. Callers that flatten a
	subtree containing controls must confirm that separately.
**/
class FlattenSafetyGate {
	// Resolves a child symbol by library item name. Defaults to the generated
	// catalog; injectable for tests and tooling.
	public var resolveSymbol:String->Null<SymbolAssetDef>;

	public function new(?resolveSymbol:String->Null<SymbolAssetDef>) {
		this.resolveSymbol = resolveSymbol != null ? resolveSymbol : AssetLibrary.getSymbol;
	}

	/** No render-safety risks → the subtree can be flattened as-is. **/
	public function isFlattenSafe(symbol:SymbolAssetDef):Bool {
		return inspect(symbol).length == 0;
	}

	/** Every render-safety risk found in the subtree, with where and why. **/
	public function inspect(symbol:SymbolAssetDef):Array<FlattenRiskFinding> {
		var findings:Array<FlattenRiskFinding> = [];
		walkSymbol(symbol, new ObjectMap(), findings);
		return findings;
	}

	function walkSymbol(symbol:SymbolAssetDef, visiting:ObjectMap<SymbolAssetDef, Bool>, findings:Array<FlattenRiskFinding>):Void {
		if (visiting.exists(symbol) || symbol.timelines.length == 0) {
			return; // cycle guard / empty symbol
		}
		visiting.set(symbol, true);
		walkTimeline(symbol, symbol.timelines[0], null, visiting, findings);
		visiting.remove(symbol);
	}

	// `pinnedFrame` non-null restricts the walk to the single frame a "single frame"
	// instance freezes, mirroring StaticSubtreeAnalyzer so the gate inspects exactly
	// the content that is actually rendered.
	function walkTimeline(symbol:SymbolAssetDef, timeline:TimelineDef, pinnedFrame:Null<Int>, visiting:ObjectMap<SymbolAssetDef, Bool>,
			findings:Array<FlattenRiskFinding>):Void {
		var symbolName = symbol.name != null ? symbol.name : symbol.href;
		for (layer in timeline.layers) {
			if (layer.visible == false) {
				continue;
			}
			if (layer.layerType == "mask") {
				findings.push({
					risk: MaskLayer,
					symbol: symbolName,
					detail: 'mask layer "${layer.name != null ? layer.name : Std.string(layer.index)}"'
				});
			}
			for (frame in layer.frames) {
				if (pinnedFrame != null) {
					var start = frame.index == null ? 0 : frame.index;
					var duration = frame.duration == null ? 1 : frame.duration;
					if (pinnedFrame < start || pinnedFrame >= start + duration) {
						continue;
					}
				}
				if (frame.elements == null) {
					continue;
				}
				for (element in frame.elements) {
					walkElement(symbol, symbolName, element, visiting, findings);
				}
			}
		}
	}

	function walkElement(symbol:SymbolAssetDef, symbolName:String, element:DisplayElementDef, visiting:ObjectMap<SymbolAssetDef, Bool>,
			findings:Array<FlattenRiskFinding>):Void {
		if (isColorBlend(element.blendMode)) {
			findings.push({
				risk: DescendantBlendMode,
				symbol: symbolName,
				detail: 'element "${elementLabel(element)}" blendMode "${element.blendMode}"'
			});
		}
		if (element.filters != null && element.filters.length > 0) {
			findings.push({
				risk: DescendantFilter,
				symbol: symbolName,
				detail: 'element "${elementLabel(element)}" has ${element.filters.length} filter(s)'
			});
		}

		if (element.type == "DOMGroup") {
			if (element.children != null) {
				for (child in element.children) {
					walkElement(symbol, symbolName, child, visiting, findings);
				}
			}
			return;
		}

		if (element.libraryItemName == null || BakedSymbolAtlas.isBaked(element.libraryItemName)) {
			return; // leaf, or a baked single-bitmap symbol that is not descended into
		}

		var child = resolveSymbol(element.libraryItemName);
		if (child == null || child.timelines.length == 0) {
			return;
		}
		if (visiting.exists(child)) {
			return;
		}
		visiting.set(child, true);
		var pinned = element.loop == "single frame" ? (element.firstFrame == null ? 0 : element.firstFrame) : null;
		walkTimeline(child, child.timelines[0], pinned, visiting, findings);
		visiting.remove(child);
	}

	// "layer" is Animate's group-compositing mode and blends with ordinary alpha, so
	// it is safe to flatten. Only genuine color-mixing modes change the result.
	function isColorBlend(blendMode:Null<String>):Bool {
		return blendMode != null && blendMode != "normal" && blendMode != "layer";
	}

	function elementLabel(element:DisplayElementDef):String {
		if (element.name != null) {
			return element.name;
		}
		if (element.libraryItemName != null) {
			return element.libraryItemName;
		}
		return element.type;
	}
}
