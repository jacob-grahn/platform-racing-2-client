package pr2.display;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.gameplay.ItemDisplay;

class RemovableTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testBaseRemoveContract();
		if (pr2.DeterministicTestMode.finishSmokeSuite("RemovableTest")) return;
		testMigratedClassRemoveContract();
		trace('RemovableTest passed $assertions assertions');
	}

	private static function testBaseRemoveContract():Void {
		var parent = new Sprite();
		var removable = new Removable();
		removable.addChild(new Sprite());
		parent.addChild(removable);
		var removes = 0;
		removable.addEventListener(Removable.REMOVE, function(_:Event):Void removes++);

		removable.safeRemove();
		assertEquals(true, removable.isRemoved(), "safeRemove marks object removed");
		assertEquals(null, removable.parent, "safeRemove detaches from parent");
		assertEquals(0, removable.numChildren, "safeRemove clears children");
		assertEquals(1, removes, "safeRemove dispatches remove event");

		removable.safeRemove();
		removable.remove();
		assertEquals(1, removes, "remove event dispatches once");
	}

	private static function testMigratedClassRemoveContract():Void {
		var parent = new Sprite();
		var display = new ItemDisplay();
		parent.addChild(display);
		var removes = 0;
		display.addEventListener(Removable.REMOVE, function(_:Event):Void removes++);

		display.remove();
		assertEquals(true, display.isRemoved(), "migrated class marks removed");
		assertEquals(null, display.parent, "migrated class detaches from parent");
		assertEquals(0, display.numChildren, "migrated class clears children after custom teardown");
		assertEquals(1, removes, "migrated class dispatches remove event");

		display.remove();
		assertEquals(1, removes, "migrated class remove is idempotent");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
