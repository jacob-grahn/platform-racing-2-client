package pr2.lobby.account;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.ui.ArrowButtons;

/**
	Port of Flash `player_profile.PartSelector`: a part stepper (`ArrowButtons`)
	plus a primary colour picker and an epic (second) colour picker that only shows
	for epic parts. Re-dispatches `Event.CHANGE` whenever the part or a colour
	changes. `partArray`/`epicArray` describe which ids are owned and which are epic
	(`"*"` meaning every id is epic).
**/
class PartSelector extends Sprite {
	public var partArray:Array<String>;
	public var epicArray:Array<String>;
	public final infoButton:Sprite;

	private var arrows:ArrowButtons;
	private var cp:ColorPicker;
	private var cp2:ColorPicker;
	private var epicOverlay:Sprite;
	private var color:Int = 0;
	private var color2:Int = -1;
	private var value:Int = 0;

	public function new(parts:Array<String>, selected:Int, col:Int, epics:Array<String>, ecol:Int = -1) {
		super();
		this.value = selected;
		this.color = col;
		this.color2 = ecol;
		this.partArray = parts;
		this.epicArray = epics;

		cp = new ColorPicker();
		cp.setColor(color);
		cp.x = 120;
		cp.addEventListener(Event.CHANGE, onColorChange);
		addChild(cp);

		cp2 = new ColorPicker();
		cp2.setColor(color2 < 0 ? 0 : color2);
		cp2.x = 120;
		cp2.y = 22;
		cp2.addEventListener(Event.CHANGE, onColorChange);
		addChild(cp2);

		epicOverlay = makeDiagonalLine(14, 14);
		epicOverlay.x = cp2.x + 3;
		epicOverlay.y = cp2.y + 3;
		addChild(epicOverlay);

		var values = [for (p in parts) Std.parseInt(p) == null ? 0 : Std.parseInt(p)];
		arrows = new ArrowButtons(values, selected);
		arrows.addEventListener(Event.CHANGE, onArrowChange);
		addChild(arrows);

		infoButton = new Sprite();
		infoButton.graphics.beginFill(0x000000, 0);
		infoButton.graphics.drawRect(0, 0, 15, 20);
		infoButton.graphics.endFill();
		infoButton.x = cp.x + 27.5;
		infoButton.y = cp.y + 3;
		addChild(infoButton);

		cpEpicCheck();
	}

	public function getColor():Int {
		return color;
	}

	public function getColorCP2():Int {
		return cp2.getColor();
	}

	public function getColor2():Int {
		return isPartEpic() ? color2 : -1;
	}

	public function getValue():Int {
		return value;
	}

	public function setValue(newVal:Int):Void {
		value = newVal;
		cpEpicCheck();
		arrows.setValue(value);
	}

	public function setColors(newColor:Int, newColor2:Int):Void {
		cp.setColor(newColor);
		cp2.setColor(newColor2 == -1 ? color2 : newColor2);
		color = newColor;
		color2 = newColor2 == -1 ? color2 : newColor2;
		cpEpicCheck();
	}

	public function randomize():Void {
		var newVal = partArray.length == 0 ? value : Std.parseInt(partArray[Std.int(Math.floor(Math.random() * partArray.length))]);
		if (newVal == null) {
			newVal = value;
		}
		setColors(Std.int(Math.random() * 0xFFFFFF), Std.int(Math.random() * 0xFFFFFF));
		setValue(newVal);
	}

	public function isPartEpic(?val:Int):Bool {
		var key = val != null ? Std.string(val) : Std.string(value);
		return epicArray.indexOf(key) != -1 || epicArray.indexOf("*") != -1;
	}

	private function onColorChange(_:Event):Void {
		color = cp.getColor();
		color2 = cp2.getColor();
		dispatchEvent(new Event(Event.CHANGE));
	}

	private function onArrowChange(_:Event):Void {
		value = arrows.value;
		cpEpicCheck();
		dispatchEvent(new Event(Event.CHANGE));
	}

	private function cpEpicCheck():Void {
		var epic = isPartEpic();
		cp2.visible = epic;
		epicOverlay.visible = epic;
	}

	private function makeDiagonalLine(w:Int, h:Int):Sprite {
		var s = new Sprite();
		s.graphics.lineStyle(1, 0);
		s.graphics.moveTo(0, h);
		s.graphics.lineTo(w, 0);
		s.alpha = 0.5;
		s.mouseEnabled = false;
		s.mouseChildren = false;
		return s;
	}

	public function remove():Void {
		cp.removeEventListener(Event.CHANGE, onColorChange);
		cp.remove();
		cp2.removeEventListener(Event.CHANGE, onColorChange);
		cp2.remove();
		arrows.removeEventListener(Event.CHANGE, onArrowChange);
		arrows.remove();
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
