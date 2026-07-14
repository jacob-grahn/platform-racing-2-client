package pr2.gameplay;

class ModesTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testConstants();
		if (pr2.DeterministicTestMode.finishSmokeSuite("ModesTest")) return;
		testFullNames();
		trace('ModesTest passed $assertions assertions');
	}

	private static function testConstants():Void {
		assertEquals("egg", Modes.egg, "egg constant");
		assertEquals("deathmatch", Modes.dm, "deathmatch constant");
		assertEquals("race", Modes.race, "race constant");
		assertEquals("objective", Modes.obj, "objective constant");
		assertEquals("hat", Modes.hat, "hat constant");
		assertEquals("roguelike", Modes.roguelike, "roguelike constant");
	}

	private static function testFullNames():Void {
		assertEquals("Alien Eggs", Modes.getFullName("e"), "short egg label");
		assertEquals("Alien Eggs", Modes.getFullName("eggs"), "legacy eggs label");
		assertEquals("Alien Eggs", Modes.getFullName("egg"), "egg label");
		assertEquals("Deathmatch", Modes.getFullName("d"), "short deathmatch label");
		assertEquals("Deathmatch", Modes.getFullName("dm"), "dm label");
		assertEquals("Deathmatch", Modes.getFullName("deathmatch"), "deathmatch label");
		assertEquals("Objective", Modes.getFullName("o"), "short objective label");
		assertEquals("Objective", Modes.getFullName("obj"), "obj label");
		assertEquals("Objective", Modes.getFullName("objective"), "objective label");
		assertEquals("Hat Attack", Modes.getFullName("h"), "short hat label");
		assertEquals("Hat Attack", Modes.getFullName("hat"), "hat label");
		assertEquals("Roguelike", Modes.getFullName("rl"), "short roguelike label");
		assertEquals("Roguelike", Modes.getFullName("l"), "listing roguelike label");
		assertEquals("Roguelike", Modes.getFullName("roguelike"), "roguelike label");
		assertEquals("Race", Modes.getFullName("race"), "race label");
		assertEquals("Race", Modes.getFullName(""), "empty defaults to race");
		assertEquals("Race", Modes.getFullName("bogus"), "unknown defaults to race");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
