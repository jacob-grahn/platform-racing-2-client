package pr2.runtime;

import pr2.generated.assets.AssetCatalog;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;

class AssetLibrary {
	private static var symbolsByName:Map<String, SymbolAssetDef>;
	private static var symbolsByLinkage:Map<String, SymbolAssetDef>;

	public static function getSymbol(name:String):Null<SymbolAssetDef> {
		ensureIndexes();
		return symbolsByName.get(name);
	}

	public static function getSymbolByLinkage(linkageClassName:String):Null<SymbolAssetDef> {
		ensureIndexes();
		return symbolsByLinkage.get(linkageClassName);
	}

	public static function requireSymbol(name:String):SymbolAssetDef {
		var symbol = getSymbol(name);
		if (symbol == null) {
			throw 'Unknown PR2 symbol: $name';
		}
		return symbol;
	}

	public static function requireSymbolByLinkage(linkageClassName:String):SymbolAssetDef {
		var symbol = getSymbolByLinkage(linkageClassName);
		if (symbol == null) {
			throw 'Unknown PR2 linkage class: $linkageClassName';
		}
		return symbol;
	}

	private static function ensureIndexes():Void {
		if (symbolsByName != null) {
			return;
		}

		symbolsByName = new Map();
		symbolsByLinkage = new Map();

		for (symbol in AssetCatalog.symbols()) {
			if (symbol.name != null) {
				symbolsByName.set(symbol.name, symbol);
			}
			if (symbol.linkageClassName != null) {
				symbolsByLinkage.set(symbol.linkageClassName, symbol);
			}
		}
	}

	private function new() {}
}
