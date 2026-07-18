package pr2.ui;

import openfl.display.DisplayObjectContainer;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;
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
	public final anim:Sprite;
	private static final ENTER_Y:Array<Float> = [25, 22.55, 20.25, 18.05, 16, 14.05, 12.25, 10.55, 9, 7.55, 6.25, 5.05, 4, 3.05, 2.25, 1.55, 1, 0.55, 0.25, 0.05, 0];
	private static final ENTER_ALPHA:Array<Float> = [0, 0.1015625, 0.19140625, 0.28125, 0.359375, 0.44140625, 0.51171875, 0.578125, 0.640625, 0.69921875, 0.75, 0.80078125, 0.83984375, 0.87890625, 0.91015625, 0.94140625, 0.9609375, 0.98046875, 0.98828125, 1, 1];
	private static final EXIT_Y:Array<Float> = [0, -0.05, -0.15, -0.35, -0.65, -1, -1.45, -1.95, -2.55, -3.25, -4, -4.85, -5.75, -6.75, -7.85, -9, -10.25, -11.55, -12.95, -14.45, -16];
	private static final EXIT_ALPHA:Array<Float> = [1, 1, 0.98828125, 0.98046875, 0.9609375, 0.94140625, 0.91015625, 0.87890625, 0.83984375, 0.80078125, 0.75, 0.69921875, 0.640625, 0.578125, 0.51171875, 0.44140625, 0.359375, 0.28125, 0.19140625, 0.1015625, 0];
	private static final COLOR_MULTIPLIER:Array<Float> = [0, 0.0703125, 0.140625, 0.2109375, 0.26953125, 0.328125, 0.37890625, 0.4296875, 0.48046875, 0.51953125, 0.55859375, 0.58984375, 0.62890625, 0.66015625, 0.6796875, 0.69921875, 0.7109375, 0.73046875, 0.73828125, 0.75, 0.75, 0.75, 0.76171875, 0.76953125, 0.78125, 0.7890625, 0.80078125, 0.80078125, 0.80859375, 0.8203125, 0.828125, 0.83984375, 0.8515625, 0.859375, 0.859375, 0.87890625, 0.87890625, 0.890625, 0.8984375, 0.91015625, 0.91015625, 0.921875, 0.9296875, 0.94140625, 0.94921875, 0.9609375, 0.9609375, 0.96875, 0.98046875, 0.98828125, 1];
	private static final COLOR_OFFSET:Array<Float> = [255, 236, 219, 202, 186, 171, 158, 145, 133, 122, 112, 103, 95, 87, 81, 76, 72, 68, 66, 64, 64, 62, 60, 58, 55, 53, 51, 49, 47, 45, 43, 41, 38, 36, 34, 32, 30, 28, 26, 23, 21, 19, 17, 15, 13, 11, 9, 6, 4, 2, 0];

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
		var frameAlpha:Float;
		if (index <= 20) {
			anim.y = ENTER_Y[index];
			frameAlpha = ENTER_ALPHA[index];
		} else if (index <= 50) {
			anim.y = 0;
			frameAlpha = 1;
		} else {
			anim.y = EXIT_Y[index - 50];
			frameAlpha = EXIT_ALPHA[index - 50];
		}
		if (index <= 50) {
			var multiplier = COLOR_MULTIPLIER[index];
			var offset = COLOR_OFFSET[index];
			anim.transform.colorTransform = new ColorTransform(multiplier, multiplier, multiplier, frameAlpha, offset, offset, 0, 0);
		} else {
			anim.transform.colorTransform = new ColorTransform(1, 1, 1, frameAlpha);
		}
	}

	public function remove():Void {
		art.removeEventListener(Event.ENTER_FRAME, advanceFrame);
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
