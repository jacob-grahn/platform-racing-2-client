package pr2.ui;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Port of Flash `ui.LobbyTab`.

	Each tab is the `LobbyTabGraphic` art: a `textBox` dynamic text laid over a
	`bg` clip whose timeline has `up` / `over` / `selected` label frames. The tab
	sizes itself to its text (`bg.width = textBox.width + 10`), reports clicks to
	its `TabsHolder`, and on hover both highlights and asks the holder to bring it
	to the front so its label is never clipped by neighbours.
**/
class LobbyTab extends Sprite {
	private var art:Null<PR2MovieClip>;
	private var bg:Null<PR2MovieClip>;
	private var tabsHolder:Null<TabsHolder>;
	private var tabFunction:Void->Void;

	public function new(tabFn:Void->Void, tabText:String) {
		super();
		this.tabFunction = tabFn;

		art = PR2MovieClip.fromLinkage("LobbyTabGraphic", {maxNestedDepth: 6});
		var textBox = Std.downcast(DisplayUtil.findByName(art, "textBox"), TextField);
		if (textBox != null) {
			textBox.autoSize = TextFieldAutoSize.LEFT;
			textBox.text = tabText;
		}
		bg = Std.downcast(DisplayUtil.findByName(art, "bg"), PR2MovieClip);
		if (bg != null && textBox != null) {
			bg.width = textBox.width + 10;
		}
		addChild(art);
		activate();
	}

	@:allow(pr2.ui.TabsHolder)
	private function setTabsHolder(h:TabsHolder):Void {
		this.tabsHolder = h;
	}

	private function onClick(_:MouseEvent):Void {
		select();
	}

	private function onHover(_:MouseEvent):Void {
		if (bg != null) {
			bg.gotoAndStop("over");
		}
		if (tabsHolder != null) {
			tabsHolder.moveToFront(this);
		}
	}

	private function onHoverOut(_:MouseEvent):Void {
		if (bg != null) {
			bg.gotoAndStop("up");
		}
	}

	public function select():Void {
		if (tabsHolder != null) {
			tabsHolder.selectTab(this);
		}
		tabFunction();
		deactivate();
		if (bg != null) {
			bg.gotoAndStop("selected");
		}
	}

	public function activate():Void {
		deactivate();
		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(MouseEvent.MOUSE_OVER, onHover);
		addEventListener(MouseEvent.MOUSE_OUT, onHoverOut);
	}

	private function deactivate():Void {
		if (bg != null) {
			bg.gotoAndStop("up");
		}
		removeEventListener(MouseEvent.CLICK, onClick);
		removeEventListener(MouseEvent.MOUSE_OVER, onHover);
		removeEventListener(MouseEvent.MOUSE_OUT, onHoverOut);
	}

	public function remove():Void {
		deactivate();
		if (art != null) {
			art.dispose();
			if (art.parent != null) {
				art.parent.removeChild(art);
			}
			art = null;
		}
		bg = null;
		tabsHolder = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}

}
