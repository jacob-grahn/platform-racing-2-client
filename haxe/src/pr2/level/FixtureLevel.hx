package pr2.level;

class FixtureLevel {
	public final id:String;
	public final name:String;
	public final widthTiles:Int;
	public final heightTiles:Int;
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
		blocks:Array<LevelBlock>
	) {
		this.id = id;
		this.name = name;
		this.widthTiles = widthTiles;
		this.heightTiles = heightTiles;
		this.tileSize = tileSize;
		this.gravity = gravity;
		this.stats = stats;
		this.playerStart = playerStart;
		this.finish = finish;
		this.blocks = blocks;
	}

	public function blockAt(x:Int, y:Int):Null<LevelBlock> {
		for (block in blocks) {
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
