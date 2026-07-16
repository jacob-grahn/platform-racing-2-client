package pr2.ui;

import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.ui.Keyboard;
import pr2.animation.AnimationClip;
import pr2.animation.AnimationClock;
import pr2.animation.AnimationGroup;
import pr2.animation.PlaybackState;
import pr2.assets.NativeAssetIds.BitmapAsset;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.SoundAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.runtime.FlButton;
import pr2.runtime.FlCheckBox;
import pr2.runtime.FlSlider;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.controls.GameScrollBar;
import pr2.ui.controls.GameSelect;
import pr2.ui.controls.GameSlider;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

class NativePresentationFoundationTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testTypedAssetIds();
		if (pr2.DeterministicTestMode.finishSmokeSuite("NativePresentationFoundationTest")) return;
		testAnimationPlayback();
		testAnimationCompositionAndOwnership();
		testControlParityContracts();
		testFocusKeyboardAndTeardown();
		testTypedViewOwnership();
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
		var flashButton = new FlButton("Follow");
		nativeButton.toggle = true;
		flashButton.toggle = true;
		nativeButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		flashButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(flashButton.selected, nativeButton.selected, "button toggle matches FlButton");
		nativeButton.enabled = false;
		flashButton.enabled = false;
		assertEquals(flashButton.mouseEnabled, nativeButton.mouseEnabled, "button disabled mouse behavior matches FlButton");

		var nativeBox = new GameCheckBox("Mute");
		var flashBox = new FlCheckBox("Mute");
		var nativeChanges = 0;
		var flashChanges = 0;
		nativeBox.addEventListener(Event.CHANGE, function(_) nativeChanges++);
		flashBox.addEventListener(Event.CHANGE, function(_) flashChanges++);
		nativeBox.selected = true;
		flashBox.selected = true;
		assertEquals(flashChanges, nativeChanges, "programmatic checkbox changes are silent like FlCheckBox");
		nativeBox.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		flashBox.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(flashBox.selected, nativeBox.selected, "checkbox click state matches FlCheckBox");
		assertEquals(flashChanges, nativeChanges, "checkbox click event matches FlCheckBox");
		nativeBox.enabled = false;
		flashBox.enabled = false;
		assertEquals(flashBox.mouseEnabled, nativeBox.mouseEnabled, "checkbox disabled mouse behavior matches FlCheckBox");

		var nativeSlider = new GameSlider(0, 10, 3, 1);
		var flashSlider = new FlSlider();
		flashSlider.minimum = 0;
		flashSlider.maximum = 10;
		flashSlider.value = 3;
		nativeSlider.value = 20;
		flashSlider.value = 20;
		assertEquals(flashSlider.value, nativeSlider.value, "slider clamps like FlSlider");
	}

	private static function testFocusKeyboardAndTeardown():Void {
		var presses = 0;
		var button = new GameButton("OK");
		button.onPress = function() presses++;
		button.focus();
		button.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.ENTER));
		assertEquals(true, button.focused, "control exposes explicit focus state");
		assertEquals(1, presses, "focused button activates from Enter");
		button.dispose();
		button.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, presses, "disposed button removes click callbacks");

		var slider = new GameSlider(0, 10, 5, 1);
		slider.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.RIGHT));
		assertEquals(6.0, slider.value, "slider supports arrow keyboard input");
		var select = new GameSelect<String>();
		select.addOption("One", "one");
		select.addOption("Two", "two");
		select.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.DOWN));
		assertEquals("one", select.selectedOption.value, "select supports keyboard navigation");
		var scroll = new GameScrollBar(0, 100, 20, 2);
		scroll.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.PAGE_DOWN));
		assertEquals(20.0, scroll.value, "scroll bar supports page keyboard input");
		var input = new GameTextInput("hello");
		input.editable = false;
		assertEquals(false, input.editable, "text input exposes typed editable state");
		input.enabled = false;
		assertEquals(false, input.textField.selectable, "disabled text input removes selection and editing");
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

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
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
