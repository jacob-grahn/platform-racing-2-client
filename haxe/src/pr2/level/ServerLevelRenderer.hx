package pr2.level;

import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.Constants;
import pr2.level.ServerLevel.DecodedBlock;

/**
	Renders the decoded server block layer in original PR2 pixel units.

	Server levels are stored around large editor coordinates (~10000 px). This
	renderer keeps the 30 px block scale and translates the world so a chosen
	focus point, usually the first start block, appears at a stable stage point.
**/
class ServerLevelRenderer extends Sprite {
	public static inline var TILE_SIZE:Int = 30;
	public static inline var DEFAULT_FOCUS_X:Float = 180;
	public static inline var DEFAULT_FOCUS_Y:Float = 280;

	private final level:ServerLevel;
	private final offsetX:Float;
	private final offsetY:Float;

	public function new(level:ServerLevel, ?focusBlock:DecodedBlock, focusScreenX:Float = DEFAULT_FOCUS_X, focusScreenY:Float = DEFAULT_FOCUS_Y) {
		super();
		this.level = level;

		var focus = focusBlock == null ? firstRenderableBlock(level) : focusBlock;
		if (focus == null) {
			offsetX = 0;
			offsetY = 0;
		} else {
			offsetX = focusScreenX - focus.x;
			offsetY = focusScreenY - focus.y;
		}

		drawBackground();
		drawBlocks();
	}

	public function worldToScreen(x:Float, y:Float):Point {
		return new Point(x + offsetX, y + offsetY);
	}

	public static function blockAssetPath(code:Int):String {
		return switch (code) {
			case ObjectCodes.BLOCK_BASIC1: "assets/blocks/basic1.png";
			case ObjectCodes.BLOCK_BASIC2: "assets/blocks/basic2.png";
			case ObjectCodes.BLOCK_BASIC3: "assets/blocks/basic3.png";
			case ObjectCodes.BLOCK_BASIC4: "assets/blocks/basic4.png";
			case ObjectCodes.BLOCK_BRICK: "assets/blocks/brick.png";
			case ObjectCodes.BLOCK_MINE: "assets/blocks/mine_block.png";
			case ObjectCodes.BLOCK_ITEM: "assets/blocks/item.png";
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4: "assets/blocks/start.png";
			case ObjectCodes.BLOCK_ICE: "assets/blocks/ice.png";
			case ObjectCodes.BLOCK_FINISH: "assets/blocks/finish.png";
			case ObjectCodes.BLOCK_CRUMBLE: "assets/blocks/crumble.png";
			case ObjectCodes.BLOCK_VANISH: "assets/blocks/vanish.png";
			case ObjectCodes.BLOCK_MOVE: "assets/blocks/move.png";
			case ObjectCodes.BLOCK_WATER: "assets/blocks/water.png";
			case ObjectCodes.BLOCK_ROTATE_RIGHT: "assets/blocks/rotate_right.png";
			case ObjectCodes.BLOCK_ROTATE_LEFT: "assets/blocks/rotate_left.png";
			case ObjectCodes.BLOCK_PUSH: "assets/blocks/push.png";
			case ObjectCodes.BLOCK_SAFETY: "assets/blocks/safety_net.png";
			case ObjectCodes.BLOCK_ITEM_INF: "assets/blocks/infinite_item.png";
			case ObjectCodes.BLOCK_HAPPY: "assets/blocks/happy.png";
			case ObjectCodes.BLOCK_SAD: "assets/blocks/sad.png";
			case ObjectCodes.BLOCK_HEART: "assets/blocks/heart.png";
			case ObjectCodes.BLOCK_TIME: "assets/blocks/time.png";
			case ObjectCodes.BLOCK_CUSTOM_STATS: "assets/blocks/custom_stats.png";
			case ObjectCodes.BLOCK_TELEPORT: "assets/blocks/teleport_block.png";
			case ObjectCodes.BLOCK_ARROW_DOWN | ObjectCodes.BLOCK_ARROW_UP | ObjectCodes.BLOCK_ARROW_LEFT | ObjectCodes.BLOCK_ARROW_RIGHT:
				"";
			default: "";
		}
	}

	private function drawBackground():Void {
		var background = new Shape();
		background.graphics.beginFill(level.bgColor);
		background.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		background.graphics.endFill();
		addChild(background);
	}

	private function drawBlocks():Void {
		for (block in level.blocks) {
			addChild(createBlockDisplay(block));
		}
	}

	private function createBlockDisplay(block:DecodedBlock):Sprite {
		var container = new Sprite();
		var pos = worldToScreen(block.x, block.y);
		container.x = pos.x;
		container.y = pos.y;

		var assetPath = blockAssetPath(block.code);
		if (assetPath != "" && Assets.exists(assetPath, AssetType.IMAGE)) {
			var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
			bitmap.smoothing = false;
			bitmap.width = TILE_SIZE;
			bitmap.height = TILE_SIZE;
			container.addChild(bitmap);
		} else {
			drawFallbackBlock(container, block.code);
		}

		return container;
	}

	private static function drawFallbackBlock(container:Sprite, code:Int):Void {
		var shape = new Shape();
		shape.graphics.beginFill(fallbackFill(code), 0.9);
		shape.graphics.drawRect(0, 0, TILE_SIZE, TILE_SIZE);
		shape.graphics.endFill();
		shape.graphics.lineStyle(1, 0x111111, 0.55);
		shape.graphics.drawRect(0.5, 0.5, TILE_SIZE - 1, TILE_SIZE - 1);
		container.addChild(shape);
	}

	private static function fallbackFill(code:Int):Int {
		return switch (code) {
			case ObjectCodes.BLOCK_ARROW_DOWN | ObjectCodes.BLOCK_ARROW_UP | ObjectCodes.BLOCK_ARROW_LEFT | ObjectCodes.BLOCK_ARROW_RIGHT: 0xD0D0D0;
			default: 0x888888;
		}
	}

	private static function firstRenderableBlock(level:ServerLevel):Null<DecodedBlock> {
		return level.blocks.length == 0 ? null : level.blocks[0];
	}
}
