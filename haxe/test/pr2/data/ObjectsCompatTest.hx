package pr2.data;

import com.jiggmin.data.Objects;
import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import pr2.level.ObjectCodes;
import pr2.level.Level.LevelArtObject;
import pr2.level.LevelRenderer;
import pr2.runtime.FontResolver;
import pr2.runtime.PR2MovieClip;

class ObjectsCompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testStampMappings();
		if (pr2.DeterministicTestMode.finishSmokeSuite("ObjectsCompatTest")) return;
		testBlockMappings();
		testBackgroundAndTextMappings();
		testUnknownCodeReturnsNull();
		testRendererUsesObjectFactoryForAllStamps();
		trace('ObjectsCompatTest passed $assertions assertions');
	}

	private static function testStampMappings():Void {
		assertNamedDisplay("Tree", ObjectCodes.STAMP_TREE, "tree stamp");
		assertNamedDisplay("Tree2", ObjectCodes.STAMP_TREE2, "tree2 stamp");
		assertNamedDisplay("Tree3", ObjectCodes.STAMP_TREE3, "tree3 stamp");
		assertNamedDisplay("PetrifiedTree", ObjectCodes.STAMP_PETRIFIED_TREE, "petrified tree stamp");
		assertNativeMatchesArchival("Cactus", ObjectCodes.STAMP_CACTUS, "cactus stamp");
		assertNamedDisplay("Rock", ObjectCodes.STAMP_ROCK, "rock stamp");
		assertNamedDisplay("Rock2", ObjectCodes.STAMP_ROCK2, "rock2 stamp");
		assertNamedDisplay("Spire", ObjectCodes.STAMP_SPIRE, "spire stamp");
		assertNamedDisplay("Spire2", ObjectCodes.STAMP_SPIRE2, "spire2 stamp");
		assertNativeMatchesArchival("Building1", ObjectCodes.STAMP_BUILDING1, "building stamp");

		var exactCompositions = [
			ObjectCodes.STAMP_TREE,
			ObjectCodes.STAMP_TREE2,
			ObjectCodes.STAMP_TREE3,
			ObjectCodes.STAMP_PETRIFIED_TREE,
			ObjectCodes.STAMP_ROCK,
			ObjectCodes.STAMP_ROCK2,
			ObjectCodes.STAMP_SPIRE,
			ObjectCodes.STAMP_SPIRE2
		];
		for (code in exactCompositions) {
			assertTrue(Std.isOfType(Objects.getFromCode(code), Shape), 'stamp $code preserves the composed XFL coordinate space');
		}
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
		var egg = Objects.getFromCode(ObjectCodes.BLOCK_MINION_EGG);
		assertNotNull(egg, "minion egg returns authored graphic");
		assertEquals("EggBlockGraphic", egg.name, "minion egg linkage");
		assertEquals(1.0, egg.scaleX, "minion egg factory preserves XFL horizontal scale");
		assertEquals(1.0, egg.scaleY, "minion egg factory preserves XFL vertical scale");
		var eggBounds = egg.getBounds(egg);
		assertTrue(eggBounds.x > 1 && eggBounds.x < 3, "minion egg factory preserves XFL registration inset");
		var teleport = Std.downcast(Objects.getFromCode(ObjectCodes.BLOCK_TELEPORT), Sprite);
		assertEquals("teleportColor", teleport.getChildAt(0).name, "teleport block includes color backing");
	}

	private static function testBackgroundAndTextMappings():Void {
		assertNamedDisplay("BG1", ObjectCodes.BG1Code, "BG1");
		assertNamedDisplay("BG2", ObjectCodes.BG2Code, "BG2");
		assertNamedDisplay("BG3", ObjectCodes.BG3Code, "BG3");
		assertNamedDisplay("BG4", ObjectCodes.BG4Code, "BG4");
		assertNamedDisplay("BG5", ObjectCodes.BG5Code, "BG5");
		assertNamedDisplay("BG6", ObjectCodes.BG6Code, "BG6");
		assertNamedDisplay("BG7", ObjectCodes.BG7Code, "BG7");

		var textBox = Std.downcast(Objects.getFromCode(ObjectCodes.TextCode), TextField);
		assertNotNull(textBox, "text object returns nested textBox");
		assertEquals("textBox", textBox.name, "text object text field name");
		assertEquals(2.0, textBox.x, "text object preserves authored x registration");
		assertEquals(2.0, textBox.y, "text object preserves authored y registration");
		assertEquals(1.00286865234375, textBox.scaleY, "text object preserves authored vertical matrix scale");
		assertEquals(76.0, textBox.width, "text object preserves authored width");
		assertNear(29.2 * 1.00286865234375, textBox.height, "text object preserves authored height and matrix scale");
		assertEquals(false, textBox.selectable, "text object preserves authored selection behavior");
		assertEquals(false, textBox.wordWrap, "text object preserves authored no-wrap behavior");
		assertEquals(true, textBox.multiline, "text object preserves authored multiline behavior");
		assertEquals(FontResolver.resolve("Verdana"), textBox.defaultTextFormat.font, "text object preserves authored font mapping");
		assertEquals(18.0, textBox.defaultTextFormat.size, "text object preserves authored font size");
		assertEquals(4, textBox.defaultTextFormat.leading, "text object preserves authored rounded 21.9 line height");
	}

	private static function testUnknownCodeReturnsNull():Void {
		assertEquals(null, Objects.getFromCode(999), "unknown object code");
	}

	private static function testRendererUsesObjectFactoryForAllStamps():Void {
		var container = new Sprite();
		LevelRenderer.addLayerObject(container, new LevelArtObject(ObjectCodes.STAMP_CACTUS, 12, 34, 1.5, 0.5), 2);
		LevelRenderer.addLayerObject(container, new LevelArtObject(ObjectCodes.STAMP_BUILDING1, 20, 40), 1);
		assertEquals(2, container.numChildren, "renderer mounts stamps that lack raster paths");
		assertEquals("Cactus", container.getChildAt(0).name, "renderer uses cactus linkage");
		assertEquals(24.0, container.getChildAt(0).x, "renderer scales cactus x");
		assertEquals(68.0, container.getChildAt(0).y, "renderer scales cactus y");
		assertEquals(3.0, container.getChildAt(0).scaleX, "renderer applies object and layer scale x");
		assertEquals(1.0, container.getChildAt(0).scaleY, "renderer applies object and layer scale y");
		assertEquals("Building1", container.getChildAt(1).name, "renderer uses building linkage");
	}

	private static function assertNamedDisplay(name:String, code:Int, message:String):Void {
		var display = Objects.getFromCode(code);
		assertNotNull(display, message);
		assertEquals(name, display.name, '$message native name');
		assertTrue(display.width > 0 && display.height > 0, '$message has visible native art');
	}

	private static function assertNativeMatchesArchival(linkage:String, code:Int, message:String):Void {
		var holder = Std.downcast(Objects.getFromCode(code), Sprite);
		assertNotNull(holder, message);
		assertEquals(linkage, holder.name, '$message holder name');
		assertTrue(holder.numChildren > 0, '$message has composed SVG child');
		assertEquals(null, Std.downcast(holder.getChildAt(0), PR2MovieClip), '$message no longer uses a timeline root');
		var archival = PR2MovieClip.fromLinkage(linkage);
		var bounds = archival.getBounds(archival);
		assertNear(bounds.width, holder.width, '$message preserves archival width');
		assertNear(bounds.height, holder.height, '$message preserves archival height');
		archival.dispose();
	}

	private static function assertNear(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.05) throw '$message: expected $expected, got $actual';
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
