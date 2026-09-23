package pr2.lobby.dialogs;

import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.util.DisplayUtil;

/**
	Port of Flash `menu.CreditsPopup`: the credits modal reached from the lobby
	bottom strip. Renders the authored `CreditsPopupGraphic` and wires the close
	button to fade out, matching the base `Popup` lifecycle.

	The XFL authors inactive credit pages on hidden layers. This popup opts into
	instantiating those layers, then applies the same initial state and link-driven
	pagination as the original ActionScript.
**/
class CreditsPopup extends Popup {
	public var artPage(get,never):Int;
	public var musicPage(get,never):Int;

	private var art:CreditsView;
	private var closeBinding:Null<Binding>;
	private var credits:Null<CreditsContent>;

	public function new() {
		super();
		art = new CreditsView();
		addChild(art);
		credits = new CreditsContent(art);
		closeBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "close_bt"), function():Void startFadeOut());
	}
	private function get_artPage():Int return credits==null?1:credits.artPage;
	private function get_musicPage():Int return credits==null?1:credits.musicPage;

	override public function remove():Void {
		if(credits!=null){credits.remove();credits=null;}
		LobbyArt.unbind(closeBinding);
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
