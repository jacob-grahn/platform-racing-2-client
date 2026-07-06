package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.events.MouseEvent;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;

/**
	Behavioural coverage for `FlButton`, the `fl.controls.Button` port, and for
	the real `playerInfo` symbol whose follow/friend/ignore buttons the player
	popup drives by flipping `label`, toggling `enabled`, and listening for clicks.
**/
class FlButtonTest {
	private static var assertions:Int = 0;

	private static final PLAYER_INFO_SYMBOL = "MovieClips/PR2_Graphics_1_Apr_2014_fla/Symbol 1049";

	public static function main():Void {
		testDefaultsAndLabel();
		testEnabledTogglesInteractivity();
		testDisabledAndEmphasizedAppearance();
		testSkinSwapsWithMouseState();
		testAuthoredButtonSymbolMouseStates();
		testToggleFlipsSelectedOnClick();
		testClickReachesExternalListeners();
		testGeneratedPlayerInfoButtons();
		testGeneratedVaultButtonKeepsBlankComponentLabel();
		trace('FlButtonTest passed $assertions assertions');
	}

	private static function testDefaultsAndLabel():Void {
		var button = new FlButton("Follow");
		assertEquals("Follow", button.label, "constructor label is exposed");
		assertEquals(true, button.enabled, "buttons start enabled");
		assertEquals(false, button.selected, "buttons start unselected");
		assertNotNull(findLabelField(button, "Follow"), "label renders as on-screen text");

		button.label = "Unfollow";
		assertEquals("Unfollow", button.label, "label setter updates the property");
		assertNotNull(findLabelField(button, "Unfollow"), "label setter updates on-screen text");
		assertEquals(null, findLabelField(button, "Follow"), "old caption is replaced, not appended");
	}

	private static function testEnabledTogglesInteractivity():Void {
		var button = new FlButton("Ignore");
		assertEquals(true, button.mouseEnabled, "enabled button accepts the mouse");
		assertEquals(true, button.buttonMode, "enabled button shows the hand cursor");

		button.enabled = false;
		assertEquals(false, button.mouseEnabled, "disabled button ignores the mouse");
		assertEquals(false, button.buttonMode, "disabled button drops the hand cursor");
		assertEquals(false, button.useHandCursor, "disabled button drops the hand cursor flag");

		button.enabled = true;
		assertEquals(true, button.mouseEnabled, "re-enabling restores mouse handling");
	}

	private static function testDisabledAndEmphasizedAppearance():Void {
		var button = new FlButton("Continue");
		var up = firstSkin(button);
		button.emphasized = true;
		assertEquals(true, button.emphasized, "emphasized property is exposed");
		assertNotSame(up, firstSkin(button), "emphasized button uses its authored skin");

		button.enabled = false;
		var label = findLabelField(button, "Continue");
		assertNotNull(label, "disabled button retains its label");
		assertEquals(0x999999, label.getTextFormat().color, "disabled label uses the Flash component color");
	}

	private static function testSkinSwapsWithMouseState():Void {
		var button = new FlButton("Follow");
		var up = firstSkin(button);
		assertNotNull(up, "a real skin symbol is rendered for the up state");

		button.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
		var over = firstSkin(button);
		assertNotNull(over, "rollover renders a skin");
		assertNotSame(up, over, "rollover swaps to the over skin");

		button.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		var down = firstSkin(button);
		assertNotSame(over, down, "press swaps to the down skin");

		button.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
		var back = firstSkin(button);
		assertSame(up, back, "rolling out returns to the cached up skin");
	}

	private static function testAuthoredButtonSymbolMouseStates():Void {
		var button = PR2MovieClip.fromSymbolName("Buttons/CancelTextButton");
		assertEquals(1, button.currentFrame, "authored button starts on its up frame");
		assertEquals(true, button.buttonMode, "authored button exposes button cursor behavior");

		button.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
		assertEquals(2, button.currentFrame, "rollover shows the authored over frame");
		button.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals(3, button.currentFrame, "press shows the authored down frame");
		button.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
		assertEquals(2, button.currentFrame, "release inside returns to the over frame");
		button.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
		assertEquals(1, button.currentFrame, "rollout restores the up frame");
		button.dispose();
	}

	private static function testToggleFlipsSelectedOnClick():Void {
		var plain = new FlButton("Push");
		plain.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(false, plain.selected, "non-toggle buttons never become selected");

		var toggle = new FlButton("Sticky");
		toggle.toggle = true;
		toggle.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, toggle.selected, "toggle button selects on first click");
		toggle.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(false, toggle.selected, "toggle button deselects on second click");
	}

	private static function testClickReachesExternalListeners():Void {
		var button = new FlButton("Follow");
		var clicks = 0;
		button.addEventListener(MouseEvent.CLICK, function(_) clicks++);
		button.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		button.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(2, clicks, "external CLICK listeners still fire alongside toggle handling");
	}

	private static function testGeneratedPlayerInfoButtons():Void {
		var playerInfo = PR2MovieClip.fromSymbolName(PLAYER_INFO_SYMBOL, {maxNestedDepth: 12});

		// follow/friend/ignore/levels are fl Components/Button; messageButton is a
		// separate button symbol (Buttons/Symbol 1360), so it is excluded here.
		for (name in ["followButton", "friendButton", "ignoreButton", "levelsButton"]) {
			var button = Std.downcast(playerInfo.getChildByTimelineName(name), FlButton);
			assertNotNull(button, '$name is rendered as a real FlButton');
		}

		var follow = Std.downcast(playerInfo.getChildByTimelineName("followButton"), FlButton);
		assertEquals("Follow", follow.label, "followButton keeps its authored 'Follow' label");
		// The player popup flips this label when the viewer already follows.
		follow.label = "Unfollow";
		assertNotNull(findLabelField(follow, "Unfollow"), "followButton label can be reassigned at runtime");

		// Guests get the social buttons disabled in the source.
		follow.enabled = false;
		assertEquals(false, follow.mouseEnabled, "followButton can be disabled like the source does for guests");
	}

	private static function testGeneratedVaultButtonKeepsBlankComponentLabel():Void {
		var vault = PR2MovieClip.fromLinkage("PR2_Graphics_1_Apr_2014_fla.vualtButton_317", {maxNestedDepth: 8});
		var button = Std.downcast(vault.getChildByTimelineName("var_155"), FlButton);
		assertNotNull(button, "vault button nested component is rendered as a real FlButton");
		assertEquals("", button.label, "vault button component label matches Flash's blank label");
		assertEquals(null, findLabelField(button, "Button"), "vault button does not render the default Button caption");
		vault.dispose();
	}

	private static function firstSkin(button:FlButton):Null<DisplayObject> {
		// The skin holder is the first child added in the constructor.
		var holder = Std.downcast(button.getChildAt(0), openfl.display.Sprite);
		if (holder == null || holder.numChildren == 0) {
			return null;
		}
		return holder.getChildAt(0);
	}

	private static function findLabelField(container:openfl.display.DisplayObjectContainer, text:String):Null<openfl.text.TextField> {
		for (i in 0...container.numChildren) {
			var field = Std.downcast(container.getChildAt(i), openfl.text.TextField);
			if (field != null && field.text == text) {
				return field;
			}
		}
		return null;
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) {
			throw message;
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertSame(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected the same instance';
		}
	}

	private static function assertNotSame(unexpected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (unexpected == actual) {
			throw '$message: expected a different instance';
		}
	}
}
