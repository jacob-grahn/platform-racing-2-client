package pr2.levelEditor;

import openfl.display.Shape;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;

class EditorBrushCursor extends EditorToolCursor {
	public final eraseMode:Bool;

	private var circle:Shape;
	private var size:Float = 4;
	private var zoom:Float = 1;
	private var drawing:Bool = false;

	public function new(manager:EditorToolCursorManager, sidebar:String, toolId:String, eraseMode:Bool) {
		super(manager, sidebar, toolId, true);
		this.eraseMode = eraseMode;
		disposable = false;
		circle = createCircle();
		// Circle is authored around (0, 0), exactly as Flash's Brush expects.
		// Generic cursor centering shifts an already-centered symbol up-left.
		addChild(circle);
		setSize(size);
	}

	public function setSize(nextSize:Float):Void {
		size = Math.max(1, nextSize);
		if (circle != null) {
			circle.width = size * zoom;
			circle.height = size * zoom;
		}
	}

	/** Native equivalent of the authored 100px-diameter white `Circle` symbol. */
	public static function createCircle():Shape {
		var result = new Shape();
		result.graphics.beginFill(0xFFFFFF);
		result.graphics.drawCircle(0, 0, 50);
		result.graphics.endFill();
		return result;
	}

	public function setZoom(nextZoom:Float):Void {
		zoom = Math.max(0.01, nextZoom);
		setSize(size);
	}

	public function setColor(color:Int):Void {
		if (circle == null) {
			return;
		}
		var transform = new ColorTransform();
		transform.color = color & 0xFFFFFF;
		circle.transform.colorTransform = transform;
	}

	public function updateVisibilityForStagePoint(stageX:Float, stageY:Float):Void {
		visible = !drawing && !manager.isOverEditorMenu(stageX, stageY);
	}

	public function setDrawing(nextDrawing:Bool):Void {
		drawing = nextDrawing;
		if (drawing) {
			visible = false;
		} else {
			updateVisibilityForStagePoint(x, y);
		}
	}

	override function mouseMoveHandler(e:MouseEvent):Void {
		super.mouseMoveHandler(e);
		updateVisibilityForStagePoint(e.stageX, e.stageY);
	}

	override public function remove():Void {
		if (circle != null) {
			if (circle.parent != null) {
				circle.parent.removeChild(circle);
			}
			circle = null;
		}
		super.remove();
	}
}
