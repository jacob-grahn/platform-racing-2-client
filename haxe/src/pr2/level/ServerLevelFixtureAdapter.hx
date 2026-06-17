package pr2.level;

import pr2.level.FixtureLevel.LevelBlock;
import pr2.level.FixtureLevel.StatDefaults;
import pr2.level.FixtureLevel.TilePosition;
import pr2.level.ServerLevel.DecodedBlock;

class ServerLevelFixtureAdapter {
	public static inline var TILE_SIZE:Int = ServerLevelRenderer.TILE_SIZE;
	private static inline var PADDING_TILES:Int = 4;

	public static function convert(level:ServerLevel, gravity:Float, ?id:String, ?name:String):ServerFixtureLevel {
		if (level.blocks.length == 0) {
			throw "server level has no blocks";
		}

		var minTileX = tileFloor(level.minX) - PADDING_TILES;
		var minTileY = tileFloor(level.minY) - PADDING_TILES;
		var maxTileX = tileFloor(level.maxX) + PADDING_TILES + 1;
		var maxTileY = tileFloor(level.maxY) + PADDING_TILES + 1;

		var blocks:Array<LevelBlock> = [];
		for (block in level.blocks) {
			blocks.push(new LevelBlock(
				tileFloor(block.x) - minTileX,
				tileFloor(block.y) - minTileY,
				blockType(block.code)
			));
		}

		var start = firstOrFallback(level.startBlocks(), level.blocks[0]);
		var finish = firstOrFallback(level.finishBlocks(), start);
		var fixture = new FixtureLevel(
			id == null ? "server-level" : id,
			name == null ? "Server Level" : name,
			maxTileX - minTileX + 1,
			maxTileY - minTileY + 1,
			TILE_SIZE,
			gravity,
			defaultStats(),
			normalizedAirPositionAbove(start, minTileX, minTileY),
			normalizedAirPositionAbove(finish, minTileX, minTileY),
			blocks
		);

		return new ServerFixtureLevel(fixture, minTileX, minTileY);
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
			case ObjectCodes.BLOCK_CRUMBLE:
				BlockType.Crumble;
			case ObjectCodes.BLOCK_VANISH:
				BlockType.Vanish;
			case ObjectCodes.BLOCK_WATER:
				BlockType.Water;
			case ObjectCodes.BLOCK_SAFETY:
				BlockType.Safety;
			case ObjectCodes.BLOCK_BASIC1 | ObjectCodes.BLOCK_BASIC2 | ObjectCodes.BLOCK_BASIC3 | ObjectCodes.BLOCK_BASIC4:
				BlockType.Basic;
			default:
				BlockType.Solid;
		}
	}

	private static function normalizedPosition(block:DecodedBlock, originTileX:Int, originTileY:Int):TilePosition {
		return new TilePosition(tileFloor(block.x) - originTileX, tileFloor(block.y) - originTileY);
	}

	private static function normalizedAirPositionAbove(block:DecodedBlock, originTileX:Int, originTileY:Int):TilePosition {
		var position = normalizedPosition(block, originTileX, originTileY);
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

class ServerFixtureLevel {
	public final fixture:FixtureLevel;
	public final originTileX:Int;
	public final originTileY:Int;

	public function new(fixture:FixtureLevel, originTileX:Int, originTileY:Int) {
		this.fixture = fixture;
		this.originTileX = originTileX;
		this.originTileY = originTileY;
	}

	public function fixturePixelToWorldX(x:Float):Float {
		return x + originTileX * ServerLevelFixtureAdapter.TILE_SIZE;
	}

	public function fixturePixelToWorldY(y:Float):Float {
		return y + originTileY * ServerLevelFixtureAdapter.TILE_SIZE;
	}
}
