# Native Presentation Foundation

This layer is the destination for the de-Flash migration. It changes code
structure and asset plumbing only: visuals, timing, input behavior, focus,
sound, and user flows remain parity requirements.

## Assets

Native presentation code requests `StaticSvg`, `BitmapAsset`, `FontAsset`, or
`SoundAsset` values through `NativeAssets`. The identifiers are generated from
`tools/native-assets.json`; `test.sh` rejects stale identifiers and missing
source files. Add a semantic name to that manifest instead of embedding an XFL
path or linkage string in a view.

## Animation

`AnimationClip` represents a frame sequence or property tween.
`AnimationGroup` composes clips, and `AnimationClock` advances them from a game
or simulation clock. Owners explicitly play, pause, stop, and dispose clips.
No primitive reads wall time, installs frame scripts, or interprets a Flash
timeline.

## Controls

`GameButton`, `GameCheckBox`, `GameSlider`, `GameTextInput`, `GameSelect`, and
`GameScrollBar` expose typed state and callbacks. They have deterministic
keyboard behavior and teardown. A `ControlSkin` is injected, so migration can
match existing art without coupling control behavior to a timeline symbol.

## Typed views and ownership

Views subclass `NativeView`, construct their layout explicitly, and expose
concrete fields. They register controls, animations, and listeners with their
owner. Calling `dispose()` removes listeners and tears down every registered
child resource. Recursive instance-name lookup is not part of the API.

```haxe
class ConfirmDialogView extends NativeView {
	public final message:TextField;
	public final confirmButton:GameButton;
	public final cancelButton:GameButton;

	public function new() {
		super();
		message = new TextField();
		confirmButton = ownControl(new GameButton("OK"));
		cancelButton = ownControl(new GameButton("Cancel"));
		addChild(message);
		addChild(confirmButton);
		addChild(cancelButton);
	}
}
```
