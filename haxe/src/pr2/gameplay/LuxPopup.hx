package pr2.gameplay;

import openfl.display.Loader;
import openfl.net.URLRequest;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.dialogs.Popup;
import pr2.net.ServerConfig;
import pr2.runtime.PR2MovieClip;

/** Port of Flash `gameplay.LuxPopup`, shown by the in-race `setLuxGain` command. */
class LuxPopup extends Popup {
	private var art:Null<PR2MovieClip>;
	private var loader:Null<Loader>;
	private var closeBinding:Null<Binding>;

	public var text(default, null):String = "";
	public var imageUrl(default, null):String = "";

	public function new(numLux:Int, loadImage:Bool = true) {
		super(false);
		art = PR2MovieClip.fromLinkage("LuxPopupGraphic", {maxNestedDepth: 5});

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
		var field = Std.downcast(LobbyArt.findByName(art, "textBox"), TextField);
		if (field != null) {
			field.text = text;
		}
		closeBinding = LobbyArt.bind(LobbyArt.findByName(art, "close_bt"), function():Void startFadeOut());
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
