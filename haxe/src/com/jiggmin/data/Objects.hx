package com.jiggmin.data;

import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.level.ObjectCodes;
import pr2.level.ArrowBlockView;
import pr2.level.LevelAssetCatalog;
import pr2.runtime.FontResolver;
import pr2.runtime.SvgAsset;

class Objects {
	public static inline var STAMP_TREE:Int = ObjectCodes.STAMP_TREE;
	public static inline var STAMP_TREE2:Int = ObjectCodes.STAMP_TREE2;
	public static inline var STAMP_TREE3:Int = ObjectCodes.STAMP_TREE3;
	public static inline var STAMP_PETRIFIED_TREE:Int = ObjectCodes.STAMP_PETRIFIED_TREE;
	public static inline var STAMP_CACTUS:Int = ObjectCodes.STAMP_CACTUS;
	public static inline var STAMP_ROCK:Int = ObjectCodes.STAMP_ROCK;
	public static inline var STAMP_ROCK2:Int = ObjectCodes.STAMP_ROCK2;
	public static inline var STAMP_SPIRE:Int = ObjectCodes.STAMP_SPIRE;
	public static inline var STAMP_SPIRE2:Int = ObjectCodes.STAMP_SPIRE2;
	public static inline var STAMP_BUILDING1:Int = ObjectCodes.STAMP_BUILDING1;

	public static inline var BLOCK_BASIC1:Int = ObjectCodes.BLOCK_BASIC1;
	public static inline var BLOCK_BASIC2:Int = ObjectCodes.BLOCK_BASIC2;
	public static inline var BLOCK_BASIC3:Int = ObjectCodes.BLOCK_BASIC3;
	public static inline var BLOCK_BASIC4:Int = ObjectCodes.BLOCK_BASIC4;
	public static inline var BLOCK_BRICK:Int = ObjectCodes.BLOCK_BRICK;
	public static inline var BLOCK_ARROW_DOWN:Int = ObjectCodes.BLOCK_ARROW_DOWN;
	public static inline var BLOCK_ARROW_UP:Int = ObjectCodes.BLOCK_ARROW_UP;
	public static inline var BLOCK_ARROW_LEFT:Int = ObjectCodes.BLOCK_ARROW_LEFT;
	public static inline var BLOCK_ARROW_RIGHT:Int = ObjectCodes.BLOCK_ARROW_RIGHT;
	public static inline var BLOCK_MINE:Int = ObjectCodes.BLOCK_MINE;
	public static inline var BLOCK_ITEM:Int = ObjectCodes.BLOCK_ITEM;
	public static inline var BLOCK_START1:Int = ObjectCodes.BLOCK_START1;
	public static inline var BLOCK_START2:Int = ObjectCodes.BLOCK_START2;
	public static inline var BLOCK_START3:Int = ObjectCodes.BLOCK_START3;
	public static inline var BLOCK_START4:Int = ObjectCodes.BLOCK_START4;
	public static inline var BLOCK_ICE:Int = ObjectCodes.BLOCK_ICE;
	public static inline var BLOCK_FINISH:Int = ObjectCodes.BLOCK_FINISH;
	public static inline var BLOCK_CRUMBLE:Int = ObjectCodes.BLOCK_CRUMBLE;
	public static inline var BLOCK_VANISH:Int = ObjectCodes.BLOCK_VANISH;
	public static inline var BLOCK_MOVE:Int = ObjectCodes.BLOCK_MOVE;
	public static inline var BLOCK_WATER:Int = ObjectCodes.BLOCK_WATER;
	public static inline var BLOCK_ROTATE_RIGHT:Int = ObjectCodes.BLOCK_ROTATE_RIGHT;
	public static inline var BLOCK_ROTATE_LEFT:Int = ObjectCodes.BLOCK_ROTATE_LEFT;
	public static inline var BLOCK_PUSH:Int = ObjectCodes.BLOCK_PUSH;
	public static inline var BLOCK_SAFETY:Int = ObjectCodes.BLOCK_SAFETY;
	public static inline var BLOCK_ITEM_INF:Int = ObjectCodes.BLOCK_ITEM_INF;
	public static inline var BLOCK_HAPPY:Int = ObjectCodes.BLOCK_HAPPY;
	public static inline var BLOCK_SAD:Int = ObjectCodes.BLOCK_SAD;
	public static inline var BLOCK_HEART:Int = ObjectCodes.BLOCK_HEART;
	public static inline var BLOCK_TIME:Int = ObjectCodes.BLOCK_TIME;
	public static inline var BLOCK_MINION_EGG:Int = ObjectCodes.BLOCK_MINION_EGG;
	public static inline var BLOCK_CUSTOM_STATS:Int = ObjectCodes.BLOCK_CUSTOM_STATS;
	public static inline var BLOCK_TELEPORT:Int = ObjectCodes.BLOCK_TELEPORT;

