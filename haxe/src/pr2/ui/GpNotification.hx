package pr2.ui;

import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.text.TextField;
import pr2.net.CommandHandler;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Port of `com.jiggmin.data.GpNotification`: listens for `gpGain` and mounts the
	authored 71-frame notification on the root stage.
**/
class GpNotification extends Sprite {
	private static var holder:Null<DisplayObjectContainer>;

	public final art:PR2MovieClip;
	public final message:String;

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
		art = PR2MovieClip.fromLinkage("GpNotificationGraphic", {maxNestedDepth: 4});
		art.setFrameScript(70, frame71);
		setText(message);
		addChild(art);
	}

	private function setText(value:String):Void {
		var anim = Std.downcast(DisplayUtil.findByName(art, "anim"), DisplayObjectContainer);
		var textBox = Std.downcast(DisplayUtil.findByName(anim, "textBox"), TextField);
		if (textBox != null) {
			textBox.text = value;
		}
	}

	private function frame71():Void {
		remove();
	}

	public function remove():Void {
		if (art != null) {
			art.dispose();
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
