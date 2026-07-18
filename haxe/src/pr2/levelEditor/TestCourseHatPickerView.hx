package pr2.levelEditor;

import openfl.display.Sprite;
import openfl.filters.DropShadowFilter;
import openfl.geom.Matrix;
import pr2.character.CharacterRig;
import pr2.character.CharacterRig.RigPartChannels;
import pr2.runtime.SvgAsset;
import pr2.ui.view.NativeView;

/** Exact native composition of XFL `HatPickerGraphic`. */
class TestCourseHatPickerView extends NativeView {
	private final hat:Sprite;

	public function new() {
		super();
		hat = new Sprite();
		hat.name = "hat";
		hat.transform.matrix = new Matrix(0.300888061523438, 0.0806121826171875, -0.0806121826171875, 0.300888061523438, 56, 20);
		addChild(hat);
		arrow("left", 10, -0.999984741210938);
		arrow("right", 100, 1);
	}

	public function setHat(id:Int):Void {
		while (hat.numChildren > 0) hat.removeChildAt(0);
		var channels = hatChannels(id);
		var primary = SvgAsset.create(channels.primary);
		primary.name = "colorMC";
		hat.addChild(primary);
		var fixed = SvgAsset.create(channels.fixed);
		fixed.name = "fixed";
		hat.addChild(fixed);
		var secondary = SvgAsset.create(channels.secondary);
		secondary.name = "colorMC2";
		secondary.visible = id == 16;
		hat.addChild(secondary);
	}

	private function arrow(name:String, x:Float, scaleX:Float):Void {
		var arrow = new EditorNativeGraphic("HatPickerArrow");
		arrow.name = name;
		arrow.x = x;
		arrow.scaleX = scaleX;
		arrow.filters = [new DropShadowFilter(3, 90, 0, 0.25, 2, 2, 1, 1)];
		addChild(arrow);
	}

	private static function hatChannels(id:Int):RigPartChannels {
		for (variant in CharacterRig.loadClassic().parts.hat.variants) if (variant.id == id) return variant;
		throw 'Character rig has no supported hat $id';
	}
}
