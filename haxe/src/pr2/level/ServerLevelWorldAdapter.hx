package pr2.level;

import pr2.level.WorldLevel.LevelBlock;
import pr2.level.WorldLevel.StatDefaults;
import pr2.level.WorldLevel.TilePosition;
import pr2.level.ServerLevel.DecodedBlock;

class ServerLevelWorldAdapter {
	public static inline var TILE_SIZE:Int = ServerLevelRenderer.TILE_SIZE;
	private static inline var PADDING_TILES:Int = 4;

	public static function convert(level:ServerLevel, gravity:Float, ?id:String, ?name:String):WorldLevel {
		if (level.blocks.length == 0) {
			throw "server level has no blocks";
		}

		var minTileX = tileFloor(level.minX) - PADDING_TILES;
		var minTileY = tileFloor(level.minY) - PADDING_TILES;
		var maxTileX = tileFloor(level.maxX) + PADDING_TILES + 1;
		var maxTileY = tileFloor(level.maxY) + PADDING_TILES + 1;

		var blocks:Array<LevelBlock> = [];
		for (block in level.blocks) {
			if (isSpawnMarkerBlock(block.code)) {
				continue;
			}
			blocks.push(new LevelBlock(
				tileFloor(block.x),
				tileFloor(block.y),
				blockType(block.code),
				block.opts
			));
		}

		var start = firstOrFallback(level.startBlocks(), level.blocks[0]);
		var finish = firstOrFallback(level.finishBlocks(), start);
		return new WorldLevel(
			id == null ? "server-level" : id,
			name == null ? "Server Level" : name,
			maxTileX - minTileX + 1,
			maxTileY - minTileY + 1,
			TILE_SIZE,
			gravity,
			defaultStats(),
			worldAirPositionAbove(start),
			worldAirPositionAbove(finish),
			blocks,
			minTileX,
			minTileY
		);
	}

	public static function blockType(code:Int):BlockType {
		return switch (code) {
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4:
				BlockType.Start;
			case ObjectCodes.BLOCK_FINISH:
				BlockType.Finish;
			case ObjectCodes.BLOCK_ICE:
				BlockType.Ice;
			case ObjectCodes.BLOCK_ARROW_DOWN:
				BlockType.ArrowDown;
			case ObjectCodes.BLOCK_ARROW_UP:
				BlockType.ArrowUp;
			case ObjectCodes.BLOCK_ARROW_LEFT:
				BlockType.ArrowLeft;
			case ObjectCodes.BLOCK_ARROW_RIGHT:
				BlockType.ArrowRight;
			case ObjectCodes.BLOCK_MINE:
				BlockType.Mine;
			case ObjectCodes.BLOCK_ITEM:
				BlockType.Item;
			case ObjectCodes.BLOCK_ITEM_INF:
				BlockType.InfiniteItem;
			case ObjectCodes.BLOCK_CRUMBLE:
				BlockType.Crumble;
			case ObjectCodes.BLOCK_VANISH:
				BlockType.Vanish;
			case ObjectCodes.BLOCK_MOVE:
				BlockType.Move;
			case ObjectCodes.BLOCK_WATER:
				BlockType.Water;
			case ObjectCodes.BLOCK_ROTATE_RIGHT:
				BlockType.RotateRight;
			case ObjectCodes.BLOCK_ROTATE_LEFT:
				BlockType.RotateLeft;
			case ObjectCodes.BLOCK_PUSH:
				BlockType.Push;
			case ObjectCodes.BLOCK_SAFETY:
				BlockType.Safety;
			case ObjectCodes.BLOCK_TELEPORT:
				BlockType.Teleport;
			case ObjectCodes.BLOCK_CUSTOM_STATS:
				BlockType.CustomStats;
			case ObjectCodes.BLOCK_BRICK:
				BlockType.Brick;
			case ObjectCodes.BLOCK_HAPPY:
				BlockType.Happy;
			case ObjectCodes.BLOCK_SAD:
				BlockType.Sad;
			case ObjectCodes.BLOCK_HEART:
				BlockType.Heart;
			case ObjectCodes.BLOCK_TIME:
				BlockType.Time;
			case ObjectCodes.BLOCK_BASIC1 | ObjectCodes.BLOCK_BASIC2 | ObjectCodes.BLOCK_BASIC3 | ObjectCodes.BLOCK_BASIC4:
				BlockType.Basic;
			default:
				BlockType.Solid;
		}
	}

	private static function isSpawnMarkerBlock(code:Int):Bool {
		return (code >= ObjectCodes.BLOCK_START1 && code <= ObjectCodes.BLOCK_START4) || code == ObjectCodes.BLOCK_MINION_EGG;
	}

	private static function worldAirPositionAbove(block:DecodedBlock):TilePosition {
		var position = new TilePosition(tileFloor(block.x), tileFloor(block.y));
		return new TilePosition(position.x, position.y - 1);
	}

	private static function tileFloor(value:Int):Int {
		return Std.int(Math.floor(value / TILE_SIZE));
	}

	private static function firstOrFallback(blocks:Array<DecodedBlock>, fallback:DecodedBlock):DecodedBlock {
		return blocks.length == 0 ? fallback : blocks[0];
	}

	private static function defaultStats():StatDefaults {
		return new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40);
	}
}
