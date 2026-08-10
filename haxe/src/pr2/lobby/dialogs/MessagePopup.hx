package pr2.lobby.dialogs;

/**
	Port of Flash `dialogs.MessagePopup`: a modal showing an HTML message and an OK
	button that fades the popup out.
**/
class MessagePopup extends Popup {
	private var art:MessageDialogView;
	private var afterClose:Null<Void->Void>;
	private var closeRequested:Bool = false;

	public function new(message:String, ?afterClose:Void->Void) {
		super();
		this.afterClose = afterClose;
		art = new MessageDialogView(message);
		art.onClose = function():Void {
			closeRequested = true;
			startFadeOut();
		};
		addChild(art);
	}

	override public function remove():Void {
		var callback = closeRequested ? afterClose : null;
		afterClose = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
		if (callback != null) callback();
	}
}
