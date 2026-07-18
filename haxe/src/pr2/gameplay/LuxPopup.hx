package pr2.gameplay;

import openfl.display.Loader;
import openfl.display.Shape;
import openfl.net.URLRequest;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.dialogs.Popup;
import pr2.net.ServerConfig;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;
import pr2.util.DisplayUtil;
import pr2.runtime.SvgAsset;

/** Port of Flash `gameplay.LuxPopup`, shown by the in-race `setLuxGain` command. */
class LuxPopup extends Popup {
	public static inline final BACKGROUND_ASSET = "assets/svg/effects/lux_popup_01.svg";

	private var art:Null<LuxPopupView>;
	private var loader:Null<Loader>;
	private var closeBinding:Null<Binding>;

	public var text(default, null):String = "";
	public var imageUrl(default, null):String = "";

	public function new(numLux:Int, loadImage:Bool = true) {
		super(false);
		art = new LuxPopupView();

		imageUrl = ServerConfig.lunaImageUrl();
		if (loadImage) {
			loader = new Loader();
			loader.x = 95;
			loader.y = -65;
			art.addChild(loader);
			try {
				loader.load(new URLRequest(imageUrl));
			} catch (_:Dynamic) {}
		}

		text = "+" + numLux + " Lux";
		var field = Std.downcast(DisplayUtil.directChildByName(art, "textBox"), TextField);
		if (field != null) {
			field.text = text;
		}
		closeBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "close_bt"), function():Void startFadeOut());
		addChild(art);
	}

	override public function remove():Void {
		if (closeBinding != null) {
			LobbyArt.unbind(closeBinding);
			closeBinding = null;
		}
		if (loader != null) {
			try {
				loader.unload();
			} catch (_:Dynamic) {}
			loader = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}

private class LuxPopupView extends NativeView {
	public final exactBackground:Shape;

	public function new() {
		super();
		exactBackground = SvgAsset.create(LuxPopup.BACKGROUND_ASSET);
		exactBackground.name = "exactBackground";
		addChild(exactBackground);
		var heading = new TextField();
		heading.x = 100;
		heading.y = 7.95;
		heading.width = 161.95;
		heading.height = 14.55;
		heading.selectable = false;
		heading.defaultTextFormat = new TextFormat("Verdana", 12, 0x000000, false, null, null, null, null,
			TextFormatAlign.CENTER);
		heading.name = "textBox";
		addChild(heading);
		var close = ownControl(new GameButton("Close"));
		close.name = "close_bt";
		close.x = 144;
		close.y = 38.45;
		close.setSize(72, 22);
		addChild(close);
	}
}
