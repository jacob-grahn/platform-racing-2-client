package pr2.lobby.tabs;

import openfl.display.Sprite;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Exact native composition of XFL `MessagesGraphic` (`TabPMs`). */
class MessagesView extends NativeView {
	public function new() {
		super();
		var background = new Sprite();
		background.name = "background";
		background.graphics.beginFill(0xFFFFFF, 0.501960784313725);
		background.graphics.drawRect(0, 0, 174 * 1.01148986816406, 350 * 0.971389770507812);
		background.graphics.endFill();
		addChild(background);
		var holder = new Sprite();
		holder.name = "var_295";
		addChild(holder);
		addButton("deleteAll_bt", "Delete All", 4, 346, 100 * 0.699996948242188);
		addButton("sendMessage_bt", "Send Message", 81, 346, 100);
	}

	private function addButton(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 22);
		addChild(control);
	}
}
