package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native level-details card with explicit hover and action targets. */
class LevelInfoView extends NativeView {
	public final levelInfo:Sprite;
	public final loading:Sprite;
	public final playButton:GameButton;

	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-205, -165, 410, 330, 14, 14);
		graphics.endFill();

		levelInfo = new Sprite();
		levelInfo.name = "levelInfo";
		addChild(levelInfo);
		field(levelInfo, "title", -174, -148, 348, 25, 17, true, TextFormatAlign.CENTER);
		field(levelInfo, "author", -174, -121, 348, 19, 11, false, TextFormatAlign.CENTER);
		field(levelInfo, "note", -174, -94, 348, 53, 11, false, TextFormatAlign.LEFT, true);

		label(levelInfo, "Version", -174, -31, 67);
		field(levelInfo, "version", -102, -31, 74, 18, 10, false, TextFormatAlign.LEFT);
		label(levelInfo, "Plays", 0, -31, 48);
		field(levelInfo, "plays", 52, -31, 122, 18, 10, false, TextFormatAlign.LEFT);
		label(levelInfo, "Minimum rank", -174, -8, 91);
		field(levelInfo, "minRank", -78, -8, 50, 18, 10, false, TextFormatAlign.LEFT);
		label(levelInfo, "Updated", 0, -8, 56);
		field(levelInfo, "updated", 58, -8, 116, 18, 10, false, TextFormatAlign.LEFT);

		makeRating(levelInfo, -174, 23);
		makeMode(levelInfo, -52, 18);
		hoverTile(levelInfo, "song", "♪", 10, 18, 34, 31, 0x6389B5);
		hoverTile(levelInfo, "cowboyChance", "C", 50, 18, 34, 31, 0xB47B3F);
		hoverTile(levelInfo, "maxTime", "⌚", 90, 18, 34, 31, 0x6C7785);
		hoverTile(levelInfo, "gravity", "G", 130, 18, 34, 31, 0x6A9A62);
		hoverTile(levelInfo, "items", "⚡", -52, 57, 48, 34, 0xA77F30);
		hoverTile(levelInfo, "hatsAllowed", "Hats", 4, 57, 58, 34, 0x7D5BA6);

		button(levelInfo, "share_bt", "Share", 69, 62, 62);
		button(levelInfo, "report_bt", "Report", 136, 62, 62);
		button(levelInfo, "unpublish_bt", "Moderate", 126, 62, 72);
		playButton = button(this, "play_bt", "Play", -92, 125, 86);
		button(this, "close_bt", "Close", 6, 125, 86);

		loading = new Sprite();
		loading.name = "loading";
		loading.graphics.beginFill(0xFFFFFF, 0.93);
		loading.graphics.drawRoundRect(-190, -150, 380, 258, 10, 10);
		loading.graphics.endFill();
		field(loading, null, -90, -8, 180, 24, 13, true, TextFormatAlign.CENTER).text = "Loading level...";
		addChild(loading);
		levelInfo.visible = false;
	}

	private function makeRating(parent:Sprite, x:Float, y:Float):Void {
		var rating = new Sprite();
		rating.name = "rating";
		rating.x = x;
		rating.y = y;
		rating.graphics.beginFill(0xD0D0D0);
		rating.graphics.drawRoundRect(0, 0, 112, 19, 5, 5);
		rating.graphics.endFill();
		var bar = new Sprite();
		bar.name = "bar";
		bar.graphics.beginFill(0xE9B82D);
		bar.graphics.drawRoundRect(0, 0, 112, 19, 5, 5);
		bar.graphics.endFill();
		rating.addChild(bar);
		var cover = hoverCover(112, 19);
		rating.addChild(cover);
		parent.addChild(rating);
	}

	private function makeMode(parent:Sprite, x:Float, y:Float):Void {
		var mode = new Sprite();
		mode.name = "gameMode";
		mode.x = x;
		mode.y = y;
		var symbol = new LevelModeSymbol();
		symbol.name = "modeSym";
		symbol.x = 17;
		symbol.y = 16;
		mode.addChild(symbol);
		mode.addChild(hoverCover(56, 34));
		parent.addChild(mode);
	}

	private function hoverTile(parent:Sprite, name:String, value:String, x:Float, y:Float, width:Float, height:Float, color:Int):Void {
		var tile = new Sprite();
		tile.name = name;
		tile.x = x;
		tile.y = y;
		tile.graphics.beginFill(color);
		tile.graphics.drawRoundRect(0, 0, width, height, 7, 7);
		tile.graphics.endFill();
		field(tile, null, 0, 6, width, height - 6, 10, true, TextFormatAlign.CENTER).text = value;
		parent.addChild(tile);
	}

	private function hoverCover(width:Float, height:Float):Sprite {
		var cover = new Sprite();
		cover.name = "cover";
		cover.graphics.beginFill(0xFFFFFF, 0.34);
		cover.graphics.drawRoundRect(0, 0, width, height, 5, 5);
		cover.graphics.endFill();
		cover.visible = false;
		return cover;
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

	private function label(parent:Sprite, value:String, x:Float, y:Float, width:Float):Void {
		field(parent, null, x, y, width, 18, 10, true, TextFormatAlign.RIGHT).text = value;
	}

	private function field(parent:Sprite, name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign, multiline:Bool = false):TextField {
		var text = new TextField();
		if (name != null) text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.multiline = multiline;
		text.wordWrap = multiline;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		parent.addChild(text);
		return text;
	}
}

/** Explicit five-state replacement for the legacy mode timeline symbol. */
class LevelModeSymbol extends Sprite {
	public function new() {
		super();
		setFrame(1);
	}

	public function setFrame(frame:Int):Void {
		graphics.clear();
		var colors = [0x4E9C61, 0xB85353, 0xD3A42B, 0x6F80C6, 0x9964B5];
		var labels = ["R", "D", "E", "O", "H"];
		var index = frame < 1 || frame > colors.length ? 0 : frame - 1;
		graphics.beginFill(colors[index]);
		graphics.lineStyle(1, 0x3F3F3F);
		graphics.drawCircle(0, 0, 14);
		graphics.endFill();
		name = name;
		if (numChildren > 0) removeChildren();
		var text = new TextField();
		text.mouseEnabled = false;
		text.selectable = false;
		text.x = -14;
		text.y = -9;
		text.width = 28;
		text.height = 19;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 11, 0xFFFFFF, true, null, null, null, null,
			TextFormatAlign.CENTER);
		text.text = labels[index];
		addChild(text);
	}
}
