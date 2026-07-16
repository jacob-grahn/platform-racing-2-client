package pr2.ui;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

/**
	Port of Flash `ui.LobbyTab`.

	Each tab is the `LobbyTabGraphic` art: a `textBox` dynamic text laid over a
	`bg` clip whose timeline has `up` / `over` / `selected` label frames. The tab
	sizes itself to its text (`bg.width = textBox.width + 10`), reports clicks to
	its `TabsHolder`, and on hover both highlights and asks the holder to bring it
	to the front so its label is never clipped by neighbours.
**/
class LobbyTab extends Sprite {
	private var bg:Sprite;
	private var base:Null<Shape>;
	private var selectedOverlay:Null<Shape>;
	private var textBox:TextField;
	private var tabsHolder:Null<TabsHolder>;
	private var tabFunction:Void->Void;

	public function new(tabFn:Void->Void, tabText:String) {
		super();
		this.tabFunction = tabFn;

		bg = new Sprite();
		bg.name = "bg";
		addChild(bg);
		textBox = new TextField();
		textBox.name = "textBox";
		textBox.x = 5;
		textBox.y = 2;
		textBox.height = 14.55;
		textBox.selectable = false;
		textBox.mouseEnabled = false;
		textBox.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0);
		textBox.autoSize = TextFieldAutoSize.LEFT;
		textBox.text = tabText;
		addChild(textBox);
		setState(StaticSvg.LobbyTabUp, false);
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
		setState(StaticSvg.LobbyTabOver, false);
		if (tabsHolder != null) {
			tabsHolder.moveToFront(this);
		}
	}

	private function onHoverOut(_:MouseEvent):Void {
		setState(StaticSvg.LobbyTabUp, false);
	}

	public function select():Void {
		if (tabsHolder != null) {
			tabsHolder.selectTab(this);
		}
		tabFunction();
		deactivate();
		setState(StaticSvg.LobbyTabOver, true);
	}

	public function activate():Void {
		deactivate();
		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(MouseEvent.MOUSE_OVER, onHover);
		addEventListener(MouseEvent.MOUSE_OUT, onHoverOut);
	}

	private function deactivate():Void {
		setState(StaticSvg.LobbyTabUp, false);
		removeEventListener(MouseEvent.CLICK, onClick);
		removeEventListener(MouseEvent.MOUSE_OVER, onHover);
		removeEventListener(MouseEvent.MOUSE_OUT, onHoverOut);
	}

	public function remove():Void {
		deactivate();
		base = null;
		selectedOverlay = null;
		tabsHolder = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function setState(asset:StaticSvg, selected:Bool):Void {
		if (base != null) bg.removeChild(base);
		if (selectedOverlay != null) bg.removeChild(selectedOverlay);
		base = NativeAssets.svg(asset);
		bg.addChild(base);
		if (selected) {
			selectedOverlay = NativeAssets.svg(StaticSvg.LobbyTabSelectedOverlay);
			bg.addChild(selectedOverlay);
		} else selectedOverlay = null;
		bg.width = textBox.width + 10;
	}

}
