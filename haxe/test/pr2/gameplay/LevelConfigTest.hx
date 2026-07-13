package pr2.gameplay;

/**
	AS3-spec transcript test for `LevelConfig`, the config-setter half of Flash
	`page.GamePage`. The geometry decode (read modes m1..m4) is covered by
	`ServerLevelDecoderTest`; this checks the metadata setters: item-code
	resolution, banned hats, gameMode `eggs`->`egg`, cowboy-chance clamping,
	gravity string formatting, max-time clamping, and credits splitting, plus the
	`setVariables` ingest order against a representative level var map.
**/
class LevelConfigTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testDefaults();
		testItems();
		testItemRuntimeSurface();
		testBadHats();
		testGameMode();
		testCowboyChance();
		testCredits();
		testSetVariables();
		testFromServerData();
		trace('LevelConfigTest passed $assertions assertions');
	}

	private static function testDefaults():Void {
		var c = new LevelConfig();
		assertEquals(10, c.allowedItems.length, "default items is all 10");
		assertEquals(0, c.badHats.length, "default has no banned hats");
		assertEquals("1", c.gravity, "default gravity");
		assertEquals("120", c.maxTime, "default max time");
		assertEquals("race", c.gameMode, "default game mode");
		assertEquals("5", c.cowboyChance, "default cowboy chance");
		assertEquals(LevelConfig.DEFAULT_COLOR, c.color, "default color");
	}

	private static function testItems():Void {
		var c = new LevelConfig();
		c.setItems("");
		assertEquals(0, c.allowedItems.length, "empty string clears items");
		c.setItems("all");
		assertEquals(10, c.allowedItems.length, "'all' selects every code");
		c.setItems(null);
		assertEquals(10, c.allowedItems.length, "null selects every code");

		c.setItems("Laser`Sword");
		assertEquals("1,8", c.allowedItems.join(","), "names resolve to codes");

		c.setItems("3`5");
		assertEquals("3,5", c.allowedItems.join(","), "numeric tokens kept as codes");
		c.setItems("10");
		assertEquals("10", c.allowedItems.join(","), "two-digit Snake code survives editor serialization");

		c.setItems("Bogus`0`99");
		assertEquals(0, c.allowedItems.length, "unknown name, 0, and out-of-range are dropped");
	}

	private static function testItemRuntimeSurface():Void {
		var specs = [
			{code: Items.LASER_GUN, className: "pr2.gameplay.items.LaserGun", name: "Laser", uses: 3, reloadMs: 800, reload: 22},
			{code: Items.MINE, className: "pr2.gameplay.items.Mine", name: "Mine", uses: 1, reloadMs: 10, reload: 0},
			{code: Items.LIGHTNING, className: "pr2.gameplay.items.Lightning", name: "Lightning", uses: 1, reloadMs: 10, reload: 0},
			{code: Items.TELEPORT, className: "pr2.gameplay.items.Teleport", name: "Teleport", uses: 1, reloadMs: 10, reload: 0},
			{code: Items.SUPER_JUMP, className: "pr2.gameplay.items.SuperJump", name: "Super Jump", uses: 1, reloadMs: 10, reload: 0},
			{code: Items.JET_PACK, className: "pr2.gameplay.items.JetPack", name: "Jet Pack", uses: 3, reloadMs: 10, reload: 0},
			{code: Items.SPEED_BURST, className: "pr2.gameplay.items.SpeedBurst", name: "Speed Burst", uses: 1, reloadMs: 10, reload: 0},
			{code: Items.SWORD, className: "pr2.gameplay.items.Sword", name: "Sword", uses: 3, reloadMs: 800, reload: 22},
			{code: Items.ICE_WAVE, className: "pr2.gameplay.items.IceWave", name: "Ice Wave", uses: 3, reloadMs: 1000, reload: 27},
			{code: Items.SNAKE, className: "pr2.gameplay.items.Snake", name: "Snake", uses: 1, reloadMs: 10, reload: 0}
		];
		for (spec in specs) {
			var item = Items.getFromCode(spec.code);
			assertEquals(spec.className, Type.getClassName(Type.getClass(item)), spec.name + " concrete item class");
			assertEquals(spec.code, Items.getCodeFromItem(item), spec.name + " code round-trips from item instance");
			assertEquals(spec.name, item.name, spec.name + " runtime name matches Flash name");
			assertEquals(spec.uses, item.initialUses, spec.name + " initial uses match Flash item");
			assertEquals(spec.reloadMs, item.reloadTimeMs, spec.name + " reload milliseconds match Flash item");
			assertEquals(spec.reload, item.reloadFrames, spec.name + " reload frames preserve Flash timing at 27fps");
		}
		assertEquals(null, Items.getFromCode(0), "unknown item code creates no item");
		assertEquals(0, Items.getCodeFromItem(null), "null item maps to code 0");
	}

	private static function testBadHats():Void {
		var c = new LevelConfig();
		c.setBadHats("");
		assertEquals(0, c.badHats.length, "empty bans no hats");
		c.setBadHats(null);
		assertEquals(0, c.badHats.length, "null bans no hats");

		c.setBadHats("2,16,1,99");
		// 1 is no-hat (excluded by > 1); 99 exceeds the greatest hat id (16).
		assertEquals("2,16", c.badHats.join(","), "keeps in-range hat ids only");
	}

	private static function testGameMode():Void {
		var c = new LevelConfig();
		c.setGameMode("eggs");
		assertEquals("egg", c.gameMode, "legacy 'eggs' normalizes to 'egg'");
		c.setGameMode("deathmatch");
		assertEquals("deathmatch", c.gameMode, "other modes pass through");
	}

	private static function testCowboyChance():Void {
		var c = new LevelConfig();
		c.setCowboyChance(null);
		assertEquals("5", c.cowboyChance, "null defaults to 5");
		c.setCowboyChance("");
		assertEquals("5", c.cowboyChance, "empty defaults to 5");
		c.setCowboyChance("150");
		assertEquals("100", c.cowboyChance, "over 100 clamps to 100");
		c.setCowboyChance("-3");
		assertEquals("0", c.cowboyChance, "under 0 clamps to 0");
		c.setCowboyChance("42");
		assertEquals("42", c.cowboyChance, "in-range value preserved");
	}

	private static function testCredits():Void {
		var c = new LevelConfig();
		c.setCredits("alice`bob`carol");
		assertEquals("alice,bob,carol", c.credits.join(","), "credits split on backtick");
		c.setCredits(null);
		assertEquals(1, c.credits.length, "null credits yields a single empty entry");
	}

	private static function testSetVariables():Void {
		var vars:Map<String, String> = new Map();
		vars.set("time", "1400000000");
		vars.set("title", "Test Level");
		vars.set("note", "gg");
		vars.set("song", "song7");
		vars.set("gameMode", "eggs");
		vars.set("cowboyChance", "250");
		vars.set("gravity", "200");
		vars.set("max_time", "20000");
		vars.set("items", "Laser`Mine");
		vars.set("badHats", "3,1");
		vars.set("level_id", "12345");
		vars.set("credits", "x`y");

		var c = new LevelConfig();
		c.setVariables(vars);

		assertEquals(1400000000.0, c.updatedTime, "time read into updatedTime");
		assertEquals("Test Level", c.title, "title set");
		assertEquals("gg", c.note, "note set");
		assertEquals("song7", c.song, "song set");
		assertEquals("egg", c.gameMode, "gameMode normalized");
		assertEquals("100", c.cowboyChance, "cowboy chance clamped");
		assertEquals("99.0", c.gravity, "gravity clamped to 99 and formatted with .0");
		assertEquals("9999", c.maxTime, "max time clamped to 9999");
		assertEquals("1,2", c.allowedItems.join(","), "items resolved");
		assertEquals("3", c.badHats.join(","), "bad hats filtered (1 dropped)");
		assertEquals(12345.0, c.levelId, "level id parsed");
		assertEquals("x,y", c.credits.join(","), "credits parsed");

		// Integral gravity gets a `.0`; fractional keeps its own decimals.
		vars.set("gravity", "2.5");
		c.setVariables(vars);
		assertEquals("2.5", c.gravity, "fractional gravity keeps decimals");
		vars.set("gravity", "");
		c.setVariables(vars);
		assertEquals("0.0", c.gravity, "missing gravity becomes 0.0");
	}

	private static function testFromServerData():Void {
		// Bridges A2: a parsed `ServerLevelData` from LevelDataClient feeds the
		// faithful config setters, the same handoff Flash did via setVariables.
		var levelData = "level_id=99&version=2&title=Bridge&gravity=3&max_time=5000"
			+ "&items=Sword`Mine&gameMode=eggs&cowboyChance=200&data=m3`0`";
		var parsed = pr2.net.LevelDataClient.parse(signed(levelData, 2, 99), 99, 2);
		var c = LevelConfig.fromServerData(parsed);
		assertEquals("Bridge", c.title, "fromServerData applies title");
		assertEquals("3.0", c.gravity, "fromServerData formats gravity");
		assertEquals("egg", c.gameMode, "fromServerData normalizes game mode");
		assertEquals("100", c.cowboyChance, "fromServerData clamps cowboy chance");
		assertEquals("8,2", c.allowedItems.join(","), "fromServerData resolves item names to codes");
	}

	private static function signed(levelData:String, version:Int, levelId:Int):String {
		return levelData
			+ haxe.crypto.Md5.encode(Std.string(version) + Std.string(levelId) + levelData + pr2.net.ServerConfig.LEVEL_SALT_2);
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
