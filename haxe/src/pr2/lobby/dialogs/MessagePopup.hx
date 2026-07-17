package pr2.lobby.dialogs;

/**
	Port of Flash `dialogs.MessagePopup`: a modal showing an HTML message and an OK
	button that fades the popup out.
**/
class MessagePopup extends Popup {
	private var art:MessageDialogView;

	public function new(message:String) {
		super();
		art = new MessageDialogView(message);
		art.onClose = function():Void startFadeOut();
		addChild(art);
	}

	override public function remove():Void {
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
