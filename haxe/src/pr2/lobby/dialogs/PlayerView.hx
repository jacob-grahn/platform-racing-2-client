package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.NativeControl;
import pr2.ui.view.NativeView;
import pr2.ui.view.LoadingView;

/** Native player profile card and its social/guild action controls. */
class PlayerView extends NativeView {
	public final playerInfo:Sprite;
	public final loadingGraphic:LoadingView;

	public function new() {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -122.5;
		panel.y = -147.2;
		panel.scaleX = 0.900802612304688;
		panel.scaleY = 1.49203491210938;
		addChild(panel);
		field(this, "nameBox", -92.5, -133.2, 188.1, 17.05, 14, false, TextFormatAlign.CENTER);
		button(this, "close_bt", "Close", -50, 101.8, 100);

		playerInfo = new Sprite();
		playerInfo.name = "playerInfo";
		playerInfo.y = -115.2;
		addChild(playerInfo);
		field(playerInfo, "statusBox", -106.75, 1, 213.5, 14.5, 10, false, TextFormatAlign.CENTER, 0x666666);
		label("Group", -37.75, 22, 37.3);
		field(playerInfo, "groupBox", -38, 34, 141, 14.55, 12, false, TextFormatAlign.LEFT);
		label("Guild", -38, 54, 37.3);
		field(playerInfo, "guildBox", -38, 66, 141, 14.55, 12, false, TextFormatAlign.LEFT);
		label("Rank", -38, 86, 36);
		field(playerInfo, "rankBox", -38, 98, 36, 14.55, 12, false, TextFormatAlign.LEFT);
		label("Joined", 12, 86, 91);
		field(playerInfo, "registerBox", 12, 98, 91, 14.85, 12, false, TextFormatAlign.RIGHT);
		label("Hats", -38, 118, 36);
		field(playerInfo, "hatBox", -38, 130, 36, 14.55, 12, false, TextFormatAlign.LEFT);
		label("Active", 12, 118, 91);
		field(playerInfo, "activeBox", 12, 130, 91, 14.95, 12, false, TextFormatAlign.RIGHT);

		sourceIcon(playerInfo, "verifiedIcon", StaticSvg.PlayerPopupVerified, -6, 21.95, 0.53656005859375);
		sourceIcon(playerInfo, "hofIcon", StaticSvg.PlayerPopupTrophy, 8, 22.45, 1);

		var supplement = new Sprite();
		supplement.name = "supplBg";
		supplement.x = -122.5;
		supplement.y = 256.9;
		var supplementArt = NativeAssets.svg(StaticSvg.QuantityPanel);
		supplementArt.scaleX = 0.900802612304688;
		supplementArt.scaleY = 0.183242797851562;
		supplement.addChild(supplementArt);
		playerInfo.addChild(supplement);
		field(playerInfo, "supplText", -110.95, 267.15, 223.5, 14.55, 12, false, TextFormatAlign.CENTER, 0x333333);

		sourceButton(playerInfo, "messageButton", PlayerSourceButtonKind.Message, -94.5, 227.9);
		button(playerInfo, "levelsButton", "View Levels", 5, 155, 100);
		button(playerInfo, "followButton", "Follow", -105, 155, 100);
		button(playerInfo, "friendButton", "Add to Friends", -105, 182, 100);
		button(playerInfo, "ignoreButton", "Ignore", 5, 182, 100);
		sourceButton(playerInfo, "inviteButton", PlayerSourceButtonKind.Invite, 1.3, 65.25);
		sourceButton(playerInfo, "kickButton", PlayerSourceButtonKind.Kick, -36.5, -55.55);
		var kickBg = new Sprite();
		kickBg.name = "kickBg";
		kickBg.x = -122.5;
		kickBg.y = -61.6;
		var kickArt = NativeAssets.svg(StaticSvg.QuantityPanel);
		kickArt.scaleX = 0.900802612304688;
		kickArt.scaleY = 0.144515991210938;
		kickBg.addChild(kickArt);
		playerInfo.addChildAt(kickBg, playerInfo.getChildIndex(find(playerInfo, "kickButton")));

		loadingGraphic = new LoadingView();
		loadingGraphic.name = "loadingGraphic";
		loadingGraphic.y = -17.2;
		addChild(loadingGraphic);
		playerInfo.visible = false;
	}

	private function find(parent:Sprite, name:String):openfl.display.DisplayObject {
		return parent.getChildByName(name);
	}

	private function sourceIcon(parent:Sprite, name:String, asset:StaticSvg, x:Float, y:Float, scale:Float):Void {
		var icon = new Sprite();
		icon.name = name;
		icon.x = x;
		icon.y = y;
		var art = NativeAssets.svg(asset);
		art.scaleX = art.scaleY = scale;
		icon.addChild(art);
		parent.addChild(icon);
	}

	private function label(value:String, x:Float, y:Float, width:Float):Void {
		field(playerInfo, null, x, y, width, 10.95, 9, false, TextFormatAlign.RIGHT, 0x666666).text = value;
	}

	private function sourceButton(parent:Sprite, name:String, kind:PlayerSourceButtonKind, x:Float, y:Float):Void {
		var control = ownControl(new PlayerSourceButton(kind));
		control.name = name;
		control.x = x;
		control.y = y;
		parent.addChild(control);
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
		align:TextFormatAlign, color:Int = 0x222222):TextField {
		var text = new TextField();
		if (name != null) text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null, align);
		parent.addChild(text);
		return text;
	}

	override public function dispose():Void {
		loadingGraphic.dispose();
		super.dispose();
	}
}

private enum abstract PlayerSourceButtonKind(Int) {
	var Message = 0;
	var Invite = 1;
	var Kick = 2;
}

private class PlayerSourceButton extends NativeControl {
	private var kind:Null<PlayerSourceButtonKind>;

	public function new(kind:PlayerSourceButtonKind) {
		super(kind == Kick ? 77.75 : kind == Invite ? 31.25 : 20, kind == Message ? 20 : 16.15);
		this.kind = kind;
		mouseChildren = false;
		redraw();
	}

	override public function redraw():Void {
		while (numChildren > 0) removeChildAt(0);
		if (kind == null) return;
		var over = state() != Normal && state() != Disabled;
		if (kind == Message) {
			var asset = state() == Pressed ? StaticSvg.LevelInfoShareDown : over ? StaticSvg.LevelInfoShareOver : StaticSvg.LevelInfoShareUp;
			addChild(NativeAssets.svg(asset));
			return;
		}
		var text = new TextField();
		text.x = 2;
		text.y = 2;
		text.width = kind == Kick ? 73.75 : 27.25;
		text.height = 12.15;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, over ? 0x000000 : 0x4E4EFE);
		text.text = kind == Kick ? "kick from guild" : "invite";
		addChild(text);
	}
}
