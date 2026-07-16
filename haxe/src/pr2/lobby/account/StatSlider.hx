package pr2.lobby.account;

import haxe.Timer;
import openfl.display.DisplayObject;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.runtime.FlSlider;
import pr2.runtime.FlSliderEvent;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Port of Flash `ui.StatSlider`: one labelled 0–100 stat row with a slider, a
	numeric entry box, and decrement/increment buttons, all kept in sync and
	clamped against the shared points budget via the owning `StatsSelect`.

	Press-and-hold acceleration follows Flash's 8/sec -> 16/sec -> 32/sec
	thresholds, and level-editor persistence only happens from the Flash save
	paths: arrow mouse-up and slider thumb release.
**/
class StatSlider extends Sprite {
	private static inline final STAT_SLIDER_TRACK_WIDTH:Float = 80;
	private static inline final ARROW_HITBOX_SIZE:Float = 24;
	private static inline final ARROW_CENTER_X:Float = 5;
	private static inline final ARROW_CENTER_Y:Float = 8;

	public var value:Int = 0;

	private var m:PR2MovieClip;
	private var target:StatsSelect;
	private var slider:Null<FlSlider>;
	private var textBox:Null<TextField>;
	private var decButton:Null<DisplayObject>;
	private var incButton:Null<DisplayObject>;
	private var holdStart:Float = 0;
	private var holdSpeed:Int = 0;
	private var holdTimer:Null<Timer>;
	private var holdMode:String = "";

	public function new(statName:String, ss:StatsSelect) {
		super();
		this.target = ss;
		m = PR2MovieClip.fromLinkage("StatSliderGraphic", {maxNestedDepth: 6});
		addChild(m);

		var nameBox = LobbyArt.text(m, "nameBox");
		if (nameBox != null) {
			nameBox.text = statName;
		}
		textBox = LobbyArt.text(m, "textBox");
		if (textBox != null) {
			textBox.restrict = "0123456789";
			textBox.type = openfl.text.TextFieldType.INPUT;
			textBox.addEventListener(Event.CHANGE, onTextChange);
		}
		slider = Std.downcast(DisplayUtil.findByName(m, "slider"), FlSlider);
		if (slider != null) {
			slider.setSize(STAT_SLIDER_TRACK_WIDTH, slider.height);
			slider.minimum = 0;
			slider.maximum = 100;
			slider.addEventListener(Event.CHANGE, onSliderChange);
			slider.addEventListener(FlSliderEvent.THUMB_RELEASE, onSliderThumbRelease);
		}
		decButton = DisplayUtil.findByName(m, "decBtn");
		incButton = DisplayUtil.findByName(m, "incBtn");
		prepareButton(decButton);
		prepareButton(incButton);
	}

	private function prepareButton(button:Null<DisplayObject>):Void {
		if (button == null) return;
		var interactive = Std.downcast(button, InteractiveObject);
		if (interactive != null) interactive.mouseEnabled = true;
		var sprite = Std.downcast(button, Sprite);
		if (sprite != null) {
			// Draw the hit geometry on the interactive object itself. OpenFL's HTML5
			// event picker does not reliably honor an unattached Sprite.hitArea.
			sprite.graphics.beginFill(0x000000, 0.001);
			sprite.graphics.drawRect(ARROW_CENTER_X - ARROW_HITBOX_SIZE / 2, ARROW_CENTER_Y - ARROW_HITBOX_SIZE / 2,
				ARROW_HITBOX_SIZE, ARROW_HITBOX_SIZE);
			sprite.graphics.endFill();
			sprite.buttonMode = true;
			sprite.useHandCursor = true;
		}
		button.addEventListener(MouseEvent.MOUSE_DOWN, arrowBtnDown);
		button.addEventListener(MouseEvent.MOUSE_UP, arrowBtnUp);
	}

	private function onSliderChange(_:Event):Void {
		if (slider != null) {
			if (target != null) {
				target.noteUserStatChange();
			}
			setValue(Std.int(slider.value));
		}
	}

	private function onSliderThumbRelease(_:FlSliderEvent):Void {
		if (target != null) {
			target.saveLEStats();
		}
	}

