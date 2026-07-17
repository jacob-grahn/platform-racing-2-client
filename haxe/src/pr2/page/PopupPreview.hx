package pr2.page;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.gameplay.FinishedPage;
import pr2.lobby.account.LoadoutsPopup;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.CreditsPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.PMRFCodesPopup;
import pr2.lobby.dialogs.SendMessagePopup;

/** Deterministic visual-parity route: `?screen=popup&popup=<variant>`. */
class PopupPreview extends Sprite {
	private final variant:String;

	public function new(variant:Null<String>) {
		super();
		this.variant = variant == null ? "message" : variant;
		graphics.beginFill(0x88A6C5);
		graphics.drawRect(0, 0, 550, 400);
		graphics.endFill();
		addEventListener(Event.ADDED_TO_STAGE, show);
	}

	private function show(_:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, show);
		switch (variant) {
			case "confirm": new ConfirmPopup(function() {}, "Are you sure you want to continue?");
			case "finished":
				var finished = new FinishedPage(6497936);
				finished.award("Level Completed", "+ 26");
				finished.setExpGain(520, 546, 546);
			case "send-message": new SendMessagePopup("Jiggmin", "Hello from Platform Racing 2!");
			case "codes": new PMRFCodesPopup();
			case "credits": new CreditsPopup();
			case "loadouts": new LoadoutsPopup(null, null, null);
			default: new MessagePopup("This is a representative popup message.");
		}
	}
}
