package pr2.lobby.account;

import openfl.display.Sprite;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import pr2.app.AppStage;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

/**
	Colour picker for the part selectors. A 20x20 swatch shows the current colour;
	clicking it opens the Flash HSV popup, live previews popup changes, records
	the committed colour in the shared recent-colours strip, and dispatches the
	Flash `Event.CHANGE` / `Event.OPEN` / `Event.CLOSE` sequence.
**/
class ColorPicker extends Sprite {
	public static inline var RIGHT:String = "right";
	public static inline var LEFT:String = "left";
	public static final recentColors:Array<Int> = [
		0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555,
		0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555
	];

	private static inline var COLOR_WELL:Float = 36;

	public var direction:String = RIGHT;

	private var color:Int = 0x0000FF;
	private var swatch:Sprite;
	private var popup:Null<ColorPickerPopup>;

	public function new() {
		super();
		swatch = new Sprite();
		swatch.scaleX = swatch.scaleY = 0.833328247070312;
		addChild(swatch);
		var skin = NativeAssets.svg(StaticSvg.ColorPickerSwatchSkin);
		skin.name = "swatchSkin";
		skin.scaleX = skin.scaleY = 1.36363220214844;
		addChild(skin);
		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;
		drawSwatch();
		addEventListener(MouseEvent.CLICK, onSwatchClick);
	}

	public function getColor():Int {
		return color;
	}

	public function setColor(c:Int):Void {
		if (color != c) {
			color = c;
			drawSwatch();
			dispatchEvent(new Event(Event.CHANGE));
		}
	}

	private function drawSwatch():Void {
		swatch.graphics.clear();
		swatch.graphics.beginFill(0x808080);
		swatch.graphics.drawRect(0, 0, COLOR_WELL, COLOR_WELL);
		swatch.graphics.endFill();
		swatch.transform.colorTransform = new ColorTransform(0, 0, 0, 1, (color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF, 0);
	}

	private function onSwatchClick(_:MouseEvent):Void {
		if (popup != null) {
			closePopup();
			return;
		}
		openPopup();
	}

	private function openPopup():Void {
		var popupParent:DisplayObjectContainer = AppStage.stage != null ? AppStage.stage : this;
		popup = new ColorPickerPopup(color);
		popup.addEventListener(Event.CHANGE, onPopupChange);
		popup.addEventListener(Event.CLOSE, closePopup);
		var origin = localToGlobal(new Point(0, 0));
		var px = direction == RIGHT ? origin.x + this.width + 5 : origin.x - popup.width - 5;
		var py = origin.y;
		popup.x = Math.round(px);
		popup.y = Math.round(py);
		popupParent.addChild(popup);
		popup.init();
		popup.addExclusion(this);
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageDown);
		}
		dispatchEvent(new Event(Event.OPEN));
	}

	private static function recordRecent(c:Int):Void {
		if (recentColors.indexOf(c) == -1) {
			recentColors.unshift(c);
			recentColors.pop();
		}
	}

	private function onStageDown(e:MouseEvent):Void {
		if (popup != null && !popup.hitTestPoint(e.stageX, e.stageY, true) && !hitTestPoint(e.stageX, e.stageY, true)) {
			closePopup();
		}
	}

	private function onPopupChange(_:Event):Void {
		if (popup != null) {
			setColor(popup.getColor());
		}
	}

	private function closePopup(?_:Event):Void {
		if (popup == null) {
			return;
		}
		var closing = popup;
		setColor(closing.getColor());
		closing.removeEventListener(Event.CHANGE, onPopupChange);
		closing.removeEventListener(Event.CLOSE, closePopup);
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageDown);
		}
		closing.remove();
		popup = null;
		recordRecent(color);
		dispatchEvent(new Event(Event.CLOSE));
	}

	public function remove():Void {
		removeEventListener(MouseEvent.CLICK, onSwatchClick);
		closePopup();
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
