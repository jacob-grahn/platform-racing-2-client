package pr2.lobby.dialogs;

import pr2.lobby.LobbyArt;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/** Rich-formatting reference popup used by `SendMessagePopup`. */
class PMRFCodesPopup extends Popup {
	private var art:Null<PR2MovieClip>;
	private var closeBinding:Null<LobbyArt.Binding>;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("PMRFCodesPopupGraphic", {maxNestedDepth: 6});
		var links = LobbyArt.text(art, "linksBox");
		if (links != null) {
			links.htmlText = '<a href="https://pr2hub.com/">https://pr2hub.com/</a><br/>'
				+ '<a href="https://pr2hub.com/">PR2 Hub Website</a><br/>'
				+ '<b>Jiggmin</b><br/>Newbieland 2<br/>PR2 Staff';
		}
		addChild(art);
		closeBinding = LobbyArt.bind(DisplayUtil.findByName(art, "close_bt"), startFadeOut);
	}

	override public function remove():Void {
		LobbyArt.unbind(closeBinding);
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
