package pr2.ui;

import openfl.display.DisplayObject;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.geom.Point;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import pr2.app.AppStage;

/**
	Flash-compatible base for authored custom cursors.
**/
class CustomCursor extends Sprite {
	public static var stageRef:Null<Stage>;
	public static var instance:Null<CustomCursor>;

	public var disposable:Bool = true;

	private var active:Bool = false;
	private var me:Null<MouseEvent>;
	private var mouseDown:Bool = false;
	private var mouseHidden:Bool = false;

	public function new() {
		super();
		mouseEnabled = false;
		mouseChildren = false;
		var stage = currentStage();
		if (stage != null) {
			x = stage.mouseX;
			y = stage.mouseY;
		}
	}

	public static function change(c:CustomCursor):Void {
		unsetInstance();
		instance = c;
		var stage = c.currentStage();
		if (stage != null && c.parent != stage) {
			stage.addChild(c);
		}
		if (!c.isActive()) {
			c.init();
		}
	}

	public static function unsetInstance():Void {
		if (instance != null) {
			var cursor = instance;
			if (cursor.disposable) {
				cursor.remove();
			} else {
				cursor.pause();
			}
			instance = null;
		}
	}

	public static function pauseCurrent():Void {
		if (instance != null) {
			instance.pause();
		}
	}

	public static function initCurrent():Void {
		if (instance != null) {
			instance.init();
		}
	}

	public function init():Void {
		active = true;
		visible = true;
		if (mouseHidden) {
			hideMouse();
		}
		var stage = currentStage();
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			stage.addEventListener(MouseEvent.MOUSE_OVER, mouseFocusHandler);
			stage.addEventListener(MouseEvent.MOUSE_OUT, mouseFocusHandler);
			stage.addEventListener(TouchEvent.TOUCH_MOVE, touchHandler);
			stage.addEventListener(TouchEvent.TOUCH_BEGIN, touchHandler);
			stage.addEventListener(TouchEvent.TOUCH_END, touchHandler);
			stage.addEventListener(TouchEvent.TOUCH_ROLL_OVER, touchHandler);
			stage.addEventListener(TouchEvent.TOUCH_ROLL_OUT, touchHandler);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		}
	}

	public function pause():Void {
		active = false;
		visible = false;
		if (mouseHidden) {
			showMouse();
		}
		var stage = currentStage();
		if (stage != null) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			stage.removeEventListener(MouseEvent.MOUSE_OVER, mouseFocusHandler);
			stage.removeEventListener(MouseEvent.MOUSE_OUT, mouseFocusHandler);
			stage.removeEventListener(TouchEvent.TOUCH_MOVE, touchHandler);
			stage.removeEventListener(TouchEvent.TOUCH_BEGIN, touchHandler);
			stage.removeEventListener(TouchEvent.TOUCH_END, touchHandler);
			stage.removeEventListener(TouchEvent.TOUCH_ROLL_OVER, touchHandler);
			stage.removeEventListener(TouchEvent.TOUCH_ROLL_OUT, touchHandler);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		}
	}

	public function isActive():Bool {
		return active;
	}

	public function getMouse():Null<MouseEvent> {
		return me;
	}

	public function isMouseDown():Bool {
		return mouseDown;
	}

	public function getID():Int {
		return -1;
	}

	public function remove():Void {
		pause();
		if (instance == this) {
			instance = null;
		}
		me = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	function hideMouse():Void {
		mouseHidden = true;
		try {
			Mouse.hide();
		} catch (_:Dynamic) {}
	}

	function showMouse():Void {
		mouseHidden = false;
		try {
			Mouse.show();
			Mouse.cursor = MouseCursor.ARROW;
			Mouse.cursor = MouseCursor.AUTO;
		} catch (_:Dynamic) {}
	}

	function mouseMoveHandler(e:MouseEvent):Void {
		me = e;
		var point = eventStagePoint(e);
		x = point.x;
		y = point.y;
	}

	function mouseDownHandler(e:MouseEvent):Void {
		me = e;
		mouseDown = true;
	}

	function mouseUpHandler(e:MouseEvent):Void {
		me = e;
		mouseDown = false;
	}

	function mouseFocusHandler(e:MouseEvent):Void {
		me = e;
	}

	function touchHandler(e:TouchEvent):Void {
		var mouseType = touchTypeToMouseType(e.type);
		if (mouseType != null) {
			dispatchEvent(new MouseEvent(mouseType));
		}
	}

	function keyDownHandler(_:KeyboardEvent):Void {}

	function keyUpHandler(_:KeyboardEvent):Void {}

	function applyCursorGraphic(d:DisplayObject):Void {
		d.x = -(d.width / 2);
		d.y = -(d.height / 2);
		var interactive = Std.downcast(d, InteractiveObject);
		if (interactive != null) {
			interactive.mouseEnabled = false;
		}
		addChild(d);
	}

	function currentStage():Null<Stage> {
		if (stageRef != null) {
			return stageRef;
		}
		if (AppStage.stage != null) {
			return AppStage.stage;
		}
		return stage;
	}

	static function eventStagePoint(e:MouseEvent):Point {
		if (e.stageX == 0 && e.stageY == 0 && (e.localX != 0 || e.localY != 0)) {
			return new Point(e.localX, e.localY);
		}
		return new Point(e.stageX, e.stageY);
	}

	public static function touchTypeToMouseType(type:String):Null<String> {
		return switch (type) {
			case TouchEvent.TOUCH_MOVE: MouseEvent.MOUSE_MOVE;
			case TouchEvent.TOUCH_BEGIN: MouseEvent.MOUSE_DOWN;
			case TouchEvent.TOUCH_END: MouseEvent.MOUSE_UP;
			case TouchEvent.TOUCH_ROLL_OVER: MouseEvent.MOUSE_OVER;
			case TouchEvent.TOUCH_ROLL_OUT: MouseEvent.MOUSE_OUT;
			default: null;
		}
	}
}
