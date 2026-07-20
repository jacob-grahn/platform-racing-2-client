package pr2.level;

import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.level.Level.LevelBlock;

/** Constructs block display trees, overlays, and deterministic vector fallbacks. */
@:access(pr2.level.LevelRenderer)
class BlockViewFactory {
	private final owner:LevelRenderer;

	public function new(owner:LevelRenderer) {
		this.owner = owner;
	}

	public function createBlockDisplay(block:LevelBlock):Sprite {
		var container = new Sprite();
		container.x = block.worldX;
		container.y = block.worldY;

		if (block.code == ObjectCodes.BLOCK_TELEPORT) {
			var background = new Shape();
			background.graphics.beginFill(teleportBlockColor(block.options));
			background.graphics.drawRect(0, 0, LevelRenderer.TILE_SIZE, LevelRenderer.TILE_SIZE);
			background.graphics.endFill();
			container.addChild(background);
		}

		var data = LevelRenderer.blockBitmapData(block.code);
		if (data != null) {
			var bitmap = new Bitmap(data);
			bitmap.smoothing = false;
			bitmap.width = LevelRenderer.TILE_SIZE;
			bitmap.height = LevelRenderer.TILE_SIZE;
			container.addChild(bitmap);
		} else throw 'Missing authored block bitmap for code ${block.code}';

		var arrowRotation = LevelRenderer.arrowOverlayRotation(block.code);
		if (arrowRotation != null) {
			var arrow = addArrowOverlay(container, arrowRotation);
			if (arrow != null) {
				owner.arrowDisplays.set(LevelRenderer.blockKey(block.worldX, block.worldY), arrow);
			}
		}

		return container;
	}

	public static function teleportBlockColor(options:String):Int {
		var parsed = Std.parseInt(options);
		return parsed == null ? LevelRenderer.TELEPORT_DEFAULT_COLOR : parsed;
	}

	public function createIceOverlay():Sprite {
		var overlay = new Sprite();
		overlay.name = LevelRenderer.ICE_OVERLAY_NAME;
		var data = LevelRenderer.blockBitmapData(ObjectCodes.BLOCK_ICE);
		if (data != null) {
			var bitmap = new Bitmap(data);
			bitmap.smoothing = false;
			bitmap.width = LevelRenderer.TILE_SIZE;
			bitmap.height = LevelRenderer.TILE_SIZE;
			overlay.addChild(bitmap);
		} else throw "Missing authored ice block bitmap";
		return overlay;
	}

	/**
		Adds the rotated arrow graphic over an arrow block, matching ArrowBlock,
		which places the ArrowBlockGraphic at the tile centre (15,15) and rotates
		it about that point.
	**/
	public static function addArrowOverlay(container:Sprite, rotation:Float):ArrowBlockView {
		var pivot = new Sprite();
		var arrow = new ArrowBlockView();
		pivot.addChild(arrow);
		pivot.x = LevelRenderer.TILE_SIZE / 2;
		pivot.y = LevelRenderer.TILE_SIZE / 2;
		pivot.rotation = rotation;
		container.addChild(pivot);
		return arrow;
	}

	public static function moveBlockArrowRotation(direction:Int):Float {
		return switch (direction) {
			case 3: 270;
			case 2: 90;
			case 1: 0;
			case 0: 180;
			default: 0;
		}
	}

}
