package pr2.page;

import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import pr2.Constants;

/**
	Placeholder for the Flash `menu.LoginPage`. The intro flow transitions here
	once the intros finish or are skipped. The real login UI is not ported yet,
	so this just paints the stage background and a label.

	TODO: port the actual login page (server check, account fields, etc.).
**/
class LoginPage extends Page {
	public function new() {
		super();
	}

	override public function initialize():Void {
		var background = new Shape();
		background.graphics.beginFill(Constants.BACKGROUND_COLOR);
		background.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		background.graphics.endFill();
		addChild(background);

		var label = new TextField();
		label.defaultTextFormat = new TextFormat("_sans", 14, 0xD7E8FF);
		label.selectable = false;
		label.mouseEnabled = false;
		label.autoSize = TextFieldAutoSize.LEFT;
		label.text = "Login page (not yet ported)";
		label.x = 20;
		label.y = 20;
		addChild(label);
	}
}
