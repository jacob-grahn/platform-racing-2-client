package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.DropShadowFilter;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.display.Removable;
import pr2.lobby.NumberFormat;
import pr2.runtime.SvgAsset;

/**
	Port of Flash `gameplay.ExpGain`: the experience-gain bar shown on the
	finished-race page. It eases the filled progress bar and the
	`current / to-rank` readout from `expStart` to `expEnd` over 45 frames
	(`ExpGain.go`), clamping both ends to `expToRank` exactly as the original.

	The authored `ExpGainGraphic` contains a `ProgressBar` instance named `bar`
	whose own inner fill is also named `bar` (`m.bar.bar.width` in AS3) and a
	`textBox` readout.
**/
class ExpGain extends Removable {
	public static inline final TRACK_ASSET = "assets/svg/effects/exp_progress_track_01.svg";
	public static inline final FILL_ASSET = "assets/svg/effects/exp_progress_fill_01.svg";
	private static inline var STEPS:Float = 45;
	private static inline var BAR_WIDTH:Float = 200;

	private var art:Null<ExpGainView>;
	private var fill:Null<DisplayObject>;
	private var textBox:Null<openfl.text.TextField>;

	private var expStart:Float = 0;
	private var expEnd:Float = 0;
	private var expToRank:Float = 0;
	private var expStep:Float = 0;

	public function new() {
		super();
		art = new ExpGainView();
		addChild(art);
		fill = art.fill;
		textBox = art.textBox;
		if (fill != null) {
			fill.width = 1;
		}
	}

	public function start(s:Float, e:Float, r:Float):Void {
		expStart = s;
		expEnd = e;
		expToRank = r;
		if (expEnd > expToRank) {
			expEnd = expToRank;
		}
		if (expStart > expToRank) {
			expStart = expToRank;
		}
		if (expStart <= expEnd) {
			expStep = (expEnd - expStart) / STEPS;
			addEventListener(Event.ENTER_FRAME, go);
		}
	}

	public function fillWidthForTests():Float return fill == null ? 0 : fill.width;
	public function textGeometryForTests():Array<Float> return textBox == null ? [] : [textBox.x, textBox.y, textBox.width, textBox.height];

	private function go(_:Event):Void {
		expStart += expStep;
		if (expStart >= expEnd) {
			removeEventListener(Event.ENTER_FRAME, go);
			expStart = expEnd;
		}
		if (textBox != null) {
			textBox.text = NumberFormat.withCommas(Std.int(Math.floor(expStart))) + " / " + NumberFormat.withCommas(Std.int(expToRank));
		}
		if (fill != null) {
			fill.width = expToRank == 0 ? 0 : BAR_WIDTH * (expStart / expToRank);
		}
	}

	override public function remove():Void {
		if (isRemoved()) return;
		removeEventListener(Event.ENTER_FRAME, go);
		if (art != null) {
			art.dispose();
			art = null;
		}
		fill = null;
		textBox = null;
		super.remove();
	}
}

private class ExpGainView extends Sprite {
	public final fill:Shape;
	public final textBox:TextField;

	public function new() {
		super();
		name = "ExpGainGraphic";
		var track = new Sprite();
		track.x = -100;
		track.filters = [new DropShadowFilter(2, 45, 0x000000, 1, 2, 2, 0.5, 1)];
		track.addChild(SvgAsset.create(ExpGain.TRACK_ASSET));
		addChild(track);
		fill = SvgAsset.create(ExpGain.FILL_ASSET);
		fill.name = "bar";
		track.addChild(fill);
		textBox = new TextField();
		textBox.name = "textBox";
		textBox.x = -92.75;
		textBox.y = 13.95;
		textBox.width = 185.45;
		textBox.height = 12.15;
		textBox.selectable = false;
		textBox.defaultTextFormat = new TextFormat("Verdana", 10, 0x666666, false, null, null, null, null,
			TextFormatAlign.CENTER);
		addChild(textBox);
	}

	public function dispose():Void {
		if (parent != null) parent.removeChild(this);
	}
}
