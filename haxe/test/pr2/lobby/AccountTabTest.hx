package pr2.lobby;

import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.character.Parts;
import pr2.lobby.account.AccountCharacter;

import pr2.lobby.account.AccountCustomizeData;
import pr2.lobby.account.LoadoutsPopup;
import pr2.lobby.account.PartInfoPopup;
import pr2.lobby.account.PartPopup;
import pr2.lobby.account.PartPreview;
import pr2.lobby.account.PartSelector;
import pr2.lobby.account.PlayerDisplay;
import pr2.lobby.account.Presets;
import pr2.lobby.account.Settings;
import pr2.lobby.account.StatsSelect;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.lobby.dialogs.HoverDelayPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.level.CourseMenu;
import pr2.lobby.tabs.AccountTab;
import pr2.ui.GuildName;
import pr2.util.TestDisplayUtil as DisplayUtil;

class AccountTabTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		pr2.DeterministicTestMode.runTest("AccountTabTest.testCharacterGraphicScale", testCharacterGraphicScale);
		if (pr2.DeterministicTestMode.finishSmokeSuite("AccountTabTest")) return;
		pr2.DeterministicTestMode.runTest("AccountTabTest.testCustomizePayload", testCustomizePayload);
		pr2.DeterministicTestMode.runTest("AccountTabTest.testPartSelectorArrowsChangePart", testPartSelectorArrowsChangePart);
		pr2.DeterministicTestMode.runTest("AccountTabTest.testHatPartPreviewAnimations", testHatPartPreviewAnimations);
		pr2.DeterministicTestMode.runTest("AccountTabTest.testStatSlidersDoNotRunUnderRightArrow", testStatSlidersDoNotRunUnderRightArrow);
		pr2.DeterministicTestMode.runTest("AccountTabTest.testHotkeys", testHotkeys);
		pr2.DeterministicTestMode.runTest("AccountTabTest.testHoverDelayPopupCleanup", testHoverDelayPopupCleanup);
		pr2.DeterministicTestMode.runTest("AccountTabTest.testRandomizeStyleButtonUsesDelayedHover", testRandomizeStyleButtonUsesDelayedHover);
		pr2.DeterministicTestMode.runTest("AccountTabTest.testLoggedOutLoadoutUsesMessagePopup", testLoggedOutLoadoutUsesMessagePopup);
		trace('AccountTabTest passed $assertions assertions');
	}

	private static function testCharacterGraphicScale():Void {
		var character = new AccountCharacter();
		assertEquals(1, character.scaleX, "Flash Character wrapper remains at scale 1");
		assertEquals(1, character.display.scaleX, "CharacterGraphic container remains at scale 1");
		var stand = character.display.getChildByName("rigRoot");
		assertEquals(0.149993896484375, stand.scaleX, "native stand rig preserves its authored internal scaleX");
		assertEquals(0.149993896484375, stand.scaleY, "native stand rig preserves its authored internal scaleY");
		character.remove();
	}

	private static function testCustomizePayload():Void {
		var args = ["1", "2", "3", "4", "5", "6", "7", "8", "0,5,9", "1,6", "2,7", "3,8", "40", "50", "60", "21", "2", "4", "11", "12", "13", "14", "5,9", "6", "*", "", "1"];
		var data = AccountCustomizeData.parse(args);
		assertEquals(5, data.hat, "hat");
		assertEquals(3, data.hats.length, "owned hats");
		assertEquals(21, data.rank, "rank");
		assertEquals(14, data.feetColor2, "secondary feet color");
		assertEquals("*", data.epicBodies[0], "epic bodies");
		assertEquals(true, data.happyHour, "happy hour");
		assertEquals(null, AccountCustomizeData.parse(["short"]), "short payload rejected");
	}

	private static function testPartSelectorArrowsChangePart():Void {
		var selector = new PartSelector(["1", "4"], 1, 0, []);
		var changes = 0;
		selector.addEventListener(openfl.events.Event.CHANGE, function(_):Void changes++);

		@:privateAccess selector.arrows.rightButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(4, selector.getValue(), "right part-picker arrow selects the next owned part");
		@:privateAccess selector.arrows.leftButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, selector.getValue(), "left part-picker arrow selects the previous owned part");
		assertEquals(2, changes, "part-picker arrows dispatch changes to the character preview");
		selector.remove();
	}

	private static function testHatPartPreviewAnimations():Void {
		var propeller = new PartPreview("HAT", 4, true);
		var propellerSlot = propeller.character.display.hatSlot(0);
		assertNotNull(propellerSlot.getChildByName("animatedOverlay"), "lobby Propeller preview mounts its blade animation");
		var propellerFrame = @:privateAccess propeller.character.display.hatAnimationFrames[0];
		propeller.character.display.advanceOneFrame();
		assertEquals(true, @:privateAccess propeller.character.display.hatAnimationFrames[0] != propellerFrame,
			"lobby Propeller preview blade animation advances");
		propeller.remove();

		var jigg = new PartPreview("HAT", 13, true);
		var jiggSlot = jigg.character.display.hatSlot(0);
		assertNotNull(jiggSlot.getChildByName("animatedOverlay"), "lobby Jigg preview mounts its bubble animation");
		var jiggFrame = @:privateAccess jigg.character.display.hatAnimationFrames[0];
		jigg.character.display.advanceOneFrame();
		assertEquals(true, @:privateAccess jigg.character.display.hatAnimationFrames[0] != jiggFrame,
			"lobby Jigg preview bubble animation advances");
		jigg.remove();
	}

	private static function testStatSlidersDoNotRunUnderRightArrow():Void {
		var stats = new StatsSelect(150, 40, 50, 60);
		var speedSlider = @:privateAccess stats.speedSlider;
		var accelSlider = @:privateAccess stats.accelSlider;
		var jumpSlider = @:privateAccess stats.jumpnSlider;
		var decButton = Std.downcast(@:privateAccess speedSlider.decButton, openfl.display.Sprite);
		var incButton = Std.downcast(@:privateAccess speedSlider.incButton, openfl.display.Sprite);

		// Flash applies the 1.5625 XFL instance scale as a width change (80 * 1.5625)
		// so the SliderThumb keeps its authored width instead of stretching ~1.5x.
		assertEquals(125.0, @:privateAccess speedSlider.slider.controlWidth, "speed slider widens to the authored track width");
		assertEquals(125.0, @:privateAccess accelSlider.slider.controlWidth, "acceleration slider widens to the authored track width");
		assertEquals(125.0, @:privateAccess jumpSlider.slider.controlWidth, "jumping slider widens to the authored track width");
		assertEquals(1.0, @:privateAccess speedSlider.slider.scaleX, "speed slider keeps unit scale so the thumb is not smeared");
		assertEquals(1.0, @:privateAccess accelSlider.slider.scaleX, "acceleration slider keeps unit scale so the thumb is not smeared");
		assertEquals(1.0, @:privateAccess jumpSlider.slider.scaleX, "jumping slider keeps unit scale so the thumb is not smeared");
		assertEquals(24.0, decButton.width, "left stat arrow has a larger square hitbox");
		assertEquals(24.0, decButton.height, "left stat arrow hitbox is square");
		assertEquals(24.0, incButton.width, "right stat arrow has a larger square hitbox");
		assertEquals(24.0, incButton.height, "right stat arrow hitbox is square");
		assertEquals(true, @:privateAccess incButton.graphics.__hitTest(-5, -2, true, new openfl.geom.Matrix()),
			"right stat arrow accepts a point outside its triangle but inside the square target");
		stats.remove();
	}

	private static function testHotkeys():Void {
		assertEquals(1, AccountTab.keyToSlot(49), "number one");
		assertEquals(10, AccountTab.keyToSlot(48), "number zero");
		assertEquals(5, AccountTab.keyToSlot(101), "numpad five");
		assertEquals(-1, AccountTab.keyToSlot(65), "non-number");
	}

	private static function testLoggedOutLoadoutUsesMessagePopup():Void {
		Settings.clear();
		assertEquals(false, @:privateAccess LoadoutsPopup.canLoadSelected(), "logged-out loadout selection is rejected");
		var open = Popup.getOpen();
		var message = Std.downcast(open[open.length - 1], MessagePopup);
		assertNotNull(message, "logged-out loadout selection opens Flash MessagePopup");
		message.remove();
	}

	private static function testHoverDelayPopupCleanup():Void {
		var wrapper = new HoverDelayPopup("Title", "Body", 500);
		@:privateAccess wrapper.showPopup();
		assertNotNull(wrapper.hover, "direct show creates delayed hover popup");
		wrapper.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals(null, wrapper.hover, "mouse down hides shown hover popup");
		@:privateAccess wrapper.showPopup();
		wrapper.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(null, wrapper.hover, "mouse out hides shown hover popup");
		@:privateAccess wrapper.showPopup();
		wrapper.remove();
		assertEquals(null, wrapper.hover, "remove cleans shown hover popup");
	}

	private static function testRandomizeStyleButtonUsesDelayedHover():Void {
		var character = new AccountCharacter();
		var display = new PlayerDisplay(character, ["1", "2"], ["1", "2"], ["1", "2"], ["1", "2"], 1, 1, 1, 1, 0, 0, 0, 0,
			["1"], ["1"], ["1"], ["1"], 0, 0, 0, 0);
		var button = @:privateAccess display.randomButton;
		assertNotNull(button, "player display mounts randomize button");
		assertEquals("Randomize Style", button.title, "randomize button hover title");
		assertEquals("Create a random style for your character. Remember to save your current style if you like it first!", button.content,
			"randomize button hover copy");
		var randomGraphic = @:privateAccess display.randomGraphic;
		assertNotNull(randomGraphic, "randomize button mounts item-block graphic");
		assertEquals("ItemBlock", randomGraphic.name, "randomize button uses item block art");
		assertEquals(15.0, randomGraphic.width, "randomize item block is small");
		assertEquals(15.0, randomGraphic.height, "randomize item block stays square");
		display.remove();
		character.remove();
	}

	private static function fieldHtml(container:Dynamic, name:String):String {
		var field = Std.downcast(DisplayUtil.findByName(container, name), TextField);
		return field == null ? "" : field.htmlText;
	}

	private static function customizeArgs():Array<String> {
		return ["1", "2", "3", "4", "5", "6", "7", "8", "0,5,9", "1,6", "2,7", "3,8", "40", "50", "60", "21", "2",
			"4", "11", "12", "13", "14", "5,9", "6", "*", "", "1"];
	}

	private static function closeAllPopups():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
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

	private static function assertContains(haystack:String, needle:String, message:String):Void {
		assertions++;
		if (haystack == null || haystack.indexOf(needle) < 0) throw '$message: expected to find $needle in $haystack';
	}

	private static function assertNotContains(haystack:String, needle:String, message:String):Void {
		assertions++;
		if (haystack != null && haystack.indexOf(needle) >= 0) throw '$message: did not expect to find $needle in $haystack';
	}
}