	public static inline var BG1Code:Int = ObjectCodes.BG1Code;
	public static inline var BG2Code:Int = ObjectCodes.BG2Code;
	public static inline var BG3Code:Int = ObjectCodes.BG3Code;
	public static inline var BG4Code:Int = ObjectCodes.BG4Code;
	public static inline var BG5Code:Int = ObjectCodes.BG5Code;
	public static inline var BG6Code:Int = ObjectCodes.BG6Code;
	public static inline var BG7Code:Int = ObjectCodes.BG7Code;
	public static inline var TextCode:Int = ObjectCodes.TextCode;

	private static inline var TILE_SIZE:Int = 30;
	private static inline var TELEPORT_DEFAULT_COLOR:Int = 0xFF7F50;

	private function new() {}

	public static function getFromCode(code:Int):Null<DisplayObject> {
		return switch (code) {
			case ObjectCodes.STAMP_TREE: stampDisplay(code, "Tree");
			case ObjectCodes.STAMP_TREE2: stampDisplay(code, "Tree2");
			case ObjectCodes.STAMP_TREE3: stampDisplay(code, "Tree3");
			case ObjectCodes.STAMP_PETRIFIED_TREE: stampDisplay(code, "PetrifiedTree");
			case ObjectCodes.STAMP_CACTUS: stampDisplay(code, "Cactus");
			case ObjectCodes.STAMP_ROCK: stampDisplay(code, "Rock");
			case ObjectCodes.STAMP_ROCK2: stampDisplay(code, "Rock2");
			case ObjectCodes.STAMP_SPIRE: stampDisplay(code, "Spire");
			case ObjectCodes.STAMP_SPIRE2: stampDisplay(code, "Spire2");
			case ObjectCodes.STAMP_BUILDING1: stampDisplay(code, "Building1");
			case ObjectCodes.BG1Code | ObjectCodes.BG2Code | ObjectCodes.BG3Code | ObjectCodes.BG4Code | ObjectCodes.BG5Code | ObjectCodes.BG6Code | ObjectCodes.BG7Code:
				backgroundDisplay(code);
			case ObjectCodes.TextCode: textObjectTextBox();
			case ObjectCodes.BLOCK_MINION_EGG:
				// EggBlockGraphic is already authored in tile-local coordinates. Keep
				// its XFL registration and asymmetric matrices instead of normalizing
				// and stretching its visible bounds to a square.
				var egg = SvgAsset.create("assets/svg/blocks/egg_overlay.svg");
				egg.name = "EggBlockGraphic";
				egg;
			case code if (code >= ObjectCodes.BLOCK_BASIC1 && code <= ObjectCodes.BLOCK_TELEPORT):
				blockDisplay(code);
			default:
				null;
		}
	}

