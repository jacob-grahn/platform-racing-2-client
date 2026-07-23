package pr2.level;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.ColorTransform;
import pr2.Constants;

/** Owns the non-gameplay background planes and their color treatment. */
@:access(pr2.level.LevelRenderer)
class LevelBackgroundRenderer {
	private final owner:LevelRenderer;

	public function new(owner:LevelRenderer) {
		this.owner = owner;
	}

	public function drawSolidBackground():Void {
		owner.solidBackground = new Shape();
		redrawSolidBackground();
		owner.addChild(owner.solidBackground);
	}

	public function drawArtBackground():Void {
		if (!owner.drawArtEnabled || owner.level.artBackgroundCode == null) return;
		var backgroundCode = owner.level.artBackgroundCode;
		owner.artBackgroundContainer = new Sprite();
		owner.addChild(owner.artBackgroundContainer);
		owner.artBackgroundTintScale = backgroundCode == 204 || backgroundCode == LevelRenderer.BG5_CODE ? 0 : 1;
		var assetPath = LevelAssetCatalog.artBackgroundAssetPath(backgroundCode);
		if (assetPath != "") addArtBackgroundChild(pr2.runtime.SvgAsset.create(assetPath), 0);
		if (backgroundCode == LevelRenderer.BG5_CODE) addArtBackgroundChild(createBg5CircleGrid());
	}

	public function redrawSolidBackground():Void {
		if (owner.solidBackground == null) return;
		owner.solidBackground.graphics.clear();
		owner.solidBackground.graphics.beginFill(owner.currentBackgroundColor);
		owner.solidBackground.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		owner.solidBackground.graphics.endFill();
	}

	public function applyColorTransforms():Void {
		for (child in owner.artBackgroundChildren) child.transform.colorTransform = colorTransform(owner.artBackgroundTintScale);
		owner.blockLayer.transform.colorTransform = colorTransform(1);
		for (i in 0...owner.artLayerContainers.length) {
			var container = owner.artLayerContainers[i];
			if (container != null && i < owner.level.artLayers.length) {
				container.transform.colorTransform = colorTransform(owner.level.artLayers[i].scale);
			}
		}
	}

	private function addArtBackgroundChild(child:DisplayObject, ?index:Int):Void {
		if (owner.artBackgroundContainer == null) return;
		if (index != null && index >= 0 && index < owner.artBackgroundContainer.numChildren) {
			owner.artBackgroundContainer.addChildAt(child, index);
		} else {
			owner.artBackgroundContainer.addChild(child);
		}
		child.transform.colorTransform = colorTransform(owner.artBackgroundTintScale);
		owner.artBackgroundChildren.push(child);
	}

	private function colorTransform(layerScale:Float):ColorTransform {
		var amount = ((1 - layerScale) * 0.4) + 0.1;
		var red = (owner.currentBackgroundColor >> 16) & 0xFF;
		var green = (owner.currentBackgroundColor >> 8) & 0xFF;
		var blue = owner.currentBackgroundColor & 0xFF;
		return new ColorTransform(1 - amount, 1 - amount, 1 - amount, 1, red * amount, green * amount, blue * amount, 0);
	}

	public static function createBg5CircleGrid(?random:Void->Float):Sprite {
		var nextRandom = random == null ? Math.random : random;
		var grid = new Sprite();
		grid.name = "bg5CircleGrid";
		grid.mouseEnabled = false;
		grid.mouseChildren = false;
		var tileSize = 50;
		var cols = Std.int(Constants.STAGE_WIDTH / tileSize);
		var rows = Std.int(Constants.STAGE_HEIGHT / tileSize);
		for (col in 0...cols) {
			for (row in 0...rows) {
				var circle = new Shape();
				circle.graphics.beginFill(Std.int(nextRandom() * 0xFFFFFF));
				circle.graphics.drawCircle(0, 0, 12.5);
				circle.graphics.endFill();
				circle.x = col * tileSize + 20;
				circle.y = row * tileSize + 20;
				grid.addChild(circle);
			}
		}
		return grid;
	}
}
