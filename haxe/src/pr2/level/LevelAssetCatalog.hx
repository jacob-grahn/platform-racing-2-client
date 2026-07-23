package pr2.level;

import openfl.display.BitmapData;
import openfl.utils.Assets;

/**
	Central catalog for level-specific visual assets.

	Keeping this outside LevelRenderer lets gameplay and editor code resolve
	assets without depending on the renderer itself.
**/
class LevelAssetCatalog {
	public static inline function isStartBlockCode(code:Int):Bool {
		return code >= ObjectCodes.BLOCK_START1 && code <= ObjectCodes.BLOCK_START4;
	}

	public static inline function isSpawnMarkerBlockCode(code:Int):Bool {
		return isStartBlockCode(code) || code == ObjectCodes.BLOCK_MINION_EGG;
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
				"assets/blocks/basic2.png";
			default: "";
		}
	}

	public static function blockBitmapData(code:Int):Null<BitmapData> {
		var path = blockAssetPath(code);
		if (path == "") return null;
		var data = Assets.getBitmapData(path);
		#if eval
		if (data == null) data = new BitmapData(LevelRenderer.TILE_SIZE, LevelRenderer.TILE_SIZE, true, 0);
		#elseif sys
		if (data == null && sys.FileSystem.exists(path)) {
			var image = lime.graphics.Image.fromBytes(sys.io.File.getBytes(path));
			if (image != null) data = BitmapData.fromImage(image);
		}
		#end
		return data;
	}

	public static inline function arrowOverlayAssetPath():String return "assets/svg/blocks/arrow_overlay.svg";

	public static function arrowOverlayRotation(code:Int):Null<Float> {
		return switch (code) {
			case ObjectCodes.BLOCK_ARROW_UP: 0;
			case ObjectCodes.BLOCK_ARROW_DOWN: 180;
			case ObjectCodes.BLOCK_ARROW_LEFT: -90;
			case ObjectCodes.BLOCK_ARROW_RIGHT: 90;
			default: null;
		}
	}

	public static function artBackgroundAssetPath(code:Int):String {
		return switch (code) {
			case 201: "assets/svg/backgrounds/bg1.svg";
			case 202: "assets/svg/backgrounds/bg2.svg";
			case 203: "assets/svg/backgrounds/bg3.svg";
			case 204: "assets/svg/backgrounds/bg4.svg";
			case 205: "assets/svg/backgrounds/bg5.svg";
			case 206: "assets/svg/backgrounds/bg6.svg";
			case 207: "assets/svg/backgrounds/bg7.svg";
			default: "";
		}
	}

	public static function stampAssetPath(code:Int):String {
		return switch (code) {
			case 0: "assets/svg/stamps/tree1.svg";
			case 1: "assets/svg/stamps/tree2.svg";
			case 2: "assets/svg/stamps/tree3.svg";
			case 3: "assets/svg/stamps/petrified_tree.svg";
			case 4: "assets/svg/stamps/cactus.svg";
			case 5: "assets/svg/stamps/rock1.svg";
			case 6: "assets/svg/stamps/rock2.svg";
			case 7: "assets/svg/stamps/spire1.svg";
			case 8: "assets/svg/stamps/spire2.svg";
			case 9: "assets/svg/stamps/building1.svg";
			default: "";
		}
	}
}
