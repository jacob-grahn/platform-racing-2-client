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
import pr2.ui.RatingSelect.RatingStarMeter;
import pr2.ui.view.NativeView;
import pr2.ui.view.LoadingView;

/** Native level-details card with explicit hover and action targets. */
class LevelInfoView extends NativeView {
	public final levelInfo:Sprite;
	public final loading:LoadingView;
	public final playButton:GameButton;

	public function new() {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -175;
		panel.y = -137.5;
		panel.scaleX = 1.2867431640625;
		panel.scaleY = 1.43986511230469;
		addChild(panel);

		levelInfo = new Sprite();
		levelInfo.name = "levelInfo";
		levelInfo.x = -1.5;
		levelInfo.y = -2.75;
		addChild(levelInfo);
		field(levelInfo, "title", -152.05, -118.8, 307.95, 14.55, 12, true, TextFormatAlign.CENTER);
		field(levelInfo, "author", -157.05, -100.25, 318.95, 14.5, 10, false, TextFormatAlign.CENTER);
		field(levelInfo, "note", 22.55, -72.4, 140, 120.65, 8, false, TextFormatAlign.CENTER, true);

		label(levelInfo, "Version:", -162.55, -59.8, 91);
		field(levelInfo, "version", -64.1, -59.8, 31, 13.35, 11, false, TextFormatAlign.LEFT);
		label(levelInfo, "Last Updated:", -162.55, -39.8, 91);
		field(levelInfo, "updated", -64.1, -39.8, 76, 13.35, 11, false, TextFormatAlign.LEFT);
		label(levelInfo, "Min. Rank:", -162.55, -19.8, 91);
		field(levelInfo, "minRank", -64.1, -19.8, 31, 13.35, 11, false, TextFormatAlign.LEFT);
		label(levelInfo, "Play Count:", -162.55, 0.2, 91);
		field(levelInfo, "plays", -64.1, 0.2, 76, 13.35, 11, false, TextFormatAlign.LEFT);
		label(levelInfo, "Rating:", -162.55, 20.2, 91);

		makeRating(levelInfo, -33.5, 27.7);
		makeMode(levelInfo, -142.95, 73.55);
		sourceTile(levelInfo, "song", StaticSvg.LevelInfoMusic, -88.5, 71.7, 28, 27);
		sourceTile(levelInfo, "cowboyChance", StaticSvg.LevelInfoCowboy, -38.55, 71.7, 28, 27);
		sourceTile(levelInfo, "maxTime", StaticSvg.LevelInfoClock, 9.5, 72, 28, 27);
		gravityButton(levelInfo, 54.8, 74.6);
		sourceTile(levelInfo, "items", StaticSvg.LevelInfoItems, 88.6, 61.9, 25, 26);
		sourceTile(levelInfo, "hatsAllowed", StaticSvg.LevelInfoHats, 149.25, 73.9, 28, 27);

		actionButton(levelInfo, "share_bt", LevelInfoActionKind.Share, -149.05, 112.8);
		actionButton(levelInfo, "report_bt", LevelInfoActionKind.Report, 150.8, 112.8);
		actionButton(levelInfo, "unpublish_bt", LevelInfoActionKind.Unpublish, 150.8, 112.8);
		playButton = button(this, "play_bt", "Play", -105.8, 99, 100);
		button(this, "close_bt", "Close", 15.2, 99, 100);

		loading = new LoadingView();
		loading.name = "loading";
		addChild(loading);
		levelInfo.visible = false;
	}

	override public function dispose():Void {
		loading.dispose();
		super.dispose();
	}

