package pr2.lobby.dialogs;

import pr2.lobby.LobbyArt;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `dialogs.ConfirmPopup`: an OK/Cancel modal. OK runs the supplied
	callback then fades out; Cancel just fades out.
**/
class ConfirmPopup extends Popup {
	private var art:PR2MovieClip;
	private var confirmFunction:Void->Void;
	private var okBinding:Null<LobbyArt.Binding>;
	private var cancelBinding:Null<LobbyArt.Binding>;

	public function new(confirmFunction:Void->Void, message:String = "Are you sure?") {
		super();
		this.confirmFunction = confirmFunction;
		art = PR2MovieClip.fromLinkage("ConfirmPopupGraphic", {maxNestedDepth: 4});
		var textBox = LobbyArt.text(art, "textBox");
		if (textBox != null) {
			textBox.htmlText = message;
		}
		addChild(art);
		okBinding = LobbyArt.bind(LobbyArt.findByName(art, "ok_bt"), clickOk);
		cancelBinding = LobbyArt.bind(LobbyArt.findByName(art, "cancel_bt"), function():Void startFadeOut());
	}

	private function clickOk():Void {
		confirmFunction();
		startFadeOut();
	}

	override public function remove():Void {
		LobbyArt.unbind(okBinding);
		LobbyArt.unbind(cancelBinding);
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
