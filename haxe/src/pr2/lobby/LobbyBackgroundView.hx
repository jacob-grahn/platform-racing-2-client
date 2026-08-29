package pr2.lobby;

import openfl.display.Shape;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.runtime.SvgAsset;
import pr2.ui.AuthoredScale9;
import pr2.ui.view.NativeView;

/** Exact frame-zero composition of XFL `UI/Pages/Lobby/LobbyBackground`. */
class LobbyBackgroundView extends NativeView {
	private static inline var FOOTER_PANEL_SYMBOL = "UI/Popups (outside levels)/BG";
	private static inline var FOOTER_PANEL_SCALE_X = 2.8712158203125;
	private static inline var FOOTER_PANEL_SCALE_Y = 0.349990844726562;
	private final art:Shape;
	public final footerPanel:Shape;

	public function new() {
		super();
		// The static SVG composer cannot express a nested Flash scale grid. Remove
		// the flattened footer instance and rebuild it as its authored SquareBG so
		// its corners, border, and vertical gradient survive the non-uniform size.
		art = SvgAsset.createWithoutSymbol(StaticSvg.LobbyBackground, FOOTER_PANEL_SYMBOL);
		addChild(art);
		footerPanel = AuthoredScale9.squarePanel();
		footerPanel.name = "footerPanel";
		footerPanel.x = 200;
		footerPanel.y = 362;
		var naturalWidth = footerPanel.width;
		var naturalHeight = footerPanel.height;
		footerPanel.width = naturalWidth * FOOTER_PANEL_SCALE_X;
		footerPanel.height = naturalHeight * FOOTER_PANEL_SCALE_Y;
		addChild(footerPanel);
		mouseEnabled = false;
		mouseChildren = false;
	}
}
