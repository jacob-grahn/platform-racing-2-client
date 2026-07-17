package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native player profile card and its social/guild action controls. */
class PlayerView extends NativeView {
	public final playerInfo:Sprite;
	public final loadingGraphic:Sprite;

	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-190, -174, 380, 348, 14, 14);
		graphics.endFill();
		field(this, "nameBox", -148, -162, 296, 25, 16, true, TextFormatAlign.CENTER);
		button(this, "close_bt", "Close", 108, 137, 65);

		playerInfo = new Sprite();
		playerInfo.name = "playerInfo";
		addChild(playerInfo);
		label("Status", -164, -127, 58);
		field(playerInfo, "statusBox", -101, -127, 118, 18, 10, false, TextFormatAlign.LEFT);
		label("Group", 17, -127, 48);
		field(playerInfo, "groupBox", 69, -127, 102, 18, 10, false, TextFormatAlign.LEFT);
		label("Rank", -164, -103, 58);
		field(playerInfo, "rankBox", -101, -103, 45, 18, 10, true, TextFormatAlign.LEFT);
		label("Hats", -50, -103, 38);
		field(playerInfo, "hatBox", -8, -103, 42, 18, 10, false, TextFormatAlign.LEFT);
		label("Joined", 38, -103, 49);
		field(playerInfo, "registerBox", 91, -103, 80, 18, 10, false, TextFormatAlign.LEFT);
		label("Active", 38, -80, 49);
		field(playerInfo, "activeBox", 91, -80, 80, 18, 10, false, TextFormatAlign.LEFT);
		label("Guild", 38, -57, 49);
		field(playerInfo, "guildBox", 91, -57, 80, 18, 10, false, TextFormatAlign.LEFT);

		icon(playerInfo, "verifiedIcon", 137, -145, 0x3D91D4, "✓");
		icon(playerInfo, "hofIcon", 164, -145, 0xD3A62A, "★");

		var supplement = new Sprite();
		supplement.name = "supplBg";
		supplement.y = 90;
		supplement.graphics.beginFill(0xE3E8EE);
		supplement.graphics.lineStyle(1, 0x87919C);
		supplement.graphics.drawRoundRect(-169, 0, 220, 32, 7, 7);
		supplement.graphics.endFill();
		playerInfo.addChild(supplement);
		field(playerInfo, "supplText", -162, 96, 205, 18, 9, false, TextFormatAlign.CENTER);

		button(playerInfo, "messageButton", "Message", -38, 9, 83);
		button(playerInfo, "levelsButton", "View Levels", 52, 9, 105);
		button(playerInfo, "followButton", "Follow", -38, 41, 83);
		button(playerInfo, "friendButton", "Add to Friends", 52, 41, 105);
		button(playerInfo, "ignoreButton", "Ignore", -38, 73, 83);
		button(playerInfo, "inviteButton", "Invite", 52, 73, 105);
		button(playerInfo, "kickButton", "Kick", 52, 73, 105);
		var kickBg = new Sprite();
		kickBg.name = "kickBg";
		kickBg.graphics.lineStyle(2, 0xB34A4A);
		kickBg.graphics.drawRoundRect(50, 71, 109, 28, 7, 7);
		playerInfo.addChildAt(kickBg, playerInfo.getChildIndex(find(playerInfo, "kickButton")));

		loadingGraphic = new Sprite();
		loadingGraphic.name = "loadingGraphic";
		loadingGraphic.graphics.beginFill(0xFFFFFF, 0.93);
		loadingGraphic.graphics.drawRoundRect(-176, -133, 352, 260, 10, 10);
		loadingGraphic.graphics.endFill();
		field(loadingGraphic, null, -90, -7, 180, 24, 13, true, TextFormatAlign.CENTER).text = "Loading player...";
		addChild(loadingGraphic);
		playerInfo.visible = false;
	}

	private function find(parent:Sprite, name:String):openfl.display.DisplayObject {
		return parent.getChildByName(name);
	}

	private function icon(parent:Sprite, name:String, x:Float, y:Float, color:Int, value:String):Void {
		var icon = new Sprite();
		icon.name = name;
		icon.x = x;
		icon.y = y;
		icon.graphics.beginFill(color);
		icon.graphics.drawCircle(10, 10, 10);
		icon.graphics.endFill();
		field(icon, null, 0, 2, 20, 18, 11, true, TextFormatAlign.CENTER).text = value;
		parent.addChild(icon);
	}

	private function label(value:String, x:Float, y:Float, width:Float):Void {
		field(playerInfo, null, x, y, width, 18, 10, true, TextFormatAlign.RIGHT).text = value;
	}

	private function button(parent:Sprite, name:String, value:String, x:Float, y:Float, width:Float):GameButton {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		parent.addChild(control);
		return control;
	}

	private function field(parent:Sprite, name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):TextField {
		var text = new TextField();
		if (name != null) text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		parent.addChild(text);
		return text;
	}
}
