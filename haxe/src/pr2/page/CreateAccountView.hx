package pr2.page;

import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Keyboard;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Explicit native composition of CreateAccountPopupGraphic. */
class CreateAccountView extends NativeView {
	public final nameInput:GameTextInput;
	public final passwordInput:GameTextInput;
	public final confirmationInput:GameTextInput;
	public final emailInput:GameTextInput;
	public final submitButton:GameButton;
	public final cancelButton:GameButton;
	public var onSubmit:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;

	public function new(name:String, password:String, confirmation:String, email:String) {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -121.9;
		panel.y = -130.35;
		panel.scaleX = 0.896774291992188;
		panel.scaleY = 1.36300659179688;
		addChild(panel);

		addLabel("-- Create Account --", -78, -118.25, 156, 17.05, 14, true, TextFormatAlign.CENTER);
		addLabel("name:", -90, -83, 41, 14.55, 12, false, TextFormatAlign.RIGHT);
		addLabel("pass:", -90, -55, 41, 14.55, 12, false, TextFormatAlign.RIGHT);
		addLabel("confirm pass:", -91, -27, 82, 14.55, 12, false, TextFormatAlign.RIGHT);
		addLabel("email (optional):", -110, 1.75, 101, 14.55, 12, false, TextFormatAlign.RIGHT);
		addLabel("The only time your email will ever be\nused is if you forget your password\nand need to recover it.", -97.1, 39, 188, 40.45, 10, false, TextFormatAlign.LEFT, 0x666666);

		nameInput = addInput("nameBox", name, 2, -85, false);
		nameInput.textField.maxChars = 20;
		passwordInput = addInput("passBox1", password, 2, -57, true);
		confirmationInput = addInput("passBox2", confirmation, 2, -29, true);
		emailInput = addInput("emailBox", email, 2, -1, false);

		submitButton = ownControl(new GameButton("Create Account"));
		submitButton.name = "createAccount_bt";
		submitButton.x = -108;
		submitButton.y = 97;
		submitButton.setSize(102, 22);
		submitButton.onPress = function():Void if (onSubmit != null) onSubmit();
		addChild(submitButton);

		cancelButton = ownControl(new GameButton("Cancel"));
		cancelButton.name = "cancel_bt";
		cancelButton.x = 7;
		cancelButton.y = 97;
		cancelButton.setSize(102, 22);
		cancelButton.onPress = function():Void if (onCancel != null) onCancel();
		addChild(cancelButton);
	}

	private function addInput(name:String, value:String, x:Float, y:Float, password:Bool):GameTextInput {
		var input = ownControl(new GameTextInput(value));
		input.name = name;
		input.x = x;
		input.y = y;
		input.setSize(121, 22);
		input.textField.displayAsPassword = password;
		listen(input.textField, KeyboardEvent.KEY_DOWN, onInputKey);
		addChild(input);
		return input;
	}

	private function addLabel(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign,
		color:Int = 0):Void {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
	}

	private function onInputKey(event:KeyboardEvent):Void {
		if (event.keyCode == Keyboard.ENTER && onSubmit != null) onSubmit();
	}

	override public function dispose():Void {
		onSubmit = null;
		onCancel = null;
		super.dispose();
	}
}
