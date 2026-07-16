package pr2.lobby.dialogs;


/**
	Port of Flash `dialogs.ConfirmPopup`: an OK/Cancel modal. OK runs the supplied
	callback then fades out; Cancel just fades out.
**/
class ConfirmPopup extends Popup {
	private var view:ConfirmDialogView;
	private var confirmFunction:Void->Void;

	public function new(confirmFunction:Void->Void, message:String = "Are you sure?") {
		super();
		this.confirmFunction = confirmFunction;
		view = new ConfirmDialogView(message);
		view.onConfirm = clickOk;
		view.onCancel = startFadeOut;
		addChild(view);
	}

	private function clickOk():Void {
		confirmFunction();
		startFadeOut();
	}

	override public function remove():Void {
		if (view != null) {
			view.dispose();
			view = null;
		}
		confirmFunction = function():Void {};
		super.remove();
	}
}
