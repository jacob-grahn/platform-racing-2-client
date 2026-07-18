package pr2.ui;

import openfl.display.DisplayObject;
import openfl.events.MouseEvent;
import pr2.display.Removable;

interface SelectableView {
	function setInteractionState(state:String):Void;
}

/** Native hover/selection state wrapper for explicitly constructed row views. */
class SelectableButton extends Removable {
	public var selectableTarget(default, null):Null<DisplayObject>;
	private var stateTarget:Null<SelectableView>;
	private var selected:Bool = false;
	private var hovering:Bool = false;

	public function new(target:DisplayObject) {
		super();
		selectableTarget = target;
		this.stateTarget = cast target;
		addEventListener(MouseEvent.MOUSE_OVER, overHandler);
		addEventListener(MouseEvent.MOUSE_OUT, outHandler);
		display();
	}

	public function setSelected(on:Bool):Void { selected = on; display(); }
	public function getSelected():Bool return selected;
	public function currentSelectableFrameForTests():String return selected ? "selected" : hovering ? "over" : "up";

	override public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_OVER, overHandler);
		removeEventListener(MouseEvent.MOUSE_OUT, outHandler);
		selectableTarget = null;
		stateTarget = null;
		super.remove();
	}

	private function overHandler(_:MouseEvent):Void { hovering = true; display(); }
	private function outHandler(_:MouseEvent):Void { hovering = false; display(); }
	private function display():Void {
		if (stateTarget != null) stateTarget.setInteractionState(currentSelectableFrameForTests());
	}
}
