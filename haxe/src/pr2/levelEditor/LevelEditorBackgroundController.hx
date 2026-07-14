package pr2.levelEditor;

import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.ColorTransform;
import pr2.level.ArtBackgroundLoader;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevelRenderer;

/** Owns editor background display objects, asynchronous loading, and tinting. */
@:access(pr2.levelEditor.LevelEditor)
class LevelEditorBackgroundController {
	private final owner:LevelEditor;

	public function new(owner:LevelEditor) {
		this.owner = owner;
	}

	public function attachEditorBackground():Void {
		owner.solidBackground = new Shape();
		owner.solidBackground.name = "editorSolidBackground";
		owner.addChild(owner.solidBackground);
		owner.artBackgroundContainer = new Sprite();
		owner.artBackgroundContainer.name = "editorArtBackground";
		owner.artBackgroundContainer.mouseEnabled = false;
		owner.artBackgroundContainer.mouseChildren = false;
		owner.addChild(owner.artBackgroundContainer);
		redrawEditorBackground();
		renderArtBackground();
	}

	public function redrawEditorBackground():Void {
		if (owner.solidBackground == null) {
			return;
		}
		owner.solidBackground.graphics.clear();
		owner.solidBackground.graphics.beginFill(owner.color);
		owner.solidBackground.graphics.drawRect(0, 0, LevelEditor.BASE_HALF_STAGE_WIDTH * 2, LevelEditor.BASE_HALF_STAGE_HEIGHT * 2);
		owner.solidBackground.graphics.endFill();
	}

	public function renderArtBackground():Void {
		owner.backgroundLoadGeneration++;
		var generation = owner.backgroundLoadGeneration;
		if (owner.artBackgroundContainer == null) {
			return;
		}
		while (owner.artBackgroundContainer.numChildren > 0) {
			owner.artBackgroundContainer.removeChildAt(0);
		}
		var code = owner.artBackgroundCode;
		if (code == null) {
			return;
		}
		if (code == ObjectCodes.BG5Code) {
			owner.artBackgroundContainer.addChild(ServerLevelRenderer.createBg5CircleGrid());
		}
		var assetPath = ServerLevelRenderer.artBackgroundAssetPath(code);
		if (assetPath == "") {
			applyArtBackgroundTransform(code);
			return;
		}
		ArtBackgroundLoader.request(assetPath, function(bitmapData):Void {
			if (bitmapData == null || owner.artBackgroundContainer == null || generation != owner.backgroundLoadGeneration || owner.artBackgroundCode != code) {
				return;
			}
			var bitmap = new Bitmap(bitmapData);
			bitmap.smoothing = true;
			bitmap.width = LevelEditor.BASE_HALF_STAGE_WIDTH * 2;
			bitmap.height = LevelEditor.BASE_HALF_STAGE_HEIGHT * 2;
			owner.artBackgroundContainer.addChildAt(bitmap, 0);
			applyArtBackgroundTransform(code);
		});
		applyArtBackgroundTransform(code);
	}

	public function applyEditorColorTransforms():Void {
		if (owner.blockLayer != null) {
			owner.blockLayer.transform.colorTransform = backgroundColorTransform(1);
		}
		for (layer in owner.drawLayers) {
			layer.transform.colorTransform = backgroundColorTransform(layer.layerScale);
		}
		for (layer in owner.objectLayers) {
			layer.transform.colorTransform = backgroundColorTransform(layer.scaleX);
		}
		if (owner.artBackgroundCode != null) {
			applyArtBackgroundTransform(owner.artBackgroundCode);
		}
	}

	public function applyArtBackgroundTransform(code:Int):Void {
		if (owner.artBackgroundContainer != null) {
			owner.artBackgroundContainer.transform.colorTransform = backgroundColorTransform(code == ObjectCodes.BG4Code || code == ObjectCodes.BG5Code ? 0 : 1);
		}
	}

	public function backgroundColorTransform(layerScale:Float):ColorTransform {
		var amount = ((1 - layerScale) * 0.4) + 0.1;
		var red = (owner.color >> 16) & 0xFF;
		var green = (owner.color >> 8) & 0xFF;
		var blue = owner.color & 0xFF;
		return new ColorTransform(1 - amount, 1 - amount, 1 - amount, 1, red * amount, green * amount, blue * amount, 0);
	}

}
