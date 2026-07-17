package pr2.level;

import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.level.ServerLevel.DecodedBlock;

/** Constructs block display trees, overlays, and deterministic vector fallbacks. */
@:access(pr2.level.ServerLevelRenderer)
class ServerLevelBlockFactory {
	private final owner:ServerLevelRenderer;

	public function new(owner:ServerLevelRenderer) {
		this.owner = owner;
	}

	public function createBlockDisplay(block:DecodedBlock):Sprite {
		var container = new Sprite();
		container.x = block.x;
		container.y = block.y;

		if (block.code == ObjectCodes.BLOCK_TELEPORT) {
			var background = new Shape();
			background.graphics.beginFill(teleportBlockColor(block.opts));
			background.graphics.drawRect(0, 0, ServerLevelRenderer.TILE_SIZE, ServerLevelRenderer.TILE_SIZE);
			background.graphics.endFill();
			container.addChild(background);
		}

		var assetPath = ServerLevelRenderer.blockAssetPath(block.code);
		if (assetPath != "" && Assets.exists(assetPath, AssetType.IMAGE)) {
			var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
			bitmap.smoothing = false;
			bitmap.width = ServerLevelRenderer.TILE_SIZE;
			bitmap.height = ServerLevelRenderer.TILE_SIZE;
			container.addChild(bitmap);
		} else {
			drawFallbackBlock(container, block.code);
		}

		var arrowRotation = ServerLevelRenderer.arrowOverlayRotation(block.code);
		if (arrowRotation != null) {
			var arrow = addArrowOverlay(container, arrowRotation);
			if (arrow != null) {
				owner.arrowDisplays.set(ServerLevelRenderer.blockKey(block.x, block.y), arrow);
			}
		}

		return container;
	}

	public static function teleportBlockColor(options:String):Int {
		var parsed = Std.parseInt(options);
		return parsed == null ? ServerLevelRenderer.TELEPORT_DEFAULT_COLOR : parsed;
	}

	public function createIceOverlay():Sprite {
		var overlay = new Sprite();
		overlay.name = ServerLevelRenderer.ICE_OVERLAY_NAME;
		var assetPath = ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_ICE);
		if (assetPath != "" && Assets.exists(assetPath, AssetType.IMAGE)) {
			var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
			bitmap.smoothing = false;
			bitmap.width = ServerLevelRenderer.TILE_SIZE;
			bitmap.height = ServerLevelRenderer.TILE_SIZE;
			overlay.addChild(bitmap);
		} else {
			drawFallbackBlock(overlay, ObjectCodes.BLOCK_ICE);
		}
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
		pivot.x = ServerLevelRenderer.TILE_SIZE / 2;
		pivot.y = ServerLevelRenderer.TILE_SIZE / 2;
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

	public static function drawFallbackBlock(container:Sprite, code:Int):Void {
		var shape = new Shape();
		shape.graphics.beginFill(fallbackFill(code), 0.9);
		shape.graphics.drawRect(0, 0, ServerLevelRenderer.TILE_SIZE, ServerLevelRenderer.TILE_SIZE);
		shape.graphics.endFill();
		shape.graphics.lineStyle(1, 0x111111, 0.55);
		shape.graphics.drawRect(0.5, 0.5, ServerLevelRenderer.TILE_SIZE - 1, ServerLevelRenderer.TILE_SIZE - 1);
		container.addChild(shape);
	}

	public static function fallbackFill(code:Int):Int {
		return switch (code) {
			case ObjectCodes.BLOCK_ARROW_DOWN | ObjectCodes.BLOCK_ARROW_UP | ObjectCodes.BLOCK_ARROW_LEFT | ObjectCodes.BLOCK_ARROW_RIGHT: 0xD0D0D0;
			default: 0x888888;
		}
	}

}
