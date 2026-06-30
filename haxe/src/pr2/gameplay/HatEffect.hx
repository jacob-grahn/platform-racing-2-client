package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.geom.ColorTransform;
import pr2.net.CommandHandler;
import pr2.runtime.PR2MovieClip;

typedef HatEffectInfo = {
	final x:Float;
	final y:Float;
	final rot:Int;
	final num:Int;
	final color:Int;
	final color2:Int;
	final id:Int;
}

/**
	Loose hat state/display ported from `effects.Hat` for hat-attack side effects.
	Physics movement is owned by `Course`; this class covers the lifecycle,
	authored hat graphic, color channels, and remote remove command.
**/
class HatEffect {
	public final id:Int;
	public final display:PR2MovieClip;
	public var posX:Float;
	public var posY:Float;
	public var rot:Int;
	public var num(default, null):Int;
	public var color(default, null):Int;
	public var color2(default, null):Int;
	private final owner:Course;
	private final commandHandler:CommandHandler;

	public function new(owner:Course, x:Int, y:Int, rot:Int, num:Int, color:Int, color2:Int, id:Int, ?displayLayer:Sprite,
			?commandHandler:CommandHandler) {
		this.owner = owner;
		this.id = id;
		this.posX = x;
		this.posY = y;
		this.rot = rot;
		this.num = num;
		this.color = color;
		this.color2 = color2;
		this.commandHandler = commandHandler != null ? commandHandler : CommandHandler.commandHandler;

		display = PR2MovieClip.fromLinkage("HatGraphic", {maxNestedDepth: 8});
		display.gotoAndStop(num);
		display.x = x;
		display.y = y;
		display.rotation = rot;
		display.scaleX = 0.15;
		display.scaleY = 0.15;
		setupColorChannel("colorMC", color, true);
		setupColorChannel("colorMC2", num == 16 && color2 == -1 ? 0 : color2, color2 != -1 || num == 16);
		if (displayLayer != null) {
			displayLayer.addChild(display);
		}
		this.owner.looseHats.set(id, this);
		this.commandHandler.defineCommand('removeHat$id', function(_:Array<String>):Void remove());
	}

	public function info():HatEffectInfo {
		return {
			x: posX,
			y: posY,
			rot: rot,
			num: num,
			color: color,
			color2: color2,
			id: id
		};
	}

	public function remove():Void {
		if (display.parent != null) {
			display.parent.removeChild(display);
		}
		if (owner.looseHats != null) {
			owner.looseHats.remove(id);
		}
		commandHandler.defineCommand('removeHat$id', null);
	}

	private function setupColorChannel(name:String, tint:Int, visible:Bool):Void {
		var child = findByName(display, name);
		if (child == null) {
			return;
		}
		child.visible = visible;
		if (visible) {
			child.transform.colorTransform = colorTransformFor(tint);
		}
	}

	private static function findByName(root:DisplayObject, name:String):Null<DisplayObject> {
		if (root.name == name) {
			return root;
		}
		var container = Std.downcast(root, Sprite);
		if (container == null) {
			return null;
		}
		for (i in 0...container.numChildren) {
			var found = findByName(container.getChildAt(i), name);
			if (found != null) {
				return found;
			}
		}
		return null;
	}

	private static function colorTransformFor(color:Int):ColorTransform {
		return new ColorTransform(0, 0, 0, 1, (color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF, 0);
	}
}
