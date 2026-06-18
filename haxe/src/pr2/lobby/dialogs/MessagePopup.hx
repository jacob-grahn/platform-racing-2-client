package pr2.lobby.dialogs;

import pr2.lobby.LobbyArt;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `dialogs.MessagePopup`: a modal showing an HTML message and an OK
	button that fades the popup out.
**/
class MessagePopup extends Popup {
	private var art:PR2MovieClip;
	private var okBinding:Null<LobbyArt.Binding>;

	public function new(message:String) {
		super();
		art = PR2MovieClip.fromLinkage("MessagePopupGraphic", {maxNestedDepth: 4});
		var textBox = LobbyArt.text(art, "textBox");
		if (textBox != null) {
			textBox.htmlText = message;
		}
		addChild(art);
		okBinding = LobbyArt.bind(LobbyArt.findByName(art, "ok_bt"), function():Void startFadeOut());
	}

	override public function remove():Void {
		LobbyArt.unbind(okBinding);
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
