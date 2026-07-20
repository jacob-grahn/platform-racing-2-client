package pr2.level;

import haxe.Json;
import pr2.level.Level.LevelBlock;
import pr2.level.Level.StatDefaults;
import pr2.level.Level.TilePosition;

class LevelParser {
	public static function parse(json:String):Level {
		var data:Dynamic = Json.parse(json);
		var level = new Level(
			requiredString(data, "id"),
			requiredString(data, "name"),
			requiredInt(data, "widthTiles"),
			requiredInt(data, "heightTiles"),
			requiredInt(data, "tileSize"),
			requiredFloat(data, "gravity"),
			parseStats(requiredObject(data, "stats")),
			parseTilePosition(requiredObject(data, "playerStart"), "playerStart"),
			parseTilePosition(requiredObject(data, "finish"), "finish"),
			parseBlocks(requiredArray(data, "blocks")),
			optionalInt(data, "minTileX"),
			optionalInt(data, "minTileY")
		);
		validate(level);
		return level;
	}

	private static function parseStats(data:Dynamic):StatDefaults {
		return new StatDefaults(
			requiredFloat(data, "speed"),
			requiredFloat(data, "acceleration"),
			requiredFloat(data, "jump")
		);
	}

	private static function parseTilePosition(data:Dynamic, field:String):TilePosition {
		return new TilePosition(requiredInt(data, "x", field), requiredInt(data, "y", field));
	}

	private static function parseBlocks(data:Array<Dynamic>):Array<LevelBlock> {
		var blocks:Array<LevelBlock> = [];
		for (index in 0...data.length) {
			var block = data[index];
			blocks.push(new LevelBlock(
				requiredInt(block, "x", 'blocks[$index]'),
				requiredInt(block, "y", 'blocks[$index]'),
				BlockType.parse(requiredString(block, "type", 'blocks[$index]')),
				optionalString(block, "options", 'blocks[$index]')
			));
		}
		return blocks;
	}

	private static function validate(level:Level):Void {
		if (level.widthTiles <= 0 || level.heightTiles <= 0) {
			throw "world dimensions must be positive";
		}
		if (level.tileSize <= 0) {
			throw "world tileSize must be positive";
		}
		if (level.gravity <= 0) {
			throw "world gravity must be positive";
		}
		if (level.stats.speed <= 0 || level.stats.acceleration <= 0 || level.stats.jump <= 0) {
			throw "world stat defaults must be positive";
		}
		requireInBounds(level.playerStart, level, "playerStart");
		requireInBounds(level.finish, level, "finish");

		var occupied:Map<String, Bool> = new Map();
		for (block in level.blocks) {
			if (!level.containsTile(block.x, block.y)) {
				throw 'block ${block.x},${block.y} is outside world bounds';
			}

			var key = block.x + "," + block.y;
			if (occupied.exists(key)) {
				throw 'duplicate block at $key';
			}
			occupied.set(key, true);
		}
	}

	private static function requireInBounds(position:TilePosition, level:Level, field:String):Void {
		if (!level.containsTile(position.x, position.y)) {
			throw '$field ${position.x},${position.y} is outside world bounds';
		}
	}

	private static function requiredObject(data:Dynamic, name:String, ?path:String):Dynamic {
		var value:Dynamic = readField(data, name, path);
		if (value == null || Reflect.isObject(value) == false) {
			throw missingMessage(name, path) + " must be an object";
		}
		return value;
	}

	private static function requiredArray(data:Dynamic, name:String, ?path:String):Array<Dynamic> {
		var value:Dynamic = readField(data, name, path);
		if (value == null || Std.isOfType(value, Array) == false) {
			throw missingMessage(name, path) + " must be an array";
		}
		return cast value;
	}

	private static function requiredString(data:Dynamic, name:String, ?path:String):String {
		var value:Dynamic = readField(data, name, path);
		if (Std.isOfType(value, String) == false) {
			throw missingMessage(name, path) + " must be a string";
		}
		return cast value;
	}

	private static function optionalString(data:Dynamic, name:String, ?path:String):String {
		if (data == null || Reflect.hasField(data, name) == false) {
			return "";
		}
		var value:Dynamic = Reflect.field(data, name);
		if (Std.isOfType(value, String) == false) {
			throw missingMessage(name, path) + " must be a string";
		}
		return cast value;
	}

	private static function requiredInt(data:Dynamic, name:String, ?path:String):Int {
		var value = requiredFloat(data, name, path);
		if (Math.isNaN(value) || value != Math.floor(value)) {
			throw missingMessage(name, path) + " must be an integer";
		}
		return Std.int(value);
	}

	private static function optionalInt(data:Dynamic, name:String):Int {
		if (data == null || !Reflect.hasField(data, name)) {
			return 0;
		}
		return requiredInt(data, name);
	}

	private static function requiredFloat(data:Dynamic, name:String, ?path:String):Float {
		var value:Dynamic = readField(data, name, path);
		if (Std.isOfType(value, Int) == false && Std.isOfType(value, Float) == false) {
			throw missingMessage(name, path) + " must be a number";
		}
		return cast value;
	}

	private static function readField(data:Dynamic, name:String, ?path:String):Dynamic {
		if (data == null || Reflect.hasField(data, name) == false) {
			throw missingMessage(name, path) + " is required";
		}
		return Reflect.field(data, name);
	}

	private static function missingMessage(name:String, ?path:String):String {
		return path == null ? name : path + "." + name;
	}
}
