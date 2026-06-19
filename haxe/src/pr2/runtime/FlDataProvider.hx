package pr2.runtime;

/**
	A minimal stand-in for `fl.data.DataProvider`, the list model shared by the
	`fl.controls` List/ComboBox ports. PR2 source treats items as plain objects
	with a `label` field (plus arbitrary payload such as `token`, `server`, …)
	and reaches them through `addItem`, `removeAll`, `getItemAt`, and `length`.
**/
class FlDataProvider {
	private var items:Array<Dynamic> = [];

	public var length(get, never):Int;

	public function new(?source:Array<Dynamic>) {
		if (source != null) {
			items = source.copy();
		}
	}

	private function get_length():Int {
		return items.length;
	}

	public function getItemAt(index:Int):Dynamic {
		if (index < 0 || index >= items.length) {
			return null;
		}
		return items[index];
	}

	public function getItemIndex(item:Dynamic):Int {
		return items.indexOf(item);
	}

	public function addItem(item:Dynamic):Void {
		items.push(item);
	}

	public function addItemAt(item:Dynamic, index:Int):Void {
		if (index < 0) {
			index = 0;
		}
		if (index > items.length) {
			index = items.length;
		}
		items.insert(index, item);
	}

	public function removeItemAt(index:Int):Dynamic {
		if (index < 0 || index >= items.length) {
			return null;
		}
		return items.splice(index, 1)[0];
	}

	public function removeAll():Void {
		items = [];
	}

	public function toArray():Array<Dynamic> {
		return items.copy();
	}

	/**
		Parse the Flash IDE component `dataProvider` serialization into a provider of
		`{<field>: <value>, ...}` items. The authoring format is a flat, comma-space
		separated list:

		  `fl.data.DataProvider, fl.data.SimpleCollectionItem, item, <fieldCount>,
		   <name>, <type>, , , ... , <itemCount>, <v0_0>, <v0_1>, ...`

		Each field contributes four tokens (name, type, and two empties); each item
		then contributes one value per field, in order. Empty values (e.g. a blank
		`data`) are preserved as empty strings, matching the original collection.
	**/
	public static function fromCollectionString(value:String):FlDataProvider {
		var dp = new FlDataProvider();
		if (value == null || value == "") {
			return dp;
		}
		var tokens = value.split(", ");
		// 0: collection class, 1: item class, 2: "item", 3: field count.
		if (tokens.length < 4) {
			return dp;
		}
		var i = 3;
		var fieldCount = parseCount(tokens[i++]);
		var fields:Array<String> = [];
		for (_ in 0...fieldCount) {
			if (i >= tokens.length) {
				return dp;
			}
			fields.push(tokens[i]);
			i += 4; // name, type code, and two reserved/empty tokens
		}
		if (i >= tokens.length) {
			return dp;
		}
		var itemCount = parseCount(tokens[i++]);
		for (_ in 0...itemCount) {
			var obj:Dynamic = {};
			for (f in 0...fieldCount) {
				var v = i < tokens.length ? tokens[i++] : "";
				Reflect.setField(obj, fields[f], v);
			}
			dp.addItem(obj);
		}
		return dp;
	}

	private static function parseCount(token:String):Int {
		var n = Std.parseInt(token);
		return n == null || n < 0 ? 0 : n;
	}
}
