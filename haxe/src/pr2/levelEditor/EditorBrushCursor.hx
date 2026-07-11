package pr2.levelEditor;

import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import pr2.runtime.PR2MovieClip;

class EditorBrushCursor extends EditorToolCursor {
	public final eraseMode:Bool;

	private var circle:PR2MovieClip;
	private var size:Float = 4;
	private var zoom:Float = 1;

	public function new(manager:EditorToolCursorManager, sidebar:String, toolId:String, eraseMode:Bool) {
		super(manager, sidebar, toolId, true);
		this.eraseMode = eraseMode;
		disposable = false;
		circle = PR2MovieClip.fromLinkage("Circle", {maxNestedDepth: 2});
		applyCursorGraphic(circle);
		setSize(size);
	}

	public function setSize(nextSize:Float):Void {
		size = Math.max(1, nextSize);
		if (circle != null) {
			circle.width = size * zoom;
			circle.height = size * zoom;
		}
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
		visible = !manager.isOverEditorMenu(stageX, stageY);
	}

	override function mouseMoveHandler(e:MouseEvent):Void {
		super.mouseMoveHandler(e);
		updateVisibilityForStagePoint(e.stageX, e.stageY);
	}

	override public function remove():Void {
		if (circle != null) {
			circle.dispose();
			circle = null;
		}
		super.remove();
	}
}
