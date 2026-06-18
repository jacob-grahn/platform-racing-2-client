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
}
