package pr2.page.auth;

import openfl.display.DisplayObject;
import openfl.events.Event;
import pr2.page.LoginFlashPopup;
import pr2.page.CreateAccountView;
import pr2.page.ForgotPasswordView;
import pr2.ui.view.NativeView;
import pr2.ui.view.NativePopupView;
import pr2.ui.view.StatusPopupView;
import pr2.ui.view.ProgressPopupView;
import pr2.lobby.dialogs.ConfirmDialogView;
import pr2.lobby.dialogs.MessagePopup;

/** Adapter preserving the original dialog compositions and fade lifecycle. */
class ClassicAuthDialog extends AuthDialog {
	private var flash:LoginFlashPopup;
	private var view:NativeView;
	private var messagePopup:MessagePopup;
	private var status:StatusPopupView;
	private var progress:ProgressPopupView;
	public function new(kind:String, message:String, values:Map<String, String>) {
		super(kind);
		switch kind {
			case "LoginPopupGraphic" | "ServerSelectPopupGraphic" | "ConnectingPopupGraphic":
				flash = new LoginFlashPopup(kind); addChild(flash);
			case "Register":
				var form = new CreateAccountView(values.get("nameBox"), values.get("passBox1"), values.get("passBox2"), values.get("emailBox"));
				view = form;
				named.set("nameBox", form.nameInput.textField);
				named.set("passBox1", form.passwordInput.textField);
				named.set("passBox2", form.confirmationInput.textField);
				named.set("emailBox", form.emailInput.textField);
				form.onSubmit = function():Void if (onSubmit != null) onSubmit();
				form.onCancel = function():Void if (onCancel != null) onCancel();
			case "Recover":
				var form = new ForgotPasswordView(values.get("nameBox")); view = form;
				named.set("nameBox", form.nameInput.textField); named.set("emailBox", form.emailInput.textField);
				form.onSubmit = function():Void if (onSubmit != null) onSubmit();
				form.onCancel = function():Void if (onCancel != null) onCancel();
			case "Logging":
				status = new StatusPopupView("Logging In..."); view = status;
				status.onClose = function():Void if (onClose != null) onClose();
			case "Progress":
				overlay(); progress = new ProgressPopupView(message); view = progress;
				progress.onClose = function():Void if (onClose != null) onClose();
			case "Confirm":
				overlay(); var confirm = new ConfirmDialogView(message); view = confirm;
				confirm.onConfirm = function():Void if (onConfirm != null) onConfirm();
				confirm.onCancel = function():Void if (onCancel != null) onCancel();
			case "Message":
				messagePopup = new MessagePopup(message, function():Void if (onClose != null) onClose());
			default: throw 'Unknown authentication dialog $kind';
		}
		if (view != null) { view.x = 275; view.y = 200; addChild(view); }
	}
	private function overlay():Void {
		graphics.beginFill(0, 0.55); graphics.drawRect(0, 0, 550, 400); graphics.endFill();
	}
	override public function child(name:String):Null<DisplayObject> return flash == null ? super.child(name) : flash.child(name);
	override public function setMessage(value:String):Void {
		if (flash != null) flash.setMessage(value);
		if (status != null) status.setMessage(value);
		if (progress != null) progress.setText(value);
	}
	override public function dismiss(immediate:Bool = false):Void {
		mouseEnabled = mouseChildren = false;
		tabChildren = false;
		if (!immediate && (flash != null || Std.isOfType(view, NativePopupView))) {
			var fading:DisplayObject = flash != null ? flash : view;
			var done:Event->Void = null;
			done = function(_:Event):Void { fading.removeEventListener("removed", done); dismiss(true); };
			fading.addEventListener("removed", done);
			if (flash != null) flash.startFadeOut(); else (cast view:NativePopupView).startFadeOut();
			return;
		}
		if (flash != null) flash.remove();
		if (view != null) view.dispose();
		if (messagePopup != null) { var popup = messagePopup; messagePopup = null; onClose = null; popup.remove(); }
		super.dismiss(true);
	}
}
