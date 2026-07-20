package pr2.level;

/** Complete decoded level and authoritative mutable gameplay state. */
class Level {
	public static inline var DEFAULT_TILE_SIZE:Int = 30;
	private static inline var PADDING_TILES:Int = 4;

	public var id(default, null):String;
	public var name(default, null):String;
	public final minTileX:Int;
	public final minTileY:Int;
	public final maxTileX:Int;
	public final maxTileY:Int;
	public final tileSize:Int;
	public var gravity(default, null):Float;
	public var stats(default, null):StatDefaults;
	public final playerStart:TilePosition;
	public final finish:TilePosition;
	public final blocks:Array<LevelBlock>;
	public final bgColor:Int;
	public final artBackgroundCode:Null<Int>;
	public final artLayers:Array<LevelArtLayer>;
	public final minX:Int;
	public final minY:Int;
	public final maxX:Int;
	public final maxY:Int;

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
		minTileY:Int = 0,
		bgColor:Int = 0xFFFFFF,
		?artLayers:Array<LevelArtLayer>,
		?artBackgroundCode:Null<Int>,
		?authoredBounds:{minX:Int, minY:Int, maxX:Int, maxY:Int}
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
		this.bgColor = bgColor;
		this.artBackgroundCode = artBackgroundCode;
		this.artLayers = artLayers == null ? [] : artLayers;
		if (authoredBounds == null) {
			this.minX = minTileX * tileSize;
			this.minY = minTileY * tileSize;
			this.maxX = this.maxTileX * tileSize;
			this.maxY = this.maxTileY * tileSize;
		} else {
			this.minX = authoredBounds.minX;
			this.minY = authoredBounds.minY;
			this.maxX = authoredBounds.maxX;
			this.maxY = authoredBounds.maxY;
		}
	}

	public static function fromDecoded(bgColor:Int, blocks:Array<LevelBlock>, ?artLayers:Array<LevelArtLayer>,
			?artBackgroundCode:Null<Int>):Level {
		if (blocks.length == 0) {
			return new Level("decoded-level", "Decoded Level", 1, 1, DEFAULT_TILE_SIZE, 1, defaultStats(), new TilePosition(0, -1),
				new TilePosition(0, -1), blocks, 0, 0, bgColor, artLayers, artBackgroundCode);
		}
		var bounds = blockBounds(blocks);
		var minTileX = tileFloor(bounds.minX) - PADDING_TILES;
		var minTileY = tileFloor(bounds.minY) - PADDING_TILES;
		var maxTileX = tileFloor(bounds.maxX) + PADDING_TILES + 1;
		var maxTileY = tileFloor(bounds.maxY) + PADDING_TILES + 1;
		var start = firstOrFallback(startBlocksIn(blocks), blocks[0]);
		var finishes = blocks.filter(function(block) return block.code == ObjectCodes.BLOCK_FINISH);
		var finish = firstOrFallback(finishes, start);
		return new Level(
			"decoded-level",
			"Decoded Level",
			maxTileX - minTileX + 1,
			maxTileY - minTileY + 1,
			DEFAULT_TILE_SIZE,
			1,
			defaultStats(),
			new TilePosition(start.x, start.y - 1),
			new TilePosition(finish.x, finish.y - 1),
			blocks,
			minTileX,
			minTileY,
			bgColor,
			artLayers,
			artBackgroundCode,
			bounds
		);
	}

	public function configureRuntime(id:String, name:String, gravity:Float):Void {
		this.id = id;
		this.name = name;
		this.gravity = gravity;
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
			if (!block.isMarker() && block.x == x && block.y == y) {
				return block;
			}
		}
		return null;
	}

	/** Document lookup that includes non-colliding start and minion-egg markers. */
	public function blockAtAny(x:Int, y:Int):Null<LevelBlock> {
		var index = blocks.length;
		while (index > 0) {
			index--;
			var block = blocks[index];
			if (block.x == x && block.y == y) return block;
		}
		return null;
	}

	public function startBlocks():Array<LevelBlock> return startBlocksIn(blocks);

	public function finishBlocks():Array<LevelBlock> {
		return blocks.filter(function(block) return block.code == ObjectCodes.BLOCK_FINISH);
	}

	public function minionEggBlocks():Array<LevelBlock> {
		return blocks.filter(function(block) return block.code == ObjectCodes.BLOCK_MINION_EGG);
	}

	private static function startBlocksIn(blocks:Array<LevelBlock>):Array<LevelBlock> {
		return blocks.filter(function(block) {
			return block.code >= ObjectCodes.BLOCK_START1 && block.code <= ObjectCodes.BLOCK_START4;
		});
	}

	private static function firstOrFallback(blocks:Array<LevelBlock>, fallback:LevelBlock):LevelBlock {
		return blocks.length == 0 ? fallback : blocks[0];
	}

	private static function blockBounds(blocks:Array<LevelBlock>):{minX:Int, minY:Int, maxX:Int, maxY:Int} {
		var first = blocks[0];
		var minX = first.worldX;
		var minY = first.worldY;
		var maxX = first.worldX;
		var maxY = first.worldY;
		for (block in blocks) {
			if (block.worldX < minX) minX = block.worldX;
			if (block.worldY < minY) minY = block.worldY;
			if (block.worldX > maxX) maxX = block.worldX;
			if (block.worldY > maxY) maxY = block.worldY;
		}
		return {minX: minX, minY: minY, maxX: maxX, maxY: maxY};
	}

	private static inline function tileFloor(value:Int):Int return Std.int(Math.floor(value / DEFAULT_TILE_SIZE));

	private static function defaultStats():StatDefaults {
		return new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40);
	}
}

