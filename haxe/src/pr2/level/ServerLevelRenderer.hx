package pr2.level;

import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.Constants;
import pr2.level.ServerLevel.DecodedArtLayer;
import pr2.level.ServerLevel.DecodedArtObject;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevel.DecodedDrawAction;
import pr2.level.ServerLevel.DecodedTextObject;

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
		drawArtBackground();
		// Course.attachBackgrounds places bg3/bg2/bg1 behind the map and bg4/bg5
		// in front. Preserve that authored depth order instead of flattening all
		// five drawing planes behind the blocks.
		drawArtLayer(2);
		drawArtLayer(1);
		drawArtLayer(0);
		drawBlocks();
		drawArtLayer(3);
		drawArtLayer(4);
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

	public static function artBackgroundAssetPath(code:Int):String {
		return switch (code) {
			case 201: "assets/backgrounds/bg1@4x.png";
			case 202: "assets/backgrounds/bg2@4x.png";
			case 203: "assets/backgrounds/bg3@4x.png";
			case 204: "assets/backgrounds/bg4@4x.png";
			case 205: "assets/backgrounds/bg5@4x.png";
			case 206: "assets/backgrounds/bg6@4x.png";
			case 207: "assets/backgrounds/bg7@4x.png";
			default: "";
		}
	}

	public static function stampAssetPath(code:Int):String {
		return switch (code) {
			case 0: "assets/stamps/tree1@4x.png";
			case 1: "assets/stamps/tree2@4x.png";
			case 2: "assets/stamps/tree3@4x.png";
			case 3: "assets/stamps/petrified_tree@4x.png";
			case 5: "assets/stamps/rock1@4x.png";
			case 6: "assets/stamps/rock2@4x.png";
			case 7: "assets/stamps/spire1@4x.png";
			case 8: "assets/stamps/spire2@4x.png";
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

	private function drawArtBackground():Void {
		if (level.artBackgroundCode == null) {
			return;
		}
		var assetPath = artBackgroundAssetPath(level.artBackgroundCode);
		if (assetPath == "" || !Assets.exists(assetPath, AssetType.IMAGE)) {
			return;
		}

		var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
		bitmap.smoothing = true;
		bitmap.width = Constants.STAGE_WIDTH;
		bitmap.height = Constants.STAGE_HEIGHT;
		addChild(bitmap);
	}

	private function drawArtLayer(index:Int):Void {
		if (index >= level.artLayers.length) return;
		var layer = level.artLayers[index];
		var container = new Sprite();
		container.name = 'artLayer${index + 1}';
		// Background.setPos rounds camera movement after applying the plane's
		// parallax scale. DrawableBackground applies that scale to placed objects
		// and text individually rather than scaling its stroke canvas.
		container.x = Math.round(offsetX * layer.scale);
		container.y = Math.round(offsetY * layer.scale);
		drawLayerStrokes(container, layer.drawActions);
		drawLayerObjects(container, layer.objects, layer.scale);
		drawLayerTexts(container, layer.texts, layer.scale);
		addChild(container);
	}

	private function drawLayerStrokes(container:Sprite, actions:Array<DecodedDrawAction>):Void {
		var color = 0x000000;
		var size = 10.0;
		var mode = "draw";
		var drawing = false;
		container.graphics.lineStyle(size, color);

		for (action in actions) {
			switch (action.kind) {
				case "c":
					color = Std.int(action.values[0]);
					container.graphics.lineStyle(size, color);
				case "t":
					size = action.values[0];
					container.graphics.lineStyle(size, color);
				case "m":
					mode = action.text;
				case "d":
					if (mode == "erase" || action.values.length < 2) {
						continue;
					}
					var x = action.values[0];
					var y = action.values[1];
					container.graphics.moveTo(x, y);
					container.graphics.lineTo(x - 0.15, y);
					container.graphics.moveTo(x, y);
					var i = 2;
					while (i + 1 < action.values.length) {
						x += action.values[i];
						y += action.values[i + 1];
						container.graphics.lineTo(x, y);
						i += 2;
					}
					drawing = true;
				default:
			}
		}
		if (!drawing) {
			container.graphics.clear();
		}
	}

	private function drawLayerObjects(container:Sprite, objects:Array<DecodedArtObject>, layerScale:Float):Void {
		for (object in objects) {
			var assetPath = stampAssetPath(object.code);
			if (assetPath == "" || !Assets.exists(assetPath, AssetType.IMAGE)) {
				continue;
			}
			var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
			bitmap.smoothing = true;
			bitmap.scaleX = object.scaleX * layerScale / 4;
			bitmap.scaleY = object.scaleY * layerScale / 4;
			bitmap.x = object.x * layerScale;
			bitmap.y = object.y * layerScale;
			container.addChild(bitmap);
		}
	}

	private function drawLayerTexts(container:Sprite, texts:Array<DecodedTextObject>, layerScale:Float):Void {
		for (text in texts) {
			var field = new TextField();
			field.selectable = false;
			field.wordWrap = false;
			field.multiline = true;
			field.autoSize = TextFieldAutoSize.LEFT;
			field.textColor = text.color;
			field.text = parseTextObjectText(text.text);
			field.scaleX = text.scaleX * layerScale;
			field.scaleY = text.scaleY * layerScale;
			field.height = 24;
			field.x = text.x * layerScale;
			field.y = text.y * layerScale;
			container.addChild(field);
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

	private static function parseTextObjectText(value:String):String {
		return StringTools.replace(StringTools.replace(value, "|", ","), "<br>", "\n");
	}
}
