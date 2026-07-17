package pr2.effects;

import openfl.display.DisplayObject;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

/**
	Ports `effects/BlockPiece.as`: an authored block fragment with randomized
	linear/angular velocity, friction, gravity, and alpha decay.
**/
class BlockPiece extends Sprite {
	public static inline var GRAVITY:Float = 1;
	public static inline var FRICTION:Float = 0.95;
	public static inline var FADE_RATE:Float = 0.01;

	public var visual(default, null):DisplayObject;
	public var selectedFrame(default, null):Int = 1;
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
			visual = createAuthoredVisual(linkage, nextRandom);
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

	private function createAuthoredVisual(linkage:String, nextRandom:Void->Float):DisplayObject {
		return switch (linkage) {
			case "BrickPieceGraphic":
				var frames:Array<StaticSvg> = [StaticSvg.BrickPiece1, StaticSvg.BrickPiece2, StaticSvg.BrickPiece3, StaticSvg.BrickPiece4, StaticSvg.BrickPiece5];
				selectedFrame = Std.int(nextRandom() * frames.length) + 1;
				NativeAssets.svg(frames[selectedFrame - 1]);
			case "CrumblePieceGraphic":
				selectedFrame = 1;
				NativeAssets.svg(StaticSvg.CrumblePiece);
			case "MinePieceGraphic":
				selectedFrame = Std.int(nextRandom() * 6) + 1;
				makeMinePiece(selectedFrame);
			default:
				throw 'Unsupported block piece graphic $linkage';
		}
	}

	private function makeMinePiece(frame:Int):DisplayObject {
		return switch (frame) {
			case 1: stack([StaticSvg.MinePiece1Back, StaticSvg.MinePiece1Front]);
			case 2: stack([StaticSvg.MinePiece2Back, StaticSvg.MinePiece2Middle, StaticSvg.MinePiece2Front]);
			case 3: stack([StaticSvg.MinePiece3Back, StaticSvg.MinePiece3Front]);
			case 4: NativeAssets.svg(StaticSvg.MinePiece4);
			case 5: NativeAssets.svg(StaticSvg.MinePiece5);
			case 6:
				var art = NativeAssets.svg(StaticSvg.MinePiece6);
				art.scaleX = art.scaleY = 0.050994873046875;
				art.x = -2.4;
				art.y = -2.35;
				art;
			default: throw 'Invalid mine piece frame $frame';
		}
	}

	private function stack(ids:Array<StaticSvg>):Sprite {
		var holder = new Sprite();
		for (id in ids) holder.addChild(NativeAssets.svg(id));
		return holder;
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
