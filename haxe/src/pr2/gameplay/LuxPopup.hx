package pr2.gameplay;

import openfl.display.Loader;
import openfl.net.URLRequest;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.dialogs.Popup;
import pr2.net.ServerConfig;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;
import pr2.util.DisplayUtil;

/** Port of Flash `gameplay.LuxPopup`, shown by the in-race `setLuxGain` command. */
class LuxPopup extends Popup {
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
		var field = Std.downcast(DisplayUtil.findByName(art, "textBox"), TextField);
		if (field != null) {
			field.text = text;
		}
		closeBinding = LobbyArt.bind(DisplayUtil.findByName(art, "close_bt"), function():Void startFadeOut());
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
	public function new() {
		super();
		graphics.beginFill(0xF3F3F3, 0.98);
		graphics.lineStyle(2, 0x6A6A6A);
		graphics.drawRoundRect(-130, -82, 260, 164, 14, 14);
		graphics.endFill();
		var heading = new TextField();
		heading.x = -110;
		heading.y = -65;
		heading.width = 200;
		heading.height = 34;
		heading.selectable = false;
		heading.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 20, 0x6748A0, true, null, null, null, null,
			TextFormatAlign.CENTER);
		heading.name = "textBox";
		addChild(heading);
		var note = new TextField();
		note.x = -112;
		note.y = -20;
		note.width = 205;
		note.height = 36;
		note.selectable = false;
		note.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 11, 0x444444, false, null, null, null, null,
			TextFormatAlign.CENTER);
		note.text = "Luna has awarded you Lux!";
		addChild(note);
		var close = ownControl(new GameButton("Close"));
		close.name = "close_bt";
		close.x = -42;
		close.y = 43;
		close.setSize(84, 24);
		addChild(close);
	}
}