class LevelBlock {
	public var x(get, set):Int;
	public var y(get, set):Int;
	public var worldX(default, null):Int;
	public var worldY(default, null):Int;
	public final type:BlockType;
	public final options:String;
	public final code:Int;

	public function new(x:Int, y:Int, type:BlockType, options:String = "", ?code:Int) {
		this.worldX = x * Level.DEFAULT_TILE_SIZE;
		this.worldY = y * Level.DEFAULT_TILE_SIZE;
		this.type = type;
		this.options = options;
		this.code = code == null ? codeForType(type) : code;
	}

	public static function fromWorldPixels(code:Int, worldX:Int, worldY:Int, options:String = ""):LevelBlock {
		var block = new LevelBlock(0, 0, typeForCode(code), options, code);
		block.worldX = worldX;
		block.worldY = worldY;
		return block;
	}

	public inline function isMarker():Bool {
		return (code >= ObjectCodes.BLOCK_START1 && code <= ObjectCodes.BLOCK_START4) || code == ObjectCodes.BLOCK_MINION_EGG;
	}

	private inline function get_x():Int return Std.int(Math.floor(worldX / Level.DEFAULT_TILE_SIZE));
	private inline function get_y():Int return Std.int(Math.floor(worldY / Level.DEFAULT_TILE_SIZE));
	private inline function set_x(value:Int):Int {
		worldX = value * Level.DEFAULT_TILE_SIZE;
		return value;
	}
	private inline function set_y(value:Int):Int {
		worldY = value * Level.DEFAULT_TILE_SIZE;
		return value;
	}

	public static function typeForCode(code:Int):BlockType {
		return switch (code) {
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4: BlockType.Start;
			case ObjectCodes.BLOCK_FINISH: BlockType.Finish;
			case ObjectCodes.BLOCK_ICE: BlockType.Ice;
			case ObjectCodes.BLOCK_ARROW_DOWN: BlockType.ArrowDown;
			case ObjectCodes.BLOCK_ARROW_UP: BlockType.ArrowUp;
			case ObjectCodes.BLOCK_ARROW_LEFT: BlockType.ArrowLeft;
			case ObjectCodes.BLOCK_ARROW_RIGHT: BlockType.ArrowRight;
			case ObjectCodes.BLOCK_MINE: BlockType.Mine;
			case ObjectCodes.BLOCK_ITEM: BlockType.Item;
			case ObjectCodes.BLOCK_ITEM_INF: BlockType.InfiniteItem;
			case ObjectCodes.BLOCK_CRUMBLE: BlockType.Crumble;
			case ObjectCodes.BLOCK_VANISH: BlockType.Vanish;
			case ObjectCodes.BLOCK_MOVE: BlockType.Move;
			case ObjectCodes.BLOCK_WATER: BlockType.Water;
			case ObjectCodes.BLOCK_ROTATE_RIGHT: BlockType.RotateRight;
			case ObjectCodes.BLOCK_ROTATE_LEFT: BlockType.RotateLeft;
			case ObjectCodes.BLOCK_PUSH: BlockType.Push;
			case ObjectCodes.BLOCK_SAFETY: BlockType.Safety;
			case ObjectCodes.BLOCK_TELEPORT: BlockType.Teleport;
			case ObjectCodes.BLOCK_CUSTOM_STATS: BlockType.CustomStats;
			case ObjectCodes.BLOCK_BRICK: BlockType.Brick;
			case ObjectCodes.BLOCK_HAPPY: BlockType.Happy;
			case ObjectCodes.BLOCK_SAD: BlockType.Sad;
			case ObjectCodes.BLOCK_HEART: BlockType.Heart;
			case ObjectCodes.BLOCK_TIME: BlockType.Time;
			case ObjectCodes.BLOCK_BASIC1 | ObjectCodes.BLOCK_BASIC2 | ObjectCodes.BLOCK_BASIC3 | ObjectCodes.BLOCK_BASIC4: BlockType.Basic;
			default: BlockType.Solid;
		}
	}

