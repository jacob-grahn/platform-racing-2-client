package pr2.character;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import pr2.runtime.PR2MovieClip;

class CharacterDisplayTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testSuperJumpWobbleUsesCurrentFrame();
		testHeldWeaponFrameAppliesToCharacterStates();
		trace('CharacterDisplayTest passed $assertions assertions');
	}

	private static function testSuperJumpWobbleUsesCurrentFrame():Void {
		var display = new CharacterDisplay();
		display.setSuperJumpWobbleRandomForTest(function() return 1.0);
		display.setState("superJumpAnim");
		display.advanceOneFrame();
		display.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(1.005, display.scaleY, "super-jump wobble scales from current animation frame");

		display.setState("standAnim");
		assertClose(1.0, display.scaleY, "leaving super-jump resets vertical scale");
		display.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(1.0, display.scaleY, "super-jump wobble listener stops after leaving state");
	}

	private static function testHeldWeaponFrameAppliesToCharacterStates():Void {
		var display = new CharacterDisplay();
		display.setItemFrameName("Laser");

		for (stateName in ["standAnim", "runAnim", "jumpAnim", "swimAnim"]) {
			var weapon = weaponClip(display, stateName);
			assertEquals(6, weapon.currentFrame, '$stateName weapon moves to Laser frame');
			assertTrue(weapon.visible, '$stateName weapon clip stays visible');
			assertTrue(visibleDescendantCount(weapon) > 0, '$stateName Laser frame has visible held-item art');
		}

		display.setState("runAnim");
		assertEquals(6, weaponClip(display, "runAnim").currentFrame, "state changes keep the held weapon frame");
		display.advanceOneFrame();
		assertEquals(6, weaponClip(display, "runAnim").currentFrame, "animation ticks keep the held weapon frame");

		display.setItemFrameName("None");
		assertEquals(1, weaponClip(display, "runAnim").currentFrame, "None resets the active weapon clip");
		assertEquals(1, weaponClip(display, "standAnim").currentFrame, "None resets inactive weapon clips too");
		assertEquals(0, visibleDescendantCount(weaponClip(display, "runAnim")), "None frame hides held-item art");
	}

	private static function weaponClip(display:CharacterDisplay, stateName:String):PR2MovieClip {
		var state = display.getStateClip(stateName);
		assertTrue(state != null, '$stateName exists');
		var weapon = Std.downcast(state.getChildByTimelineName("weapon"), PR2MovieClip);
		assertTrue(weapon != null, '$stateName exposes weapon clip');
		return weapon;
	}

	private static function visibleDescendantCount(root:DisplayObject):Int {
		if (!root.visible) {
			return 0;
		}
		var container = Std.downcast(root, DisplayObjectContainer);
		if (container == null) {
			return 1;
		}
		var count = 0;
		for (i in 0...container.numChildren) {
			count += visibleDescendantCount(container.getChildAt(i));
		}
		return count;
	}

	private static function assertEquals<T>(expected:T, actual:T, message:String):Void {
		assertions++;
		if (actual != expected) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) {
			throw 'assertion failed: $message';
		}
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.0001) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
