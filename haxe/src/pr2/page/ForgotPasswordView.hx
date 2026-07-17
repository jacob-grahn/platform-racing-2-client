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

/** Explicit native composition of ForgotPassPopupGraphic. */
class ForgotPasswordView extends NativeView {
	public final nameInput:GameTextInput;
	public final emailInput:GameTextInput;
	public final submitButton:GameButton;
	public final cancelButton:GameButton;
	public var onSubmit:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;

	public function new(prefilledName:String) {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -100;
		panel.y = -109;
		panel.scaleX = 0.735366821289062;
		panel.scaleY = 1.14141845703125;
		addChild(panel);

		addLabel("-- Forgot Password --", -85.5, -97.25, 170, 17.05, 14, true, TextFormatAlign.CENTER);
		addLabel("name:", -83.9, -62, 41, 14.55, 12, false, TextFormatAlign.RIGHT);
		addLabel("email:", -83.9, -34, 40.95, 14.55, 12, false, TextFormatAlign.RIGHT);
		addLabel("If you entered an email address\nwhen you registered, then you can\nhave a new password sent to that\nemail address.", -83, 0, 166, 54.6, 10, false, TextFormatAlign.CENTER, 0x444444);

		nameInput = ownControl(new GameTextInput(prefilledName));
		nameInput.name = "nameBox";
		nameInput.x = -36;
		nameInput.y = -62;
		nameInput.setSize(120, 22);
		nameInput.textField.maxChars = 20;
		listen(nameInput.textField, KeyboardEvent.KEY_DOWN, onInputKey);
		addChild(nameInput);

		emailInput = ownControl(new GameTextInput());
		emailInput.name = "emailBox";
		emailInput.x = -36;
		emailInput.y = -34;
		emailInput.setSize(120, 22);
		listen(emailInput.textField, KeyboardEvent.KEY_DOWN, onInputKey);
		addChild(emailInput);

		submitButton = ownControl(new GameButton("OK"));
		submitButton.name = "ok_bt";
		submitButton.x = -80;
		submitButton.y = 74;
		submitButton.setSize(74, 22);
		submitButton.onPress = function():Void if (onSubmit != null) onSubmit();
		addChild(submitButton);

		cancelButton = ownControl(new GameButton("Cancel"));
		cancelButton.name = "cancel_bt";
		cancelButton.x = 6;
		cancelButton.y = 74;
		cancelButton.setSize(74, 22);
		cancelButton.onPress = function():Void if (onCancel != null) onCancel();
		addChild(cancelButton);
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
