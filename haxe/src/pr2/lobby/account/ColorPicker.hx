package pr2.lobby.account;

import openfl.display.Sprite;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.app.AppStage;

/**
	Colour picker for the part selectors. A 20×20 swatch shows the current colour;
	clicking it opens the `ColorChoices` palette grid as an overlay, and picking a
	cell sets the colour, records it in the shared recent-colours strip, and
	dispatches `Event.CHANGE`.

	This is a faithful-in-behaviour port of `com.jiggmin.ColorPicker.ColorPicker`
	(swatch + palette + recent colours); the original's HSV/eyedropper popup is
	reduced to the swatch palette, which is the path the customize UI exercises.
**/
class ColorPicker extends Sprite {
	public static inline var RIGHT:String = "right";
	public static inline var LEFT:String = "left";
	public static final recentColors:Array<Int> = [
		0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555,
		0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555
	];

	private static inline var SWATCH:Float = 20;
	private static inline var CELL:Float = 11;

	public var direction:String = RIGHT;

	private var color:Int = 0x0000FF;
	private var swatch:Sprite;
	private var popup:Null<Sprite>;

	public function new() {
		super();
		swatch = new Sprite();
		addChild(swatch);
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
		swatch.graphics.lineStyle(1, 0x000000);
		swatch.graphics.beginFill(color & 0xFFFFFF);
		swatch.graphics.drawRect(0, 0, SWATCH, SWATCH);
		swatch.graphics.endFill();
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
		var grid = ColorChoices.populate(recentColors);
		popup = new Sprite();
		var width = ColorChoices.COLS * CELL;
		var height = ColorChoices.ROWS * CELL;
		popup.graphics.lineStyle(1, 0x000000);
		popup.graphics.beginFill(0x222222);
		popup.graphics.drawRect(-1, -1, width + 2, height + 2);
		popup.graphics.endFill();
		for (col in 0...ColorChoices.COLS) {
			for (row in 0...ColorChoices.ROWS) {
				addCell(popup, grid[col][row], col * CELL, row * CELL);
			}
		}
		var origin = localToGlobal(new openfl.geom.Point(0, 0));
		var px = direction == RIGHT ? origin.x + this.width + 5 : origin.x - popup.width - 5;
		var py = origin.y;
		var stageHeight = AppStage.stage != null ? AppStage.stage.stageHeight : 600;
		if (py + height > stageHeight) {
			py = stageHeight - height;
		}
		popup.x = Math.round(px);
		popup.y = Math.round(py);
		popupParent.addChild(popup);
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageDown);
		}
		dispatchEvent(new Event(Event.OPEN));
	}

	private function addCell(into:Sprite, cellColor:Int, x:Float, y:Float):Void {
		var cell = new Sprite();
		cell.graphics.beginFill(cellColor & 0xFFFFFF);
		cell.graphics.drawRect(0, 0, CELL, CELL);
		cell.graphics.endFill();
		cell.x = x;
		cell.y = y;
		cell.buttonMode = true;
		cell.useHandCursor = true;
		cell.addEventListener(MouseEvent.CLICK, function(_:MouseEvent):Void {
			pick(cellColor);
		});
		into.addChild(cell);
	}

	private function pick(c:Int):Void {
		setColor(c);
		closePopup();
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

	private function closePopup():Void {
		if (popup == null) {
			return;
		}
		recordRecent(color);
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageDown);
		}
		if (popup != null && popup.parent != null) {
			popup.parent.removeChild(popup);
		}
		popup = null;
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
