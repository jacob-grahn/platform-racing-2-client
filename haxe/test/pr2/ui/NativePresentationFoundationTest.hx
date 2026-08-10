package pr2.ui;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.ui.Keyboard;
import pr2.animation.AnimationClip;
import pr2.animation.AnimationClock;
import pr2.animation.AnimationGroup;
import pr2.animation.PlaybackState;
import pr2.assets.NativeAssetIds.BitmapAsset;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.SoundAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.ConfirmDialogView;
import pr2.lobby.dialogs.MessageDialogView;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.page.CreateAccountView;
import pr2.page.ForgotPasswordView;
import pr2.page.LoginFlashPopup;
import pr2.ui.controls.ControlState;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.controls.GameScrollBar;
import pr2.ui.controls.GameSelect;
import pr2.ui.controls.GameSlider;
import pr2.ui.controls.GameTextInput;
import pr2.ui.controls.GameTextArea;
import pr2.ui.controls.NativeControl;
import pr2.ui.controls.SliderControlSkin;
import pr2.ui.view.NativeView;
import pr2.ui.view.StatusPopupView;

class NativePresentationFoundationTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		pr2.DeterministicTestMode.runTest("NativePresentationFoundationTest.testTypedAssetIds", testTypedAssetIds);
		if (pr2.DeterministicTestMode.finishSmokeSuite("NativePresentationFoundationTest")) return;
		pr2.DeterministicTestMode.runTest("NativePresentationFoundationTest.testAnimationPlayback", testAnimationPlayback);
		pr2.DeterministicTestMode.runTest("NativePresentationFoundationTest.testAnimationCompositionAndOwnership", testAnimationCompositionAndOwnership);
		pr2.DeterministicTestMode.runTest("NativePresentationFoundationTest.testControlParityContracts", testControlParityContracts);
		pr2.DeterministicTestMode.runTest("NativePresentationFoundationTest.testFocusKeyboardAndTeardown", testFocusKeyboardAndTeardown);
		pr2.DeterministicTestMode.runTest("NativePresentationFoundationTest.testFlashTabOrdering", testFlashTabOrdering);
		pr2.DeterministicTestMode.runTest("NativePresentationFoundationTest.testTypedViewOwnership", testTypedViewOwnership);
		pr2.DeterministicTestMode.runTest("NativePresentationFoundationTest.testConfirmDialogAuthoredContract", testConfirmDialogAuthoredContract);
		pr2.DeterministicTestMode.runTest("NativePresentationFoundationTest.testPopupStackLifecycle", testPopupStackLifecycle);
		pr2.DeterministicTestMode.runTest("NativePresentationFoundationTest.testNativeLoginPopupRoots", testNativeLoginPopupRoots);
		pr2.DeterministicTestMode.runTest("NativePresentationFoundationTest.testMessagePopupAuthoredContract", testMessagePopupAuthoredContract);
		trace('NativePresentationFoundationTest passed $assertions assertions');
	}

	private static function testTypedAssetIds():Void {
		assertEquals("assets/svg/stamps/rock1.svg", cast StaticSvg.RockStamp, "static SVG has a typed semantic id");
		assertEquals("assets/blocks/basic1.png", cast BitmapAsset.BasicBlock, "bitmap has a typed semantic id");
		assertEquals("Arial", cast FontAsset.Body, "font has a typed semantic id");
		assertEquals("assets/audio/sfx/jump.mp3", cast SoundAsset.Jump, "sound has a typed semantic id");
	}

	private static function testAnimationPlayback():Void {
		var shown = -1;
		var completed = 0;
		var clip = AnimationClip.frames(3, function(frame) shown = frame);
		clip.onComplete = function() completed++;
		assertEquals(0, shown, "frame sequence renders its initial frame");
		clip.play();
		clip.advance(2);
		assertEquals(2, shown, "frame sequence advances from the simulation clock");
		clip.pause();
		clip.advance(1);
		assertEquals(2, shown, "paused animation does not advance");
		clip.play();
		clip.advance(1);
		assertEquals(PlaybackState.Completed, clip.state, "non-looping clip completes explicitly");
		assertEquals(2, shown, "completion holds the final sequence frame");
		assertEquals(1, completed, "completion callback fires once");

		var property = 0.0;
		var tween = AnimationClip.tween(4, 10, 18, function(value) property = value);
		tween.play();
		tween.advance(2);
		assertEquals(14.0, property, "property tween interpolates deterministically");
		tween.stop();
		assertEquals(10.0, property, "stopping restores the initial property");

		var loop = AnimationClip.frames(3, function(frame) shown = frame, true);
		loop.play();
		loop.advance(4);
		assertEquals(1, loop.currentFrame, "looping wraps excess simulation frames");
	}

	private static function testAnimationCompositionAndOwnership():Void {
		var first = AnimationClip.frames(2, function(_) {});
		var second = AnimationClip.frames(4, function(_) {});
		var group = new AnimationGroup([first, second]);
		var clock = new AnimationClock();
		clock.add(group);
		group.play();
		clock.advance(4);
		assertEquals(PlaybackState.Completed, group.state, "composed clip completes at its longest child");
		clock.dispose();
		assertEquals(PlaybackState.Disposed, group.state, "clock tears down owned animation");
		assertEquals(PlaybackState.Disposed, first.state, "group tears down child animation");
	}

	private static function testControlParityContracts():Void {
		var nativeButton = new GameButton("Follow");
		assertEquals(cast StaticSvg.ButtonUp, cast @:privateAccess nativeButton.authoredAsset(), "default button starts on exact authored up skin");
		nativeButton.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
		assertEquals(cast StaticSvg.ButtonOver, cast @:privateAccess nativeButton.authoredAsset(), "button hover selects exact authored over skin");
		nativeButton.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals(cast StaticSvg.ButtonDown, cast @:privateAccess nativeButton.authoredAsset(), "button press selects exact authored down skin");
		nativeButton.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
		nativeButton.toggle = true;
		nativeButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, nativeButton.selected, "button toggle selects the control");
		assertEquals(cast StaticSvg.ButtonSelectedOver, cast @:privateAccess nativeButton.authoredAsset(), "selected hovered button uses authored combined state");
		nativeButton.enabled = false;
		assertEquals(false, nativeButton.mouseEnabled, "disabled button ignores pointer input");
		assertEquals(cast StaticSvg.ButtonSelectedDisabled, cast @:privateAccess nativeButton.authoredAsset(), "selected disabled button uses authored combined state");
		assertEquals(0x555555, nativeButton.labelField.textColor, "disabled button uses the authored component label color");
		assertEquals(5.0, nativeButton.labelField.x, "button reserves the authored five-pixel label gutter");
		assertEquals(90.0, nativeButton.labelField.width, "button label width excludes both authored gutters");
		var buttonBackground = @:privateAccess nativeButton.authoredBackground;
		assertEquals(null, buttonBackground.scale9Grid, "button wrapper does not nine-slice and clip its child on HTML5");
		assertEquals(true, buttonBackground.getChildAt(0).scale9Grid != null, "button nine-slices the authored vector itself");
		var emphasized = new GameButton("Primary");
		emphasized.emphasized = true;
		assertEquals(cast StaticSvg.ButtonEmphasized, cast @:privateAccess emphasized.authoredAsset(), "emphasized button uses exact authored emphasized skin");

		var nativeBox = new GameCheckBox("Mute");
		assertEquals(true, nativeBox.getBounds(nativeBox).right >= 100, "checkbox keeps a stable full-width HTML5 hit area");
		assertEquals(cast StaticSvg.CheckBoxUp, cast @:privateAccess nativeBox.authoredAsset(), "checkbox starts on exact authored up icon");
		nativeBox.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
		assertEquals(cast StaticSvg.CheckBoxOver, cast @:privateAccess nativeBox.authoredAsset(), "checkbox hover uses exact authored over icon");
		nativeBox.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
		var nativeChanges = 0;
		nativeBox.addEventListener(Event.CHANGE, function(_) nativeChanges++);
		nativeBox.selected = true;
		assertEquals(cast StaticSvg.CheckBoxSelectedUp, cast @:privateAccess nativeBox.authoredAsset(), "programmatic selection uses authored selected-up icon");
		assertEquals(0, nativeChanges, "programmatic checkbox changes are silent");
		nativeBox.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(false, nativeBox.selected, "checkbox click toggles its selected state");
		assertEquals(1, nativeChanges, "checkbox click dispatches one change event");
		nativeBox.enabled = false;
		assertEquals(false, nativeBox.mouseEnabled, "disabled checkbox ignores pointer input");
		assertEquals(cast StaticSvg.CheckBoxDisabled, cast @:privateAccess nativeBox.authoredAsset(), "disabled unchecked box uses authored disabled icon");
		assertEquals(18.0, nativeBox.labelField.x, "checkbox label keeps the authored icon-plus-four-pixel gap");

		var nativeSlider = new GameSlider(0, 10, 3, 1);
		nativeSlider.value = 20;
		assertEquals(10.0, nativeSlider.value, "slider clamps to its maximum");
		nativeSlider.value = 5;
		@:privateAccess nativeSlider.thumb.dispatchEvent(new MouseEvent(MouseEvent.CLICK, true, false, 0, 0));
		assertEquals(5.0, nativeSlider.value, "thumb release click uses slider coordinates instead of resetting from thumb-local zero");
	}

	private static function testFocusKeyboardAndTeardown():Void {
		var presses = 0;
		var button = new GameButton("OK");
		button.onPress = function() presses++;
		NativeControl.showFocusIndicator = true;
		button.focus();
		button.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.ENTER));
		assertEquals(true, button.focused, "control exposes explicit focus state");
		assertEquals(1, presses, "focused button activates from Enter");
		assertEquals(true, @:privateAccess button.focusIndicator.visible, "keyboard-focused native button shows the authored Flash focus outline");
		button.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals(true, button.focused, "pointer press still focuses the control");
		assertEquals(false, @:privateAccess button.focusIndicator.visible, "pointer-focused control hides the outline like Flash showFocusIndicator");
		button.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
		assertEquals(cast ControlState.Normal, cast button.state(), "pointer focus does not leave the control in the Focused skin state");
		NativeControl.showFocusIndicator = true;
		button.focus();
		assertEquals(true, button.tabEnabled, "enabled native button participates in Tab navigation");
		button.enabled = false;
		assertEquals(false, button.tabEnabled, "disabled native button leaves the Tab order like Flash UIComponent");
		assertEquals(false, @:privateAccess button.focusIndicator.visible, "disabled native button hides the focus outline");
		button.enabled = true;
		assertEquals(true, button.tabEnabled, "re-enabled native button returns to the Tab order");
		var lobbyActivations = 0;
		var lobbyBinding = LobbyArt.bind(button, function():Void lobbyActivations++);
		button.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.ENTER));
		assertEquals(2, presses, "button keeps its own keyboard activation callback when lobby wiring is attached");
		assertEquals(1, lobbyActivations, "lobby click wiring also responds to keyboard activation");
		button.dispatchEvent(new Event(Event.ACTIVATE));
		assertEquals(1, lobbyActivations, "browser lifecycle activation does not press the focused button");
		LobbyArt.unbind(lobbyBinding);
		button.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.ENTER));
		assertEquals(1, lobbyActivations, "removing lobby wiring also removes its keyboard activation listener");
		button.dispose();
		button.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(3, presses, "disposed button removes click callbacks");

		var slider = new GameSlider(0, 10, 5, 1);
		var fallbackTrack = new Shape();
		new SliderControlSkin().draw(fallbackTrack.graphics, 80, 22, pr2.ui.controls.ControlState.Normal);
		assertEquals(0.0, fallbackTrack.width, "slider omits the obsolete fallback track behind the authored SVG");
		assertEquals("slider_track_up", slider.trackAssetForTests(), "slider starts with exact XFL track skin");
		assertEquals("slider_thumb_up", slider.thumbAssetForTests(), "slider starts with exact XFL thumb skin");
		@:privateAccess slider.thumb.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
		assertEquals("slider_thumb_over", slider.thumbAssetForTests(), "slider hover uses exact XFL thumb-over skin");
		@:privateAccess slider.thumb.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals("slider_thumb_down", slider.thumbAssetForTests(), "slider press uses exact XFL thumb-down skin");
		slider.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.RIGHT));
		assertEquals(6.0, slider.value, "slider supports arrow keyboard input");
		slider.enabled = false;
		assertEquals("slider_track_disabled", slider.trackAssetForTests(), "disabled slider uses exact XFL track skin");
		assertEquals("slider_thumb_disabled", slider.thumbAssetForTests(), "disabled slider uses exact XFL thumb skin");
		var select = new GameSelect<String>();
		assertEquals(true, select.getBounds(select).right >= 100, "select keeps a stable component-sized HTML5 hit area");
		assertEquals(cast StaticSvg.ComboBoxUp, cast @:privateAccess select.authoredAsset(), "select starts on exact authored ComboBox up skin");
		select.addOption("One", "one");
		select.addOption("Two", "two");
		select.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.DOWN));
		assertEquals("one", select.selectedOption.value, "select supports keyboard navigation");
		select.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, select.open, "select opens its option list from a mouse click");
		assertEquals(cast StaticSvg.ComboBoxDown, cast @:privateAccess select.authoredAsset(), "open select uses exact authored down skin");
		var options = Std.downcast(select.getChildByName("options"), openfl.display.Sprite);
		assertEquals(true, options != null, "open select renders mouse-selectable options");
		options.getChildByName("option_1").dispatchEvent(new MouseEvent(MouseEvent.CLICK, true));
		assertEquals("two", select.selectedOption.value, "select chooses an option from the mouse");
		assertEquals(false, select.open, "select closes after a mouse selection");
		select.removeAll();
		for (index in 0...7) select.addOption('Option $index', 'value_$index');
		select.rowCount = 3;
		select.selectedIndex = 6;
		select.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		options = Std.downcast(select.getChildByName("options"), openfl.display.Sprite);
		assertEquals(true, options.getChildByName("option_4") != null, "open list scrolls to include the selected row");
		assertEquals(true, options.getChildByName("option_6") != null, "rowCount includes the selected final row");
		assertEquals(null, options.getChildByName("option_3"), "rowCount clips rows before the visible window");
		options.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL, true, false, 0, 0, null, false, false, false, false, -1));
		assertEquals(4, @:privateAccess select.scrollOffset, "mouse wheel clamps scrolling at the final full row window");
		select.close();
		select.enabled = false;
		assertEquals(cast StaticSvg.ComboBoxDisabled, cast @:privateAccess select.authoredAsset(), "disabled select uses exact authored disabled skin");
		assertEquals(0x999999, select.labelField.textColor, "disabled select uses authored caption color");
		var scroll = new GameScrollBar(0, 100, 20, 2);
		assertEquals(cast StaticSvg.ScrollArrowUpUpAuthored, cast @:privateAccess scroll.arrowAsset(true, false, false), "scrollbar starts with exact authored up-arrow skin");
		assertEquals(cast StaticSvg.ScrollThumbUpAuthored, cast @:privateAccess scroll.thumbAsset(), "scrollbar starts with exact authored thumb skin");
		assertEquals(15.0, scroll.controlWidth, "authored scrollbar retains its 15-pixel width");
		scroll.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.PAGE_DOWN));
		assertEquals(20.0, scroll.value, "scroll bar supports page keyboard input");
		@:privateAccess scroll.downArrow.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
		assertEquals(cast StaticSvg.ScrollArrowDownOverAuthored, cast @:privateAccess scroll.arrowAsset(false, true, false), "scrollbar hover selects exact authored down-arrow over skin");
		@:privateAccess scroll.downArrow.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(22.0, scroll.value, "scrollbar arrow advances by lineStep");
		scroll.enabled = false;
		assertEquals(cast StaticSvg.ScrollArrowDownDisabledAuthored, cast @:privateAccess scroll.arrowAsset(false, false, false), "disabled scrollbar selects exact authored arrow skin");
		var input = new GameTextInput("hello");
		assertEquals(cast StaticSvg.TextInputUp, cast @:privateAccess input.authoredAsset(), "text input starts with exact authored up skin");
		assertEquals(true, input.tabEnabled, "TextInput component participates in the Flash tab order");
		assertEquals(false, input.textField.tabEnabled, "TextInput internal field does not create a duplicate tab stop");
		assertEquals(5.0, input.textField.x, "text input keeps the authored component five-pixel horizontal padding");
		assertEquals(1.0, input.textField.y, "text input leaves one pixel for the authored bevel");
		assertEquals(90.0, input.textField.width, "text input text width excludes both authored horizontal gutters");
		var inputBackground = @:privateAccess input.authoredBackground;
		assertEquals(null, inputBackground.scale9Grid, "text input wrapper does not nine-slice and clip its child on HTML5");
		assertEquals(true, inputBackground.getChildAt(0).scale9Grid != null, "text input nine-slices the authored vector itself");
		input.displayAsPassword = true;
		input.restrict = "A-Z0-9";
		input.maxChars = 20;
		assertEquals(true, input.textField.displayAsPassword, "text input forwards password display to its native field");
		assertEquals("A-Z0-9", input.textField.restrict, "text input forwards authored character restrictions");
		assertEquals(20, input.textField.maxChars, "text input forwards authored maximum length");
		input.setSelection(1, 4);
		assertEquals(1, input.selectionBeginIndex, "text input exposes the native selection start");
		assertEquals(4, input.selectionEndIndex, "text input exposes the native selection end");
		var inputChanges = 0;
		input.addEventListener(Event.CHANGE, function(_) inputChanges++);
		input.textField.dispatchEvent(new Event(Event.CHANGE));
		assertEquals(1, inputChanges, "text input rebroadcasts field changes from the component like fl.controls.TextInput");
		input.editable = false;
		assertEquals(false, input.editable, "text input exposes typed editable state");
		input.enabled = false;
		assertEquals(false, input.textField.selectable, "disabled text input removes selection and editing");
		assertEquals(cast StaticSvg.TextInputDisabled, cast @:privateAccess input.authoredAsset(), "disabled text input uses exact authored disabled skin");
		assertEquals(0x999999, input.textField.textColor, "disabled text input uses the authored disabled text color");

		var area = new GameTextArea(200, 80);
		assertEquals(cast StaticSvg.TextAreaUp, cast @:privateAccess area.authoredAsset(), "text area starts with exact authored up skin");
		assertEquals(false, area.textField.tabEnabled, "TextArea internal field does not create a duplicate tab stop");
		assertEquals(true, area.textField.multiline, "text area preserves authored multiline behavior");
		assertEquals(true, area.textField.wordWrap, "text area preserves authored default word wrapping");
		assertEquals(3.0, area.textField.x, "text area keeps the authored inner text inset");
		assertEquals(194.0, area.textField.width, "short text area content uses the full authored inner width");
		assertEquals(184.0, area.verticalScrollBar.x, "text area docks the 15-pixel authored scrollbar at the right inset");
		assertEquals(false, area.verticalScrollBar.visible, "default auto policy hides the scrollbar without overflow");
		area.text = "one\ntwo\nthree\nfour\nfive\nsix\nseven\neight";
		assertEquals(true, area.textField.maxScrollV >= 1, "text area synchronizes multiline content with its scroll target");
		assertEquals(true, area.verticalScrollBar.visible, "default auto policy reveals the authored scrollbar for overflow");
		assertEquals(179.0, area.textField.width, "overflowing text reserves the authored scrollbar and text gutters");
		area.verticalScrollPolicy = "off";
		assertEquals(false, area.verticalScrollBar.visible, "off policy hides the authored scrollbar");
		assertEquals(194.0, area.textField.width, "off policy restores the full text width");
		area.editable = false;
		assertEquals(TextFieldType.DYNAMIC, area.textField.type, "non-editable text area remains selectable but stops accepting input");
		area.enabled = false;
		assertEquals(cast StaticSvg.TextAreaDisabled, cast @:privateAccess area.authoredAsset(), "disabled text area uses exact authored disabled skin");
		assertEquals(false, area.textField.selectable, "disabled text area removes selection");
		area.dispose();
	}

	private static function testFlashTabOrdering():Void {
		var root = new Sprite();
		var lower = new GameButton("Lower");
		lower.x = 10;
		lower.y = 80;
		root.addChild(lower);
		var upperRight = new GameButton("Upper right");
		upperRight.x = 100;
		upperRight.y = 20;
		var renderedSkinChild = new Sprite();
		renderedSkinChild.tabEnabled = true;
		upperRight.addChild(renderedSkinChild);
		root.addChild(upperRight);
		var upperLeft = new GameTextInput();
		upperLeft.x = 10;
		upperLeft.y = 20;
		root.addChild(upperLeft);
		var disabled = new GameButton("Disabled");
		disabled.y = 5;
		disabled.enabled = false;
		root.addChild(disabled);
		var ordered = @:privateAccess KeyboardFocusManager.orderedCandidates(root);
		assertEquals(3, ordered.length, "Flash tab order treats native components as atomic and excludes disabled controls");
		assertEquals(upperLeft, ordered[0], "automatic Flash tab order starts at the upper-left control");
		assertEquals(upperRight, ordered[1], "automatic Flash tab order moves left-to-right on a row");
		assertEquals(lower, ordered[2], "automatic Flash tab order then moves top-to-bottom");
		assertEquals(0, @:privateAccess KeyboardFocusManager.candidateIndex(ordered, upperLeft.textField),
			"focus delegated to a TextInput field resolves back to its component tab stop");
		lower.tabIndex = 2;
		upperRight.tabIndex = 1;
		ordered = @:privateAccess KeyboardFocusManager.orderedCandidates(root);
		assertEquals(2, ordered.length, "authored tabIndex order excludes automatic controls like Flash");
		assertEquals(upperRight, ordered[0], "authored tabIndex sorts in ascending order");
		assertEquals(lower, ordered[1], "authored tabIndex retains the remaining indexed control");
	}

	private static function testTypedViewOwnership():Void {
		var view = new ExampleDialogView();
		var clicks = 0;
		view.listen(view.confirmButton, MouseEvent.CLICK, function(_) clicks++);
		view.confirmButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, clicks, "typed view listener receives events before teardown");
		view.dispose();
		view.confirmButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, clicks, "typed view removes owned listeners");
		assertEquals(true, view.confirmButton.disposed, "typed view disposes owned controls");
		assertEquals(PlaybackState.Disposed, view.openAnimation.state, "typed view disposes owned animations");
	}

	private static function testConfirmDialogAuthoredContract():Void {
		var view = new ConfirmDialogView("<b>Are you sure?</b>");
		assertClose(-155, view.messageArea.x, "confirm TextArea X matches XFL");
		assertClose(-65, view.messageArea.y, "confirm TextArea Y matches XFL");
		assertClose(309.109497070313, view.messageArea.controlWidth, "confirm TextArea consumes its XFL X scale as component width");
		assertClose(99.966796875, view.messageArea.controlHeight, "confirm TextArea consumes its XFL Y scale over the 44px component avatar");
		assertClose(1, view.messageArea.scaleX, "confirm TextArea does not magnify its component text horizontally");
		assertClose(1, view.messageArea.scaleY, "confirm TextArea does not magnify its component text vertically");
		assertClose(11, view.message.defaultTextFormat.size, "confirm TextArea keeps the original component font size");
		assertEquals(false, view.messageArea.editable, "confirm TextArea is non-editable as authored");
		assertEquals("Are you sure?", view.message.text, "confirm text area accepts the authored HTML content path");
		view.messageArea.text = [
			"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
			"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"
		].join("\n");
		assertEquals(true, view.messageArea.verticalScrollBar.visible, "long confirmation text reveals the authored scrollbar");
		assertEquals(true, view.message.maxScrollV > 1, "long confirmation text exposes a scrollable native text range");
		assertClose(-124, view.confirmButton.x, "confirm OK button X matches XFL");
		assertClose(43, view.confirmButton.y, "confirm OK button Y matches XFL");
		assertClose(22, view.cancelButton.x, "confirm Cancel button X matches XFL");
		var confirms = 0;
		var cancels = 0;
		view.onConfirm = function():Void confirms++;
		view.onCancel = function():Void cancels++;
		view.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.ENTER));
		view.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.ESCAPE));
		assertEquals(0, confirms, "unfocused Enter does not invent a ConfirmPopup shortcut absent from AS3");
		assertEquals(0, cancels, "Escape does not invent a ConfirmPopup shortcut absent from AS3");
		view.confirmButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		view.cancelButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, confirms, "authored OK button invokes confirmation once");
		assertEquals(1, cancels, "authored Cancel button invokes cancellation once");
		view.dispose();
	}

	private static function testPopupStackLifecycle():Void {
		for (popup in Popup.getOpen().copy()) popup.remove();
		var resets = 0;
		var focused:openfl.display.InteractiveObject = null;
		StageFocus.resetHook = function():Void resets++;
		StageFocus.focusHook = function(target):Void focused = target;
		var parent = new MessagePopup("Parent popup");
		parent.layoutForSizeForTests(1100, 800);
		assertClose(2, parent.scaleX, "popup resize uses uniform authored-stage density");
		assertClose(550, parent.x, "popup resize centers x");
		assertClose(400, parent.y, "popup resize centers y");
		var overlay = parent.overlayForTests();
		assertClose(550, overlay.width, "scaled popup overlay keeps stage-local width");
		assertClose(400, overlay.height, "scaled popup overlay keeps stage-local height");
		assertClose(-275, overlay.x, "scaled popup overlay stays centered locally");
		parent.layoutForSizeForTests(1200, 400);
		assertClose(1, parent.scaleX, "wide resize does not upscale past limiting height");
		assertClose(1200, overlay.width, "wide resize expands modal hit cover across stage");
		assertClose(-600, overlay.x, "wide resize centers expanded modal hit cover");

		var child = new MessagePopup("Nested child");
		assertEquals(false, parent.isTopmostForTests(), "parent popup yields hit stacking to nested child");
		assertEquals(true, child.isTopmostForTests(), "newest nested popup owns topmost hit layer");
		for (_ in 0...7) child.dispatchEvent(new Event(Event.ENTER_FRAME));
		child.startFadeOut();
		child.startFadeOut();
		for (_ in 0...7) child.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(false, Popup.getOpen().contains(child), "repeated fade request removes nested child exactly once");
		assertEquals(parent, focused, "nested child close restores focus to still-open parent popup");
		assertEquals(0, resets, "nested child close does not reset focus to stage");
		child.remove();
		assertEquals(0, resets, "repeated nested remove is idempotent");
		parent.remove();
		parent.remove();
		assertEquals(1, resets, "top-level repeated remove resets stage focus exactly once");
		assertEquals(0, Popup.getOpen().length, "popup stack is empty after parent teardown");
		StageFocus.resetHooks();
	}

	private static function testNativeLoginPopupRoots():Void {
		var login = new LoginFlashPopup("LoginPopupGraphic");
		var forgotButton = Std.downcast(login.child("forgotPass"), openfl.display.InteractiveObject);
		assertEquals(true, forgotButton != null && forgotButton.tabEnabled, "login forgot-password SimpleButton remains reachable with Tab");
		var forgotContainer = Std.downcast(forgotButton, openfl.display.DisplayObjectContainer);
		var forgotLabel = Std.downcast(forgotContainer.getChildAt(0), TextField);
		assertEquals(10, forgotLabel.defaultTextFormat.size, "tab support preserves the original forgot-password font size");
		var forgotActivations = 0;
		login.bindButton("forgotPass", function():Void forgotActivations++);
		forgotButton.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.ENTER));
		assertEquals(1, forgotActivations, "login popup buttons activate from the keyboard like Flash buttons");
		login.remove();

		var forgotHolder = new openfl.display.Sprite();
		var forgot = new ForgotPasswordView("Jiggmin");
		forgotHolder.addChild(forgot);
		assertClose(0, forgot.alpha, "forgot-password popup starts at zero alpha like dialogs.Popup");
		assertClose(-100, forgot.getChildAt(0).x, "forgot-password ShadowBG keeps its XFL X");
		assertClose(-109, forgot.getChildAt(0).y, "forgot-password ShadowBG keeps its XFL Y");
		assertClose(-36, forgot.nameInput.x, "forgot-password name input keeps its XFL X");
		assertClose(-62, forgot.nameInput.y, "forgot-password name input keeps its XFL Y");
		assertEquals("Jiggmin", forgot.nameInput.text, "forgot-password preserves the prefilled login name");
		var forgotSubmits = 0;
		forgot.onSubmit = function():Void forgotSubmits++;
		forgot.nameInput.textField.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.ENTER));
		assertEquals(1, forgotSubmits, "forgot-password submits from Enter on either authored input");
		for (_ in 0...7) forgot.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(1, forgot.alpha, "forgot-password reaches full alpha after the authored seven fade frames");
		forgot.startFadeOut();
		for (_ in 0...7) forgot.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(0, forgotHolder.numChildren, "forgot-password removes itself after the authored fade-out");

		var create = new CreateAccountView("name", "pass", "confirm", "mail");
		assertClose(-121.9, create.getChildAt(0).x, "create-account ShadowBG keeps its XFL X");
		assertClose(-130.35, create.getChildAt(0).y, "create-account ShadowBG keeps its XFL Y");
		assertClose(2, create.nameInput.x, "create-account name input keeps its XFL X");
		assertClose(-85, create.nameInput.y, "create-account name input keeps its XFL Y");
		assertClose(110.000610351562, create.nameInput.controlWidth, "create-account input keeps its XFL component width");
		assertEquals(20, create.nameInput.maxChars, "create-account name keeps its authored maximum length");
		assertEquals(true, create.passwordInput.displayAsPassword, "create-account password uses the authored password display");
		assertEquals(true, create.confirmationInput.displayAsPassword, "create-account confirmation uses the authored password display");
		var creates = 0;
		create.onSubmit = function():Void creates++;
		create.nameInput.textField.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.ENTER));
		assertEquals(0, creates, "create-account does not invent Enter submission absent from its AS3 owner");
		create.submitButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, creates, "create-account submits from its authored button");
		create.dispose();

		var logging = new StatusPopupView("Logging In...");
		assertClose(-81.4, logging.getChildAt(0).x, "logging-in ShadowBG keeps its XFL X");
		assertClose(-48, logging.getChildAt(0).y, "logging-in ShadowBG keeps its XFL Y");
		var loggingLabel = Std.downcast(logging.getChildAt(1), TextField);
		assertEquals("Logging In...", loggingLabel.text, "logging-in keeps exact authored copy");
		assertClose(-37.4, loggingLabel.x, "logging-in label keeps its XFL X");
		assertClose(-28.2, loggingLabel.y, "logging-in label keeps its XFL Y");
		assertClose(-48.4, logging.closeButton.x, "logging-in Close button keeps its XFL X");
		assertClose(10, logging.closeButton.y, "logging-in Close button keeps its XFL Y");
		logging.dispose();
	}

	private static function testMessagePopupAuthoredContract():Void {
		var view = new MessageDialogView("<b>Server message</b>");
		assertClose(-166.5, view.getChildAt(0).x, "message popup ShadowBG keeps its XFL X");
		assertClose(-75, view.getChildAt(0).y, "message popup ShadowBG keeps its XFL Y");
		assertClose(-155, view.messageArea.x, "message TextArea keeps its XFL X");
		assertClose(-65, view.messageArea.y, "message TextArea keeps its XFL Y");
		assertClose(309.109497070313, view.messageArea.controlWidth, "message TextArea consumes its XFL X scale as component width");
		assertClose(99.966796875, view.messageArea.controlHeight, "message TextArea consumes its XFL Y scale over the 44px component avatar");
		assertClose(1, view.messageArea.scaleX, "message TextArea does not magnify its component text horizontally");
		assertClose(1, view.messageArea.scaleY, "message TextArea does not magnify its component text vertically");
		assertClose(11, view.message.defaultTextFormat.size, "message TextArea keeps the original component font size");
		assertEquals(true, view.messageArea.y + view.messageArea.controlHeight < view.okButton.y,
			"message TextArea ends above the OK button");
		assertEquals(false, view.messageArea.editable, "message TextArea is non-editable as authored");
		assertEquals("Server message", view.message.text, "message popup applies its AS3 htmlText assignment");
		view.messageArea.text = [
			"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
			"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"
		].join("\n");
		assertEquals(true, view.messageArea.verticalScrollBar.visible, "long message text reveals the authored scrollbar");
		assertEquals(true, view.message.maxScrollV > 1, "long message text exposes a scrollable native text range");
		assertEquals(true, view.messageArea.verticalScrollBar.maximum > 1, "message scrollbar adopts the native text range");
		assertEquals(true, view.messageArea.verticalScrollBar.enabled, "message scrollbar remains interactive");
		assertEquals(1, view.messageArea.verticalScrollBar.value, "message scrollbar starts at the top of the text");
		view.messageArea.verticalScrollBar.scrollTo(2);
		assertEquals(2, view.messageArea.verticalScrollBar.value, "message scrollbar advances through its scroll range");
		assertEquals(2, view.message.scrollV, "message scrollbar scrolls the native text field");
		assertClose(-50, view.okButton.x, "message OK button keeps its XFL X");
		assertClose(43, view.okButton.y, "message OK button keeps its XFL Y");
		var closes = 0;
		view.onClose = function():Void closes++;
		view.okButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, closes, "message popup dismisses from its authored OK button");
		view.dispose();

		var afterClose = 0;
		var popup = new MessagePopup("Retry message", function():Void afterClose++);
		@:privateAccess popup.art.okButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		popup.remove();
		assertEquals(1, afterClose, "MessagePopup runs its optional continuation after an OK dismissal");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}
}

private class ExampleDialogView extends NativeView {
	public final message:TextField;
	public final confirmButton:GameButton;
	public final cancelButton:GameButton;
	public final openAnimation:AnimationClip;
	public function new() {
		super();
		message = new TextField();
		confirmButton = ownControl(new GameButton("OK"));
		cancelButton = ownControl(new GameButton("Cancel"));
		openAnimation = ownAnimation(AnimationClip.tween(4, 0, 1, function(value) alpha = value));
		addChild(message);
		addChild(confirmButton);
		addChild(cancelButton);
	}
}
