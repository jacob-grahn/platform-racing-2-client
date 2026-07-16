package pr2.character;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.utils.Assets;
import pr2.runtime.PR2MovieClip;

class CharacterDisplayTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testSuperJumpWobbleUsesCurrentFrame();
		if (pr2.DeterministicTestMode.finishSmokeSuite("CharacterDisplayTest")) return;
		testAuthoredTimelinePartsAndColors();
		testHeldWeaponFrameAppliesToCharacterStates();
		testHeldItemUseAnimationsSurviveCharacterTicks();
		testHeldMineUsesExportedBitmap();
		testSnakeHeldGraphicUsesEyedVanishBlock();
		trace('CharacterDisplayTest passed $assertions assertions');
	}

	private static function testAuthoredTimelinePartsAndColors():Void {
		var display = new CharacterDisplay();
		var state = display.getStateClip("standAnim");
		var head = Std.downcast(state.getChildByTimelineName("head"), PR2MovieClip);
		assertTrue(head != null, "stand state exposes its authored head clip");
		assertTrue(!head.cacheAsBitmap, "explicit head cache does not use OpenFL cacheAsBitmap");
		assertTrue(display.explicitPartCacheForTest(head) != null, "stand head has an explicit local-space bitmap");
		for (partName in ["body", "foot1", "foot2"]) {
			var part = Std.downcast(state.getChildByTimelineName(partName), PR2MovieClip);
			assertTrue(part != null, 'stand state exposes its authored $partName clip');
			assertTrue(!part.cacheAsBitmap, '$partName does not use OpenFL cacheAsBitmap');
			assertTrue(display.explicitPartCacheForTest(part) != null, '$partName has an explicit local-space bitmap');
		}
		assertEquals(null, descendantNamedWithPrefix(head, "__atlasLayer"), "character does not mount a legacy atlas layer");
		assertTrue(visibleDescendantCount(head) > 0, "authored head timeline contains visible exported art");

		var originalX = head.transform.matrix.tx;
		var originalY = head.transform.matrix.ty;
		display.setPartColor("head", 0x123456, -1);
		var primary = Std.downcast(head.getChildByTimelineName("colorMC"), PR2MovieClip);
		var secondary = Std.downcast(head.getChildByTimelineName("colorMC2"), PR2MovieClip);
		assertTrue(primary != null, "authored head exposes its primary color clip");
		assertTrue(secondary != null, "authored head exposes its secondary color clip");
		assertClose(0, primary.transform.colorTransform.redMultiplier, "Flash color replacement clears red multiplication");
		assertClose(0x12, primary.transform.colorTransform.redOffset, "Flash color replacement applies red offset");
		assertClose(0x34, primary.transform.colorTransform.greenOffset, "Flash color replacement applies green offset");
		assertClose(0x56, primary.transform.colorTransform.blueOffset, "Flash color replacement applies blue offset");
		assertTrue(!secondary.visible, "missing epic color hides the authored secondary clip");
		assertClose(originalX, head.transform.matrix.tx, "recoloring preserves authored head x position");
		assertClose(originalY, head.transform.matrix.ty, "recoloring preserves authored head y position");

		var uncached = new CharacterDisplay(null, null, false);
		var uncachedState = uncached.getStateClip("standAnim");
		var uncachedHead = Std.downcast(uncachedState.getChildByTimelineName("head"), PR2MovieClip);
		assertEquals(null, uncached.explicitPartCacheForTest(uncachedHead), "visual-test mode can leave parts uncached");
		assertClose(uncachedHead.transform.matrix.tx, head.transform.matrix.tx, "cache preserves first-frame head x registration");
		assertClose(uncachedHead.transform.matrix.ty, head.transform.matrix.ty, "cache preserves first-frame head y registration");
		assertClose(uncachedHead.transform.matrix.a, head.transform.matrix.a, "cache preserves first-frame head x scale");
		assertClose(uncachedHead.transform.matrix.d, head.transform.matrix.d, "cache preserves first-frame head y scale");

		display.advanceOneFrame();
		var advancedHead = Std.downcast(state.getChildByTimelineName("head"), PR2MovieClip);
		assertEquals(head, advancedHead, "standing sway reuses the cached head instance");
		assertTrue(display.explicitPartCacheForTest(advancedHead) != null, "standing sway keeps the explicit head bitmap");
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

	private static function testSnakeHeldGraphicUsesEyedVanishBlock():Void {
		var display = new CharacterDisplay();
		display.setItemFrameName("Snake");
		for (stateName in ["standAnim", "runAnim", "jumpAnim", "swimAnim"]) {
			var weapon = weaponClip(display, stateName);
			assertEquals(1, weapon.currentFrame, '$stateName Snake uses the empty authored weapon frame');
			var snake = weapon.getChildByName("__snakeHeldItem");
			assertTrue(snake != null, '$stateName mounts the eyed vanish-block held graphic');
			assertTrue(visibleDescendantCount(snake) > 0, '$stateName Snake held graphic is visible');
			assertClose(2, snake.scaleX, '$stateName held Snake is twice its original width');
			assertClose(2, snake.scaleY, '$stateName held Snake is twice its original height');
		}
		display.advanceOneFrame();
		assertTrue(weaponClip(display, "standAnim").getChildByName("__snakeHeldItem") != null,
			"animation ticks preserve the Snake held graphic");
		display.setItemFrameName("None");
		assertEquals(null, weaponClip(display, "standAnim").getChildByName("__snakeHeldItem"), "clearing the item removes the Snake held graphic");
	}

	private static function testHeldItemUseAnimationsSurviveCharacterTicks():Void {
		var display = new CharacterDisplay();
		display.setItemFrameName("Laser");
		assertTrue(display.playItemUseAnimation("Laser"), "laser starts its authored gun recoil");
		var gun = Std.downcast(weaponClip(display, "standAnim").getChildByTimelineName("gun"), PR2MovieClip);
		assertTrue(gun != null, "laser frame exposes the gun animation");
		assertEquals(2, gun.currentFrame, "laser recoil starts on the shoot label");
		display.advanceOneFrame();
		assertEquals(gun, Std.downcast(weaponClip(display, "standAnim").getChildByTimelineName("gun"), PR2MovieClip),
			"character ticks preserve the active gun clip");
		assertEquals(2, gun.currentFrame, "character ticks do not reset the gun recoil");
		gun.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(3, gun.currentFrame, "gun recoil advances after the character tick");

		display.setItemFrameName("Sword");
		assertTrue(display.playItemUseAnimation("Sword"), "sword starts its authored swing");
		var sword = Std.downcast(weaponClip(display, "standAnim").getChildByTimelineName("sword"), PR2MovieClip);
		assertTrue(sword != null, "sword frame exposes the swing animation");
		assertEquals(2, sword.currentFrame, "sword swing starts on the swing label");
		display.advanceOneFrame();
		assertEquals(sword, Std.downcast(weaponClip(display, "standAnim").getChildByTimelineName("sword"), PR2MovieClip),
			"character ticks preserve the active sword clip");
		sword.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(3, sword.currentFrame, "sword swing advances after the character tick");

		display.setState("runAnim");
		assertTrue(display.playItemUseAnimation("Sword"), "running sword starts a fresh swing");
		var runningSword = Std.downcast(weaponClip(display, "runAnim").getChildByTimelineName("sword"), PR2MovieClip);
		runningSword.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(3, runningSword.currentFrame, "running sword reaches the middle of its swing");
		display.setState("standAnim");
		assertEquals(1, runningSword.currentFrame, "leaving a state resets its unfinished sword animation");
		display.setState("runAnim");
		assertEquals(1, Std.downcast(weaponClip(display, "runAnim").getChildByTimelineName("sword"), PR2MovieClip).currentFrame,
			"returning to the original state does not restore a stuck half-swing");
	}

	private static function testHeldMineUsesExportedBitmap():Void {
		Assets.cache.setBitmapData("assets/blocks/mine_block.png", new BitmapData(30, 30, false, 0x6A6250));
		var display = new CharacterDisplay();
		display.setItemFrameName("Mine");
		assertTrue(bitmapDescendantCount(weaponClip(display, "standAnim")) > 0,
			"held mine resolves Flash's embedded MineBitmap to the exported PNG");
		Assets.cache.removeBitmapData("assets/blocks/mine_block.png");
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

	private static function bitmapDescendantCount(root:DisplayObject):Int {
		var count = Std.isOfType(root, Bitmap) ? 1 : 0;
		var container = Std.downcast(root, DisplayObjectContainer);
		if (container != null) {
			for (i in 0...container.numChildren) {
				count += bitmapDescendantCount(container.getChildAt(i));
			}
		}
		return count;
	}

	private static function descendantNamedWithPrefix(root:DisplayObject, prefix:String):Null<DisplayObject> {
		if (root.name != null && StringTools.startsWith(root.name, prefix)) {
			return root;
		}
		var container = Std.downcast(root, DisplayObjectContainer);
		if (container != null) {
			for (i in 0...container.numChildren) {
				var match = descendantNamedWithPrefix(container.getChildAt(i), prefix);
				if (match != null) {
					return match;
				}
			}
		}
		return null;
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
