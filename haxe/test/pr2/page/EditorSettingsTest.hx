package pr2.page;

import haxe.crypto.Md5;
import openfl.display.Sprite;
import pr2.gameplay.Items;
import pr2.gameplay.LevelConfig;
import pr2.level.ServerLevel.DecodedTextObject;
import pr2.level.ServerLevelDecoder;
import pr2.net.ServerConfig;
import pr2.net.ServerLevelData;
import pr2.page.LevelEditor.EditorBackgroundColorPickerButton;
import pr2.page.LevelEditor.EditorHatsSettingsPopup;
import pr2.page.LevelEditor.EditorItemSettingsPopup;
import pr2.page.LevelEditor.EditorModeSettingsPopup;
import pr2.page.LevelEditor.EditorMusicSettingsPopup;
import pr2.page.LevelEditor.EditorObjectLayer;
import pr2.page.LevelEditor.EditorValueSettingsPopup;

class EditorSettingsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testDefaultSetters();
		testVariablesAndLevelVars();
		testApplyLoadedLevelData();
		testPasswordHashing();
		testBackgroundColorPickerCommit();
		testTextObjectSaveStringUsesDecodedArtFormat();
		testValueSettingsPopupCommit();
		testMusicSettingsPopupCommit();
		testModeSettingsPopupCommit();
		testItemSettingsPopupCommit();
		testHatsSettingsPopupCommit();
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

	private static function testApplyLoadedLevelData():Void {
		var vars = new Map<String, String>();
		vars.set("live", "1");
		vars.set("min_level", "9");
		vars.set("has_pass", "1");
		vars.set("title", "Loaded Editor Level");
		vars.set("note", "loaded note");
		vars.set("song", "4");
		vars.set("gravity", "2");
		vars.set("max_time", "300");
		vars.set("items", "Sword");
		vars.set("badHats", "5");
		vars.set("gameMode", "objective");
		vars.set("cowboyChance", "25");
		vars.set("data", "m4`abcdef`0;0;11,1;0;16,1;0;10;4");

		var editor = new LevelEditor();
		editor.initialize();
		editor.applyLoadedLevelData(new ServerLevelData(vars, true), true);

		assertEquals("Loaded Editor Level", editor.title, "loaded level title applies to editor");
		assertEquals("loaded note", editor.note, "loaded level note applies to editor");
		assertEquals("9", editor.minRank, "loaded level minimum rank applies to editor");
		assertEquals(1, editor.hasPass, "loaded password marker applies to editor");
		assertEquals("objective", editor.gameMode, "loaded game mode applies to editor");
		assertEquals(true, editor.reportsMode, "loaded report mode applies to editor menu");
		assertEquals(3, editor.blockLayer.blocks.length, "loaded block data replaces default editor blocks");
		assertEquals("0;0;11,1;0;16,1;0;10;4", editor.blockLayer.getSaveString(), "loaded blocks export with original options");
		editor.remove();
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

	private static function testBackgroundColorPickerCommit():Void {
		var editor = new LevelEditor();
		editor.initialize();
		editor.menu.changeSideBar(editor.menu.bg);
		var picker = Std.downcast(editor.menu.bg.getChildByName("colorEntry"), EditorBackgroundColorPickerButton);
		assertNotNull(picker, "background sidebar mounts a color picker entry");
		assertEquals(LevelConfig.DEFAULT_COLOR, picker.pickerColor(), "background picker opens with editor color");

		picker.setPickedColor(0x224466);
		assertEquals(0x224466, editor.color, "background picker commits editor color");
		assertEquals("224466", editor.getLevelVars().get("data").split("`")[1], "background picker color exports in m4 data");

		editor.setColor(0xABCDEF);
		assertEquals(0xABCDEF, picker.pickerColor(), "background picker updates after editor color changes");
		editor.remove();
	}

	private static function testTextObjectSaveStringUsesDecodedArtFormat():Void {
		var layer = new EditorObjectLayer(1, 1);
		var textObject = layer.addText("Hello #`,&+-;", 105, 116, 0x123456);
		textObject.moveToLocal(120, 130);
		textObject.resizeTo(1.23, 0.75);

		var decoded = ServerLevelDecoder.decodeArtObjects("m4", layer.getSaveString());
		assertEquals(1, decoded.length, "text object save emits one art object");
		var text = Std.downcast(decoded[0], DecodedTextObject);
		assertNotNull(text, "text object save decodes as text");
		assertEquals("Hello #35#96#44#38#43#45#59", text.text, "text object save escapes Flash separators");
		assertEquals(120, text.x, "text object save exports moved x");
		assertEquals(130, text.y, "text object save exports moved y");
		assertEquals(0x123456, text.color, "text object save exports color");
		assertEquals(1.23, text.scaleX, "text object save exports width scale");
		assertEquals(0.75, text.scaleY, "text object save exports height scale");
		layer.remove();
	}

	private static function testValueSettingsPopupCommit():Void {
		var editor = new LevelEditor();

		var rankPopup = new EditorValueSettingsPopup(editor, new Sprite(), "rank");
		assertEquals("0", rankPopup.value(), "rank popup opens with editor minimum rank");
		rankPopup.setValue("42");
		assertEquals("42", editor.minRank, "rank popup commits minimum rank");
		assertEquals("42", editor.getLevelVars().get("min_level"), "rank popup export uses minimum rank");
		rankPopup.remove();

		var gravityPopup = new EditorValueSettingsPopup(editor, new Sprite(), "gravity");
		gravityPopup.setValue("2.5");
		assertEquals("2.5", editor.gravity, "gravity popup commits gravity");
		assertEquals("2.5", editor.getLevelVars().get("gravity"), "gravity popup export uses gravity");
		gravityPopup.setValue("");
		assertEquals("0", editor.getLevelVars().get("gravity"), "empty gravity popup value uses Flash default zero");
		gravityPopup.remove();

		var timePopup = new EditorValueSettingsPopup(editor, new Sprite(), "time");
		timePopup.setValue("0");
		assertEquals("0", editor.maxTime, "time popup commits infinite-time zero");
		assertEquals("0", editor.getLevelVars().get("max_time"), "time popup export uses committed time");
		timePopup.remove();

		var cowboyPopup = new EditorValueSettingsPopup(editor, new Sprite(), "sfcm");
		cowboyPopup.setValue("75");
		assertEquals("75", editor.cowboyChance, "cowboy chance popup commits chance");
		assertEquals("75", editor.getLevelVars().get("cowboyChance"), "cowboy chance popup exports chance");
		cowboyPopup.remove();

		var passPopup = new EditorValueSettingsPopup(editor, new Sprite(), "pass");
		passPopup.setValue("secret");
		assertEquals(1, editor.hasPass, "password popup marks level passworded");
		assertEquals(Md5.encode("secret" + ServerConfig.LEVEL_PASS_SALT), editor.getLevelVars().get("passHash"),
			"password popup exports salted password hash");
		passPopup.setValue("");
		assertEquals(0, editor.hasPass, "empty password popup clears password flag");
		assertEquals("", editor.getLevelVars().get("passHash"), "empty password popup exports no hash");
		passPopup.remove();
	}

	private static function testMusicSettingsPopupCommit():Void {
		var editor = new LevelEditor();
		editor.setSong("");
		var popup = new EditorMusicSettingsPopup(editor, new Sprite());

		assertEquals("random", popup.selectedSongId(), "blank editor song opens as random");

		popup.setSelectedSongId("7");
		assertEquals("7", editor.song, "music menu commits selected track");
		assertEquals("7", editor.getLevelVars().get("song"), "committed music selection exports as level vars");

		popup.setSelectedSongId("0");
		assertEquals("0", editor.song, "music menu commits no-song selection");
		popup.remove();
	}

	private static function testModeSettingsPopupCommit():Void {
		var editor = new LevelEditor();
		editor.setGameMode("objective");
		var popup = new EditorModeSettingsPopup(editor, new Sprite());

		assertEquals("objective", popup.selectedMode(), "mode menu loads editor game mode");

		popup.setSelectedMode("hat");
		assertEquals("hat", editor.gameMode, "mode menu commits selected game mode");
		assertEquals("hat", editor.getLevelVars().get("gameMode"), "committed mode menu selection exports as level vars");

		popup.setSelectedMode("eggs");
		assertEquals("egg", editor.gameMode, "mode menu normalizes legacy eggs mode");
		popup.remove();
	}

	private static function testItemSettingsPopupCommit():Void {
		var editor = new LevelEditor();
		editor.setItems("Laser`Teleport");
		var popup = new EditorItemSettingsPopup(editor, new Sprite());

		assertEquals(true, popup.isItemSelected(Items.LASER_GUN), "item menu loads allowed item");
		assertEquals(false, popup.isItemSelected(Items.MINE), "item menu leaves disallowed item unchecked");
		assertEquals(true, popup.isItemSelected(Items.TELEPORT), "item menu loads second allowed item");

		popup.setItemSelected(Items.LASER_GUN, false);
		popup.setItemSelected(Items.MINE, true);
		popup.remove();

		assertArrayEquals([Items.MINE, Items.TELEPORT], editor.allowedItems, "item menu commits selected items in Flash order");
		assertEquals("2`4", editor.getLevelVars().get("items"), "committed item menu selection exports as level vars");
	}

	private static function testHatsSettingsPopupCommit():Void {
		var editor = new LevelEditor();
		editor.setBadHats("5,12");
		var popup = new EditorHatsSettingsPopup(editor, new Sprite());

		assertEquals(false, popup.isHatAllowed(5), "hats menu loads existing cowboy ban");
		assertEquals(false, popup.isHatAllowed(12), "hats menu loads existing thief ban");
		assertEquals(true, popup.isHatAllowed(6), "hats menu leaves other hats allowed");

		popup.setHatAllowed(5, true);
		popup.setHatAllowed(6, false);
		popup.remove();

		assertArrayEquals([6, 12], editor.badHats, "hats menu commits unchecked hats in Flash order");
		assertEquals("6,12", editor.getLevelVars().get("badHats"), "committed hats menu selection exports as level vars");

		editor.setGameMode("hat");
		editor.setBadHats("");
		popup = new EditorHatsSettingsPopup(editor, new Sprite());
		assertEquals(false, popup.isHatAllowed(14), "hat attack forces artifact unchecked");
		popup.remove();
		assertArrayEquals([14], editor.badHats, "hat attack artifact state commits as banned");
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

	private static function assertNotNull(actual:Dynamic, message:String):Void {
		assertions++;
		if (actual == null) {
			throw '$message: expected non-null';
		}
	}
}
