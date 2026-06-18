package pr2.lobby;

import pr2.page.Page;
import pr2.page.PageHolder;
import pr2.runtime.PR2MovieClip;
import pr2.ui.LobbyTab;
import pr2.ui.TabsHolder;

/**
	Port of Flash `lobby.LobbySide`: a `PageHolder` that pairs a tab strip
	(`TabsHolder`) with a `HalfSquareBG` panel behind the active tab page. Used as
	the base for both the left and right lobby panes. The active page is offset to
	`(4, 20)` so it sits inside the panel, below the tab row.

	The AS3 constructor took the tabs directly and called `super()` last. Haxe
	forbids referencing `this` (needed to bind each tab's `changePage` handler)
	before `super()`, so construction is split: subclasses call `super()` then
	`configure(...)` once their `this`-bound tab handlers can be created.
**/
class LobbySide extends PageHolder {
	private var bg:Null<PR2MovieClip>;
	private var tabsHolder:Null<TabsHolder>;

	public function new() {
		super();
	}

	private function configure(tabs:Array<LobbyTab>, hId:String = "", tabSel:Int = 0, maxW:Float = 100, h:Float = 100):Void {
		bg = PR2MovieClip.fromLinkage("HalfSquareBG", {maxNestedDepth: 4});
		bg.y = 15;
		addChild(bg);
		tabsHolder = new TabsHolder(tabs, hId, tabSel, maxW);
		addChild(tabsHolder);
		setSize(maxW, h);
	}

	public function setSize(w:Float, h:Float):Void {
		if (bg != null) {
			bg.height = h - 15;
			bg.width = w;
		}
		if (tabsHolder != null) {
			tabsHolder.populateTabs(w);
		}
	}

	override public function changePage(page:Page):Void {
		super.changePage(page);
		if (page != null) {
			page.x = 4;
			page.y = 20;
		}
	}

	public function remove():Void {
		if (tabsHolder != null) {
			tabsHolder.remove();
			tabsHolder = null;
		}
		var current = getCurrentPage();
		if (current != null) {
			current.remove();
		}
		if (bg != null) {
			if (bg.parent != null) {
				bg.parent.removeChild(bg);
			}
			bg.dispose();
			bg = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
