package pr2.page;

import openfl.display.Sprite;

/**
	Base class for full-screen pages, ported from the Flash `page.Page`.

	A page owns one logical screen worth of display objects. `PageHolder`
	drives the lifecycle: it calls `initialize` when the page becomes active
	and `remove` when it is swapped out. Pages get a back-reference to their
	holder so they can request a page change (the Flash client reached the
	holder through the global `Main.pageHolder`; here it is injected instead).
**/
class Page extends Sprite {
	public var pageHolder:Null<PageHolder>;

	public function new() {
		super();
	}

	public function initialize():Void {}

	public function remove():Void {
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
