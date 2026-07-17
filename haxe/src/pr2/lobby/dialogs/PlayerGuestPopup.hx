package pr2.lobby.dialogs;

import pr2.lobby.LobbySession;

/**
	Port of Flash `dialogs.PlayerGuestPopup`: the stripped-down profile popup shown
	when a clicked name resolves to a guest (or `PlayerPopup` gets guest data back).
	It is just the name header and a Close button. The moderator ban menu
	(group >= 2 only) matches Flash's `dialogs.BanMenu`.
**/
class PlayerGuestPopup extends Popup {
	private var art:Null<PlayerGuestView>;
	private var banMenu:Null<BanMenu>;

	public function new(name:String) {
		super();
		art = new PlayerGuestView(name);
		addChild(art);
		art.onClose = startFadeOut;
		if (LobbySession.group >= 2) {
			banMenu = new BanMenu(name, this);
			banMenu.x = banMenu.width / 2 + 3;
			if (art != null) {
				art.x = -(art.width / 2) - 3;
			}
			addChild(banMenu);
		}
	}

	override public function remove():Void {
		if (banMenu != null) {
			banMenu.remove();
			banMenu = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
