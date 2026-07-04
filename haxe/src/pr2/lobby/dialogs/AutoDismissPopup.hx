package pr2.lobby.dialogs;

class AutoDismissPopup extends InfoPopup {
	private var autoDismiss:Null<AutoDismissController>;

	public function new() {
		super();
		autoDismiss = new AutoDismissController(this, remove);
	}

	override public function remove():Void {
		if (autoDismiss != null) {
			autoDismiss.remove();
			autoDismiss = null;
		}
		super.remove();
	}
}
