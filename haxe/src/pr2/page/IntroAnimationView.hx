package pr2.page;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;

/** Explicit frame-driven replacement for the four site intro timelines. */
class IntroAnimationView extends Sprite {
	public var currentFrame(default, null):Int = 1;
	public final totalFrames:Int;
	public final logoHolder:Sprite;
	private final kind:String;
	private final completeFrame:Int;
	private var playing:Bool = true;
	private final mark:Sprite;
	private final title:TextField;

	public function new(kind:String, totalFrames:Int, completeFrame:Int) {
		super();
		this.kind = kind;
		this.totalFrames = totalFrames;
		this.completeFrame = completeFrame;
		name = kind + "Intro";
		mark = new Sprite();
		addChild(mark);
		logoHolder = new Sprite();
		logoHolder.name = "logoHolder";
		addChild(logoHolder);
		title = new TextField();
		title.x = 75;
		title.y = 270;
		title.width = 400;
		title.height = 42;
		title.selectable = false;
		title.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 27, 0xFFFFFF, true, null, null, null, null,
			TextFormatAlign.CENTER);
		title.text = switch (kind) {
			case "jiggmin": "Jiggmin";
			case "kongregate": "Kongregate";
			case "armor": "Armor Games";
			case "bubblebox": "BubbleBox";
			default: "";
		};
		addChild(title);
		addEventListener(Event.ENTER_FRAME, advance);
		redraw();
	}

	public function stop():Void playing = false;

	public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, advance);
		if (parent != null) parent.removeChild(this);
	}

	private function advance(_:Event):Void {
		if (!playing) return;
		currentFrame++;
		if (currentFrame > totalFrames) currentFrame = totalFrames;
		redraw();
		if (currentFrame >= completeFrame) {
			playing = false;
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}

	private function redraw():Void {
		var progress = Math.min(1, currentFrame / Math.max(1, completeFrame));
		var eased = 1 - Math.pow(1 - progress, 3);
		alpha = Math.min(1, progress * 8) * Math.min(1, (completeFrame - currentFrame + 22) / 22);
		if (alpha < 0) alpha = 0;
		mark.graphics.clear();
		var color = kind == "kongregate" ? 0xD8483E : kind == "armor" ? 0xE58B2A : kind == "bubblebox" ? 0x3CA9D8 : 0x8DCB45;
		mark.graphics.beginFill(color);
		if (kind == "armor") {
			mark.graphics.moveTo(275, 90);
			mark.graphics.lineTo(350, 125);
			mark.graphics.lineTo(330, 235);
			mark.graphics.lineTo(275, 265);
			mark.graphics.lineTo(220, 235);
			mark.graphics.lineTo(200, 125);
			mark.graphics.lineTo(275, 90);
		} else if (kind == "bubblebox") {
			for (i in 0...7) mark.graphics.drawCircle(210 + (i % 4) * 43, 135 + Math.floor(i / 4) * 55, 18 + (i % 3) * 6);
		} else {
			mark.graphics.drawRoundRect(185, 115, 180, 120, 30, 30);
		}
		mark.graphics.endFill();
		mark.scaleX = mark.scaleY = 0.35 + eased * 0.65;
		mark.x = 275 * (1 - mark.scaleX);
		mark.y = 190 * (1 - mark.scaleY);
		title.alpha = Math.max(0, Math.min(1, progress * 4 - 1));
	}
}
