package pr2.runtime;

import pr2.generated.assets.AssetTypes.SymbolAssetDef;

/**
	Combined flatten decision: a subtree may be collapsed into a single cached quad
	only when it passes BOTH gates — `StaticSubtreeAnalyzer` (its output never
	changes over time) AND `FlattenSafetyGate` (flattening is render-safe under
	OpenFL HTML5: no stage-relative blend, no filter/mask needing verification).

	One shared analyzer + gate are reused so each symbol's verdict is computed once
	and memoized for the whole process (both gates cache per-symbol internally).
**/
class FlattenPolicy {
	static var analyzer:StaticSubtreeAnalyzer;
	static var gate:FlattenSafetyGate;

	public static function isFlattenable(symbol:SymbolAssetDef):Bool {
		if (analyzer == null) {
			analyzer = new StaticSubtreeAnalyzer();
			gate = new FlattenSafetyGate();
		}
		return analyzer.isStaticSymbol(symbol) && gate.isFlattenSafe(symbol);
	}

	private function new() {}
}
