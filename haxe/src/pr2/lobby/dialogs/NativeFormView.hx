package pr2.lobby.dialogs;

import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Native composition shared by the account settings forms. */
class NativeFormView extends NativeView {
	public final inputs:Map<String, GameTextInput> = new Map();
	public final panels:Array<Shape> = [];
	public final labels:Array<TextField> = [];
	public var submitButton(default, null):GameButton;
	public var cancelButton(default, null):GameButton;
	public var onSubmit:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;

	public function new(linkage:String) {
		super();
		switch (linkage) {
			case "ChangePasswordPopupGraphic": buildChangePassword();
			case "SetEmailPopupGraphic": buildSetEmail();
			case "TransferGuildPopupGraphic": buildTransferGuild();
			case "LogoutPassPopupGraphic": buildLegacyLogout();
			default:
				throw 'Unsupported native form: $linkage';
		}
	}

	private function buildChangePassword():Void {
		addPanel(-145, -88.25, 1.06626892089844, 0.9222412109375);
		addLabel("-- Change Password --", -88, -76.25, 176, 17.05, 14, true, TextFormatAlign.CENTER);
		addLabel("current password:", -100.3, -41, 109.05, 14.55, 12, false, TextFormatAlign.LEFT);
		addLabel("new password:", -81.75, -13, 90.35, 14.55, 12, false, TextFormatAlign.LEFT);
		addLabel("confirm new password:", -130.875, 15, 139.61, 14.55, 12, false, TextFormatAlign.LEFT);
		addInput("currentPassBox", 20.2, -43, true, 0);
		addInput("newPassBox1", 20.2, -15, true, 0);
		addInput("newPassBox2", 20.2, 13, true, 0);
		addButtons("ok_bt", "OK", -80, 7, 52, 74.0005493164062);
	}

	private function buildSetEmail():Void {
		addPanel(-145, -88.25, 1.06626892089844, 0.92236328125);
		addLabel("-- Change Email --", -73, -76.25, 146, 17.05, 14, true, TextFormatAlign.CENTER);
		addLabel("password:", -69.85, -41, 61.9, 14.55, 12, false, TextFormatAlign.LEFT);
		addLabel("new email:", -74.65, -13, 66.7, 14.55, 12, false, TextFormatAlign.LEFT);
		addLabel("confirm new email:", -124.55, 15, 116.33, 14.55, 12, false, TextFormatAlign.LEFT);
		addInput("passBox", 1.2, -43, true, 100);
		addInput("email1Box", 1.2, -15, false, 100);
		addInput("email2Box", 1.2, 13, false, 100);
		addButtons("ok_bt", "OK", -80, 7, 52, 74.0005493164062);
	}

	private function buildTransferGuild():Void {
		addPanel(-145, -116, 1.06626892089844, 0.92236328125);
		addPanel(-145, 65.7, 1.06640625, 0.26177978515625);
		addLabel("-- Transfer Guild --", -78, -104, 156, 17.05, 14, true, TextFormatAlign.CENTER);
		addLabel("your email:", -76.4, -68.75, 68.55, 14.55, 12, false, TextFormatAlign.RIGHT);
		addLabel("your pass:", -71.65, -40.75, 63.8, 14.55, 12, false, TextFormatAlign.LEFT);
		addLabel("new owner's name:", -126.05, -12.75, 118.2, 14.55, 12, false, TextFormatAlign.LEFT);
		addLabel("This lets you transfer ownership of your guild to a fellow guild member.", -117.25, 76.15, 234.5, 29.1, 12, false,
			TextFormatAlign.CENTER);
		addInput("emailBox", 4, -70.75, false, 100);
		addInput("passBox", 4, -42.75, true, 0);
		addInput("nameBox", 4, -14.75, false, 20);
		addButtons("ok_bt", "OK", -80, 7, 24.25, 74.0005493164062);
	}

	private function buildLegacyLogout():Void {
		addPanel(-122.45, -79.15, 0.900650024414062, 0.837631225585938);
		addLabel("-- Almost Done! --", -107.95, -68, 216.95, 17.05, 14, true, TextFormatAlign.CENTER);
		addLabel("For your security, please enter your password to log out.", -107.95, -43, 216.95, 29.1, 12, false,
			TextFormatAlign.CENTER);
		addLabel("pass:", -86.3, 2, 32.55, 14.55, 12, false, TextFormatAlign.LEFT);
		addInput("passBox", -43.5, 0, true, 0, 129.998779296875);
		addButtons("logout_bt", "Log Out", -80, 7, 40, 74.0005493164062);
	}

	private function addPanel(x:Float, y:Float, scaleX:Float, scaleY:Float):Shape {
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = x;
		panel.y = y;
		panel.scaleX = scaleX;
		panel.scaleY = scaleY;
		panels.push(panel);
		addChild(panel);
		return panel;
	}

	private function addInput(name:String, x:Float, y:Float, password:Bool, maxChars:Int, width:Float = 110.000610351562):GameTextInput {
		var input = ownControl(new GameTextInput());
		input.name = name;
		input.x = x;
		input.y = y;
		input.setSize(width, 22);
		input.displayAsPassword = password;
		input.maxChars = maxChars;
		inputs.set(name, input);
		addChild(input);
		return input;
	}

	private function addButtons(submitName:String, submitLabel:String, submitX:Float, cancelX:Float, y:Float, width:Float):Void {
		submitButton = ownControl(new GameButton(submitLabel));
		submitButton.name = submitName;
		submitButton.x = submitX;
		submitButton.y = y;
		submitButton.setSize(width, 22);
		submitButton.onPress = function():Void if (onSubmit != null) onSubmit();
		addChild(submitButton);
		cancelButton = ownControl(new GameButton("Cancel"));
		cancelButton.name = "cancel_bt";
		cancelButton.x = cancelX;
		cancelButton.y = y;
		cancelButton.setSize(width, 22);
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
		field.multiline = height > 18;
		field.wordWrap = height > 18;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null, align);
		field.text = value;
		labels.push(field);
		addChild(field);
	}

	override public function dispose():Void {
		onSubmit = null;
		onCancel = null;
		super.dispose();
	}
}