	private static function codeForType(type:BlockType):Int {
		return switch (type) {
			case Start: ObjectCodes.BLOCK_START1;
			case Finish: ObjectCodes.BLOCK_FINISH;
			case Ice: ObjectCodes.BLOCK_ICE;
			case ArrowDown: ObjectCodes.BLOCK_ARROW_DOWN;
			case ArrowUp: ObjectCodes.BLOCK_ARROW_UP;
			case ArrowLeft: ObjectCodes.BLOCK_ARROW_LEFT;
			case ArrowRight: ObjectCodes.BLOCK_ARROW_RIGHT;
			case Mine: ObjectCodes.BLOCK_MINE;
			case Item: ObjectCodes.BLOCK_ITEM;
			case InfiniteItem: ObjectCodes.BLOCK_ITEM_INF;
			case Crumble: ObjectCodes.BLOCK_CRUMBLE;
			case Vanish: ObjectCodes.BLOCK_VANISH;
			case Move: ObjectCodes.BLOCK_MOVE;
			case Water: ObjectCodes.BLOCK_WATER;
			case RotateRight: ObjectCodes.BLOCK_ROTATE_RIGHT;
			case RotateLeft: ObjectCodes.BLOCK_ROTATE_LEFT;
			case Push: ObjectCodes.BLOCK_PUSH;
			case Safety: ObjectCodes.BLOCK_SAFETY;
			case Teleport: ObjectCodes.BLOCK_TELEPORT;
			case CustomStats: ObjectCodes.BLOCK_CUSTOM_STATS;
			case Brick: ObjectCodes.BLOCK_BRICK;
			case Happy: ObjectCodes.BLOCK_HAPPY;
			case Sad: ObjectCodes.BLOCK_SAD;
			case Heart: ObjectCodes.BLOCK_HEART;
			case Time: ObjectCodes.BLOCK_TIME;
			case Basic | Solid | SnakeTrail: ObjectCodes.BLOCK_BASIC1;
		}
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

class LevelArtLayer {
	public final drawActions:Array<LevelDrawAction>;
	public final objects:Array<LevelArtObject>;
	public final texts:Array<LevelTextObject>;
	public final scale:Float;

	public function new(?drawActions:Array<LevelDrawAction>, ?objects:Array<LevelArtObject>, ?texts:Array<LevelTextObject>, scale:Float = 1) {
		this.drawActions = drawActions == null ? [] : drawActions;
		this.objects = objects == null ? [] : objects;
		this.texts = texts == null ? [] : texts;
		this.scale = scale;
	}
}

class LevelDrawAction {
	public final kind:String;
	public final values:Array<Float>;
	public final text:String;

	public function new(kind:String, ?values:Array<Float>, text:String = "") {
		this.kind = kind;
		this.values = values == null ? [] : values;
		this.text = text;
	}
}

class LevelArtObject {
	public final code:Int;
	public final x:Float;
	public final y:Float;
	public final scaleX:Float;
	public final scaleY:Float;

	public function new(code:Int, x:Float, y:Float, scaleX:Float = 1, scaleY:Float = 1) {
		this.code = code;
		this.x = x;
		this.y = y;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
	}
}

class LevelTextObject {
	public final text:String;
	public final x:Float;
	public final y:Float;
	public final color:Int;
	public final scaleX:Float;
	public final scaleY:Float;

	public function new(text:String, x:Float, y:Float, color:Int, scaleX:Float = 1, scaleY:Float = 1) {
		this.text = text;
		this.x = x;
		this.y = y;
		this.color = color;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
	}
}
