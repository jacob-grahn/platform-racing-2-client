package pr2.character;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import pr2.runtime.PR2MovieClip;

typedef PhysicsParticleParams = {
	var graphic:String;
	var colors:Array<Int>;
	var life:Int;
	var startAlpha:Float;
	var minVelAlpha:Null<Float>;
	var maxVelAlpha:Null<Float>;
	var minVelX:Null<Float>;
	var maxVelX:Null<Float>;
	var minVelY:Null<Float>;
	var maxVelY:Null<Float>;
	var velScaleX:Float;
	var velScaleY:Float;
	var fricX:Null<Float>;
	var fricY:Null<Float>;
	var minOffsetX:Float;
	var maxOffsetX:Float;
	var minOffsetY:Float;
	var maxOffsetY:Float;
	var minScale:Float;
	var maxScale:Float;
	@:optional var minX:Null<Float>;
	@:optional var maxX:Null<Float>;
	@:optional var minY:Null<Float>;
	@:optional var maxY:Null<Float>;
	@:optional var accelX:Null<Float>;
	@:optional var accelY:Null<Float>;
	@:optional var targetAlpha:Null<Float>;
	@:optional var minVelRotation:Null<Float>;
	@:optional var maxVelRotation:Null<Float>;
	@:optional var minRotation:Null<Float>;
	@:optional var maxRotation:Null<Float>;
}

class PhysicsParticle extends Sprite {
	public var graphic(default, null):DisplayObject;
	private var velX:Float;
	private var velY:Float;
	private var fricX:Float;
	private var fricY:Float;
	private var accelX:Float;
	private var accelY:Float;
	private var maxLife:Int;
	private var life:Int;
	private var curAlpha:Float;
	private var velAlpha:Float;
	private var velScaleX:Float;
	private var velScaleY:Float;
	private var velRotation:Float;
	private final random:Void->Float;

	public function new(params:PhysicsParticleParams, ?random:Void->Float) {
		super();
		this.random = random == null ? Math.random : random;
		setColor(params.colors);
		x = randRange(params.minX, params.maxX);
		y = randRange(params.minY, params.maxY);
		rotation = randRange(params.minRotation, params.maxRotation);
		scaleX = scaleY = randRange(params.minScale, params.maxScale);
		velX = randRange(params.minVelX, params.maxVelX);
		velY = randRange(params.minVelY, params.maxVelY);
		fricX = params.fricX == null ? 1 : params.fricX;
		fricY = params.fricY == null ? 1 : params.fricY;
		accelX = params.accelX == null ? 0 : params.accelX;
		accelY = params.accelY == null ? 0 : params.accelY;
		life = maxLife = params.life == 0 ? 10 : params.life;
		curAlpha = alpha = params.startAlpha;
		velAlpha = randRange(params.minVelAlpha, params.maxVelAlpha);
		velScaleX = params.velScaleX;
		velScaleY = params.velScaleY;
		velRotation = randRange(params.minVelRotation, params.maxVelRotation);
		graphic = makeGraphic(params.graphic);
		if (graphic != null) {
			addChild(graphic);
		}
		addEventListener(Event.ENTER_FRAME, tick);
	}

	private function setColor(colors:Array<Int>):Void {
		if (colors == null || colors.length == 0) {
			return;
		}
		var index = Std.int(Math.floor(random() * colors.length));
		if (index >= colors.length) {
			index = colors.length - 1;
		}
		var transform = new ColorTransform();
		transform.color = colors[index];
		this.transform.colorTransform = transform;
	}

	private function makeGraphic(name:String):DisplayObject {
		return PR2MovieClip.fromLinkage(name, {maxNestedDepth: 2});
	}

	private function randRange(min:Null<Float>, max:Null<Float>):Float {
		if (min == null || max == null || Math.isNaN(min) || Math.isNaN(max)) {
			return 0;
		}
		return random() * (max - min) + min;
	}

	@:allow(pr2.character.ParticleEmitterTest)
	private function tick(_:Event):Void {
		x += velX;
		y += velY;
		velX = (velX + accelX) * fricX;
		velY = (velY + accelY) * fricY;
		scaleX += velScaleX;
		scaleY += velScaleY;
		rotation += velRotation;
		curAlpha += velAlpha;
		if (curAlpha > 1) {
			curAlpha = 1;
		}
		alpha = curAlpha * (life / maxLife);
		life--;
		if (life <= 0) {
			remove();
		}
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, tick);
		var clip = Std.downcast(graphic, PR2MovieClip);
		if (clip != null) {
			clip.dispose();
		}
		if (graphic != null && graphic.parent == this) {
			removeChild(graphic);
		}
		graphic = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