	private function makeRating(parent:Sprite, x:Float, y:Float):Void {
		var rating = new LevelInfoRatingSymbol();
		rating.name = "rating";
		rating.x = x;
		rating.y = y;
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

	private function sourceTile(parent:Sprite, name:String, asset:StaticSvg, x:Float, y:Float, width:Float, height:Float):Void {
		var tile = new Sprite();
		tile.name = name;
		tile.x = x;
		tile.y = y;
		tile.addChild(NativeAssets.svg(asset));
		tile.addChild(hoverCover(width, height));
		parent.addChild(tile);
	}

	private function gravityButton(parent:Sprite, x:Float, y:Float):Void {
		var tile = new Sprite();
		tile.name = "gravity";
		tile.x = x;
		tile.y = y;
		var text = field(tile, null, -7.75, -10.6, 15.5, 21.25, 20, false, TextFormatAlign.CENTER);
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Display), 20, 0x000000, false, null, null, null, null,
			TextFormatAlign.CENTER);
		text.text = "G";
		listen(tile, openfl.events.MouseEvent.MOUSE_OVER, function(_:openfl.events.MouseEvent):Void text.textColor = 0x666666);
		listen(tile, openfl.events.MouseEvent.MOUSE_OUT, function(_:openfl.events.MouseEvent):Void text.textColor = 0x000000);
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

	private function actionButton(parent:Sprite, name:String, kind:LevelInfoActionKind, x:Float, y:Float):Void {
		var control = ownControl(new LevelInfoActionButton(kind));
		control.name = name;
		control.x = x;
		control.y = y;
		parent.addChild(control);
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

class LevelInfoRatingSymbol extends Sprite {
	private final meter:RatingStarMeter;
	private final scaleProxy:Sprite;

	public function new() {
		super();
		meter = new RatingStarMeter();
		meter.x = -32.6;
		meter.y = -6.5;
		meter.scaleX = 1.18113708496094;
		meter.scaleY = 1.18180847167969;
		addChild(meter);
		scaleProxy = new Sprite();
		scaleProxy.name = "bar";
		addChild(scaleProxy);
		var cover = new Sprite();
		cover.name = "cover";
		cover.graphics.beginFill(0xFFFFFF, 0.2);
		cover.graphics.drawRect(-33, -7.02, 66, 14.02);
		cover.graphics.endFill();
		cover.visible = false;
		addChild(cover);
	}

	public function displayRating(value:Float):Void {
		meter.displayRating(value);
		scaleProxy.scaleX = value / 5;
	}
}

private enum abstract LevelInfoActionKind(Int) {
	var Share = 0;
	var Report = 1;
	var Unpublish = 2;
}

private class LevelInfoActionButton extends NativeControl {
	private var kind:Null<LevelInfoActionKind>;

	public function new(kind:LevelInfoActionKind) {
		super(20, 20);
		this.kind = kind;
		mouseChildren = false;
		redraw();
	}

	override public function redraw():Void {
		while (numChildren > 0) removeChildAt(0);
		if (kind == null) return;
		var down = state() == Pressed;
		var over = state() == Hovered || state() == Focused;
		var asset = switch (kind) {
			case Share: down ? StaticSvg.LevelInfoShareDown : over ? StaticSvg.LevelInfoShareOver : StaticSvg.LevelInfoShareUp;
			case Report: down ? StaticSvg.LevelInfoReportDown : over ? StaticSvg.LevelInfoReportOver : StaticSvg.LevelInfoReportUp;
			case Unpublish: down ? StaticSvg.LevelInfoUnpublishDown : over ? StaticSvg.LevelInfoUnpublishOver : StaticSvg.LevelInfoUnpublishUp;
		};
		addChild(NativeAssets.svg(asset));
	}
}

/** Explicit five-state replacement for the legacy mode timeline symbol. */
class LevelModeSymbol extends Sprite {
	private var art:openfl.display.DisplayObject;
	public function new() {
		super();
		setFrame(1);
	}

	public function setFrame(frame:Int):Void {
		graphics.clear();
		var assets = [StaticSvg.LevelInfoModeRace, StaticSvg.LevelInfoModeDeathmatch, StaticSvg.LevelInfoModeEgg, StaticSvg.LevelInfoModeObjective,
			StaticSvg.LevelInfoModeHat];
		var index = frame < 1 || frame > assets.length ? 0 : frame - 1;
		graphics.beginFill(0xCCCCCC, 0.749019607843137);
		graphics.drawRect(-17.35, -12.9, 34.2, 25.05);
		graphics.endFill();
		if (art != null && art.parent == this) removeChild(art);
		art = NativeAssets.svg(assets[index]);
		art.x = -12.5;
		art.y = -6.9;
		art.scaleX = 0.318450927734375;
		art.scaleY = 0.316574096679688;
		addChild(art);
	}
}
