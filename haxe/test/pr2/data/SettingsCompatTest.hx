package pr2.data;

import com.jiggmin.data.Settings;

class SettingsCompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testStoreNameAndRawLoad();
		if (pr2.DeterministicTestMode.finishSmokeSuite("SettingsCompatTest")) return;
		testDefaultsPopulateSessionData();
		testPartialControlsAndStatsPersist();
		testNoUserOrBlockedCookiesDoNotThrow();
		Settings.disablePersistenceForTests();
		trace('SettingsCompatTest passed $assertions assertions');
	}

	private static function testStoreNameAndRawLoad():Void {
		Settings.useMemoryStoreForTests();
		var disabled:Array<Dynamic> = [2, "17"];
		Settings.seedRawStoreForTests("Alice! Bob", {
			musicLevel: 44,
			filterSwears: false,
			disabledSongs: disabled,
			leTestHat: 9,
		});
		Settings.init("Alice! Bob");

		assertEquals("pr2_AliceBob", Settings.storeNameForTests("Alice! Bob"), "store name strips non-word chars");
		assertEquals(44, Settings.musicLevel, "cookie value mirrors to static music level");
		assertEquals(false, Settings.filterSwears, "cookie value mirrors to static filter");
		assertEquals(false, Settings.getValue(Settings.FILTER_SWEARS, true), "cookie value mirrors to dataArr");
		assertEquals("2", Settings.disabledSongs()[0], "numeric disabled song ids remain readable");
		assertEquals(9, Settings.getValue(Settings.LE_TEST_HAT, 2), "cookie hat mirrors to dataArr");
	}

	private static function testDefaultsPopulateSessionData():Void {
		Settings.useMemoryStoreForTests();
		Settings.init("New User");

		assertEquals(0, Settings.disabledSongs().length, "disabled songs default");
		assertEquals(true, Settings.getValue(Settings.DRAW_ART, false), "draw art default");
		assertEquals(false, Settings.getValue(Settings.ART_LOSSLESS_QUALITY, true), "lossless quality default");
		assertEquals(true, Settings.getValue(Settings.FILTER_SWEARS, false), "filter default");
		assertEquals(2, Settings.getValue(Settings.LE_TEST_HAT, 99), "test hat default");
		var controls:Dynamic = Settings.getValue(Settings.ALTERNATE_CONTROLS, null);
		assertEquals(87, Reflect.field(controls, "up"), "controls default up");
		var stats:Dynamic = Settings.getValue(Settings.LE_TEST_STATS, null);
		assertEquals(50, Reflect.field(stats, "speed"), "test stats default speed");
	}

	private static function testPartialControlsAndStatsPersist():Void {
		Settings.useMemoryStoreForTests();
		Settings.init("Tester");

		Settings.setValue(Settings.ALTERNATE_CONTROLS, {up: 38, item: 32});
		var controls:Dynamic = Settings.getValue(Settings.ALTERNATE_CONTROLS, null);
		assertEquals(38, Reflect.field(controls, "up"), "partial controls update up");
		assertEquals(68, Reflect.field(controls, "right"), "partial controls keep default right");
		assertEquals(32, Reflect.field(controls, "item"), "partial controls update item");
		var rawControls:Dynamic = Reflect.field(Settings.rawStoreForTests("Tester"), Settings.ALTERNATE_CONTROLS);
		assertEquals(38, Reflect.field(rawControls, "up"), "raw controls update up");
		assertEquals(65, Reflect.field(rawControls, "left"), "raw controls keep default left");

		Settings.setValue(Settings.LE_TEST_STATS, {speed: 61});
		var stats:Dynamic = Settings.getValue(Settings.LE_TEST_STATS, null);
		assertEquals(61, Reflect.field(stats, "speed"), "partial stats update speed");
		assertEquals(50, Reflect.field(stats, "acceleration"), "partial stats keep acceleration");
		var rawStats:Dynamic = Reflect.field(Settings.rawStoreForTests("Tester"), Settings.LE_TEST_STATS);
		assertEquals(61, Reflect.field(rawStats, "speed"), "raw stats update speed");
		assertEquals(50, Reflect.field(rawStats, "jumping"), "raw stats keep jumping");
	}

	private static function testNoUserOrBlockedCookiesDoNotThrow():Void {
		Settings.disablePersistenceForTests();
		Settings.setValue(Settings.MUSIC_VOLUME, 35);
		assertEquals(35, Settings.musicLevel, "blocked cookies still update session static value");
		assertEquals(false, Settings.isNameSet(), "blocked-cookie test has no user");
		Settings.setValue(Settings.ALTERNATE_CONTROLS, {up: 40});
		var controls:Dynamic = Settings.getValue(Settings.ALTERNATE_CONTROLS, null);
		assertEquals(87, Reflect.field(controls, "up"), "control patch no-ops without cookie/user");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
