package pr2.gameplay;

import openfl.display.Sprite;
import pr2.character.CharacterRig;
import pr2.character.CharacterRig.RigPartChannels;
import pr2.runtime.SvgAsset;

/** Native loose-hat vector with primary and secondary tint channels. */
class HatEffectView extends Sprite {
	public final colorMC:Sprite;
	public final colorMC2:Sprite;
	public final fixedArt:Sprite;
	public var currentFrame(default, null):Int = 1;

	public function new() {
		super();
		name = "HatGraphic";
		colorMC = new Sprite();
		colorMC.name = "colorMC";
		addChild(colorMC);
		fixedArt = new Sprite();
		fixedArt.name = "static";
		addChild(fixedArt);
		colorMC2 = new Sprite();
		colorMC2.name = "colorMC2";
		addChild(colorMC2);
		setHatId(1);
	}

	public function setHatId(frame:Int):Void {
		currentFrame = frame;
		var channels = hatChannels(frame);
		setChannel(colorMC, channels.primary);
		setChannel(fixedArt, channels.fixed);
		setChannel(colorMC2, channels.secondary);
	}

	private static function setChannel(holder:Sprite, path:String):Void {
		while (holder.numChildren > 0) holder.removeChildAt(0);
		var art = SvgAsset.create(path);
		art.name = path;
		holder.addChild(art);
	}

	private static function hatChannels(id:Int):RigPartChannels {
		for (variant in CharacterRig.loadClassic().parts.hat.variants) if (variant.id == id) return variant;
		throw 'Unsupported loose hat frame $id';
	}

	public function dispose():Void {
		if (parent != null) parent.removeChild(this);
	}
}
