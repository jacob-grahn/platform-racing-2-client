package pr2.lobby.account;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import openfl.geom.Point;
import pr2.runtime.PR2MovieClip;
import pr2.ui.CustomCursor;

/**
	Port of `com.jiggmin.ColorPicker.CursorEyedropper`.
**/
class CursorEyedropper extends CustomCursor {
	public var color:Int = -1;

	private var exclusions:Array<DisplayObject> = [];
	private var cursorContainer:Null<BitmapData>;
	private var sampleSource:Null<DisplayObject>;

	public function new(?sampleSource:DisplayObject) {
		super();
		visible = false;
		applyCursorGraphic(PR2MovieClip.fromLinkage("CursorEyedropperGraphic"));
		this.sampleSource = sampleSource;
		ensureBitmap();
	}

	override public function init():Void {
		super.init();
		visible = false;
		addEventListener(Event.ENTER_FRAME, maybeUpdate);
	}

	override public function pause():Void {
		super.pause();
		removeEventListener(Event.ENTER_FRAME, maybeUpdate);
	}

	public function addExclusion(d:DisplayObject):Void {
		exclusions.push(d);
	}

	override public function remove():Void {
		showMouse();
		super.remove();
		if (cursorContainer != null) {
			cursorContainer.dispose();
			cursorContainer = null;
		}
		exclusions = [];
		sampleSource = null;
	}

	private function maybeUpdate(_:Event):Void {
		var me = getMouse();
		var targetObj = me != null ? Std.downcast(me.target, DisplayObject) : null;
		if (targetObj == null && sampleSource != null) {
			targetObj = sampleSource;
		}
		if (targetObj == null) {
			return;
		}
		var useEyedropper = true;
		while (targetObj.parent != null) {
			if (isExcluded(targetObj)) {
				useEyedropper = false;
				break;
			}
			targetObj = targetObj.parent;
		}
		if (useEyedropper) {
			if (!visible) {
				visible = true;
				hideMouse();
				drawEyedropper();
			}
			updateColor();
			dispatchEvent(new Event(Event.CHANGE));
		} else if (visible) {
			visible = false;
			showMouse();
			color = -1;
			dispatchEvent(new Event(Event.CHANGE));
		}
	}

	override function mouseDownHandler(e:MouseEvent):Void {
		if (visible) {
			e.stopImmediatePropagation();
			drawEyedropper();
			updateColor();
			dispatchEvent(new Event(Event.COMPLETE));
		}
		super.mouseDownHandler(e);
	}

	private function drawEyedropper():Void {
		if (!visible) {
			return;
		}
		var source = currentSampleSource();
		if (source == null) {
			return;
		}
		ensureBitmap();
		visible = false;
		cursorContainer.fillRect(cursorContainer.rect, 0);
		var bitmap = Std.downcast(source, Bitmap);
		if (bitmap != null && bitmap.bitmapData != null) {
			cursorContainer.copyPixels(bitmap.bitmapData, bitmap.bitmapData.rect, new Point());
		} else {
			var matrix = new Matrix();
			var bounds = source.getBounds(source);
			if (bounds.left != 0 || bounds.top != 0) {
				matrix.translate(-bounds.left, -bounds.top);
			}
			cursorContainer.draw(source, matrix);
		}
		visible = true;
	}

	private function isExcluded(d:DisplayObject):Bool {
		return exclusions.indexOf(d) != -1;
	}

	private function updateColor():Void {
		var me = getMouse();
		if (me == null || cursorContainer == null) {
			color = -1;
			return;
		}
		var source = currentSampleSource();
		if (source == null) {
			color = -1;
			return;
		}
		var stagePoint = CustomCursor.eventStagePoint(me);
		var localPoint = source.stage == null ? stagePoint : source.globalToLocal(stagePoint);
		var px = clamp(Math.floor(localPoint.x), 0, cursorContainer.width - 1);
		var py = clamp(Math.floor(localPoint.y), 0, cursorContainer.height - 1);
		color = cursorContainer.getPixel(px, py);
	}

	private function ensureBitmap():Void {
		var source = currentSampleSource();
		var width = 1;
		var height = 1;
		if (source != null) {
			var bounds = source.getBounds(source);
			width = Std.int(Math.max(1, Math.ceil(bounds.width)));
			height = Std.int(Math.max(1, Math.ceil(bounds.height)));
		} else {
			var stage = currentStage();
			if (stage != null) {
				width = Std.int(Math.max(1, stage.stageWidth));
				height = Std.int(Math.max(1, stage.stageHeight));
			}
		}
		if (cursorContainer == null || cursorContainer.width != width || cursorContainer.height != height) {
			if (cursorContainer != null) {
				cursorContainer.dispose();
			}
			cursorContainer = new BitmapData(width, height, false, 0);
		}
	}

	private function currentSampleSource():Null<DisplayObject> {
		if (sampleSource != null) {
			return sampleSource;
		}
		return currentStage();
	}

	private static function clamp(value:Float, minimum:Int, maximum:Int):Int {
		return Std.int(Math.max(minimum, Math.min(maximum, value)));
	}
}
