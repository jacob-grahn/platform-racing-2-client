package pr2.lobby.dialogs;

import openfl.text.TextField;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameTextArea;
import pr2.ui.view.LoadingView;
import pr2.ui.view.NativeView;

/** Native composition of the chat-room list info panel. */
class ChatRoomInfoView extends NativeView {
	public final textBox:TextField;
	public final textArea:GameTextArea;
	public final loadingGraphic:LoadingView;

	public function new() {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -109;
		panel.y = -75;
		panel.scaleX = 0.808746337890625;
		panel.scaleY = 0.785232543945312;
		addChild(panel);
		textArea = ownControl(new GameTextArea(197.100830078125, 128));
		textArea.name = "textBox_control";
		textArea.x = -98;
		textArea.y = -65;
		addChild(textArea);
		textBox = textArea.textField;
		textBox.name = "textBox";
		loadingGraphic = new LoadingView();
		loadingGraphic.name = "loadingGraphic";
		addChild(loadingGraphic);
	}

	override public function dispose():Void {
		loadingGraphic.dispose();
		super.dispose();
	}
}
