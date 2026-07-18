package pr2.levelEditor;

import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.lobby.account.StatSlider;
import pr2.lobby.dialogs.HoverPopup;
import pr2.page.EditorBlockOptions;
import pr2.ui.controls.GameCheckBox;

class EditorCustomStatsBlockOptionsPopup extends EditorBlockOptionsPopup {
	private var speedSlider:StatSlider;
	private var accelSlider:StatSlider;
	private var jumpnSlider:StatSlider;
	private var resetCheck:Null<GameCheckBox>;
	private var resetPop:Null<HoverPopup>;

	public function new(editor:LevelEditor, block:EditorBlockObject) {
		super(editor, block, "CustomStatsBlockOptionsGraphic");
		speedSlider = makeSlider("Speed", "speedSlider", -62.75, -40);
		accelSlider = makeSlider("Acceleration", "accelSlider", -62.75, 0);
		jumpnSlider = makeSlider("Jumping", "jumpnSlider", -62.75, 40);
		resetCheck = Std.downcast(art.childNamed("resetChk"), GameCheckBox);
		if (resetCheck != null) {
			resetCheck.addEventListener(Event.CHANGE, onResetClick);
			resetCheck.addEventListener(MouseEvent.MOUSE_OVER, onResetMouse);
			resetCheck.addEventListener(MouseEvent.MOUSE_OUT, onResetMouse);
			resetCheck.selected = block.options == "reset";
		}
		var stats = EditorBlockOptions.customStats(block.options);
		speedSlider.setValue(stats[0]);
		accelSlider.setValue(stats[1]);
		jumpnSlider.setValue(stats[2]);
		onResetClick();
	}

	public function setCustomStats(speed:Int, acceleration:Int, jumping:Int):Void {
		speedSlider.setValue(speed);
		accelSlider.setValue(acceleration);
		jumpnSlider.setValue(jumping);
	}

	public function setResetSelected(selected:Bool):Void {
		if (resetCheck != null) {
			resetCheck.selected = selected;
		}
		onResetClick();
	}

	override public function remove():Void {
		onResetMouse();
		if (resetCheck != null) {
			resetCheck.removeEventListener(Event.CHANGE, onResetClick);
			resetCheck.removeEventListener(MouseEvent.MOUSE_OVER, onResetMouse);
			resetCheck.removeEventListener(MouseEvent.MOUSE_OUT, onResetMouse);
		}
		block.setOptions(EditorBlockOptions.applyCustomStats(resetCheck != null && resetCheck.selected, speedSlider.value, accelSlider.value,
			jumpnSlider.value));
		speedSlider.remove();
		accelSlider.remove();
		jumpnSlider.remove();
		super.remove();
	}

	private function makeSlider(label:String, sliderName:String, sliderX:Float, sliderY:Float):StatSlider {
		var slider = new StatSlider(label, null);
		slider.name = sliderName;
		slider.x = sliderX;
		slider.y = sliderY;
		addChild(slider);
		return slider;
	}

	private function onResetClick(?_):Void {
		var resetting = resetCheck != null && resetCheck.selected;
		for (slider in [speedSlider, accelSlider, jumpnSlider]) {
			slider.alpha = resetting ? 0.25 : 1;
			slider.mouseEnabled = !resetting;
			slider.mouseChildren = !resetting;
		}
	}

	private function onResetMouse(?event:MouseEvent):Void {
		if (event != null && event.type == MouseEvent.MOUSE_OVER && resetPop == null && resetCheck != null) {
			resetPop = new HoverPopup("Reset To Starting Stats",
				"Checking this box will reset the bumping player's stats to those with which they entered the course.", resetCheck);
		} else if (resetPop != null) {
			resetPop.remove();
			resetPop = null;
		}
	}
}
