package pr2.lobby;

#if js
import js.Browser;
#end
import openfl.display.DisplayObject;
import pr2.app.QueryParams;
import pr2.page.Page;
import pr2.page.PageHolder;
import pr2.runtime.AssetLibrary;
import pr2.runtime.NineSliceSymbol;
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
	private var bg:Null<DisplayObject>;
	private var bgSlice:Null<NineSliceSymbol>;
	private var bgExtraW:Float = 0;
	private var bgExtraH:Float = 0;
	private var tabsHolder:Null<TabsHolder>;

	public function new() {
		super();
	}

	private function configure(tabs:Array<LobbyTab>, hId:String = "", tabSel:Int = 0, maxW:Float = 100, h:Float = 100, bgExtraW:Float = 0,
			bgExtraH:Float = 0):Void {
		this.bgExtraW = bgExtraW;
		this.bgExtraH = bgExtraH;
		bgSlice = NineSliceSymbol.tryCreate(AssetLibrary.requireSymbolByLinkage("HalfSquareBG"), {maxNestedDepth: 4});
		bg = bgSlice != null ? bgSlice : PR2MovieClip.fromLinkage("HalfSquareBG", {maxNestedDepth: 4});
		bg.y = 15;
		addChild(bg);
		tabsHolder = new TabsHolder(tabs, hId, tabSel, maxW);
		addChild(tabsHolder);
		setSize(maxW, h);
	}

	/**
		Resolve the initial selected tab from a `?<queryKey>=<name>` URL flag,
		mirroring how `?screen=` jumps straight to a screen. `tabKeys` are the
		pane's short tab names (the same keys reported via `data-pr2-lobby-*`), in
		display order. Returns `fallback` when the flag is absent or unrecognised.
	**/
	private function initialTabIndex(queryKey:String, tabKeys:Array<String>, fallback:Int):Int {
		#if js
		var requested = QueryParams.get(Browser.location.search, queryKey);
		if (requested != null) {
			var index = tabKeys.indexOf(requested.toLowerCase());
			if (index >= 0) {
				return index;
			}
		}
		#end
		return fallback;
	}

	public function setSize(w:Float, h:Float):Void {
		if (bg != null) {
			var bgW = w + bgExtraW;
			var bgH = h - 15 + bgExtraH;
			if (bgSlice != null) {
				bgSlice.setTargetSize(bgW, bgH);
			} else {
				bg.height = bgH;
				bg.width = bgW;
			}
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
			var bgClip = Std.downcast(bg, PR2MovieClip);
			if (bgClip != null) {
				bgClip.dispose();
			}
			bg = null;
			bgSlice = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