	private function onTextChange(_:Event):Void {
		if (textBox != null) {
			if (target != null) {
				target.noteUserStatChange();
			}
			var parsed = Std.parseInt(textBox.text);
			setValue(parsed == null ? 0 : parsed);
		}
	}

	public function setValue(v:Int):Void {
		value = clamp(v, 0, 100);
		if (target != null) {
			var remaining = target.getPointsRemaining();
			if (remaining < 0) {
				value += remaining;
			}
			if (value < 0) {
				value = 0;
			}
		}
		if (textBox != null) {
			textBox.text = Std.string(value);
		}
		if (slider != null) {
			slider.value = value;
		}
		if (target != null) {
			target.updateStatsDisplay();
			if (target.getPointsRemaining() <= 0 && holdStart > 0) {
				arrowBtnUp();
			}
		}
	}

	private function arrowBtnDown(e:MouseEvent):Void {
		holdStart = nowMs();
		holdMode = e.currentTarget == incButton ? "inc" : "dec";
		updateHoldSpeed(holdMode);
	}

	private function arrowBtnUp(?e:Dynamic = null):Void {
		holdStart = 0;
		holdSpeed = 0;
		stopHoldTimer();
		if (target != null) {
			if (e != false) {
				target.noteUserStatChange();
			}
			target.saveLEStats();
		}
	}

	private function updateHoldSpeed(mode:String):Void {
		var elapsed = nowMs() - holdStart;
		if (elapsed <= 2000) {
			holdSpeed = 8;
			updateStatFromHeld(mode);
		} else if (elapsed <= 4000) {
			holdSpeed = 16;
		} else {
			holdSpeed = 32;
		}
		stopHoldTimer();
		if (holdSpeed <= 0) {
			return;
		}
		holdTimer = new Timer(Math.floor(1000 / holdSpeed));
		holdTimer.run = function():Void updateStatFromHeld(mode);
	}

	private function updateStatFromHeld(mode:String):Void {
		var elapsed = nowMs() - holdStart;
		var newVal = mode == "inc" ? value + 1 : value - 1;
		setValue(clamp(newVal, 0, 100));
		if ((holdSpeed == 8 && elapsed > 2000) || (holdSpeed == 16 && elapsed > 4000)) {
			updateHoldSpeed(mode);
		} else if ((newVal <= 0 && mode == "dec") || (newVal >= 100 && mode == "inc")) {
			arrowBtnUp();
		}
	}

	private function stopHoldTimer():Void {
		if (holdTimer != null) {
			holdTimer.stop();
			holdTimer = null;
		}
	}

	private function nowMs():Float {
		return com.jiggmin.data.Data.getMS();
	}

	public function beginHoldForTests(mode:String):Void {
		holdStart = nowMs();
		holdMode = mode;
		updateHoldSpeed(mode);
	}

	public function setHoldElapsedForTests(ms:Float):Void {
		holdStart = nowMs() - ms;
	}

	public function updateHoldSpeedForTests(mode:String):Void {
		updateHoldSpeed(mode);
	}

	public function updateStatFromHeldForTests(mode:String):Void {
		updateStatFromHeld(mode);
	}

	public function holdSpeedForTests():Int {
		return holdSpeed;
	}

	private static inline function clamp(v:Int, lo:Int, hi:Int):Int {
		return v < lo ? lo : (v > hi ? hi : v);
	}

	public function remove():Void {
		arrowBtnUp(false);
		if (textBox != null) {
			textBox.removeEventListener(Event.CHANGE, onTextChange);
		}
		if (slider != null) {
			slider.removeEventListener(Event.CHANGE, onSliderChange);
			slider.removeEventListener(FlSliderEvent.THUMB_RELEASE, onSliderThumbRelease);
		}
		if (decButton != null) {
			decButton.removeEventListener(MouseEvent.MOUSE_DOWN, arrowBtnDown);
			decButton.removeEventListener(MouseEvent.MOUSE_UP, arrowBtnUp);
		}
		if (incButton != null) {
			incButton.removeEventListener(MouseEvent.MOUSE_DOWN, arrowBtnDown);
			incButton.removeEventListener(MouseEvent.MOUSE_UP, arrowBtnUp);
		}
		if (m != null) {
			m.dispose();
			m = null;
		}
		target = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
