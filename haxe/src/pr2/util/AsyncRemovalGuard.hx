package pr2.util;

typedef AsyncRemovable = {
	function remove():Void;
}

/**
	Tracks async work owned by a removable view.

	Owners wrap callbacks with `wrap` and track cancellable loaders with `watch`;
	`remove` then prevents late callbacks from mutating torn-down UI and cancels
	any resources that expose a Flash-style `remove`.
**/
class AsyncRemovalGuard {
	private var active:Bool = true;
	private var resources:Array<AsyncRemovable> = [];

	public function new() {}

	public function isActive():Bool {
		return active;
	}

	public function watch<T:AsyncRemovable>(resource:T):T {
		if (resource == null) {
			return resource;
		}
		if (!active) {
			resource.remove();
		} else {
			resources.push(resource);
		}
		return resource;
	}

	public function wrap<T>(callback:T->Void):T->Void {
		return function(value:T):Void {
			if (active && callback != null) {
				callback(value);
			}
		}
	}

	public function wrapVoid(callback:Void->Void):Void->Void {
		return function():Void {
			if (active && callback != null) {
				callback();
			}
		}
	}

	public function remove():Void {
		if (!active) {
			return;
		}
		active = false;
		for (resource in resources) {
			resource.remove();
		}
		resources = [];
	}
}