	private static function stampDisplay(code:Int, linkage:String):DisplayObject {
		var assetPath = LevelAssetCatalog.stampAssetPath(code);
		if (assetPath != "") {
			var vector = if (code == ObjectCodes.STAMP_CACTUS || code == ObjectCodes.STAMP_BUILDING1) {
				// These standalone SVGs compose the exact timeline SVG leaves, so
				// preserve their authored geometry instead of fitting to a measured box.
				SvgAsset.createNormalized(assetPath);
			} else {
				// The native-composed SVGs retain the XFL symbol's registration point,
				// visible bounds, and nested instance matrices.  Normalizing or fitting
				// them would shift artwork whose authored bounds extend above/left of
				// (0, 0), and would replace exact XFL geometry with measured scaling.
				SvgAsset.create(assetPath);
			};
			vector.name = linkage;
			return vector;
		}
		return null;
	}

	private static function backgroundDisplay(code:Int):DisplayObject {
		var path = LevelAssetCatalog.artBackgroundAssetPath(code);
		var background = SvgAsset.create(path);
		background.name = switch (code) {
			case ObjectCodes.BG1Code: "BG1";
			case ObjectCodes.BG2Code: "BG2";
			case ObjectCodes.BG3Code: "BG3";
			case ObjectCodes.BG4Code: "BG4";
			case ObjectCodes.BG5Code: "BG5";
			case ObjectCodes.BG6Code: "BG6";
			case ObjectCodes.BG7Code: "BG7";
			default: "";
		}
		return background;
	}

	private static function textObjectTextBox():Null<DisplayObject> {
		var textBox = new TextField();
		textBox.name = "textBox";
		var format = new TextFormat(FontResolver.resolve("Verdana"), 18);
		format.leading = 4;
		textBox.defaultTextFormat = format;
		textBox.x = 2;
		textBox.y = 2;
		textBox.scaleY = 1.00286865234375;
		textBox.width = 76;
		textBox.height = 29.2;
		textBox.selectable = false;
		textBox.wordWrap = false;
		textBox.multiline = true;
		return textBox;
	}

	private static function blockDisplay(code:Int):Sprite {
		var holder = new Sprite();
		holder.name = blockClassName(code);
		if (code == ObjectCodes.BLOCK_TELEPORT) {
			var background = new Shape();
			background.name = "teleportColor";
			background.graphics.beginFill(TELEPORT_DEFAULT_COLOR);
			background.graphics.drawRect(0, 0, TILE_SIZE, TILE_SIZE);
			background.graphics.endFill();
			holder.addChild(background);
		}
		addBlockBitmap(holder, code);
		addArrowGraphic(holder, code);
		return holder;
	}

	private static function addBlockBitmap(holder:Sprite, code:Int):Void {
		var data = LevelAssetCatalog.blockBitmapData(code);
		if (data != null) {
			var bitmap = new Bitmap(data);
			bitmap.name = blockBitmapName(code);
			bitmap.smoothing = false;
			bitmap.width = TILE_SIZE;
			bitmap.height = TILE_SIZE;
			holder.addChild(bitmap);
			return;
		}
		throw 'Missing authored block bitmap for code $code';
	}

	private static function addArrowGraphic(holder:Sprite, code:Int):Void {
		var rotation = LevelAssetCatalog.arrowOverlayRotation(code);
		if (rotation == null) {
			return;
		}
		var arrow = new ArrowBlockView();
		arrow.name = "ArrowBlockGraphic";
		arrow.x = TILE_SIZE / 2;
		arrow.y = TILE_SIZE / 2;
		arrow.rotation = rotation;
		holder.addChild(arrow);
	}

