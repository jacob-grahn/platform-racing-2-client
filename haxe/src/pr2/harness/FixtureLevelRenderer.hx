package pr2.harness;

import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.level.BlockType;
import pr2.level.FixtureLevel;
import pr2.level.FixtureLevel.LevelBlock;

class FixtureLevelRenderer extends Sprite {
	private static inline var GRID_COLOR:Int = 0x3E465D;
	private final useBitmapAssets:Bool;

	public function new(level:FixtureLevel, useBitmapAssets:Bool = true) {
		super();
		this.useBitmapAssets = useBitmapAssets;
		drawGrid(level);
		for (block in level.blocks) {
			addChild(createBlockDisplay(block, level.tileSize));
		}
	}

	private function drawGrid(level:FixtureLevel):Void {
		var grid = new Shape();
		grid.graphics.lineStyle(1, GRID_COLOR, 0.35);
		var width = level.widthTiles * level.tileSize;
		var height = level.heightTiles * level.tileSize;

		for (x in 0...level.widthTiles + 1) {
			grid.graphics.moveTo(x * level.tileSize, 0);
			grid.graphics.lineTo(x * level.tileSize, height);
		}
		for (y in 0...level.heightTiles + 1) {
			grid.graphics.moveTo(0, y * level.tileSize);
			grid.graphics.lineTo(width, y * level.tileSize);
		}
		addChild(grid);
	}

	private function createBlockDisplay(block:LevelBlock, tileSize:Int):Sprite {
		var container = new Sprite();
		container.x = block.x * tileSize;
		container.y = block.y * tileSize;

		var assetPath = blockAssetPath(block.type);
		if (useBitmapAssets && Assets.exists(assetPath, AssetType.IMAGE)) {
			var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
			bitmap.smoothing = false;
			bitmap.width = tileSize;
			bitmap.height = tileSize;
			container.addChild(bitmap);
			return container;
		}

		var fallback = new Shape();
		fallback.graphics.beginFill(blockFill(block.type));
		fallback.graphics.drawRect(0, 0, tileSize, tileSize);
		fallback.graphics.endFill();
		fallback.graphics.lineStyle(2, blockStroke(block.type), 0.9);
		fallback.graphics.drawRect(1, 1, tileSize - 2, tileSize - 2);
		container.addChild(fallback);
		return container;
	}

	private static function blockAssetPath(type:BlockType):String {
		return switch (type) {
			case Basic: "assets/blocks/basic1.png";
			case Start: "assets/blocks/start.png";
			case Finish: "assets/blocks/finish.png";
			case Vanish: "assets/blocks/vanish.png";
			case Teleport: "assets/blocks/teleport_block.png";
			default: "";
		}
	}

	private static function blockFill(type:BlockType):Int {
		return switch (type) {
			case Basic: 0x63718C;
			case Start: 0x3A8E52;
			case Finish: 0xB64B4B;
			case Vanish: 0x56707A;
			case Teleport: 0xFF7F50;
			default: 0x888888;
		}
	}

	private static function blockStroke(type:BlockType):Int {
		return switch (type) {
			case Basic: 0xAAB4C8;
			case Start: 0xB6F0C3;
			case Finish: 0xFFD2D2;
			case Vanish: 0xBDEAF5;
			case Teleport: 0xFFD0C0;
			default: 0xCCCCCC;
		}
	}
}
