package pr2.harness;

import pr2.character.CharacterRenderMode;

class GameplayHarnessOptionsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testDefaults();
		testParsesRepresentativeOutfitQuery();
		testFallsBackForInvalidValues();
		trace('GameplayHarnessOptionsTest passed $assertions assertions');
	}

	private static function testDefaults():Void {
		var options = GameplayHarnessOptions.parseQuery(null);

		assertEquals(2, options.partIds.hat, "default hat");
		assertEquals(1, options.partIds.head, "default head");
		assertEquals(1, options.partIds.body, "default body");
		assertEquals(1, options.partIds.feet, "default feet");
		assertEquals(0x2F86FF, options.primaryColor, "default primary color");
		assertEquals(0xFFCC33, options.secondaryColor, "default secondary color");
		assertEquals(CharacterRenderMode.Layered, options.renderMode, "default render mode");
	}

	private static function testParsesRepresentativeOutfitQuery():Void {
		var options = GameplayHarnessOptions.parseQuery("?hat=16&head=37&body=29&feet=40&primary=%23aa00ff&secondary=00cc11&render=composite");

		assertEquals(16, options.partIds.hat, "query hat");
		assertEquals(37, options.partIds.head, "query head");
		assertEquals(29, options.partIds.body, "query body");
		assertEquals(40, options.partIds.feet, "query feet");
		assertEquals(0xAA00FF, options.primaryColor, "query primary color");
		assertEquals(0x00CC11, options.secondaryColor, "query secondary color");
		assertEquals(CharacterRenderMode.Composite, options.renderMode, "query render mode");
		assertEquals("hat=16;head=37;body=29;feet=40;primary=aa00ff;secondary=00cc11;render=composite", options.serialize(), "serialized options");
	}

	private static function testFallsBackForInvalidValues():Void {
		var options = GameplayHarnessOptions.parseQuery("hat=24&head=-3&body=nope&feet=101&primary=zzzzzz&secondary=12345&render=unknown");

		assertEquals(2, options.partIds.hat, "unsupported hat falls back");
		assertEquals(1, options.partIds.head, "invalid head falls back");
		assertEquals(1, options.partIds.body, "invalid body falls back");
		assertEquals(1, options.partIds.feet, "unsupported feet falls back");
		assertEquals(0x2F86FF, options.primaryColor, "invalid primary color falls back");
		assertEquals(0xFFCC33, options.secondaryColor, "invalid secondary color falls back");
		assertEquals(CharacterRenderMode.Layered, options.renderMode, "unknown render mode falls back");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
