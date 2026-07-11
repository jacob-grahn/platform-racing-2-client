package pr2.levelEditor;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import pr2.ui.CustomCursor;



class EditorToolCursor extends CustomCursor {
	public final manager:EditorToolCursorManager;
	public final sidebar:String;
	public final toolId:String;
	public final ignoresTemporaryDelete:Bool;

	public function new(manager:EditorToolCursorManager, sidebar:String, toolId:String, ignoresTemporaryDelete:Bool = false) {
		super();
		this.manager = manager;
		this.sidebar = sidebar;
		this.toolId = toolId;
		this.ignoresTemporaryDelete = ignoresTemporaryDelete;
	}

	override function keyDownHandler(e:KeyboardEvent):Void {
		if (e.keyCode == Keyboard.COMMAND || e.keyCode == Keyboard.CONTROL) {
			manager.beginTemporaryDelete();
		}
	}

	override function keyUpHandler(e:KeyboardEvent):Void {
		if (e.keyCode == Keyboard.COMMAND || e.keyCode == Keyboard.CONTROL) {
			manager.endTemporaryDelete();
		}
	}
}
