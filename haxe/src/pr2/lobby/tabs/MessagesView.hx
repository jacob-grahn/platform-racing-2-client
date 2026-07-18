package pr2.lobby.tabs;

import openfl.display.Sprite;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Exact native composition of XFL `MessagesGraphic` (`TabPMs`). */
class MessagesView extends NativeView {
	private static inline final MASK_WIDTH:Float = 100 * 1.843994140625;
	private static inline final MASK_HEIGHT:Float = 100 * 3.39999389648438;

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
		// XFL layer 3 masks the scrolling `var_295` layer from (0, 0) through
		// (184.4, 340). Keep this as a display mask instead of scrollRect so
		// CustomScrollBar still measures the holder's complete content height.
		var scrollMask = new Sprite();
		scrollMask.name = "messagesMask";
		scrollMask.graphics.beginFill(0x000000);
		scrollMask.graphics.drawRect(0, 0, MASK_WIDTH, MASK_HEIGHT);
		scrollMask.graphics.endFill();
		addChild(scrollMask);
		holder.mask = scrollMask;
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
