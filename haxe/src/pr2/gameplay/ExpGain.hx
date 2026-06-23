package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.lobby.LobbyArt;
import pr2.lobby.NumberFormat;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `gameplay.ExpGain`: the experience-gain bar shown on the
	finished-race page. It eases the filled progress bar and the
	`current / to-rank` readout from `expStart` to `expEnd` over 45 frames
	(`ExpGain.go`), clamping both ends to `expToRank` exactly as the original.

	The authored `ExpGainGraphic` contains a `ProgressBar` instance named `bar`
	whose own inner fill is also named `bar` (`m.bar.bar.width` in AS3) and a
	`textBox` readout.
**/
class ExpGain extends Sprite {
	private static inline var STEPS:Float = 45;
	private static inline var BAR_WIDTH:Float = 200;

	private var art:Null<PR2MovieClip>;
	private var fill:Null<DisplayObject>;
	private var textBox:Null<openfl.text.TextField>;

	private var expStart:Float = 0;
	private var expEnd:Float = 0;
	private var expToRank:Float = 0;
	private var expStep:Float = 0;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("ExpGainGraphic", {maxNestedDepth: 4});
		addChild(art);
		// `m.bar` is the ProgressBar instance; its inner fill is also named `bar`.
		var bar = Std.downcast(LobbyArt.findByName(art, "bar"), openfl.display.DisplayObjectContainer);
		fill = LobbyArt.findByName(bar, "bar");
		textBox = LobbyArt.text(art, "textBox");
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

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, go);
		if (art != null) {
			art.dispose();
			art = null;
		}
		fill = null;
		textBox = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
