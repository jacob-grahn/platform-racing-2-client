package pr2.ui;

import openfl.display.Sprite;
import openfl.events.MouseEvent;

/**
	Port of Flash `ui.TabsHolder`.

	Owns a row of `LobbyTab`s, remembers the last selected tab per holder id
	(`lobbyLeft`, `lobbyRight`, `playerLists`) across the life of the session, and
	keeps the selected tab visually in front. `populateTabs` delegates the overlap
	math to `TabLayout`. The static `memory` map mirrors the AS3 static so a tab
	selection is restored when the pane is rebuilt.
**/
class TabsHolder extends Sprite {
	private static var memory:Map<String, Int> = new Map();

	public var tabArr:Array<LobbyTab>;
	private var selected:Int;
	private var holderId:String;

	public function new(tabs:Array<LobbyTab>, hId:String = "", sel:Int = 0, maxW:Float = 100) {
		super();
		this.tabArr = tabs;
		this.holderId = hId;
		this.selected = resolveSelected(hId, sel, tabs.length);
		for (tab in tabs) {
			tab.setTabsHolder(this);
			addChild(tab);
		}
		populateTabs(maxW);
		if (tabs.length > 0) {
			tabs[selected].select();
		}
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}

	public static function setLastTab(holderId:String, tabNum:Int):Void {
		memory.set(holderId, tabNum);
	}

	/** Last selected tab index for a holder, or null if never selected. */
	public static function getLastTab(holderId:String):Null<Int> {
		return memory.exists(holderId) ? memory.get(holderId) : null;
	}

	/** Pure resolution of the initial selected index, honouring remembered state. */
	public static function resolveSelected(holderId:String, sel:Int, tabCount:Int):Int {
		var remembered = getLastTab(holderId);
		if (remembered != null && remembered < tabCount) {
			return remembered;
		}
		return sel;
	}

	/** Clear remembered selections — test/teardown helper. */
	public static function clearMemory():Void {
		memory = new Map();
	}

	public function populateTabs(maxW:Float):Void {
		var widths:Array<Float> = [for (tab in tabArr) tab.width];
		var xs = TabLayout.positions(widths, maxW);
		for (i in 0...tabArr.length) {
			tabArr[i].x = xs[i];
		}
	}

	private function onMouseOut(_:MouseEvent):Void {
		resetTabPositions();
	}

	private function resetTabPositions():Void {
		var i = 0;
		while (i < selected) {
			moveToFront(tabArr[i]);
			i++;
		}
		i = tabArr.length - 1;
		while (i > selected) {
			moveToFront(tabArr[i]);
			i--;
		}
		if (tabArr.length > 0) {
			moveToFront(tabArr[selected]);
		}
	}

	@:allow(pr2.ui.LobbyTab)
	private function selectTab(target:LobbyTab):Void {
		for (i in 0...tabArr.length) {
			var tab = tabArr[i];
			if (tab == target) {
				selected = i;
			} else {
				tab.activate();
			}
		}
		resetTabPositions();
	}

	@:allow(pr2.ui.LobbyTab)
	private function moveToFront(tab:LobbyTab):Void {
		addChildAt(tab, numChildren - 1);
	}

	/** Currently selected index — exposed for parity tests. */
	public function selectedIndex():Int {
		return selected;
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		for (tab in tabArr) {
			tab.remove();
		}
		if (holderId != "") {
			setLastTab(holderId, selected);
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
