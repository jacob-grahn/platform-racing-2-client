package pr2.runtime;

import haxe.ds.ObjectMap;
import pr2.generated.assets.AssetTypes.DisplayElementDef;
import pr2.generated.assets.AssetTypes.TimelineDef;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;

/**
	Decides whether a symbol's rendered output is invariant over time: i.e. once a
	`PR2MovieClip` of it reaches frame 1, does any pixel it draws ever change?

	This is the shared prerequisite for flattening a subtree into a single quad,
	whether at runtime via `cacheAsBitmap` or ahead of time via a baked atlas. A
	"static" subtree can be flattened with no invalidation logic, because there is
	provably nothing to invalidate.

	The analyzer mirrors the *runtime* behavior of `PR2MovieClip`, not the authored
	intent, because the runtime is what actually animates:

	- A layer changes its drawn elements over time iff it has more than one keyframe
	  (`PR2MovieClip.applyLayer` holds a single keyframe across its whole duration,
	  and does not interpolate tweens — so a single keyframe renders identically on
	  every frame it spans).
	- Leaf visuals (`DOMShape`/`DOMRectangleObject`/`DOMOvalObject`/`DOMStaticText`)
	  are pure functions of their element def — always static.
	- A `DOMComponentInstance` is interactive and holds its own state — never static.
	- A nested symbol instance animates iff it auto-plays a multi-frame timeline.
	  `PR2MovieClip` auto-plays any instance whose loop mode is not "single frame"
	  when its symbol has more than one frame (the constructor calls `play()` for
	  `totalFrames > 1`); a "single frame" instance is pinned via `gotoAndStop` and
	  shows exactly one frame.

	Staticness only concerns *temporal* change. Whether a static subtree is also
	*safe* to flatten under OpenFL's HTML5 renderer (masks, filters, blend modes,
	hit-testing) is a separate gate the caller must apply on top of this.
**/
class StaticSubtreeAnalyzer {
	// Resolves a child symbol by library item name. Defaults to the generated
	// catalog; tests and tools inject a fixture resolver so the cross-symbol
	// recursion can be exercised without (or alongside) `AssetCatalog`.
	public var resolveSymbol:String->Null<SymbolAssetDef>;

	// Memoizes the static verdict per symbol. Symbols recur heavily across the
	// catalog and are immutable build data, so a symbol resolves to one answer.
	final cache = new ObjectMap<SymbolAssetDef, Bool>();

	public function new(?resolveSymbol:String->Null<SymbolAssetDef>) {
		this.resolveSymbol = resolveSymbol != null ? resolveSymbol : AssetLibrary.getSymbol;
	}

	/**
		True when a `PR2MovieClip` of `symbol`, played normally from frame 1, never
		changes its rendered output — the whole descendant tree included.
	**/
	public function isStaticSymbol(symbol:SymbolAssetDef):Bool {
		return evalSymbol(symbol, new ObjectMap());
	}

	// `visiting` holds the symbols on the current recursion path. A back-edge onto
	// one of them is a reference cycle: it returns `true` so the cycle edge itself
	// cannot veto staticness. Any genuinely animated member of the cycle is still
	// caught by its own timeline check when that member is first visited, so the
	// short-circuit only breaks the recursion, it does not hide animation.
	function evalSymbol(symbol:SymbolAssetDef, visiting:ObjectMap<SymbolAssetDef, Bool>):Bool {
		if (cache.exists(symbol)) {
			return cache.get(symbol);
		}
		if (visiting.exists(symbol)) {
			return true;
		}
		visiting.set(symbol, true);

		var result = symbol.timelines.length == 0 || evalTimeline(symbol.timelines[0], visiting);

		visiting.remove(symbol);
		cache.set(symbol, result);
		return result;
	}

	// A timeline is static iff every layer holds a single keyframe (no temporal
	// change) and every element it ever draws is itself static.
	function evalTimeline(timeline:TimelineDef, visiting:ObjectMap<SymbolAssetDef, Bool>):Bool {
		for (layer in timeline.layers) {
			if (layer.visible == false) {
				continue; // hidden layers are never rendered (PR2MovieClip.applyLayer)
			}
			if (layer.frames.length > 1) {
				return false; // more than one keyframe → drawn elements change over time
			}
			for (frame in layer.frames) {
				if (frame.elements == null) {
					continue;
				}
				for (element in frame.elements) {
					if (!evalElement(element, visiting)) {
						return false;
					}
				}
			}
		}
		return true;
	}

	function evalElement(element:DisplayElementDef, visiting:ObjectMap<SymbolAssetDef, Bool>):Bool {
		switch (element.type) {
			case "DOMShape" | "DOMRectangleObject" | "DOMOvalObject" | "DOMStaticText":
				return true;
			case "DOMComponentInstance":
				return false; // interactive component, holds its own state
			case "DOMGroup":
				if (element.children == null) {
					return true;
				}
				for (child in element.children) {
					if (!evalElement(child, visiting)) {
						return false;
					}
				}
				return true;
			default:
		}

		if (element.libraryItemName == null) {
			return true; // no symbol → rendered as a static vector shape or placeholder
		}
		if (BakedSymbolAtlas.isBaked(element.libraryItemName)) {
			return true; // already collapsed to a single static Bitmap
		}

		var child = resolveSymbol(element.libraryItemName);
		if (child == null) {
			// Bitmap media is currently rendered by the explicit bitmap fallback;
			// an unresolved symbol is rejected by PR2MovieClip and must never make a
			// subtree eligible for flattening.
			return element.type == "DOMBitmapInstance";
		}

		// A "single frame" instance is pinned with gotoAndStop and never advances,
		// so only the one displayed frame matters. Any other loop mode auto-plays a
		// multi-frame child, so the child must be fully static on its own timeline.
		if (element.loop == "single frame") {
			return evalPinnedFrame(child, element.firstFrame == null ? 0 : element.firstFrame, visiting);
		}
		return evalSymbol(child, visiting);
	}

	// Evaluates only the elements visible at a single pinned frame, mirroring
	// `PR2MovieClip.applyLayer`'s held-keyframe expansion. Lets a "single frame"
	// instance of an otherwise-animated symbol still count as static when the
	// specific pose it freezes is static.
	function evalPinnedFrame(symbol:SymbolAssetDef, frameIndex:Int, visiting:ObjectMap<SymbolAssetDef, Bool>):Bool {
		if (symbol.timelines.length == 0) {
			return true;
		}
		if (visiting.exists(symbol)) {
			return true; // cycle guard, same rationale as evalSymbol
		}
		visiting.set(symbol, true);

		var result = true;
		var timeline = symbol.timelines[0];
		for (layer in timeline.layers) {
			if (layer.visible == false) {
				continue;
			}
			for (frame in layer.frames) {
				var start = frame.index == null ? 0 : frame.index;
				var duration = frame.duration == null ? 1 : frame.duration;
				if (frameIndex < start || frameIndex >= start + duration) {
					continue; // this keyframe is not the one shown at frameIndex
				}
				if (frame.elements == null) {
					continue;
				}
				for (element in frame.elements) {
					if (!evalElement(element, visiting)) {
						result = false;
						break;
					}
				}
			}
			if (!result) {
				break;
			}
		}

		visiting.remove(symbol);
		return result;
	}
}
