package pr2.tools;

import pr2.generated.assets.AssetCatalog;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;
import pr2.runtime.AssetLibrary;
import pr2.runtime.FlattenSafetyGate;
import pr2.runtime.FlattenSafetyGate.FlattenRisk;
import pr2.runtime.StaticSubtreeAnalyzer;

/**
	Dev harness: prints the static / animated partition that
	`StaticSubtreeAnalyzer` produces over the asset catalog, so flatten candidates
	can be eyeballed before any `cacheAsBitmap` / baked-atlas work.

	Run via `tools/lobby_static_audit.hxml` (haxe --interp; no assets needed).
	Under `--interp`, `Sys.args()` is the compiler command line, so roots are taken
	from the `AUDIT_ROOTS` environment variable instead.

	- Default (no `AUDIT_ROOTS`): partitions the whole catalog and lists the
	  animated symbols (the ones that cannot be naively flattened) plus a summary.
	- `AUDIT_ROOTS=HalfSquareBG,SomeOtherClip`: treats each comma-separated entry as
	  a root symbol name or linkage class, prints its own verdict, then breaks its
	  direct children into static (flatten candidates) and animated. Pass the lobby's
	  top-level clips to scope the audit to what the lobby actually instantiates.
**/
class LobbyStaticAudit {
	public static function main():Void {
		var analyzer = new StaticSubtreeAnalyzer();
		var gate = new FlattenSafetyGate();
		var roots = Sys.getEnv("AUDIT_ROOTS");
		if (roots != null && StringTools.trim(roots) != "") {
			for (name in roots.split(",")) {
				var trimmed = StringTools.trim(name);
				if (trimmed != "") {
					auditRoot(analyzer, gate, trimmed);
				}
			}
		} else {
			auditCatalog(analyzer, gate);
		}
	}

	// A symbol is a flatten candidate only when it passes BOTH gates: static
	// (output never changes) AND flatten-safe (no blend/filter/mask render risk).
	private static function classify(analyzer:StaticSubtreeAnalyzer, gate:FlattenSafetyGate, symbol:SymbolAssetDef):String {
		if (!analyzer.isStaticSymbol(symbol)) {
			return "animated";
		}
		return gate.isFlattenSafe(symbol) ? "safe" : "risky";
	}

	private static function auditCatalog(analyzer:StaticSubtreeAnalyzer, gate:FlattenSafetyGate):Void {
		var safe:Array<String> = [];
		var risky:Array<String> = [];
		var animated:Array<String> = [];
		for (symbol in AssetCatalog.symbols()) {
			var label = symbol.name != null ? symbol.name : symbol.linkageClassName;
			if (label == null) {
				continue;
			}
			switch (classify(analyzer, gate, symbol)) {
				case "safe": safe.push(label);
				case "risky": risky.push(symbol.name != null ? symbol.name : label);
				default: animated.push(label);
			}
		}
		safe.sort(compareStrings);
		risky.sort(compareStrings);

		Sys.println('Catalog symbols: ${safe.length + risky.length + animated.length}');
		Sys.println('  flatten-ready (static + safe): ${safe.length}');
		Sys.println('  static but risky (needs verification): ${risky.length}');
		Sys.println('  animated (cannot naively flatten): ${animated.length}');
		Sys.println("");
		Sys.println("Static-but-risky symbols (why each is held back):");
		for (name in risky) {
			var symbol = AssetLibrary.getSymbol(name);
			Sys.println('  - $name: ${summarizeRisks(gate, symbol)}');
		}
	}

	private static function auditRoot(analyzer:StaticSubtreeAnalyzer, gate:FlattenSafetyGate, name:String):Void {
		var root = resolve(name);
		if (root == null) {
			Sys.println('[$name] not found (tried symbol name and linkage class)');
			Sys.println("");
			return;
		}

		switch (classify(analyzer, gate, root)) {
			case "safe":
				Sys.println('[$name] FLATTEN-READY (static + safe, whole subtree → one quad)');
				Sys.println("");
				return;
			case "risky":
				Sys.println('[$name] STATIC BUT RISKY: ${summarizeRisks(gate, root)}');
				Sys.println("  (frozen output, but flattening needs runtime verification)");
				Sys.println("");
				return;
			default:
				Sys.println('[$name] ANIMATED');
		}

		// Break the direct children into the three buckets, so a non-static root can
		// still be flattened in its flatten-ready pieces.
		var ready:Array<String> = [];
		var risky:Array<String> = [];
		var animated:Array<String> = [];
		var seen:Map<String, Bool> = new Map();
		if (root.timelines.length > 0) {
			for (layer in root.timelines[0].layers) {
				for (frame in layer.frames) {
					if (frame.elements == null) {
						continue;
					}
					for (element in frame.elements) {
						if (element.libraryItemName == null || seen.exists(element.libraryItemName)) {
							continue;
						}
						seen.set(element.libraryItemName, true);
						var child = AssetLibrary.getSymbol(element.libraryItemName);
						if (child == null) {
							continue;
						}
						switch (classify(analyzer, gate, child)) {
							case "safe": ready.push(element.libraryItemName);
							case "risky": risky.push(element.libraryItemName);
							default: animated.push(element.libraryItemName);
						}
					}
				}
			}
		}
		ready.sort(compareStrings);
		risky.sort(compareStrings);
		animated.sort(compareStrings);

		Sys.println('  flatten-ready children: ${ready.length}');
		for (child in ready) {
			Sys.println('    + $child');
		}
		Sys.println('  static-but-risky children: ${risky.length}');
		for (child in risky) {
			Sys.println('    ~ $child: ${summarizeRisks(gate, AssetLibrary.getSymbol(child))}');
		}
		Sys.println('  animated children (keep): ${animated.length}');
		for (child in animated) {
			Sys.println('    - $child');
		}
		Sys.println("");
	}

	// Compact "kind xN" summary of a symbol's flatten risks, e.g. "filter x3, mask x1".
	private static function summarizeRisks(gate:FlattenSafetyGate, symbol:Null<SymbolAssetDef>):String {
		if (symbol == null) {
			return "?";
		}
		var counts:Map<String, Int> = new Map();
		for (finding in gate.inspect(symbol)) {
			var key = switch (finding.risk) {
				case DescendantBlendMode: "blend";
				case DescendantFilter: "filter";
				case MaskLayer: "mask";
			};
			counts.set(key, (counts.exists(key) ? counts.get(key) : 0) + 1);
		}
		var parts:Array<String> = [];
		for (key in counts.keys()) {
			parts.push('$key x${counts.get(key)}');
		}
		parts.sort(compareStrings);
		return parts.length == 0 ? "none" : parts.join(", ");
	}

	private static function resolve(name:String):Null<SymbolAssetDef> {
		var symbol = AssetLibrary.getSymbol(name);
		return symbol != null ? symbol : AssetLibrary.getSymbolByLinkage(name);
	}

	private static function compareStrings(a:String, b:String):Int {
		return a < b ? -1 : (a > b ? 1 : 0);
	}
}
