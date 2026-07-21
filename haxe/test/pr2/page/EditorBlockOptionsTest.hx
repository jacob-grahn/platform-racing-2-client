package pr2.page;

import openfl.display.DisplayObjectContainer;
import openfl.display.DisplayObject;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import pr2.level.BlockType;
import pr2.level.ObjectCodes;
import pr2.levelEditor.EditorBlockOptionsView;
import pr2.levelEditor.LevelListItemView;
import pr2.levelEditor.GetLevelsView;
import pr2.levelEditor.SaveLevelView;
import pr2.levelEditor.HandleLevelReportView;
import pr2.levelEditor.LevelEditor;
import pr2.levelEditor.TestCourseHatPickerView;
import pr2.levelEditor.TestCourseView;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameSlider;
import pr2.ui.controls.GameTextArea;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.ProgressPopupView;
import pr2.ui.view.StatusPopupView;

class EditorBlockOptionsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.Item), "item blocks expose options");
		if (pr2.DeterministicTestMode.finishSmokeSuite("EditorBlockOptionsTest")) return;
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.InfiniteItem), "infinite item blocks expose options");
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.Teleport), "teleport blocks expose options");
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.Happy), "happy blocks expose options");
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.Sad), "sad blocks expose options");
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.CustomStats), "custom stat blocks expose options");
		assertEquals(false, EditorBlockOptions.hasOptions(BlockType.Brick), "plain blocks do not expose options");

		assertEquals("", EditorBlockOptions.applyItemOptions([4, 1], [1, 4]), "level item defaults save as empty options");
		assertEquals("none", EditorBlockOptions.applyItemOptions([], [1, 4]), "no selected items saves as none");
		assertEquals("1-4-9", EditorBlockOptions.applyItemOptions([9, 4, 4, 1], [1, 2]), "items save sorted and unique");
		assertArrayEquals([1, 4], EditorBlockOptions.selectedItems("", [4, 1]), "empty item options load level defaults");
		assertArrayEquals([], EditorBlockOptions.selectedItems("none", [4, 1]), "none item options load no items");
		assertArrayEquals([1, 9], EditorBlockOptions.selectedItems("9-1", []), "explicit item options load sorted choices");

		assertEquals("", EditorBlockOptions.applyTeleportColor(EditorBlockOptions.TELEPORT_DEFAULT_COLOR), "default teleport color saves empty");
		assertEquals("255", EditorBlockOptions.applyTeleportColor(255), "custom teleport color saves decimal string");
		assertEquals(EditorBlockOptions.TELEPORT_DEFAULT_COLOR, EditorBlockOptions.teleportColor(""), "empty teleport options load default color");
		assertEquals(255, EditorBlockOptions.teleportColor("255"), "custom teleport options load color");

		assertEquals("", EditorBlockOptions.applyStatChange(BlockType.Happy, 2), "happy default-or-less saves empty");
		assertEquals("100", EditorBlockOptions.applyStatChange(BlockType.Happy, 120), "happy stat change clamps high");
		assertEquals("", EditorBlockOptions.applyStatChange(BlockType.Sad, -2), "sad default-or-less saves empty");
		assertEquals("-100", EditorBlockOptions.applyStatChange(BlockType.Sad, -120), "sad stat change clamps low");
		assertEquals(5, EditorBlockOptions.statChange(BlockType.Happy, ""), "happy empty options load default amount");
		assertEquals(-5, EditorBlockOptions.statChange(BlockType.Sad, ""), "sad empty options load default amount");

		assertEquals("", EditorBlockOptions.applyCustomStats(false, 50, 50, 50), "default custom stats save empty");
		assertEquals("reset", EditorBlockOptions.applyCustomStats(true, 10, 20, 30), "custom stat reset saves reset marker");
		assertEquals("0-50-100", EditorBlockOptions.applyCustomStats(false, -5, 50, 140), "custom stats clamp to valid range");
		assertArrayEquals([50, 50, 50], EditorBlockOptions.customStats(""), "empty custom stats load defaults");
		assertArrayEquals([50, 50, 50], EditorBlockOptions.customStats("reset"), "reset custom stats keep slider defaults");
		assertArrayEquals([100, 75, 100], EditorBlockOptions.customStats("105-75-140"), "custom stats load clamped values");
		testEditorEggBlockUsesAuthoredGraphic();
		testAuthoredBlockOptionsViews();
		testAuthoredTestCourseViews();
		testAuthoredLevelListRows();
		testAuthoredGetLevelsView();
		testAuthoredSaveLevelView();
		testAuthoredEditorStatusViews();
		testAuthoredHandleReportView();

		trace('EditorBlockOptionsTest passed $assertions assertions');
	}

	private static function testAuthoredHandleReportView():Void {
		var view = new HandleLevelReportView();
		assertPoint(view.getChildByName("background"), -150, -135, 1.10301208496094, 1.41368103027344, "handle-report background");
		var title = Std.downcast(view.getChildByName("titleBox"), TextField);
		assertNear(-153.05, title.x, "handle-report title x");
		assertNear(-88, title.y, "handle-report title y");
		assertNear(286, title.width, "handle-report title width");
		var reason = Std.downcast(view.getChildByName("reason"), pr2.ui.controls.GameSelect);
		assertNear(-87.5, reason.x, "handle-report reason x");
		assertNear(-20, reason.y, "handle-report reason y");
		assertNear(175, reason.controlWidth, "handle-report reason width");
		assertEquals(8, reason.length, "handle-report authored reason count");
		reason.selectedIndex = 6;
		assertEquals("Republished Removed Level", reason.selectedOption.label, "handle-report authored reason ordering");
		var duration = Std.downcast(view.getChildByName("duration"), pr2.ui.controls.GameSelect);
		assertNear(-102.5, duration.x, "handle-report duration x");
		assertNear(13.8, duration.y, "handle-report duration y");
		assertNear(90, duration.controlWidth, "handle-report duration width");
		assertEquals(9, duration.length, "handle-report authored duration count");
		assertEquals("15768000", duration.itemAt(7), "handle-report six-month duration");
		var other = Std.downcast(view.getChildByName("otherReasonBox"), GameTextInput);
		assertNear(-94, other.x, "handle-report other reason x");
		assertNear(145, other.controlWidth, "handle-report other reason width");
		var info = view.getChildByName("info_bt");
		assertNear(32.95, info.x, "handle-report info x");
		assertNear(-75.3, info.y, "handle-report info y");
		var ban = Std.downcast(view.getChildByName("ban_bt"), GameButton);
		assertEquals("Ban", ban.label, "handle-report ban label");
		assertNear(10, ban.x, "handle-report ban x");
		assertNear(13.8, ban.y, "handle-report ban y");
		var archive = Std.downcast(view.getChildByName("archive_bt"), GameButton);
		assertNear(-100, archive.x, "handle-report archive x");
		assertNear(90, archive.y, "handle-report archive y");
		view.dispose();
	}

	private static function testAuthoredEditorStatusViews():Void {
		var connecting = new StatusPopupView("Connecting...", true);
		assertPoint(connecting.getChildByName("background"), -81, -48, 0.604461669921875, 0.505264282226562, "connecting background");
		var label = Std.downcast(connecting.getChildByName("statusLabel"), TextField);
		assertEquals("Connecting...", label.text, "connecting authored label");
		assertNear(-37, label.x, "connecting label x");
		assertNear(-28.2, label.y, "connecting label y");
		assertNear(79.6, label.width, "connecting label width");
		assertEquals("var_1", connecting.closeButton.name, "connecting authored close instance name");
		assertNear(-48, connecting.closeButton.x, "connecting close x");
		assertNear(10, connecting.closeButton.y, "connecting close y");
		assertNear(100, connecting.closeButton.controlWidth, "connecting close width");
		connecting.dispose();

		var uploading = new ProgressPopupView("Uploading level...");
		assertPoint(uploading.getChildByName("background"), -125, -52, 0.919113159179688, 0.544708251953125, "uploading background");
		assertEquals("Uploading level...", uploading.message.text, "uploading dynamic message");
		assertNear(-98, uploading.message.x, "uploading message x");
		assertNear(-38.15, uploading.message.y, "uploading message y");
		assertNear(196, uploading.message.width, "uploading message width");
		assertNear(-50, uploading.closeButton.x, "uploading close x");
		assertNear(19, uploading.closeButton.y, "uploading close y");
		assertNear(100, uploading.closeButton.controlWidth, "uploading close width");
		uploading.dispose();
	}

	private static function testAuthoredSaveLevelView():Void {
		var view = new SaveLevelView();
		assertPoint(view.getChildByName("background"), -136, -120.4, 1, 1.33515930175781, "save-level background");
		var heading = Std.downcast(view.getChildByName("heading"), TextField);
		assertEquals("-- Save Level --", heading.text, "save-level heading");
		assertNear(-53, heading.x, "save-level heading x");
		assertNear(-109.15, heading.y, "save-level heading y");
		var titleLabel = Std.downcast(view.getChildByName("titleLabel"), TextField);
		assertNear(-134, titleLabel.x, "save-level title label x");
		assertNear(1.00286865234375, titleLabel.scaleY, "save-level title label scale y");
		var title = Std.downcast(view.getChildByName("titleBox"), GameTextInput);
		assertNear(-79, title.x, "save-level title input x");
		assertNear(-78, title.y, "save-level title input y");
		assertNear(203.001403808594, title.controlWidth, "save-level title input authored width");
		assertNear(1, title.scaleX, "save-level title input does not stretch text");
		assertEquals(50, title.maxChars, "save-level title input limit");
		var note = Std.downcast(view.getChildByName("noteBox"), GameTextArea);
		assertNear(-79, note.x, "save-level note input x");
		assertNear(-41, note.y, "save-level note input y");
		assertNear(203.0029296875, note.controlWidth, "save-level note authored width");
		assertNear(61.01025390625, note.controlHeight, "save-level note authored height");
		assertNear(1, note.scaleX, "save-level note does not stretch text horizontally");
		assertNear(1, note.scaleY, "save-level note does not stretch text vertically");
		assertEquals(255, note.maxChars, "save-level note limit");
		var titleCount = Std.downcast(view.getChildByName("titleCharsRemaining"), TextField);
		assertEquals("50 / 50", titleCount.text, "save-level authored title count");
		assertNear(-134, titleCount.x, "save-level title count x");
		assertNear(-68, titleCount.y, "save-level title count y");
		var noteCount = Std.downcast(view.getChildByName("noteCharsRemaining"), TextField);
		assertEquals("255 / 255", noteCount.text, "save-level authored note count");
		assertNear(-134, noteCount.x, "save-level note count x");
		assertNear(-29, noteCount.y, "save-level note count y");
		var publishLabel = Std.downcast(view.getChildByName("publishLabel"), TextField);
		assertNear(-102.45, publishLabel.x, "save-level publish label x");
		var newestLabel = Std.downcast(view.getChildByName("newestLabel"), TextField);
		assertNear(39.9, newestLabel.x, "save-level newest label x");
		var warning = Std.downcast(view.getChildByName("warning"), TextField);
		assertNear(-105.45, warning.x, "save-level warning x");
		var publish = Std.downcast(view.getChildByName("publish_chk"), GameCheckBox);
		assertNear(-107.45, publish.x, "save-level publish x");
		assertNear(25, publish.y, "save-level publish y");
		assertNear(0.850082397460938, publish.scaleX, "save-level publish scale");
		var newest = Std.downcast(view.getChildByName("newest_chk"), GameCheckBox);
		assertEquals(false, newest.enabled, "save-level newest starts disabled");
		assertNear(8, newest.x, "save-level newest x");
		assertNear(1.05000305175781, newest.scaleX, "save-level newest scale");
		var save = Std.downcast(view.getChildByName("save_bt"), GameButton);
		assertNear(-114, save.x, "save-level save x");
		assertNear(94, save.y, "save-level save y");
		assertNear(100, save.controlWidth, "save-level save width");
		var cancel = Std.downcast(view.getChildByName("cancel_bt"), GameButton);
		assertNear(13, cancel.x, "save-level cancel x");
		view.dispose();
	}

	private static function testAuthoredGetLevelsView():Void {
		var view = new GetLevelsView();
		assertPoint(view.getChildByName("background"), -147, -129, 1.08087158203125, 1.3455810546875, "get-levels background");
		var listSkin = view.getChildByName("listSkin");
		assertPoint(listSkin, -131, -86, 1.64472961425781, 7.27272033691406, "get-levels list skin");
		assertNotNull(listSkin.scale9Grid, "get-levels list skin preserves its authored nine-slice grid");
		assertNear(1.55, listSkin.scale9Grid.x, "get-levels list skin grid x");
		assertNear(1.55, listSkin.scale9Grid.y, "get-levels list skin grid y");
		assertNear(148.5, listSkin.scale9Grid.width, "get-levels list skin grid width");
		assertNear(18.4, listSkin.scale9Grid.height, "get-levels list skin grid height");
		var title = Std.downcast(view.getChildByName("titleBox"), TextField);
		assertEquals("-- Load --", title.text, "get-levels authored title");
		assertNear(-84.15, title.x, "get-levels title x");
		assertNear(-117, title.y, "get-levels title y");
		assertNear(162.85, title.width, "get-levels title width");
		assertNear(17.05, title.height, "get-levels title height");
		var holder = Std.downcast(view.getChildByName("levelsHolder"), DisplayObjectContainer);
		assertNear(-130, holder.x, "get-levels holder x");
		assertNear(-85, holder.y, "get-levels holder y");
		assertNotNull(holder.mask, "get-levels list uses the authored fixed mask");
		assertNear(248, holder.mask.width, "get-levels mask width");
		assertNear(158, holder.mask.height, "get-levels mask height");
		assertPoint(view.getChildByName("loadingGraphic"), 0, 0.05, 1, 1, "get-levels loading graphic");
		var load = Std.downcast(view.getChildByName("load_bt"), GameButton);
		assertEquals("Load", load.label, "get-levels load label");
		assertNear(-131, load.x, "get-levels load x");
		assertNear(89, load.y, "get-levels load y");
		assertNear(76, load.controlWidth, "get-levels load width");
		var deleteButton = Std.downcast(view.getChildByName("delete_bt"), GameButton);
		assertNear(-37, deleteButton.x, "get-levels delete x");
		var cancel = Std.downcast(view.getChildByName("cancel_bt"), GameButton);
		assertNear(58, cancel.x, "get-levels cancel x");
		view.dispose();
	}

	private static function testAuthoredLevelListRows():Void {
		var normal = new LevelListItemView();
		var title = Std.downcast(normal.getChildByName("titleBox"), TextField);
		assertEquals("Title goes here", title.text, "level row authored title placeholder");
		assertNear(2, title.x, "level row title x");
		assertNear(2, title.y, "level row title y");
		assertNear(158.95, title.width, "level row title width");
		var status = Std.downcast(normal.getChildByName("statusBox"), TextField);
		assertEquals("Unpublished", status.text, "level row authored status placeholder");
		assertNear(171, status.x, "level row status x");
		assertNear(2, status.y, "level row status y");
		assertNear(72, status.width, "level row status width");
		assertEquals(1, normal.currentFrame, "level row authored up frame");
		normal.setInteractionState("over");
		assertEquals(6, normal.currentFrame, "level row authored over frame");
		assertEquals("authoredBackground", normal.getChildAt(0).name, "level row keeps authored background below text");
		normal.setInteractionState("selected");
		assertEquals(11, normal.currentFrame, "level row authored selected frame");

		var reported = new LevelListItemView(true);
		var reportedTitle = Std.downcast(reported.getChildByName("titleBox"), TextField);
		assertNear(2.5, reportedTitle.y, "reported level row title y");
		assertNear(14.55, reportedTitle.height, "reported level row title height");
		var time = Std.downcast(reported.getChildByName("timeBox"), TextField);
		assertEquals("14/Jun/2020", time.text, "reported row authored time placeholder");
		assertNear(171, time.x, "reported level row time x");
		assertNear(2.5, time.y, "reported level row time y");
		assertNear(78.05, time.width, "reported level row time width");
	}

	private static function testAuthoredTestCourseViews():Void {
		var controls = new TestCourseView();
		var background = controls.getChildByName("background");
		assertPoint(background, 0, 0, 1, 1, "test-course background keeps the composed XFL coordinate space");
		var restart = Std.downcast(controls.getChildByName("restart_bt"), GameButton);
		assertEquals("Restart", restart.label, "test-course restart label");
		assertNear(94, restart.x, "test-course restart x");
		assertNear(169, restart.y, "test-course restart y");
		assertNear(54, restart.controlWidth, "test-course restart authored width");
		assertNear(22, restart.controlHeight, "test-course restart authored height");
		var back = Std.downcast(controls.getChildByName("back_bt"), GameButton);
		assertEquals("Back", back.label, "test-course back label");
		assertNear(153, back.x, "test-course back x");
		assertNear(169, back.y, "test-course back y");

		var picker = new TestCourseHatPickerView();
		var left = picker.getChildByName("left");
		assertNear(10, left.x, "hat picker left x");
		assertNear(-0.999984741210938, left.scaleX, "hat picker left authored mirror");
		assertEquals(1, left.filters.length, "hat picker left has authored shadow");
		var right = picker.getChildByName("right");
		assertNear(100, right.x, "hat picker right x");
		assertNear(1, right.scaleX, "hat picker right scale");
		var hat = Std.downcast(picker.getChildByName("hat"), DisplayObjectContainer);
		assertNear(0.300888061523438, hat.transform.matrix.a, "hat picker hat matrix a");
		assertNear(0.0806121826171875, hat.transform.matrix.b, "hat picker hat matrix b");
		assertNear(-0.0806121826171875, hat.transform.matrix.c, "hat picker hat matrix c");
		assertNear(0.300888061523438, hat.transform.matrix.d, "hat picker hat matrix d");
		assertNear(56, hat.transform.matrix.tx, "hat picker hat x");
		assertNear(20, hat.transform.matrix.ty, "hat picker hat y");
		picker.setHat(2);
		assertEquals(3, hat.numChildren, "hat picker mounts all authored color channels");
		assertEquals(false, hat.getChildByName("colorMC2").visible, "ordinary hat hides the secondary channel like Flash");
		picker.setHat(16);
		assertEquals(true, hat.getChildByName("colorMC2").visible, "epic hat exposes the secondary channel like Flash");
	}

	private static function testAuthoredBlockOptionsViews():Void {
		var stat = new EditorBlockOptionsView("StatBlockOptionsGraphic");
		assertPoint(stat.childNamed("background"), -117.7, -59.95, 0.867233276367188, 0.68072509765625, "stat background");
		var statTitle = Std.downcast(stat.childNamed("titleBox"), TextField);
		assertEquals("-- Happy Block --", statTitle.text, "stat authored default title");
		assertNear(-56, statTitle.x, "stat title x");
		assertNear(-49, statTitle.y, "stat title y");
		var statDesc = Std.downcast(stat.childNamed("descBox"), TextField);
		assertEquals("All the stats of players that bump this block will be increased by:", statDesc.text, "stat authored description");
		assertNear(-103, statDesc.x, "stat description x");
		assertNear(-23, statDesc.y, "stat description y");
		var slider = Std.downcast(stat.childNamed("slider"), GameSlider);
		assertNear(-90, slider.x, "stat slider x");
		assertNear(24.85, slider.y, "stat slider y");
		assertNear(184.5, slider.controlWidth, "stat slider authored width");
		var statValue = Std.downcast(stat.childNamed("statBox"), TextField);
		assertEquals("5", statValue.text, "stat authored default value");
		assertNear(-12.95, statValue.x, "stat value x");
		assertNear(46.5, statValue.y, "stat value y");

		var teleport = new EditorBlockOptionsView("TeleportBlockOptionsGraphic");
		assertPoint(teleport.childNamed("background"), -117.7, -59.95, 0.867233276367188, 0.68072509765625, "teleport background");
		var teleportTitle = Std.downcast(teleport.childNamed("title"), TextField);
		assertEquals("-- Teleport Block --", teleportTitle.text, "teleport title");
		assertNear(-68, teleportTitle.x, "teleport title x");
		assertNear(-49, teleportTitle.y, "teleport title y");
		var teleportDesc = Std.downcast(teleport.childNamed("description"), TextField);
		assertEquals("Choose the background color of this block. Blocks with the same color will be linked to this one.", teleportDesc.text,
			"teleport description");
		assertNear(-103, teleportDesc.x, "teleport description x");
		assertNear(-28, teleportDesc.y, "teleport description y");

		var item = new EditorBlockOptionsView("ItemBlockOptionsGraphic");
		assertPoint(item.childNamed("background"), -118, -105, 0.86767578125, 1.09947204589844, "item background");
		var itemTitle = Std.downcast(item.childNamed("title"), TextField);
		assertEquals("-- Item Block --", itemTitle.text, "item title");
		assertNear(-57.1, itemTitle.x, "item title x");
		assertNear(-92.6, itemTitle.y, "item title y");
		var laser = Std.downcast(item.childNamed("check1"), GameCheckBox);
		assertEquals("Laser Gun", laser.label, "item laser label");
		assertNear(-101.05, laser.x, "item laser x");
		assertNear(-31.6, laser.y, "item laser y");
		var ice = Std.downcast(item.childNamed("check9"), GameCheckBox);
		assertEquals("Ice Wave", ice.label, "item ice label");
		assertNear(-101.05, ice.x, "item ice x");
		assertNear(68.4, ice.y, "item ice y");
		assertEquals(null, item.childNamed("check10"), "post-Flash snake is not injected into authored item options");

		var custom = new EditorBlockOptionsView("CustomStatsBlockOptionsGraphic");
		assertPoint(custom.childNamed("background"), -120, -115, 0.88232421875, 1.20414733886719, "custom stats background");
		var customTitle = Std.downcast(custom.childNamed("title"), TextField);
		assertEquals("-- Custom Stats Block --", customTitle.text, "custom stats title");
		assertNear(-79.45, customTitle.x, "custom stats title x");
		assertNear(-103.15, customTitle.y, "custom stats title y");
		var reset = Std.downcast(custom.childNamed("resetChk"), GameCheckBox);
		assertEquals("Reset To Starting Stats", reset.label, "custom reset label");
		assertNear(-75, reset.x, "custom reset x");
		assertNear(80, reset.y, "custom reset y");
		assertNear(1.5, reset.scaleX, "custom reset scale");
	}

	private static function assertPoint(value:DisplayObject, x:Float, y:Float, scaleX:Float, scaleY:Float, message:String):Void {
		assertNotNull(value, message);
		assertNear(x, value.x, message + " x");
		assertNear(y, value.y, message + " y");
		assertNear(scaleX, value.scaleX, message + " scale x");
		assertNear(scaleY, value.scaleY, message + " scale y");
	}

	private static function testEditorEggBlockUsesAuthoredGraphic():Void {
		var editor = new LevelEditor();
		editor.initialize();
		var block = editor.blockLayer.addBlockAtStage(ObjectCodes.BLOCK_MINION_EGG, null, 0, 0);
		assertNotNull(block, "egg block can be placed");

		var holder = Std.downcast(block.getChildAt(0), DisplayObjectContainer);
		assertNotNull(holder, "egg block display holder is mounted");
		var eggBlock = holder.getChildAt(0);
		assertNotNull(eggBlock, "egg block uses authored native art");
		assertEquals("EggBlockGraphic", eggBlock.name, "egg block native name");
		assertEquals(1.0, eggBlock.scaleX, "egg block keeps the authored horizontal scale");
		assertEquals(1.0, eggBlock.scaleY, "egg block keeps the authored vertical scale");
		assertEquals(0.0, eggBlock.x, "egg block keeps the authored registration x");
		assertEquals(0.0, eggBlock.y, "egg block keeps the authored registration y");
		var bounds:Rectangle = eggBlock.getBounds(eggBlock);
		assertTrue(bounds.x > 1 && bounds.x < 3, "egg block keeps the authored left inset");
		assertTrue(bounds.width > 24 && bounds.width < 26, "egg block keeps the authored visible width");
		assertTrue(bounds.height > 28 && bounds.height < 31, "egg block keeps the authored visible height");
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
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw '$message: value was null';
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) throw '$message: expected true';
	}

	private static function assertNear(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.001) throw '$message: expected $expected, got $actual';
	}
}
