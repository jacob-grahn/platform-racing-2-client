package pr2.page;

import haxe.crypto.Md5;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.geom.Point;
import openfl.ui.Keyboard;
import pr2.lobby.account.ColorPicker;
import pr2.lobby.account.Settings;
import pr2.lobby.account.StatSlider;
import pr2.lobby.Memory;
import pr2.gameplay.Items;
import pr2.gameplay.LevelConfig;
import pr2.level.BlockType;
import pr2.level.ServerLevel.DecodedTextObject;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevelDecoder;
import pr2.net.ServerConfig;
import pr2.net.ServerLevelData;
import pr2.levelEditor.LevelEditor;
import pr2.levelEditor.LevelEditor.EditorBackgroundColorPickerButton;
import pr2.levelEditor.LevelEditor.EditorBlockObject;
import pr2.levelEditor.LevelEditor.EditorHatsSettingsPopup;
import pr2.levelEditor.LevelEditor.EditorItemSettingsPopup;
import pr2.levelEditor.LevelEditor.EditorModeSettingsPopup;
import pr2.levelEditor.LevelEditor.EditorMusicSettingsPopup;
import pr2.levelEditor.LevelEditor.EditorDrawableLayer;
import pr2.levelEditor.LevelEditor.EditorObjectLayer;
import pr2.levelEditor.LevelEditor.EditorSideBarEntry;
import pr2.levelEditor.LevelEditor.EditorTextObject;
import pr2.levelEditor.LevelEditor.EditorValueSettingsPopup;
import pr2.levelEditor.LevelEditor.TestCoursePage;
import pr2.levelEditor.EditorToolCursorManager.EditorBrushCursor;
import pr2.runtime.FlSliderEvent;
import pr2.ui.CustomCursor;
import pr2.ui.StageFocus;

class EditorSettingsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testDefaultSetters();
		testVariablesAndLevelVars();
		testApplyLoadedLevelData();
		testPasswordHashing();
		testBackgroundColorPickerCommit();
		testBackgroundButtonCommit();
		testBlockGridLinesFollowZoomAndCamera();
		testTextObjectSaveStringUsesDecodedArtFormat();
		testValueSettingsPopupCommit();
		testMusicSettingsPopupCommit();
		testModeSettingsPopupCommit();
		testItemSettingsPopupCommit();
		testHatsSettingsPopupCommit();
		testBrushTargetGating();
		testBrushStrokeSegmentation();
		testStampPlacementCancellationAndCursorScale();
		testBlockDragPlacement();
		testBlockObjectInteractions();
		testObjectDeleterLifecycle();
		testTextToolDropLifecycle();
		testTextObjectEditSemantics();
		testStampDrawObjectActions();
		testEditorToolCursorLifecycle();
		testCustomCursorRuntimeHooks();
		testStatSliderHoldAccelerationAndSavePaths();
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
		vars.set("data", [
			"m4",
			"abcdef",
			"0;0;11,1;0;16,1;0;10;4",
			"",
			"",
			"",
			"c123456,t8,mdraw,d10;12;5;6",
			"",
			"",
			"BG7",
			"",
			"",
			"c654321,merase,d20;22;3;4",
			""
		].join("`"));

		var editor = new LevelEditor();
		editor.initialize();
		editor.applyLoadedLevelData(new ServerLevelData(vars, true), true);

		assertEquals("Loaded Editor Level", editor.title, "loaded level title applies to editor");
		assertEquals("loaded note", editor.note, "loaded level note applies to editor");
		assertEquals("9", editor.minRank, "loaded level minimum rank applies to editor");
		assertEquals(1, editor.hasPass, "loaded password marker applies to editor");
		assertEquals("objective", editor.gameMode, "loaded game mode applies to editor");
		assertEquals(0xABCDEF, editor.color, "loaded m4 data applies background color");
		assertEquals(207, editor.artBackgroundCode, "loaded m4 data applies art background code");
		assertEquals(true, editor.reportsMode, "loaded report mode applies to editor menu");
		assertEquals(3, editor.blockLayer.blocks.length, "loaded block data replaces default editor blocks");
		assertEquals("0;0;11,1;0;16,1;0;10;4", editor.blockLayer.getSaveString(), "loaded blocks export with original options");
		assertEquals("c123456,t8,mdraw,d10;12;5;6", editor.drawLayers[0].getSaveString(), "loaded draw layer 1 preserves draw actions");
		assertEquals(4, editor.drawLayers[0].drawActions.length, "loaded draw layer 1 decodes editable draw actions");
		assertEquals("c654321,merase,d20;22;3;4", editor.drawLayers[3].getSaveString(), "loaded draw layer 4 preserves draw actions");
		assertEquals(0, editor.drawLayers[0].redoArray.length, "loaded draw layer clears redo state");
		editor.remove();
	}

	private static function testBackgroundButtonCommit():Void {
		var editor = new LevelEditor();
		editor.initialize();
		editor.menu.changeSideBar(editor.menu.bg);
		var bg1 = Std.downcast(editor.menu.bg.getChildByName("bg1Entry"), EditorSideBarEntry);
		var bg5 = Std.downcast(editor.menu.bg.getChildByName("bg5Entry"), EditorSideBarEntry);

		bg1.dispatchEvent(new MouseEvent(MouseEvent.CLICK, true));
		assertEquals(8172673, editor.color, "BG1 button commits Flash background color");
		assertEquals(201, editor.artBackgroundCode, "BG1 button commits art background code");
		assertEquals("201", editor.getLevelVars().get("data").split("`")[9], "BG1 button exports art background code");
		assertEquals("", editor.selectedToolId, "background button does not select a placement tool");

		bg5.dispatchEvent(new MouseEvent(MouseEvent.CLICK, true));
		assertEquals(0, editor.color, "BG5 button commits Flash black background color");
		assertEquals(205, editor.artBackgroundCode, "BG5 button commits art background code");
		assertEquals("205", editor.getLevelVars().get("data").split("`")[9], "BG5 button exports art background code");

		editor.setColor(0x224466);
		assertEquals(null, editor.artBackgroundCode, "plain color commit clears selected art background");
		assertEquals("", editor.getLevelVars().get("data").split("`")[9], "plain color commit clears art background export");
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
		assertEquals(ColorPicker.LEFT, @:privateAccess picker.picker.direction, "background picker opens to the left like Flash");

		picker.setPickedColor(0x224466);
		assertEquals(0x224466, editor.color, "background picker commits editor color");
		assertEquals("224466", editor.getLevelVars().get("data").split("`")[1], "background picker color exports in m4 data");

		editor.setColor(0xABCDEF);
		assertEquals(0xABCDEF, picker.pickerColor(), "background picker updates after editor color changes");
		var focusResets = 0;
		StageFocus.resetHook = function():Void {
			focusResets++;
		};
		@:privateAccess picker.picker.dispatchEvent(new Event(Event.CLOSE));
		assertEquals(1, focusResets, "background picker close returns focus to stage");
		StageFocus.resetHooks();
		editor.remove();
	}

	private static function testBlockGridLinesFollowZoomAndCamera():Void {
		var grid = new BlockGridLines();
		assertEquals(false, grid.mouseEnabled, "block grid ignores direct mouse input");
		assertEquals(false, grid.mouseChildren, "block grid ignores child mouse input");
		assertClose(580, grid.drawnWidth, "default block grid covers the editor viewport plus one segment horizontally");
		assertClose(430, grid.drawnHeight, "default block grid covers the editor viewport plus one segment vertically");

		grid.setZoom(0.5);
		assertClose(1130, grid.drawnWidth, "zoomed-out block grid redraws wider in local coordinates");
		assertClose(830, grid.drawnHeight, "zoomed-out block grid redraws taller in local coordinates");
		grid.setPos(77, -44);
		assertClose(expectedGridPos(77), grid.x, "block grid x follows camera modulo segment size");
		assertClose(expectedGridPos(-44), grid.y, "block grid y follows camera modulo segment size");
		assertTrue(grid.x <= 0 && grid.x + grid.drawnWidth >= BlockGridLines.VIEW_WIDTH / 0.5,
			"block grid covers the full zoomed viewport horizontally");
		assertTrue(grid.y <= 0 && grid.y + grid.drawnHeight >= BlockGridLines.VIEW_HEIGHT / 0.5,
			"block grid covers the full zoomed viewport vertically");
		grid.remove();
		assertEquals(null, grid.parent, "block grid remove detaches the overlay");

		var editor = new LevelEditor();
		editor.initialize();
		assertNotNull(editor.blockGrid, "level editor mounts block grid overlay");
		assertTrue(editor.blockGrid.parent == editor.blockLayer.parent, "block grid shares the editor layer container");
		assertTrue(editor.blockGrid.parent.getChildIndex(editor.blockGrid) < editor.blockGrid.parent.getChildIndex(editor.blockLayer),
			"block grid sits behind editor blocks");
		editor.setZoom(0.5);
		editor.setPos(-900, -720);
		assertClose(1130, editor.blockGrid.drawnWidth, "editor zoom redraws block grid");
		assertClose(expectedGridPos(editor.posX), editor.blockGrid.x, "editor pan repositions block grid x");
		assertClose(expectedGridPos(editor.posY), editor.blockGrid.y, "editor pan repositions block grid y");
		assertTrue(editor.blockGrid.x <= 0 && editor.blockGrid.x + editor.blockGrid.drawnWidth >= BlockGridLines.VIEW_WIDTH / editor.zoom,
			"editor block grid covers the full visible background horizontally");
		assertTrue(editor.blockGrid.y <= 0 && editor.blockGrid.y + editor.blockGrid.drawnHeight >= BlockGridLines.VIEW_HEIGHT / editor.zoom,
			"editor block grid covers the full visible background vertically");
		editor.remove();
		assertEquals(null, editor.blockGrid, "editor teardown clears block grid reference");
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

		var focusResets = 0;
		StageFocus.resetHook = function():Void focusResets++;
		@:privateAccess popup.autoDismiss.armForTests();
		popup.dropdown.dispatchEvent(new Event(Event.OPEN));
		@:privateAccess popup.autoDismiss.stageMouseDownForTests(-1000, -1000);
		assertEquals(false, @:privateAccess popup.removed, "mode menu stays open while combo dropdown is open");
		@:privateAccess popup.selectMode("hat");
		popup.dropdown.dispatchEvent(new Event(Event.CLOSE));
		assertEquals("hat", editor.gameMode, "mode menu close commits selected mode");
		assertEquals(0, focusResets, "mode menu combo close does not reset focus before popup removal");
		popup.remove();
		assertEquals(1, focusResets, "mode menu removal returns focus to stage");
		StageFocus.resetHooks();
	}

	private static function testItemSettingsPopupCommit():Void {
		var editor = new LevelEditor();
		editor.initialize();
		editor.setItems("Laser`Teleport");
		var itemBlock = editor.blockLayer.addBlockAtStage(ObjectCodes.BLOCK_ITEM, BlockType.Item, 120, 120);
		itemBlock.setOptions(Items.MINE + "-" + Items.TELEPORT);
		var popup = new EditorItemSettingsPopup(editor, new Sprite());

		assertEquals(true, popup.isItemSelected(Items.LASER_GUN), "item menu loads allowed item");
		assertEquals(false, popup.isItemSelected(Items.MINE), "item menu leaves disallowed item unchecked");
		assertEquals(true, popup.isItemSelected(Items.TELEPORT), "item menu loads second allowed item");

		popup.setItemSelected(Items.LASER_GUN, false);
		popup.setItemSelected(Items.MINE, true);
		popup.remove();

		assertArrayEquals([Items.MINE, Items.TELEPORT], editor.allowedItems, "item menu commits selected items in Flash order");
		assertEquals("2`4", editor.getLevelVars().get("items"), "committed item menu selection exports as level vars");
		assertEquals("", itemBlock.options, "item menu refresh clears item-block options matching new allowed items");

		var testCourse = new TestCoursePage(editor.getLevelVars());
		testCourse.initialize();
		assertArrayEquals([Items.MINE, Items.TELEPORT], testCourse.course.allowedItemsForTests(),
			"test course receives item menu allowed-items semantics");
		testCourse.remove();
		editor.remove();
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

	private static function testEditorToolCursorLifecycle():Void {
		Memory.clear();
		var editor = new LevelEditor();
		editor.initialize();

		editor.selectEditorTool("tools", "brush");
		assertNotNull(editor.toolCursor.current, "brush selection creates a cursor");
		assertEquals("brush", editor.toolCursor.current.toolId, "brush cursor records tool id");
		var brushCursor = Std.downcast(editor.toolCursor.current, EditorBrushCursor);
		assertNotNull(brushCursor, "brush selection uses a brush cursor");
		var circle = editor.toolCursor.current.getChildAt(0);
		editor.setBrushSize(12);
		editor.setZoom(0.5);
		assertClose(6, circle.width, "brush cursor width scales by zoom");
		assertClose(6, circle.height, "brush cursor height scales by zoom");

		editor.selectEditorTool("stamps", "text");
		assertNotNull(editor.toolCursor.current, "text selection creates a cursor");
		assertEquals("text", editor.toolCursor.current.toolId, "text cursor records tool id");
		assertEquals(true, editor.toolCursor.current.ignoresTemporaryDelete, "text cursor does not temporary-swap to delete");
		editor.toolCursor.beginTemporaryDelete();
		assertEquals(false, Memory.has("leCursorTempInstanceType"), "text cursor does not store temporary delete memory");

		editor.selectEditorTool("tools", "brush");
		editor.toolCursor.beginTemporaryDelete();
		assertEquals(false, Memory.has("leCursorTempInstanceType"), "brush cursor does not store temporary delete memory");
		editor.selectEditorTool("blocks", "brick");
		assertEquals("brick", editor.selectedToolId, "block selection starts from brick");
		editor.toolCursor.beginTemporaryDelete();
		assertEquals("blocks", editor.selectedToolSidebar, "temporary delete preserves block sidebar");
		assertEquals("delete", editor.selectedToolId, "temporary delete updates editor tool id");
		assertEquals("delete", editor.toolCursor.current.toolId, "temporary delete swaps cursor");
		assertEquals(ObjectCodes.BLOCK_BRICK, Memory.getInt("leCursorTempInstanceID"), "temporary delete stores cursor id in Memory");
		assertEquals("blocks", Memory.getString("leCursorTempSidebar"), "temporary delete stores sidebar in Memory");
		assertEquals("brick", Memory.getString("leCursorTempToolId"), "temporary delete stores tool id in Memory");
		editor.toolCursor.endTemporaryDelete();
		assertEquals("blocks", editor.selectedToolSidebar, "temporary delete restores sidebar");
		assertEquals("brick", editor.selectedToolId, "temporary delete restores tool id");
		assertEquals(false, Memory.has("leCursorTempInstanceType"), "temporary delete clears Memory on restore");

		editor.remove();
		assertEquals(null, CustomCursor.instance, "editor teardown clears custom cursor singleton");
		Memory.clear();
	}

	private static function testCustomCursorRuntimeHooks():Void {
		var forwarded = false;
		var cursor = new CustomCursor();
		cursor.addEventListener(MouseEvent.MOUSE_DOWN, function(_:MouseEvent):Void forwarded = true);
		@:privateAccess cursor.touchHandler(new TouchEvent(TouchEvent.TOUCH_BEGIN));
		assertEquals(true, forwarded, "custom cursor forwards touch begin as mouse down");
		assertEquals(MouseEvent.MOUSE_MOVE, CustomCursor.touchTypeToMouseType(TouchEvent.TOUCH_MOVE), "custom cursor maps touch move");
		assertEquals(-1, cursor.getID(), "base custom cursor exposes default identity");
		cursor.remove();

		var editor = new LevelEditor();
		editor.initialize();
		editor.selectEditorTool("stamps", "stamp0");
		assertEquals(ObjectCodes.STAMP_TREE, editor.toolCursor.current.getID(), "stamp cursor exposes object id");
		editor.selectEditorTool("blocks", "brick");
		assertEquals(ObjectCodes.BLOCK_BRICK, editor.toolCursor.current.getID(), "block cursor exposes block id");
		editor.remove();
	}

	private static function testStatSliderHoldAccelerationAndSavePaths():Void {
		var standalone = new StatSlider("Speed", null);
		standalone.setValue(10);
		standalone.beginHoldForTests("inc");
		assertEquals(8, standalone.holdSpeedForTests(), "stat hold starts at 8 updates/sec");
		assertEquals(11, standalone.value, "stat hold applies first step immediately");
		standalone.setHoldElapsedForTests(2501);
		standalone.updateHoldSpeedForTests("inc");
		assertEquals(16, standalone.holdSpeedForTests(), "stat hold accelerates after two seconds");
		standalone.updateStatFromHeldForTests("inc");
		assertEquals(12, standalone.value, "stat hold continues incrementing after acceleration");
		standalone.setHoldElapsedForTests(4501);
		standalone.updateHoldSpeedForTests("inc");
		assertEquals(32, standalone.holdSpeedForTests(), "stat hold accelerates after four seconds");
		standalone.setValue(100);
		standalone.updateStatFromHeldForTests("inc");
		assertEquals(0, standalone.holdSpeedForTests(), "stat hold stops at upper bound");
		standalone.remove();

		Settings.useMemoryStoreForTests();
		Settings.init("Tester");
		Settings.setValue(Settings.LE_TEST_STATS, {speed: 10, acceleration: 20, jumping: 30});
		var editor = new LevelEditor();
		editor.initialize();
		var testCourse = new TestCoursePage(editor.getLevelVars());
		testCourse.initialize();
		var stats = testCourse.statsSelect;
		var speedSlider = @:privateAccess stats.speedSlider;
		var persistedBeforeChange = Reflect.field(Settings.getValue(Settings.LE_TEST_STATS), "speed");
		stats.setStats(91, 82, 73);
		stats.noteUserStatChange();
		assertEquals(true, @:privateAccess stats.updateSavedLEStats, "stat change marks pending LE stats");
		assertEquals(true, @:privateAccess stats.localChar.inLE(), "test stats character reports level editor mode");
		assertEquals(91, stats.getStats().speed, "stat picker holds changed speed before save path");
		assertEquals(persistedBeforeChange, Reflect.field(Settings.getValue(Settings.LE_TEST_STATS), "speed"), "stat change does not persist before save path");
		@:privateAccess speedSlider.onSliderThumbRelease(new FlSliderEvent(FlSliderEvent.THUMB_RELEASE, speedSlider.value));
		assertEquals(91, Reflect.field(Settings.getValue(Settings.LE_TEST_STATS), "speed"), "thumb release persists pending LE stats");
		stats.setStats(92, 82, 73);
		stats.noteUserStatChange();
		@:privateAccess stats.localChar.levelEditorStatsEnabled = false;
		stats.saveLEStats();
		assertEquals(91, Reflect.field(Settings.getValue(Settings.LE_TEST_STATS), "speed"), "saveLEStats respects inLE guard");
		testCourse.remove();
		editor.remove();
		Settings.disablePersistenceForTests();
	}

	private static function testBrushTargetGating():Void {
		var editor = new LevelEditor();
		editor.initialize();
		editor.selectEditorTool("tools", "brush");

		var drawPoint = pointOutsideMenu(editor);
		assertEquals(true, editor.canStartBrushFromTargetForTests(editor.activeDrawLayer, drawPoint.x, drawPoint.y),
			"brush starts from the active drawable layer");
		assertEquals(true, editor.canStartBrushFromTargetForTests(editor.activeObjectLayer, drawPoint.x, drawPoint.y),
			"brush starts from transparent active object-layer targets");
		assertEquals(true, editor.canStartBrushFromTargetForTests(editor.blockGrid, drawPoint.x, drawPoint.y),
			"brush starts from grid line targets");
		assertEquals(true, editor.canStartBrushFromTargetForTests(editor, drawPoint.x, drawPoint.y),
			"brush starts from editor background targets");
		assertEquals(false, editor.canStartBrushFromTargetForTests(editor.menu, drawPoint.x, drawPoint.y),
			"brush rejects menu targets");

		assertEquals(true, editor.beginSelectedBrushAt(drawPoint.x, drawPoint.y), "brush starts when the draw layer is idle");
		assertEquals(false, editor.beginSelectedBrushAt(drawPoint.x + 2, drawPoint.y + 2), "brush cannot restart while the draw layer is busy");
		assertEquals(false, editor.canStartBrushFromTargetForTests(editor.activeDrawLayer, drawPoint.x + 2, drawPoint.y + 2),
			"target gate rejects busy draw layers");
		assertEquals(true, editor.endSelectedBrush(), "brush stroke finishes after busy-layer check");
		assertEquals(true, editor.beginSelectedBrushAt(drawPoint.x, drawPoint.y), "brush can start again after finishing");
		editor.activeDrawLayer.finishStroke();
		assertEquals(false, editor.continueSelectedBrushAt(drawPoint.x + 4, drawPoint.y + 4),
			"brush stroke stops if the drawable layer is no longer drawing");
		assertEquals(false, editor.isDrawing(), "editor clears drawing state when the drawable layer stops");

		editor.selectEditorTool("tools", "eraser");
		assertEquals(true, editor.canStartBrushFromTargetForTests(editor.activeDrawLayer, drawPoint.x, drawPoint.y),
			"eraser uses the same drawable target gate");
		editor.remove();
	}

	private static function testBrushStrokeSegmentation():Void {
		var editor = new LevelEditor();
		editor.initialize();
		editor.selectEditorTool("tools", "brush");
		var drawPoint = pointOutsideMenu(editor);
		var layer = editor.activeDrawLayer;

		assertEquals(true, editor.beginSelectedBrushAt(drawPoint.x, drawPoint.y), "brush segmentation stroke starts");
		assertEquals(true, editor.continueSelectedBrushAt(drawPoint.x + 401, drawPoint.y), "brush segmentation stroke extends");
		assertEquals(true, editor.isDrawing(), "brush remains active after distance segmentation restart");
		assertEquals(1, layer.drawRasterizeCountForTests(), "distance segmentation rasterizes the completed draw segment");
		assertEquals(2, drawActionCount(layer), "distance segmentation starts a new draw action at the current point");

		assertEquals(true, editor.restartSelectedBrushStrokeForTests(), "timer segmentation restarts active brush stroke");
		assertEquals(2, layer.drawRasterizeCountForTests(), "timer segmentation rasterizes the completed draw segment");
		assertEquals(3, drawActionCount(layer), "timer segmentation records a fresh draw action");
		assertEquals(true, editor.endSelectedBrush(), "segmented brush stroke finishes");
		assertEquals(3, layer.drawRasterizeCountForTests(), "final brush finish rasterizes the draw segment");
		editor.remove();

		editor = new LevelEditor();
		editor.initialize();
		editor.selectEditorTool("tools", "eraser");
		drawPoint = pointOutsideMenu(editor);
		layer = editor.activeDrawLayer;
		assertEquals(true, editor.beginSelectedBrushAt(drawPoint.x, drawPoint.y), "eraser segmentation stroke starts");
		assertEquals(true, editor.continueSelectedBrushAt(drawPoint.x + 20, drawPoint.y), "eraser segmentation stroke extends");
		assertEquals(true, editor.endSelectedBrush(), "eraser segmentation stroke finishes");
		assertEquals(0, layer.drawRasterizeCountForTests(), "eraser finish skips draw rasterize path");
		assertEquals(1, layer.eraseCleanupCountForTests(), "eraser finish calls erase cleanup path");
		editor.remove();
	}

	private static function testStampPlacementCancellationAndCursorScale():Void {
		var editor = new LevelEditor();
		editor.initialize();
		editor.selectEditorTool("stamps", "stamp0");
		var drawPoint = pointOutsideMenu(editor);

		assertEquals(true, editor.canPlaceStampFromTargetForTests(editor, drawPoint.x, drawPoint.y),
			"stamp placement accepts editor background targets");
		assertEquals(false, editor.canPlaceStampFromTargetForTests(editor.menu, drawPoint.x, drawPoint.y),
			"stamp placement rejects menu targets");
		assertEquals(true, editor.canPlaceStampFromTargetForTests(editor.activeObjectLayer, drawPoint.x, drawPoint.y),
			"stamp placement accepts transparent active object-layer targets");

		assertNotNull(editor.toolCursor.current, "stamp selection creates an object cursor");
		assertClose(1, editor.toolCursor.current.scaleX, "stamp cursor starts at active object layer scale");
		assertClose(1, editor.toolCursor.current.scaleY, "stamp cursor starts at active object layer y scale");
		editor.setActiveObjectLayer(5);
		editor.toolCursor.current.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(2, editor.toolCursor.current.scaleX, "stamp cursor follows active object layer x scale");
		assertClose(2, editor.toolCursor.current.scaleY, "stamp cursor follows active object layer y scale");

		editor.menu.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true));
		assertEquals("", editor.selectedToolId, "menu click cancels pending stamp placement");
		assertEquals(0, editor.activeObjectLayer.placedObjects.length, "menu click does not place a stamp");

		editor.selectEditorTool("stamps", "stamp0");
		editor.activeObjectLayer.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true));
		assertEquals("stamp0", editor.selectedToolId, "object-layer click keeps the selected stamp active");
		assertEquals(1, editor.activeObjectLayer.placedObjects.length, "object-layer click places a stamp");
		editor.remove();
	}

	private static function testBlockDragPlacement():Void {
		var editor = new LevelEditor();
		editor.initialize();
		editor.selectEditorTool("blocks", "brick");
		var point = pointOutsideMenu(editor);
		var nextPoint = new Point(point.x + LevelEditor.segSize, point.y);

		editor.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false, point.x, point.y));
		var firstBlock = editor.blockLayer.getBlockAtStage(point.x, point.y);
		assertNotNull(firstBlock, "block drag placement starts from mouse down");
		assertEquals(ObjectCodes.BLOCK_BRICK, firstBlock.code, "block drag placement uses the selected block code");

		editor.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_MOVE, true, false, nextPoint.x, nextPoint.y));
		var draggedBlock = editor.blockLayer.getBlockAtStage(nextPoint.x, nextPoint.y);
		assertNotNull(draggedBlock, "block drag placement continues on mouse move");
		assertEquals(ObjectCodes.BLOCK_BRICK, draggedBlock.code, "block drag placement creates blocks while dragging");

		var count = editor.blockLayer.blocks.length;
		editor.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_MOVE, true, false, nextPoint.x, nextPoint.y));
		assertEquals(count, editor.blockLayer.blocks.length, "block drag placement skips occupied segments");
		editor.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP, true, false, nextPoint.x, nextPoint.y));
		editor.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_MOVE, true, false, nextPoint.x + LevelEditor.segSize, nextPoint.y));
		assertEquals(count, editor.blockLayer.blocks.length, "block drag placement stops on mouse up");
		editor.remove();
	}

	private static function testBlockObjectInteractions():Void {
		var editor = new LevelEditor();
		editor.initialize();
		editor.selectEditorTool("blocks", "item");
		var point = pointOutsideMenu(editor);
		var itemBlock = editor.placeSelectedBlockAt(point.x, point.y);
		assertNotNull(itemBlock, "block interaction setup places an item block");
		assertEquals(true, itemBlock.deleteable, "placed blocks are deleteable");
		assertNotNull(itemBlock.getChildByName("DeleteButton"), "selected deleteable blocks show the authored delete button");
		assertNotNull(itemBlock.getChildByName("optionsButton"), "selected option blocks show the authored options button");

		editor.setZoom(0.5);
		assertClose(2, itemBlock.deleteButtonScaleXForTests(), "block delete control counter-scales editor zoom");
		assertClose(2, itemBlock.optionButtonScaleXForTests(), "block option control counter-scales editor zoom");
		editor.setZoom(1);

		var startSegX = itemBlock.segX;
		var startSegY = itemBlock.segY;
		var itemCenter = itemBlock.localToGlobal(new Point(LevelEditor.segSize / 2, LevelEditor.segSize / 2));
		itemBlock.beginDragAt(itemCenter.x, itemCenter.y);
		itemBlock.dragTo(itemCenter.x + LevelEditor.segSize * 2 - 2, itemCenter.y + LevelEditor.segSize + 7);
		itemBlock.endDragAt(itemCenter.x + LevelEditor.segSize * 2 - 2, itemCenter.y + LevelEditor.segSize + 7);
		assertEquals(startSegX + 2, itemBlock.segX, "block drag snaps x to the 30px grid");
		assertEquals(startSegY + 1, itemBlock.segY, "block drag snaps y to the 30px grid");
		assertEquals(itemBlock, editor.blockLayer.getBlockAtSeg(startSegX + 2, startSegY + 1), "snapped drag updates block lookup");
		assertEquals(null, editor.blockLayer.getBlockAtSeg(startSegX, startSegY), "snapped drag clears the previous lookup");

		var startBlock:EditorBlockObject = null;
		for (block in editor.blockLayer.blocks) {
			if (!block.deleteable) {
				startBlock = block;
				break;
			}
		}
		assertNotNull(startBlock, "editor seeds non-deleteable start blocks");
		editor.selectBlock(startBlock);
		assertEquals(null, startBlock.getChildByName("DeleteButton"), "start blocks do not show a delete control");
		var protectedSegX = startBlock.segX;
		var protectedSegY = startBlock.segY;
		var currentCenter = itemBlock.localToGlobal(new Point(LevelEditor.segSize / 2, LevelEditor.segSize / 2));
		var protectedCenter = startBlock.localToGlobal(new Point(LevelEditor.segSize / 2, LevelEditor.segSize / 2));
		itemBlock.beginDragAt(currentCenter.x, currentCenter.y);
		itemBlock.dragTo(protectedCenter.x, protectedCenter.y);
		itemBlock.endDragAt(protectedCenter.x, protectedCenter.y);
		assertEquals(startSegX + 2, itemBlock.segX, "dragging onto a start block keeps the moved block in its last segment");
		assertEquals(startSegY + 1, itemBlock.segY, "protected start overwrite keeps the moved block y segment");
		assertEquals(startBlock, editor.blockLayer.getBlockAtSeg(protectedSegX, protectedSegY), "dragging onto a start block preserves that block");
		editor.remove();
	}

	private static function testObjectDeleterLifecycle():Void {
		var editor = new LevelEditor();
		editor.initialize();
		var point = pointOutsideMenu(editor);
		var nextPoint = new Point(point.x + 300, point.y);

		editor.selectEditorTool("stamps", "stamp0");
		editor.placeSelectedToolAt(point.x, point.y);
		editor.placeSelectedToolAt(nextPoint.x, nextPoint.y);
		assertEquals(2, editor.activeObjectLayer.placedObjects.length, "deleter setup places two stamps");
		editor.selectEditorTool("stamps", "delete");
		editor.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false, point.x, point.y));
		editor.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_MOVE, true, false, nextPoint.x, nextPoint.y));
		assertEquals(0, editor.activeObjectLayer.placedObjects.length, "object deleter continues deleting stamps while dragging");
		editor.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP, true, false, nextPoint.x, nextPoint.y));

		editor.selectEditorTool("blocks", "brick");
		var blockPoint = pointOutsideMenu(editor);
		var nextBlockPoint = new Point(blockPoint.x + LevelEditor.segSize, blockPoint.y);
		editor.placeSelectedBlockAt(blockPoint.x, blockPoint.y);
		editor.placeSelectedBlockAt(nextBlockPoint.x, nextBlockPoint.y);
		assertNotNull(editor.blockLayer.getBlockAtStage(blockPoint.x, blockPoint.y), "deleter setup places first block");
		assertNotNull(editor.blockLayer.getBlockAtStage(nextBlockPoint.x, nextBlockPoint.y), "deleter setup places second block");
		editor.selectEditorTool("blocks", "delete");
		editor.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false, blockPoint.x, blockPoint.y));
		editor.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_MOVE, true, false, nextBlockPoint.x, nextBlockPoint.y));
		assertEquals(null, editor.blockLayer.getBlockAtStage(blockPoint.x, blockPoint.y), "block deleter removes the mouse-down block");
		assertEquals(null, editor.blockLayer.getBlockAtStage(nextBlockPoint.x, nextBlockPoint.y), "block deleter continues deleting while dragging");
		editor.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP, true, false, nextBlockPoint.x, nextBlockPoint.y));
		editor.remove();
	}

	private static function testTextToolDropLifecycle():Void {
		var editor = new LevelEditor();
		editor.initialize();
		editor.selectEditorTool("stamps", "text");
		assertEquals("text", editor.toolCursor.current.toolId, "text tool creates authored cursor");
		var point = pointOutsideMenu(editor);
		var label = editor.placeSelectedTextAt(point.x, point.y);
		assertNotNull(label, "text tool drops a text object");
		var expected = editor.activeObjectLayer.globalToLocal(new Point(point.x - 5, point.y - 16));
		assertEquals(Std.int(expected.x), Std.int(label.x), "text tool applies Flash x drop offset");
		assertEquals(Std.int(expected.y), Std.int(label.y), "text tool applies Flash y drop offset");
		assertEquals(true, label.isEditing(), "text tool immediately starts editing dropped text");
		assertEquals("", editor.selectedToolId, "text tool clears selected tool after drop");
		assertEquals(null, editor.toolCursor.current, "text tool removes cursor after drop");
		assertEquals(false, label.displayFieldVisibleForTests(), "text display field is hidden while editing");
		assertEquals(500, label.editFieldMaxCharsForTests(), "text edit field preserves Flash max character limit");
		assertEquals(true, label.editFieldWidthForTests() >= 100, "text edit field preserves Flash minimum edit width");
		assertEquals(false, label.hasAuthoredEditButtonForTests(), "text edit button is removed while editing");
		assertEquals(true, label.hasColorPickerForTests(), "text object mounts the color picker control while editing");
		label.setEditingText("label");
		label.finishEditing();
		assertEquals(false, label.isEditing(), "text edit controls stop editing on finish");
		assertEquals(true, label.displayFieldVisibleForTests(), "text display field returns after editing");
		assertEquals(true, label.hasAuthoredEditButtonForTests(), "text object restores the authored edit button after editing");
		assertEquals(true, label.hasColorPickerForTests(), "text object keeps the color picker control after editing");
		editor.setZoom(0.5);
		assertClose(2, label.editButtonScaleXForTests(), "text edit button counter-scales editor zoom");
		assertClose(0.8, label.colorPickerScaleXForTests(), "text color picker uses Flash 0.4 control scale and counters editor zoom");
		assertClose(2, label.resizeHandleScaleXForTests(), "text draw-object resize handle counter-scales editor zoom");
		editor.remove();
	}

	private static function testTextObjectEditSemantics():Void {
		var editor = new LevelEditor();
		editor.initialize();
		var point = pointOutsideMenu(editor);
		EditorTextObject.lastColor = 0;

		var label = editor.activeObjectLayer.addText("seed", point.x, point.y, 0x123456, true);
		label.setEditingText("changed");
		label.finishEditing();
		assertEquals(-1, editor.activeObjectLayer.getActionString().indexOf(",y"),
			"text changes are not recorded until the text object is deselected");
		editor.activeObjectLayer.selectTextObjectForTests(-1);
		assertEquals(true, StringTools.endsWith(editor.activeObjectLayer.getActionString(), ",y0;changed;1193046"),
			"text changes record Flash y action on deselect");

		assertEquals("#3596", EditorTextObject.escapeText("#96"), "escapeText replaces # before encoded-looking text");
		assertEquals("#96", EditorTextObject.parseText("#3596"), "parseText replaces #35 last");
		assertEquals("#96#`&,;+-", EditorTextObject.parseText("#3596#35#96#38#44#59#43#45"),
			"parseText replacement order matches Flash");

		EditorTextObject.lastColor = 0x010203;
		var colorText = editor.activeObjectLayer.addText("color", point.x + 100, point.y, 0x111111);
		colorText.setColor(0x222222);
		assertEquals(0x010203, EditorTextObject.lastColor, "direct text color changes do not replace lastColor");
		colorText.chooseColorForTests(0x333333);
		assertEquals(0x333333, EditorTextObject.lastColor, "color picker commits update lastColor");

		var editingText = editor.activeObjectLayer.addText("keep", point.x + 200, point.y, 0x444444, true);
		editingText.handleDeleteKeyForTests(Keyboard.BACKSPACE);
		assertEquals(true, editor.activeObjectLayer.textObjects.indexOf(editingText) >= 0,
			"Backspace does not delete text objects while editing nonempty text");
		editingText.setEditingText("");
		editingText.handleDeleteKeyForTests(Keyboard.DELETE);
		assertEquals(-1, editor.activeObjectLayer.textObjects.indexOf(editingText),
			"Delete removes text objects while editing an empty field");

		var plainText = editor.activeObjectLayer.addText("gone", point.x + 300, point.y, 0x555555);
		plainText.handleDeleteKeyForTests(Keyboard.DELETE);
		assertEquals(-1, editor.activeObjectLayer.textObjects.indexOf(plainText),
			"Delete removes selected text objects when not editing");

		var blankText = editor.activeObjectLayer.addText("text", point.x + 400, point.y, 0x666666, true);
		blankText.setEditingText("   ");
		blankText.finishEditing();
		assertEquals(-1, editor.activeObjectLayer.textObjects.indexOf(blankText), "blank edited text deletes the text object");
		EditorTextObject.lastColor = 0;
		editor.remove();
	}

	private static function testStampDrawObjectActions():Void {
		var editor = new LevelEditor();
		editor.initialize();
		var point = pointOutsideMenu(editor);
		var stamp = editor.activeObjectLayer.addStamp(0, point.x, point.y);
		var originalX = stamp.x;
		var originalY = stamp.y;
		assertEquals("o0;" + originalX + ";" + originalY, editor.activeObjectLayer.getActionString(), "stamp placement records Flash add-object action");
		editor.activeObjectLayer.selectPlacedStampForTests(0);
		editor.setZoom(0.5);
		assertClose(2, editor.activeObjectLayer.placedStampResizeHandleScaleXForTests(0),
			"stamp draw-object resize handle counter-scales editor zoom");
		editor.setZoom(1);

		editor.activeObjectLayer.dragPlacedStampForTests(0, point.x, point.y, point.x + 30, point.y + 45);
		assertEquals(originalX + 30, editor.activeObjectLayer.placedObjects[0].x, "stamp drag rounds and stores moved x");
		assertEquals(originalY + 45, editor.activeObjectLayer.placedObjects[0].y, "stamp drag rounds and stores moved y");
		assertEquals("o0;" + originalX + ";" + originalY + ",m0;" + editor.activeObjectLayer.placedObjects[0].x + ";"
			+ editor.activeObjectLayer.placedObjects[0].y, editor.activeObjectLayer.getActionString(), "stamp drag records Flash move action");

		var moved = editor.activeObjectLayer.placedObjects[0];
		var resizeStart = editor.activeObjectLayer.localToGlobal(new Point(moved.x, moved.y));
		var resizeEnd = editor.activeObjectLayer.localToGlobal(new Point(moved.x + 285, moved.y + 129.5625));
		editor.activeObjectLayer.resizePlacedStampForTests(0, resizeStart.x, resizeStart.y, resizeEnd.x, resizeEnd.y);
		assertEquals(1.25, editor.activeObjectLayer.placedObjects[0].scaleX, "stamp resize rounds scale x");
		assertEquals(0.75, editor.activeObjectLayer.placedObjects[0].scaleY, "stamp resize rounds scale y");
		assertEquals(true, StringTools.endsWith(editor.activeObjectLayer.getActionString(), ",r0;1.25;0.75"),
			"stamp resize records Flash resize action");

		editor.selectEditorTool("stamps", "delete");
		var deletePoint = editor.activeObjectLayer.localToGlobal(new Point(moved.x + 10, moved.y + 10));
		assertEquals(true, editor.deleteSelectedObjectAt(deletePoint.x, deletePoint.y), "stamp delete removes resized draw object");
		assertEquals(0, editor.activeObjectLayer.placedObjects.length, "stamp delete removes model object");
		assertEquals(true, StringTools.endsWith(editor.activeObjectLayer.getActionString(), ",d0"), "stamp delete records Flash delete action");

		assertEquals(true, editor.activeObjectLayer.undo(), "stamp delete undo is available");
		assertEquals(1, editor.activeObjectLayer.placedObjects.length, "stamp delete undo rebuilds object");
		assertEquals(1.25, editor.activeObjectLayer.placedObjects[0].scaleX, "stamp delete undo restores scale x");
		assertEquals(0.75, editor.activeObjectLayer.placedObjects[0].scaleY, "stamp delete undo restores scale y");
		assertEquals(true, editor.activeObjectLayer.redo(), "stamp delete redo is available");
		assertEquals(0, editor.activeObjectLayer.placedObjects.length, "stamp delete redo removes object again");
		editor.remove();
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

	private static function drawActionCount(layer:EditorDrawableLayer):Int {
		var count = 0;
		for (entry in layer.saveArray) {
			if (StringTools.startsWith(entry, "d")) {
				count++;
			}
		}
		return count;
	}

	private static function pointOutsideMenu(editor:LevelEditor):Point {
		for (x in [40, 120, 240, 480, 720, 960]) {
			for (y in [40, 120, 240, 480, 720]) {
				if (!editor.isPointOverMenu(x, y)) {
					return new Point(x, y);
				}
			}
		}
		throw "expected a test point outside the editor menu";
	}

	private static function expectedGridPos(camera:Float):Float {
		var rem = camera % BlockGridLines.SEG_SIZE;
		return rem > 0 ? rem - BlockGridLines.SEG_SIZE : rem;
	}

	private static function assertClose(expected:Float, actual:Float, message:String, tolerance:Float = 0.01):Void {
		assertions++;
		if (Math.isNaN(actual) || Math.abs(expected - actual) > tolerance) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertTrue(actual:Bool, message:String):Void {
		assertions++;
		if (!actual) {
			throw '$message: expected true';
		}
	}

	private static function assertNotNull(actual:Dynamic, message:String):Void {
		assertions++;
		if (actual == null) {
			throw '$message: expected non-null';
		}
	}
}
