package pr2.lobby.account;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import openfl.geom.Point;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
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
		applyCursorGraphic(makeCursorGraphic());
		this.sampleSource = sampleSource;
		ensureBitmap();
	}

	private function makeCursorGraphic():DisplayObject {
		var art = new Sprite();
		art.addChild(NativeAssets.svg(StaticSvg.EyedropperBack));
		art.addChild(NativeAssets.svg(StaticSvg.EyedropperFront));
		art.scaleX = art.scaleY = 0.681365966796875;
		art.x = 6.4;
		art.y = -8.4;
		return art;
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
			#if html5
			// Reading one pixel from WebGL synchronizes the GPU. Doing that from
			// ENTER_FRAME (as Flash did with its already-cached BitmapData) stalls
			// the whole editor while the picker is open. Sample once on click below.
			if (Std.isOfType(currentSampleSource(), Stage)) {
				return;
			}
			#end
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
		#if html5
		// The browser already has the completed game frame in its canvas. Drawing
		// the Stage into BitmapData makes OpenFL walk the editor's full 60,000px
		// display tree and can stall indefinitely on art-heavy levels.
		if (Std.isOfType(source, Stage)) {
			return;
		}
		#end
		ensureBitmap();
		visible = false;
		cursorContainer.fillRect(cursorContainer.rect, 0);
		var bitmap = Std.downcast(source, Bitmap);
		if (bitmap != null && bitmap.bitmapData != null) {
			cursorContainer.copyPixels(bitmap.bitmapData, bitmap.bitmapData.rect, new Point());
		} else {
			var matrix = new Matrix();
			if (!Std.isOfType(source, Stage)) {
				var bounds = source.getBounds(source);
				if (bounds.left != 0 || bounds.top != 0) {
					matrix.translate(-bounds.left, -bounds.top);
				}
			}
			// Flash captures exactly stageWidth x stageHeight. The editor's stage
			// bounds include its 60,000px world, so an unclipped HTML5 draw can try
			// to allocate a world-sized intermediate canvas and appear to freeze.
			cursorContainer.draw(source, matrix, null, null, cursorContainer.rect);
		}
		visible = true;
	}

	private function isExcluded(d:DisplayObject):Bool {
		return exclusions.indexOf(d) != -1;
	}

	private function updateColor():Void {
		var me = getMouse();
		if (me == null) {
			color = -1;
			return;
		}
		var source = currentSampleSource();
		if (source == null) {
			color = -1;
			return;
		}
		#if html5
		if (Std.isOfType(source, Stage)) {
			var sampled = sampleHtml5StagePixel(CustomCursor.eventStagePoint(me));
			color = sampled == null ? -1 : sampled;
			return;
		}
		#end
		if (cursorContainer == null) {
			color = -1;
			return;
		}
		var stagePoint = CustomCursor.eventStagePoint(me);
		var localPoint = source.stage == null ? stagePoint : source.globalToLocal(stagePoint);
		var px = clamp(Math.floor(localPoint.x), 0, cursorContainer.width - 1);
		var py = clamp(Math.floor(localPoint.y), 0, cursorContainer.height - 1);
		color = cursorContainer.getPixel(px, py);
	}

	#if html5
	private function sampleHtml5StagePixel(stagePoint:Point):Null<Int> {
		try {
			var canvas:Dynamic = js.Browser.document.querySelector("canvas");
			var sourceStage = currentStage();
			if (canvas == null || sourceStage == null || sourceStage.stageWidth <= 0 || sourceStage.stageHeight <= 0) {
				return null;
			}
			var px = Std.int(Math.max(0, Math.min(canvas.width - 1, Math.floor(stagePoint.x / sourceStage.stageWidth * canvas.width))));
			var py = Std.int(Math.max(0, Math.min(canvas.height - 1, Math.floor(stagePoint.y / sourceStage.stageHeight * canvas.height))));
			var context2d:Dynamic = canvas.getContext("2d");
			if (context2d != null) {
				var data:Dynamic = context2d.getImageData(px, py, 1, 1).data;
				return (data[0] << 16) | (data[1] << 8) | data[2];
			}
			var gl:Dynamic = canvas.getContext("webgl2");
			if (gl == null) gl = canvas.getContext("webgl");
			if (gl == null) gl = canvas.getContext("experimental-webgl");
			if (gl == null) {
				return null;
			}
			var pixels = new js.lib.Uint8Array(4);
			gl.readPixels(px, canvas.height - 1 - py, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
			return (pixels[0] << 16) | (pixels[1] << 8) | pixels[2];
		} catch (_:Dynamic) {
			return null;
		}
	}
	#end

	private function ensureBitmap():Void {
		var source = currentSampleSource();
		var width = 1;
		var height = 1;
		var sourceStage = Std.downcast(source, Stage);
		if (sourceStage != null) {
			width = Std.int(Math.max(1, sourceStage.stageWidth));
			height = Std.int(Math.max(1, sourceStage.stageHeight));
		} else if (source != null) {
			var bounds = source.getBounds(source);
			width = Std.int(Math.max(1, Math.ceil(bounds.width)));
			height = Std.int(Math.max(1, Math.ceil(bounds.height)));
		}
		if (cursorContainer == null || cursorContainer.width != width || cursorContainer.height != height) {
			if (cursorContainer != null) {
				cursorContainer.dispose();
			}
			cursorContainer = new BitmapData(width, height, false, 0);
		}
	}

	public function captureWidthForTests():Int {
		return cursorContainer == null ? 0 : cursorContainer.width;
	}

	public function captureHeightForTests():Int {
		return cursorContainer == null ? 0 : cursorContainer.height;
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
