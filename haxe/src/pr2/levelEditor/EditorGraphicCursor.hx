package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.events.Event;

class EditorGraphicCursor extends EditorToolCursor {
	private var graphic:Null<DisplayObject>;
	private final scaleWithObjectLayer:Bool;
	private final cursorId:Int;

	public function new(manager:EditorToolCursorManager, sidebar:String, toolId:String, graphic:DisplayObject, hideSystemMouse:Bool = false,
			ignoresTemporaryDelete:Bool = false, scaleWithObjectLayer:Bool = false, cursorId:Int = -1) {
		super(manager, sidebar, toolId, ignoresTemporaryDelete);
		this.graphic = graphic;
		this.scaleWithObjectLayer = scaleWithObjectLayer;
		this.cursorId = cursorId;
		applyCursorGraphic(graphic);
		if (hideSystemMouse) {
			hideMouse();
		}
		if (scaleWithObjectLayer) {
			updateObjectLayerScale();
			addEventListener(Event.ENTER_FRAME, updateObjectLayerScale);
		}
	}

	override public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, updateObjectLayerScale);
		graphic = null;
		super.remove();
	}

	override public function getID():Int {
		return cursorId;
	}

	private function updateObjectLayerScale(?_:Event):Void {
		if (!scaleWithObjectLayer) {
			return;
		}
		scaleX = manager.objectCursorScaleX();
		scaleY = manager.objectCursorScaleY();
	}
}
