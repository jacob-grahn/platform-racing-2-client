package pr2.ui;

import openfl.display.DisplayObjectContainer;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.net.CommandHandler;

/**
	Port of `com.jiggmin.data.GpNotification`: listens for `gpGain` and mounts the
	native equivalent of the authored 71-frame notification on the root stage.
**/
class GpNotification extends Sprite {
	private static var holder:Null<DisplayObjectContainer>;

	public final art:Sprite;
	public final message:String;
	public var currentFrame(default, null):Int = 1;
	private final anim:Sprite;

	public static function init(target:DisplayObjectContainer, ?handler:CommandHandler):Void {
		holder = target;
		var cm = handler == null ? CommandHandler.commandHandler : handler;
		cm.defineCommand("gpGain", gpGain);
	}

	public static function gpGain(args:Array<String>):Void {
		if (holder == null) {
			return;
		}
		var parsed = args.length > 0 ? Std.parseInt(args[0]) : null;
		var gp = parsed == null ? 0 : parsed;
		holder.addChild(new GpNotification(gp));
	}

	public function new(gp:Int) {
		super();
		x = 25;
		y = 25;
		message = "+" + gp + " GP";
		art = new Sprite();
		anim = new Sprite();
		anim.name = "anim";
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.scaleX = 0.294158935546875;
		panel.scaleY = 0.183242797851562;
		anim.addChild(panel);
		var textBox = new TextField();
		textBox.name = "textBox";
		textBox.x = 5;
		textBox.y = 9;
		textBox.width = 70;
		textBox.height = 17.05;
		textBox.selectable = false;
		textBox.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 14, 0x333333, false, null, null, null, null,
			TextFormatAlign.CENTER);
		textBox.text = message;
		anim.addChild(textBox);
		art.addChild(anim);
		art.addEventListener(Event.ENTER_FRAME, advanceFrame);
		applyFrame();
		addChild(art);
	}

	private function advanceFrame(_:Event):Void {
		currentFrame++;
		applyFrame();
		if (currentFrame >= 71) remove();
	}

	private function applyFrame():Void {
		var index = currentFrame - 1;
		if (index <= 20) {
			var progress = index / 20;
			anim.y = 25 * (1 - progress) * (1 - progress);
			anim.alpha = progress;
		} else if (index <= 50) {
			anim.y = 0;
			anim.alpha = 1;
		} else {
			var progress = (index - 50) / 20;
			anim.y = -16 * progress * progress;
			anim.alpha = 1 - progress;
		}
	}

	public function remove():Void {
		art.removeEventListener(Event.ENTER_FRAME, advanceFrame);
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
