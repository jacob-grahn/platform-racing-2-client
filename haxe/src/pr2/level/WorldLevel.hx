package pr2.level;

/** Collision/gameplay level whose tile coordinates are authored world coordinates. */
class WorldLevel {
	public final id:String;
	public final name:String;
	public final minTileX:Int;
	public final minTileY:Int;
	public final maxTileX:Int;
	public final maxTileY:Int;
	public final tileSize:Int;
	public final gravity:Float;
	public final stats:StatDefaults;
	public final playerStart:TilePosition;
	public final finish:TilePosition;
	public final blocks:Array<LevelBlock>;

	public function new(
		id:String,
		name:String,
		widthTiles:Int,
		heightTiles:Int,
		tileSize:Int,
		gravity:Float,
		stats:StatDefaults,
		playerStart:TilePosition,
		finish:TilePosition,
		blocks:Array<LevelBlock>,
		minTileX:Int = 0,
		minTileY:Int = 0
	) {
		this.id = id;
		this.name = name;
		this.minTileX = minTileX;
		this.minTileY = minTileY;
		this.maxTileX = minTileX + widthTiles - 1;
		this.maxTileY = minTileY + heightTiles - 1;
		this.tileSize = tileSize;
		this.gravity = gravity;
		this.stats = stats;
		this.playerStart = playerStart;
		this.finish = finish;
		this.blocks = blocks;
	}

	public var widthTiles(get, never):Int;
	private inline function get_widthTiles():Int return maxTileX - minTileX + 1;

	public var heightTiles(get, never):Int;
	private inline function get_heightTiles():Int return maxTileY - minTileY + 1;

	public inline function containsTile(x:Int, y:Int):Bool {
		return x >= minTileX && y >= minTileY && x <= maxTileX && y <= maxTileY;
	}

	public function blockAt(x:Int, y:Int):Null<LevelBlock> {
		var index = blocks.length;
		while (index > 0) {
			index--;
			var block = blocks[index];
			if (block.x == x && block.y == y) {
				return block;
			}
		}
		return null;
	}
}

class LevelBlock {
	public var x:Int;
	public var y:Int;
	public final type:BlockType;
	public final options:String;

	public function new(x:Int, y:Int, type:BlockType, options:String = "") {
		this.x = x;
		this.y = y;
		this.type = type;
		this.options = options;
	}
}

class TilePosition {
	public final x:Int;
	public final y:Int;

	public function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}
}

class StatDefaults {
	public final speed:Float;
	public final acceleration:Float;
	public final jump:Float;

	public function new(speed:Float, acceleration:Float, jump:Float) {
		this.speed = speed;
		this.acceleration = acceleration;
		this.jump = jump;
	}
}
