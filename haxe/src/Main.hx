package;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import pr2.Constants;

class Main extends Sprite {
	private var background:Shape;
	private var frameCounter:Int = 0;
	private var pressedKeys:Map<Int, Bool> = new Map();
	private var inputLog:Array<String> = [];
	private var statusText:TextField;
	private var pointerText:TextField;

	public function new() {
		super();

		if (stage != null) {
			init();
		} else {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?event:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, init);

		stage.frameRate = Constants.FRAME_RATE;
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;

		drawBackground();
		createHud();
		addEventListeners();
		logInput("boot stage=" + Constants.STAGE_WIDTH + "x" + Constants.STAGE_HEIGHT + " fps=" + Constants.FRAME_RATE);
	}

	private function drawBackground():Void {
		background = new Shape();
		background.graphics.beginFill(Constants.BACKGROUND_COLOR);
		background.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		background.graphics.endFill();
		addChild(background);
	}

	private function createHud():Void {
		statusText = makeTextField(10, 8, 360, 160, 0xFFFFFF);
		addChild(statusText);

		pointerText = makeTextField(10, Constants.STAGE_HEIGHT - 54, 360, 44, 0xD7E8FF);
		addChild(pointerText);
	}

	private function makeTextField(x:Float, y:Float, width:Float, height:Float, color:Int):TextField {
		var field = new TextField();
		field.defaultTextFormat = new TextFormat("_sans", 12, color);
		field.selectable = false;
		field.mouseEnabled = false;
		field.multiline = true;
		field.wordWrap = true;
		field.autoSize = TextFieldAutoSize.NONE;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		return field;
	}

	private function addEventListeners():Void {
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(MouseEvent.CLICK, onMouseClick);
	}

	private function onEnterFrame(event:Event):Void {
		frameCounter++;
		statusText.text = "Platform Racing 2 OpenFL port\n"
			+ "frame=" + frameCounter + " fixedDt=" + Constants.FIXED_TIMESTEP_SECONDS + "\n"
			+ "keys=" + describePressedKeys() + "\n\n"
			+ inputLog.join("\n");
	}

	private function onKeyDown(event:KeyboardEvent):Void {
		if (!pressedKeys.exists(event.keyCode)) {
			pressedKeys.set(event.keyCode, true);
			logInput("key down " + keyName(event.keyCode));
		}
	}

	private function onKeyUp(event:KeyboardEvent):Void {
		if (pressedKeys.exists(event.keyCode)) {
			pressedKeys.remove(event.keyCode);
		}
		logInput("key up " + keyName(event.keyCode));
	}

	private function onMouseMove(event:MouseEvent):Void {
		pointerText.text = "mouse x=" + Math.round(event.stageX) + " y=" + Math.round(event.stageY);
	}

	private function onMouseDown(event:MouseEvent):Void {
		logInput("mouse down x=" + Math.round(event.stageX) + " y=" + Math.round(event.stageY));
	}

	private function onMouseUp(event:MouseEvent):Void {
		logInput("mouse up x=" + Math.round(event.stageX) + " y=" + Math.round(event.stageY));
	}

	private function onMouseClick(event:MouseEvent):Void {
		logInput("mouse click x=" + Math.round(event.stageX) + " y=" + Math.round(event.stageY));
	}

	private function logInput(message:String):Void {
		inputLog.unshift("[" + frameCounter + "] " + message);
		if (inputLog.length > 8) {
			inputLog.pop();
		}
	}

	private function describePressedKeys():String {
		var names:Array<String> = [];
		for (keyCode in pressedKeys.keys()) {
			names.push(keyName(keyCode));
		}
		names.sort(Reflect.compare);
		return names.length == 0 ? "(none)" : names.join(", ");
	}

	private function keyName(keyCode:Int):String {
		return switch (keyCode) {
			case Keyboard.LEFT: "left";
			case Keyboard.RIGHT: "right";
			case Keyboard.UP: "up";
			case Keyboard.DOWN: "down";
			case Keyboard.SPACE: "space";
			case Keyboard.SHIFT: "shift";
			case Keyboard.CONTROL: "control";
			case Keyboard.ENTER: "enter";
			case Keyboard.ESCAPE: "escape";
			default: Std.string(keyCode);
		}
	}
}
