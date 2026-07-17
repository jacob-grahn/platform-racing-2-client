package pr2.lobby.dialogs;

import pr2.lobby.chat.HtmlNameMaker;

/** Rich-formatting reference popup used by `SendMessagePopup`. */
class PMRFCodesPopup extends Popup {
	private var art:Null<PMRFCodesView>;
	private var htmlNameMaker:Null<HtmlNameMaker>;

	public function new() {
		super();
		art = new PMRFCodesView();
		htmlNameMaker = new HtmlNameMaker();
		var links = art.linksBox;
		if (links != null) {
			htmlNameMaker.listenForLink(links);
			links.htmlText = htmlNameMaker.makeLink("https://pr2hub.com/", "https://pr2hub.com/") + "<br/>"
				+ htmlNameMaker.makeLink("PR2 Hub Website", "https://pr2hub.com/") + "<br/>"
				+ htmlNameMaker.makeName("Jiggmin", "3") + "<br/>"
				+ htmlNameMaker.makeLevel("Newbieland 2", 50815) + "<br/>"
				+ htmlNameMaker.makeGuild("PR2 Staff", 183);
		}
		addChild(art);
		art.onClose = startFadeOut;
	}

	override public function remove():Void {
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
