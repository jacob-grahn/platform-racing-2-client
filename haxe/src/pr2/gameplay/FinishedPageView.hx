package pr2.gameplay;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Exact XFL end-of-race shell with native dynamic award fields and buttons. */
class FinishedPageView extends NativeView {
	public static inline final SHELL_ASSET = "assets/svg/effects/finished_page_01.svg";

	public function new() {
		super();
		var shell = SvgAsset.create(SHELL_ASSET);
		shell.name = "exactShell";
		addChild(shell);
		for (index in 1...6) {
			var y = -100.5 + (index - 1) * 22;
			field("bonus" + index, -127.95, y, 161.9, 14.5, TextFormatAlign.RIGHT);
			field("exp" + index, 50.25, y, 76, 14.55, TextFormatAlign.LEFT);
		}
		field("expTotal", 50.25, 19.5, 76, 14.55, TextFormatAlign.LEFT);
		button("close_bt", "Close", -111, 121);
		button("return_bt", "Return to Lobby", 8, 121);
	}

	private function button(name:String, label:String, x:Float, y:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(100, 22);
		addChild(control);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, align:TextFormatAlign):Void {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat("Verdana", 12, 0x000000, false, null, null, null, null, align);
		text.text = "--";
		addChild(text);
	}
}
