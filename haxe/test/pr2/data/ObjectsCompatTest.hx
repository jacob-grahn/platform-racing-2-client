package pr2.data;

import com.jiggmin.data.Objects;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.text.TextField;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevel.DecodedArtObject;
import pr2.level.ServerLevelRenderer;
import pr2.runtime.PR2MovieClip;

class ObjectsCompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testStampMappings();
		testBlockMappings();
		testBackgroundAndTextMappings();
		testUnknownCodeReturnsNull();
		testRendererUsesObjectFactoryForAllStamps();
		trace('ObjectsCompatTest passed $assertions assertions');
	}

	private static function testStampMappings():Void {
		assertLinkage("Tree", ObjectCodes.STAMP_TREE, "tree stamp");
		assertLinkage("Tree2", ObjectCodes.STAMP_TREE2, "tree2 stamp");
		assertLinkage("Tree3", ObjectCodes.STAMP_TREE3, "tree3 stamp");
		assertLinkage("PetrifiedTree", ObjectCodes.STAMP_PETRIFIED_TREE, "petrified tree stamp");
		assertLinkage("Cactus", ObjectCodes.STAMP_CACTUS, "cactus stamp");
		assertLinkage("Rock", ObjectCodes.STAMP_ROCK, "rock stamp");
		assertLinkage("Rock2", ObjectCodes.STAMP_ROCK2, "rock2 stamp");
		assertLinkage("Spire", ObjectCodes.STAMP_SPIRE, "spire stamp");
		assertLinkage("Spire2", ObjectCodes.STAMP_SPIRE2, "spire2 stamp");
		assertLinkage("Building1", ObjectCodes.STAMP_BUILDING1, "building stamp");
	}

	private static function testBlockMappings():Void {
		var expected = [
			ObjectCodes.BLOCK_BASIC1 => "BasicBlock",
			ObjectCodes.BLOCK_BASIC2 => "BasicBlock",
			ObjectCodes.BLOCK_BASIC3 => "BasicBlock",
			ObjectCodes.BLOCK_BASIC4 => "BasicBlock",
			ObjectCodes.BLOCK_BRICK => "BrickBlock",
			ObjectCodes.BLOCK_ARROW_DOWN => "ArrowDownBlock",
			ObjectCodes.BLOCK_ARROW_UP => "ArrowUpBlock",
			ObjectCodes.BLOCK_ARROW_LEFT => "ArrowLeftBlock",
			ObjectCodes.BLOCK_ARROW_RIGHT => "ArrowRightBlock",
			ObjectCodes.BLOCK_MINE => "MineBlock",
			ObjectCodes.BLOCK_ITEM => "ItemBlock",
			ObjectCodes.BLOCK_START1 => "StartBlock",
			ObjectCodes.BLOCK_START2 => "StartBlock",
			ObjectCodes.BLOCK_START3 => "StartBlock",
			ObjectCodes.BLOCK_START4 => "StartBlock",
			ObjectCodes.BLOCK_ICE => "IceBlock",
			ObjectCodes.BLOCK_FINISH => "FinishBlock",
			ObjectCodes.BLOCK_CRUMBLE => "CrumbleBlock",
			ObjectCodes.BLOCK_VANISH => "VanishBlock",
			ObjectCodes.BLOCK_MOVE => "MoveBlock",
			ObjectCodes.BLOCK_WATER => "WaterBlock",
			ObjectCodes.BLOCK_ROTATE_RIGHT => "RotateRightBlock",
			ObjectCodes.BLOCK_ROTATE_LEFT => "RotateLeftBlock",
			ObjectCodes.BLOCK_PUSH => "PushBlock",
			ObjectCodes.BLOCK_SAFETY => "SafetyBlock",
			ObjectCodes.BLOCK_ITEM_INF => "InfItemBlock",
			ObjectCodes.BLOCK_HAPPY => "HappyBlock",
			ObjectCodes.BLOCK_SAD => "SadBlock",
			ObjectCodes.BLOCK_HEART => "HeartBlock",
			ObjectCodes.BLOCK_TIME => "TimeBlock",
			ObjectCodes.BLOCK_CUSTOM_STATS => "CustomStatsBlock",
			ObjectCodes.BLOCK_TELEPORT => "TeleportBlock"
		];

		for (code => name in expected) {
			var display = Std.downcast(Objects.getFromCode(code), Sprite);
			assertNotNull(display, '$name display');
			assertEquals(name, display.name, '$name factory name');
			assertTrue(display.width > 0 && display.height > 0, '$name has visible block art');
		}

		var arrow = Std.downcast(Objects.getFromCode(ObjectCodes.BLOCK_ARROW_RIGHT), Sprite);
		var arrowGraphic = findChild(arrow, "ArrowBlockGraphic");
		assertNotNull(arrowGraphic, "arrow block adds authored arrow graphic");
		assertEquals(90.0, arrowGraphic.rotation, "right arrow rotation");
		var egg = Std.downcast(Objects.getFromCode(ObjectCodes.BLOCK_MINION_EGG), PR2MovieClip);
		assertNotNull(egg, "minion egg returns authored graphic");
		assertEquals("EggBlockGraphic", egg.name, "minion egg linkage");
		var teleport = Std.downcast(Objects.getFromCode(ObjectCodes.BLOCK_TELEPORT), Sprite);
		assertEquals("teleportColor", teleport.getChildAt(0).name, "teleport block includes color backing");
	}

	private static function testBackgroundAndTextMappings():Void {
		assertLinkage("BG1", ObjectCodes.BG1Code, "BG1");
		assertLinkage("BG2", ObjectCodes.BG2Code, "BG2");
		assertLinkage("BG3", ObjectCodes.BG3Code, "BG3");
		assertLinkage("BG4", ObjectCodes.BG4Code, "BG4");
		assertLinkage("BG5", ObjectCodes.BG5Code, "BG5");
		assertLinkage("BG6", ObjectCodes.BG6Code, "BG6");
		assertLinkage("BG7", ObjectCodes.BG7Code, "BG7");

		var textBox = Std.downcast(Objects.getFromCode(ObjectCodes.TextCode), TextField);
		assertNotNull(textBox, "text object returns nested textBox");
		assertEquals("textBox", textBox.name, "text object text field name");
	}

	private static function testUnknownCodeReturnsNull():Void {
		assertEquals(null, Objects.getFromCode(999), "unknown object code");
	}

	private static function testRendererUsesObjectFactoryForAllStamps():Void {
		var container = new Sprite();
		ServerLevelRenderer.addLayerObject(container, new DecodedArtObject(ObjectCodes.STAMP_CACTUS, 12, 34, 1.5, 0.5), 2);
		ServerLevelRenderer.addLayerObject(container, new DecodedArtObject(ObjectCodes.STAMP_BUILDING1, 20, 40), 1);
		assertEquals(2, container.numChildren, "renderer mounts stamps that lack raster paths");
		assertEquals("Cactus", container.getChildAt(0).name, "renderer uses cactus linkage");
		assertEquals(24.0, container.getChildAt(0).x, "renderer scales cactus x");
		assertEquals(68.0, container.getChildAt(0).y, "renderer scales cactus y");
		assertEquals(3.0, container.getChildAt(0).scaleX, "renderer applies object and layer scale x");
		assertEquals(1.0, container.getChildAt(0).scaleY, "renderer applies object and layer scale y");
		assertEquals("Building1", container.getChildAt(1).name, "renderer uses building linkage");
	}

	private static function assertLinkage(linkage:String, code:Int, message:String):Void {
		var clip = Std.downcast(Objects.getFromCode(code), PR2MovieClip);
		assertNotNull(clip, message);
		assertEquals(linkage, clip.symbol.linkageClassName, '$message linkage');
	}

	private static function findChild(container:Sprite, name:String):Null<DisplayObject> {
		for (i in 0...container.numChildren) {
			var child = container.getChildAt(i);
			if (child.name == name) {
				return child;
			}
		}
		return null;
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
}
