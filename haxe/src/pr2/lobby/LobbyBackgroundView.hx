package pr2.lobby;

import openfl.display.Shape;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;

/** Exact frame-zero composition of XFL `UI/Pages/Lobby/LobbyBackground`. */
class LobbyBackgroundView extends NativeView {
	private final art:Shape;

	public function new() {
		super();
		art = NativeAssets.svg(StaticSvg.LobbyBackground);
		addChild(art);
		mouseEnabled = false;
		mouseChildren = false;
	}
}
