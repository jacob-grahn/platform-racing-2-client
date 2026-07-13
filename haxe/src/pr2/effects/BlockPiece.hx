package pr2.effects;

import openfl.display.DisplayObject;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.runtime.PR2MovieClip;

/**
	Ports `effects/BlockPiece.as`: an authored block fragment with randomized
	linear/angular velocity, friction, gravity, and alpha decay.
**/
class BlockPiece extends Sprite {
	public static inline var GRAVITY:Float = 1;
	public static inline var FRICTION:Float = 0.95;
	public static inline var FADE_RATE:Float = 0.01;

	public var graphic(default, null):Null<PR2MovieClip>;
	public var visual(default, null):DisplayObject;
	private var velX:Float;
	private var velY:Float;
	private var rotVel:Float;
	private final gravity:Float;
	private final friction:Float;
	private final fadeRate:Float;
	private var ownsCustomVisual:Bool = false;

	public function new(linkage:Null<String>, gravity:Float = GRAVITY, friction:Float = FRICTION, fadeRate:Float = FADE_RATE, spreadX:Float = 10,
			spreadY:Float = 10, spreadRot:Float = 10, startX:Float = 0, startY:Float = 0, ?random:Void->Float,
			?customVisual:DisplayObject) {
		super();
		var nextRandom = random == null ? Math.random : random;
		if (customVisual != null) {
			visual = customVisual;
			ownsCustomVisual = true;
		} else {
			graphic = PR2MovieClip.fromLinkage(linkage);
			applyConstructorFrameScript(linkage, nextRandom);
			visual = graphic;
		}
		addChild(visual);
		x = startX;
		y = startY;
		this.gravity = gravity;
		this.friction = friction;
		this.fadeRate = fadeRate;
		rotation = nextRandom() * 360;
		velX = nextRandom() * spreadX * 2 - spreadX;
		velY = nextRandom() * spreadY * 2 - spreadY;
		rotVel = nextRandom() * spreadRot * 2 - spreadRot;
		addEventListener(Event.ENTER_FRAME, tick);
	}

	private function applyConstructorFrameScript(linkage:String, nextRandom:Void->Float):Void {
		if (linkage == "BrickPieceGraphic" || linkage == "MinePieceGraphic") {
			graphic.gotoAndStop(Std.int(nextRandom() * graphic.totalFrames) + 1);
		}
	}

	private function tick(_:Event):Void {
		velX *= friction;
		velY *= friction;
		rotVel *= friction;
		velY += gravity;
		x += velX;
		y += velY;
		rotation += rotVel;
		alpha -= fadeRate;
		if (alpha <= 0) {
			remove();
		}
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, tick);
		if (graphic != null) {
			graphic.dispose();
			graphic = null;
		}
		if (visual != null && visual.parent == this) {
			removeChild(visual);
		}
		if (ownsCustomVisual) {
			var bitmap = Std.downcast(visual, Bitmap);
			if (bitmap != null && bitmap.bitmapData != null) {
				bitmap.bitmapData.dispose();
				bitmap.bitmapData = null;
			}
		}
		visual = null;
		ownsCustomVisual = false;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