	private static function blockBitmapName(code:Int):String {
		return switch (code) {
			case ObjectCodes.BLOCK_BASIC1: "Basic1Bitmap";
			case ObjectCodes.BLOCK_BASIC2 | ObjectCodes.BLOCK_ARROW_DOWN | ObjectCodes.BLOCK_ARROW_UP | ObjectCodes.BLOCK_ARROW_LEFT | ObjectCodes.BLOCK_ARROW_RIGHT:
				"Basic2Bitmap";
			case ObjectCodes.BLOCK_BASIC3: "Basic3Bitmap";
			case ObjectCodes.BLOCK_BASIC4: "Basic4Bitmap";
			case ObjectCodes.BLOCK_BRICK: "BrickBitmap";
			case ObjectCodes.BLOCK_MINE: "MineBitmap";
			case ObjectCodes.BLOCK_ITEM: "ItemBitmap";
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4: "StartBitmap";
			case ObjectCodes.BLOCK_ICE: "IceBitmap";
			case ObjectCodes.BLOCK_FINISH: "FinishBitmap";
			case ObjectCodes.BLOCK_CRUMBLE: "CrumbleBitmap";
			case ObjectCodes.BLOCK_VANISH: "VanishBitmap";
			case ObjectCodes.BLOCK_MOVE: "MoveBitmap";
			case ObjectCodes.BLOCK_WATER: "WaterBitmap";
			case ObjectCodes.BLOCK_ROTATE_RIGHT: "RotateRightBitmap";
			case ObjectCodes.BLOCK_ROTATE_LEFT: "RotateLeftBitmap";
			case ObjectCodes.BLOCK_PUSH: "PushBitmap";
			case ObjectCodes.BLOCK_SAFETY: "SafetyNetBitmap";
			case ObjectCodes.BLOCK_ITEM_INF: "InfiniteItemBitmap";
			case ObjectCodes.BLOCK_HAPPY: "HappyBitmap";
			case ObjectCodes.BLOCK_SAD: "SadBitmap";
			case ObjectCodes.BLOCK_HEART: "HeartBitmap";
			case ObjectCodes.BLOCK_TIME: "TimeBitmap";
			case ObjectCodes.BLOCK_CUSTOM_STATS: "CustomStatsBitmap";
			case ObjectCodes.BLOCK_TELEPORT: "TeleportBitmap";
			default: "BlockBitmap";
		}
	}

	private static function blockClassName(code:Int):String {
		return switch (code) {
			case ObjectCodes.BLOCK_BASIC1 | ObjectCodes.BLOCK_BASIC2 | ObjectCodes.BLOCK_BASIC3 | ObjectCodes.BLOCK_BASIC4: "BasicBlock";
			case ObjectCodes.BLOCK_BRICK: "BrickBlock";
			case ObjectCodes.BLOCK_ARROW_DOWN: "ArrowDownBlock";
			case ObjectCodes.BLOCK_ARROW_UP: "ArrowUpBlock";
			case ObjectCodes.BLOCK_ARROW_LEFT: "ArrowLeftBlock";
			case ObjectCodes.BLOCK_ARROW_RIGHT: "ArrowRightBlock";
			case ObjectCodes.BLOCK_MINE: "MineBlock";
			case ObjectCodes.BLOCK_ITEM: "ItemBlock";
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4: "StartBlock";
			case ObjectCodes.BLOCK_ICE: "IceBlock";
			case ObjectCodes.BLOCK_FINISH: "FinishBlock";
			case ObjectCodes.BLOCK_CRUMBLE: "CrumbleBlock";
			case ObjectCodes.BLOCK_VANISH: "VanishBlock";
			case ObjectCodes.BLOCK_MOVE: "MoveBlock";
			case ObjectCodes.BLOCK_WATER: "WaterBlock";
			case ObjectCodes.BLOCK_ROTATE_RIGHT: "RotateRightBlock";
			case ObjectCodes.BLOCK_ROTATE_LEFT: "RotateLeftBlock";
			case ObjectCodes.BLOCK_PUSH: "PushBlock";
			case ObjectCodes.BLOCK_SAFETY: "SafetyBlock";
			case ObjectCodes.BLOCK_ITEM_INF: "InfItemBlock";
			case ObjectCodes.BLOCK_HAPPY: "HappyBlock";
			case ObjectCodes.BLOCK_SAD: "SadBlock";
			case ObjectCodes.BLOCK_HEART: "HeartBlock";
			case ObjectCodes.BLOCK_TIME: "TimeBlock";
			case ObjectCodes.BLOCK_CUSTOM_STATS: "CustomStatsBlock";
			case ObjectCodes.BLOCK_TELEPORT: "TeleportBlock";
			default: "Block";
		}
	}
}
