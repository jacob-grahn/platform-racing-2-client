package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.view.LoadingView;
import pr2.ui.view.NativeView;

/** Native composition of the chat-room list info panel. */
class ChatRoomInfoView extends NativeView {
	public final textBox:TextField;
	public final loadingGraphic:LoadingView;

	public function new() {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -109;
		panel.y = -75;
		panel.scaleX = 0.808746337890625;
		panel.scaleY = 0.785232543945312;
		addChild(panel);
		textBox = new TextField();
		textBox.name = "textBox";
		textBox.x = -98;
		textBox.y = -65;
		textBox.width = 197;
		textBox.height = 128;
		textBox.multiline = true;
		textBox.wordWrap = true;
		textBox.selectable = true;
		textBox.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 11, 0);
		addChild(textBox);
		loadingGraphic = new LoadingView();
		loadingGraphic.name = "loadingGraphic";
		addChild(loadingGraphic);
	}

	override public function dispose():Void {
		loadingGraphic.dispose();
		super.dispose();
	}
}
