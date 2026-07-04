package pr2.lobby.dialogs;

import pr2.lobby.LobbyArt;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/** Rich-formatting reference popup used by `SendMessagePopup`. */
class PMRFCodesPopup extends Popup {
	private var art:Null<PR2MovieClip>;
	private var closeBinding:Null<LobbyArt.Binding>;
	private var htmlNameMaker:Null<HtmlNameMaker>;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("PMRFCodesPopupGraphic", {maxNestedDepth: 6});
		htmlNameMaker = new HtmlNameMaker();
		var links = LobbyArt.text(art, "linksBox");
		if (links != null) {
			htmlNameMaker.listenForLink(links);
			links.htmlText = htmlNameMaker.makeLink("https://pr2hub.com/", "https://pr2hub.com/") + "<br/>"
				+ htmlNameMaker.makeLink("PR2 Hub Website", "https://pr2hub.com/") + "<br/>"
				+ htmlNameMaker.makeName("Jiggmin", "3") + "<br/>"
				+ htmlNameMaker.makeLevel("Newbieland 2", 50815) + "<br/>"
				+ htmlNameMaker.makeGuild("PR2 Staff", 183);
		}
		addChild(art);
		closeBinding = LobbyArt.bind(DisplayUtil.findByName(art, "close_bt"), startFadeOut);
	}

	override public function remove():Void {
		LobbyArt.unbind(closeBinding);
		if (htmlNameMaker != null) {
			htmlNameMaker.remove();
			htmlNameMaker = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
