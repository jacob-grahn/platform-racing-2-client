package pr2.page;

import openfl.display.DisplayObjectContainer;
import pr2.level.BlockType;
import pr2.level.ObjectCodes;
import pr2.levelEditor.LevelEditor;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class EditorBlockOptionsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.Item), "item blocks expose options");
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

		trace('EditorBlockOptionsTest passed $assertions assertions');
	}

	private static function testEditorEggBlockUsesAuthoredGraphic():Void {
		var editor = new LevelEditor();
		editor.initialize();
		var block = editor.blockLayer.addBlockAtStage(ObjectCodes.BLOCK_MINION_EGG, null, 0, 0);
		assertNotNull(block, "egg block can be placed");

		var holder = Std.downcast(block.getChildAt(0), DisplayObjectContainer);
		assertNotNull(holder, "egg block display holder is mounted");
		var eggBlock = Std.downcast(holder.getChildAt(0), PR2MovieClip);
		assertNotNull(eggBlock, "egg block uses authored EggBlockGraphic");
		assertEquals("EggBlockGraphic", eggBlock.symbol.linkageClassName, "egg block linkage");

		var leftFoot = Std.downcast(DisplayUtil.findByName(eggBlock, "var_152"), PR2MovieClip);
		var rightFoot = Std.downcast(DisplayUtil.findByName(eggBlock, "var_165"), PR2MovieClip);
		assertStoppedFoot(leftFoot, "var_152");
		assertStoppedFoot(rightFoot, "var_165");
	}

	private static function assertStoppedFoot(foot:PR2MovieClip, name:String):Void {
		assertNotNull(foot, '$name is present');
		var startFrame = foot.currentFrame;
		foot.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		assertEquals(startFrame, foot.currentFrame, '$name constructor stop is preserved');
		var colorMC = Std.downcast(DisplayUtil.findByName(foot, "colorMC"), PR2MovieClip);
		var colorMC2 = Std.downcast(DisplayUtil.findByName(foot, "colorMC2"), PR2MovieClip);
		assertNotNull(colorMC, '$name colorMC is present');
		assertNotNull(colorMC2, '$name colorMC2 is present');
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
}
