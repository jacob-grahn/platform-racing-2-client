package pr2.lobby.dialogs;

import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `dialogs.PlayerGuestPopup`: the stripped-down profile popup shown
	when a clicked name resolves to a guest (or `PlayerPopup` gets guest data back).
	It is just the name header and a Close button. The moderator ban menu
	(group >= 2 only) is an upstream symbol that is not ported yet and is omitted.
**/
class PlayerGuestPopup extends Popup {
	private var art:Null<PR2MovieClip>;
	private var closeBinding:Null<Binding>;

	public function new(name:String) {
		super();
		art = PR2MovieClip.fromLinkage("PlayerGuestPopupGraphic", {maxNestedDepth: 5});
		var nameBox:Null<TextField> = LobbyArt.text(art, "nameBox");
		if (nameBox != null) {
			nameBox.text = "-- " + name + " --";
		}
		addChild(art);
		closeBinding = LobbyArt.bind(LobbyArt.findByName(art, "close_bt"), startFadeOut);
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
