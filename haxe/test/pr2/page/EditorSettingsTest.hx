package pr2.page;

import haxe.crypto.Md5;
import pr2.gameplay.Items;
import pr2.gameplay.LevelConfig;
import pr2.net.ServerConfig;

class EditorSettingsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testDefaultSetters();
		testVariablesAndLevelVars();
		testPasswordHashing();
		trace('EditorSettingsTest passed $assertions assertions');
	}

	private static function testDefaultSetters():Void {
		var editor = new LevelEditor();
		editor.setSong(null);
		editor.setGravity("");
		editor.setMaxTime(null);
		editor.setMinRank("");
		editor.setCowboyChance("");
		editor.setGameMode("eggs");
		editor.setItems("Laser`Sword");
		editor.setBadHats("2,16,1,99");
		editor.setColor(0x123456);

		assertEquals("", editor.song, "null song saves as empty string");
		assertEquals("1", editor.gravity, "blank gravity defaults to 1");
		assertEquals("120", editor.maxTime, "blank time defaults to 120");
		assertEquals("0", editor.minRank, "blank rank defaults to 0");
		assertEquals("5", editor.cowboyChance, "blank cowboy chance defaults to 5");
		assertEquals("egg", editor.gameMode, "legacy eggs mode normalizes");
		assertArrayEquals([Items.LASER_GUN, Items.SWORD], editor.allowedItems, "allowed item names resolve");
		assertEquals("2,16", editor.badHats.join(","), "bad hats filter no-hat and out-of-range ids");
		assertEquals(0x123456, editor.color, "background color is tracked");
	}

	private static function testVariablesAndLevelVars():Void {
		var vars = new Map<String, String>();
		vars.set("live", "1");
		vars.set("min_level", "12");
		vars.set("has_pass", "1");
		vars.set("title", "Editor Vars");
		vars.set("note", "notes");
		vars.set("song", "7");
		vars.set("gravity", "3");
		vars.set("max_time", "500");
		vars.set("items", "Mine`Teleport");
		vars.set("badHats", "3,1");
		vars.set("gameMode", "deathmatch");
		vars.set("cowboyChance", "150");
		vars.set("credits", "alice`bob");

		var editor = new LevelEditor();
		editor.setVariables(vars);
		var levelVars = editor.getLevelVars();

		assertEquals(1.0, editor.live, "live flag loads");
		assertEquals("12", editor.minRank, "min rank loads");
		assertEquals(1, editor.hasPass, "password placeholder marks passworded level");
		assertEquals("", levelVars.get("passHash"), "asterisk placeholder does not submit a hash");
		assertEquals("Editor Vars", levelVars.get("title"), "title exports");
		assertEquals("notes", levelVars.get("note"), "note exports");
		assertEquals("7", levelVars.get("song"), "song exports");
		assertEquals("3.0", levelVars.get("gravity"), "gravity uses LevelConfig formatting");
		assertEquals("500", levelVars.get("max_time"), "max time exports");
		assertEquals("2`4", levelVars.get("items"), "items export as backtick codes");
		assertEquals("3", levelVars.get("badHats"), "bad hats export as comma list");
		assertEquals("deathmatch", levelVars.get("gameMode"), "game mode exports");
		assertEquals("100", levelVars.get("cowboyChance"), "cowboy chance clamps through LevelConfig");
		assertEquals("alice`bob", levelVars.get("credits"), "credits export with backticks");
		var saveParts = levelVars.get("data").split("`");
		assertEquals(14, saveParts.length, "empty m4 save string has every layer field");
		assertEquals("m4", saveParts[0], "empty save uses m4 format");
		assertEquals(StringTools.hex(LevelConfig.DEFAULT_COLOR).toLowerCase(), saveParts[1], "empty save exports background color");
		for (i in 2...saveParts.length) {
			assertEquals("", saveParts[i], 'empty save layer $i is blank');
		}
	}

	private static function testPasswordHashing():Void {
		var editor = new LevelEditor();
		editor.setPass("secret");
		var levelVars = editor.getLevelVars();
		assertEquals(1, editor.hasPass, "plain password marks level passworded");
		assertEquals(Md5.encode("secret" + ServerConfig.LEVEL_PASS_SALT), levelVars.get("passHash"), "plain password hashes with level salt");

		editor.setPass("");
		levelVars = editor.getLevelVars();
		assertEquals(0, editor.hasPass, "empty password clears password flag");
		assertEquals("", levelVars.get("passHash"), "empty password submits no hash");
	}

	private static function assertArrayEquals(expected:Array<Int>, actual:Array<Int>, message:String):Void {
		assertions++;
		if (expected.length != actual.length) {
			throw '$message: expected $expected, got $actual';
		}
		for (i in 0...expected.length) {
			if (expected[i] != actual[i]) {
				throw '$message: expected $expected, got $actual';
			}
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
