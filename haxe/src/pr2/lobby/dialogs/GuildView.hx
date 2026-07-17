package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native guild profile, member list, and moderation actions. */
class GuildView extends NativeView {
	public final loadingGraphic:Sprite;
	public final messageButton:GameButton;

	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-180, -145, 360, 290, 14, 14);
		graphics.endFill();
		field("titleBox", -145, -132, 290, 24, 16, true, TextFormatAlign.CENTER);
		field("gpTodayBox", -155, -79, 145, 18, 11, true, TextFormatAlign.LEFT);
		field("gpTotalBox", 5, -79, 150, 18, 11, true, TextFormatAlign.RIGHT);
		field("membersCount", -155, -57, 310, 18, 10, false, TextFormatAlign.LEFT);
		field("guildProse", -155, 58, 310, 40, 10, false, TextFormatAlign.CENTER, true);
		var holder = new Sprite();
		holder.name = "membersHolder";
		holder.x = -151;
		holder.y = -31;
		addChild(holder);
		button("edit_bt", "Edit", -158, 108, 55);
		button("delete_bt", "Delete", -98, 108, 58);
		messageButton = button("messageButton", "Message Guild", -33, 108, 103);
		button("close_bt", "Close", 77, 108, 80);
		loadingGraphic = new Sprite();
		loadingGraphic.name = "loadingGraphic";
		loadingGraphic.graphics.beginFill(0xFFFFFF, 0.9);
		loadingGraphic.graphics.drawRoundRect(-165, -96, 330, 190, 10, 10);
		loadingGraphic.graphics.endFill();
		var loadingText = new TextField();
		loadingText.x = -80;
		loadingText.y = -10;
		loadingText.width = 160;
		loadingText.height = 22;
		loadingText.selectable = false;
		loadingText.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 13, 0x444444, true, null, null, null, null,
			TextFormatAlign.CENTER);
		loadingText.text = "Loading guild...";
		loadingGraphic.addChild(loadingText);
		addChild(loadingGraphic);
		setMember(false);
	}

	public function setMember(member:Bool):Void {
		if (member && messageButton.parent != this) addChild(messageButton);
		if (!member && messageButton.parent == this) removeChild(messageButton);
	}

	private function button(name:String, value:String, x:Float, y:Float, width:Float):GameButton {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		addChild(control);
		return control;
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign,
		multiline:Bool = false):Void {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.multiline = multiline;
		text.wordWrap = multiline;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		addChild(text);
	}
}
