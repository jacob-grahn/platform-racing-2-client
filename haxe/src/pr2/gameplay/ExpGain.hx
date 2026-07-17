package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.display.Removable;
import pr2.lobby.NumberFormat;

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
	public final fill:Sprite;
	public final textBox:TextField;

	public function new() {
		super();
		name = "ExpGainGraphic";
		graphics.beginFill(0x2E2E2E, 0.92);
		graphics.lineStyle(1, 0x111111);
		graphics.drawRoundRect(0, 0, 204, 31, 7, 7);
		graphics.endFill();
		var track = new Sprite();
		track.x = 2;
		track.y = 2;
		track.graphics.beginFill(0x6C6C6C);
		track.graphics.drawRoundRect(0, 0, 200, 12, 5, 5);
		track.graphics.endFill();
		addChild(track);
		fill = new Sprite();
		fill.name = "bar";
		fill.graphics.beginFill(0xE8C348);
		fill.graphics.drawRoundRect(0, 0, 200, 12, 5, 5);
		fill.graphics.endFill();
		track.addChild(fill);
		textBox = new TextField();
		textBox.name = "textBox";
		textBox.x = 4;
		textBox.y = 14;
		textBox.width = 196;
		textBox.height = 16;
		textBox.selectable = false;
		textBox.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0xFFFFFF, false, null, null, null, null,
			TextFormatAlign.CENTER);
		addChild(textBox);
	}

	public function dispose():Void {
		if (parent != null) parent.removeChild(this);
	}
}
