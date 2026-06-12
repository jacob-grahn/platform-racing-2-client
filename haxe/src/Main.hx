package;

#if js
import js.Browser;
#end
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import pr2.Constants;
import pr2.character.CharacterAppearance;
import pr2.runtime.PR2MovieClip;

class Main extends Sprite {
	private var background:Shape;
	private var characterClip:PR2MovieClip;
	private var runAnim:PR2MovieClip;
	private var frameCounter:Int = 0;
	private var pressedKeys:Map<Int, Bool> = new Map();
	private var inputLog:Array<String> = [];
	private var statusText:TextField;
	private var harnessText:TextField;
	private var pointerText:TextField;
	private var fpsWindowStartMs:Int = 0;
	private var fpsWindowFrames:Int = 0;
	private var observedFps:Int = 0;
	private var fpsSamples:Array<Int> = [];
	private static inline var CHARACTER_SCALE:Float = 0.30;
	private static inline var TEST_HAT_ID:Int = 1;
	private static inline var TEST_HEAD_ID:Int = 1;
	private static inline var TEST_BODY_ID:Int = 1;
	private static inline var TEST_FEET_ID:Int = 1;

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
		createCharacterRunHarness();
		createHud();
		addEventListeners();
		fpsWindowStartMs = Lib.getTimer();
		logInput("boot stage=" + Constants.STAGE_WIDTH + "x" + Constants.STAGE_HEIGHT + " fps=" + Constants.FRAME_RATE);
	}

	private function drawBackground():Void {
		background = new Shape();
		background.graphics.beginFill(Constants.BACKGROUND_COLOR);
		background.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		background.graphics.endFill();
		addChild(background);

		var ground = new Shape();
		ground.graphics.beginFill(0x303950);
		ground.graphics.drawRect(0, 304, Constants.STAGE_WIDTH, 96);
		ground.graphics.endFill();
		ground.graphics.lineStyle(2, 0x6D7FA8, 0.75);
		ground.graphics.moveTo(0, 304);
		ground.graphics.lineTo(Constants.STAGE_WIDTH, 304);
		addChild(ground);
	}

	private function createCharacterRunHarness():Void {
		characterClip = PR2MovieClip.fromLinkage("CharacterGraphic", {maxNestedDepth: 12});
		characterClip.x = 276;
		characterClip.y = 268;
		characterClip.scaleX = CHARACTER_SCALE;
		characterClip.scaleY = CHARACTER_SCALE;
		addChild(characterClip);

		showOnlyCharacterState("runAnim");
		if (runAnim != null) {
			runAnim.gotoAndStop(1);
		}
		CharacterAppearance.applyPartIds(characterClip, {
			hat: TEST_HAT_ID,
			head: TEST_HEAD_ID,
			body: TEST_BODY_ID,
			feet: TEST_FEET_ID
		});

		harnessText = makeTextField(350, 14, 190, 90, 0xD7E8FF);
		harnessText.text = "Character harness\n"
			+ "linkage=CharacterGraphic\n"
			+ "state=runAnim\n"
			+ "hat/head/body/feet=1\n"
			+ "fps=" + Constants.FRAME_RATE;
		addChild(harnessText);
	}

	private function showOnlyCharacterState(activeChildName:String):Void {
		var stateNames = [
			"runAnim",
			"standAnim",
			"jumpAnim",
			"superJumpAnim",
			"bumpedAnim",
			"crouchAnim",
			"crouchWalkAnim",
			"swimAnim",
			"frozenSolidAnim"
		];

		for (stateName in stateNames) {
			var child = characterClip.getChildByTimelineName(stateName);
			if (child != null) {
				child.visible = stateName == activeChildName;
				var childClip = Std.downcast(child, PR2MovieClip);
				if (childClip != null) {
					childClip.stopAll();
				}
			}
		}
		runAnim = Std.downcast(characterClip.getChildByTimelineName(activeChildName), PR2MovieClip);
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
		if (runAnim != null) {
			runAnim.advanceOneFrame();
		}
		updateObservedFps();
		statusText.text = "Platform Racing 2 OpenFL port\n"
			+ "frame=" + frameCounter + " fixedDt=" + Constants.FIXED_TIMESTEP_SECONDS + "\n"
			+ "observedFps=" + observedFps + " target=" + Constants.FRAME_RATE + "\n"
			+ "characterFrame=" + characterClip.currentFrame + "/" + characterClip.totalFrames + "\n"
			+ "runAnimFrame=" + (runAnim == null ? "(missing)" : runAnim.currentFrame + "/" + runAnim.totalFrames) + "\n"
			+ "keys=" + describePressedKeys() + "\n\n"
			+ inputLog.join("\n");
	}

	private function updateObservedFps():Void {
		fpsWindowFrames++;
		var now = Lib.getTimer();
		var elapsed = now - fpsWindowStartMs;
		if (elapsed < 1000) {
			return;
		}

		observedFps = Math.round(fpsWindowFrames * 1000 / elapsed);
		fpsWindowFrames = 0;
		fpsWindowStartMs = now;
		fpsSamples.push(observedFps);
		if (fpsSamples.length > 60) {
			fpsSamples.shift();
		}

		var message = 'observedFps=$observedFps target=${Constants.FRAME_RATE} samples=${fpsSamples.join(",")}';
		trace(message);
		#if js
		Browser.console.log(message);
		Browser.document.body.setAttribute("data-pr2-observed-fps", Std.string(observedFps));
		Browser.document.body.setAttribute("data-pr2-fps-samples", fpsSamples.join(","));
		#end
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
