package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

private typedef FormFieldSpec = {final name:String; final label:String; final password:Bool;}

/** Native composition shared by the account settings forms. */
class NativeFormView extends NativeView {
	public final inputs:Map<String, GameTextInput> = new Map();
	public var onSubmit:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;

	public function new(linkage:String) {
		super();
		var title:String;
		var description = "";
		var submitName = "ok_bt";
		var submitLabel = "OK";
		var fields:Array<FormFieldSpec>;
		switch (linkage) {
			case "ChangePasswordPopupGraphic":
				title = "-- Change Password --";
				fields = [
					{name: "currentPassBox", label: "current password:", password: true},
					{name: "newPassBox1", label: "new password:", password: true},
					{name: "newPassBox2", label: "confirm new password:", password: true}
				];
			case "SetEmailPopupGraphic":
				title = "-- Change Email --";
				fields = [
					{name: "email1Box", label: "new email:", password: false},
					{name: "email2Box", label: "confirm new email:", password: false},
					{name: "passBox", label: "password:", password: true}
				];
			case "TransferGuildPopupGraphic":
				title = "-- Transfer Guild --";
				description = "This lets you transfer ownership of your guild\nto a fellow guild member.";
				fields = [
					{name: "nameBox", label: "new owner's name:", password: false},
					{name: "passBox", label: "your pass:", password: true},
					{name: "emailBox", label: "your email:", password: false}
				];
			case "LogoutPassPopupGraphic":
				title = "-- Almost Done! --";
				description = "For your security, please enter your password to log out.";
				submitName = "logout_bt";
				submitLabel = "Log Out";
				fields = [{name: "passBox", label: "pass:", password: true}];
			default:
				throw 'Unsupported native form: $linkage';
		}

		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -140;
		panel.y = -105;
		panel.scaleX = 1.03;
		panel.scaleY = description == "" ? 1.08 : 1.28;
		addChild(panel);
		addLabel(title, -105, -91, 210, 18, 14, true, TextFormatAlign.CENTER);
		for (index in 0...fields.length) {
			var spec = fields[index];
			var y = -55 + index * 30;
			addLabel(spec.label, -126, y + 3, 105, 16, 11, false, TextFormatAlign.RIGHT);
			var input = ownControl(new GameTextInput());
			input.name = spec.name;
			input.x = -15;
			input.y = y;
			input.setSize(130, 22);
			input.textField.displayAsPassword = spec.password;
			inputs.set(spec.name, input);
			addChild(input);
		}
		if (description != "") addLabel(description, -115, 37, 230, 34, 10, false, TextFormatAlign.CENTER, 0x555555);

		var ok = ownControl(new GameButton(submitLabel));
		ok.name = submitName;
		ok.x = -88;
		ok.y = description == "" ? 49 : 78;
		ok.setSize(78, 22);
		ok.onPress = function():Void if (onSubmit != null) onSubmit();
		addChild(ok);
		var cancel = ownControl(new GameButton("Cancel"));
		cancel.name = "cancel_bt";
		cancel.x = 10;
		cancel.y = ok.y;
		cancel.setSize(78, 22);
		cancel.onPress = function():Void if (onCancel != null) onCancel();
		addChild(cancel);
	}

	private function addLabel(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign,
		color:Int = 0):Void {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
	}

	override public function dispose():Void {
		onSubmit = null;
		onCancel = null;
		super.dispose();
	}
}
