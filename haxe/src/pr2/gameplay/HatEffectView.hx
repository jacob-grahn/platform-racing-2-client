package pr2.gameplay;

import openfl.display.Sprite;

/** Native loose-hat vector with primary and secondary tint channels. */
class HatEffectView extends Sprite {
	public final colorMC:Sprite;
	public final colorMC2:Sprite;
	public var currentFrame(default, null):Int = 1;

	public function new() {
		super();
		name = "HatGraphic";
		colorMC = new Sprite();
		colorMC.name = "colorMC";
		addChild(colorMC);
		colorMC2 = new Sprite();
		colorMC2.name = "colorMC2";
		addChild(colorMC2);
		gotoAndStop(1);
	}

	public function gotoAndStop(frame:Int):Void {
		currentFrame = frame;
		colorMC.graphics.clear();
		colorMC.graphics.beginFill(0xFFFFFF);
		colorMC.graphics.drawEllipse(-55, -22, 110, 34);
		colorMC.graphics.drawRoundRect(-34, -55, 68, 46, 18, 18);
		colorMC.graphics.endFill();
		colorMC2.graphics.clear();
		colorMC2.graphics.beginFill(0xFFFFFF);
		colorMC2.graphics.drawRect(-38, -15, 76, 10);
		colorMC2.graphics.endFill();
	}

	public function dispose():Void {
		if (parent != null) parent.removeChild(this);
	}
}
