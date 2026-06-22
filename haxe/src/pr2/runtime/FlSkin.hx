package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.geom.Rectangle;

/**
	Small shared helpers for the `fl.controls.*` ports (FlButton, FlCheckBox,
	FlComboBox, …). The Adobe components are skinned by real library symbols
	under `Components/Component Assets/<Kind>Skins/`; these helpers instantiate
	those symbols through `PR2MovieClip` and nine-slice them to size the same way
	`FlButton` does, so every control draws the original artwork.
**/
class FlSkin {
	/**
		Instantiate a skin symbol by library name, or `null` when it is missing
		(an unported/absent asset). Callers fall back to a drawn approximation.
	**/
	public static function create(symbolName:String):Null<DisplayObject> {
		var symbol = AssetLibrary.getSymbol(symbolName);
		if (symbol == null) {
			return null;
		}
		return new PR2MovieClip(symbol);
	}

	/**
		Native (authoring) bounds of a freshly instantiated skin, measured in its
		own coordinate space. Falls back to the supplied nominal size when the
		symbol reports nothing renderable (e.g. during headless interp tests).
	**/
	public static function nativeBounds(skin:DisplayObject, fallbackWidth:Float, fallbackHeight:Float):Rectangle {
		var bounds = skin.getBounds(skin);
		if (bounds == null || bounds.width <= 0 || bounds.height <= 0) {
			return new Rectangle(0, 0, fallbackWidth, fallbackHeight);
		}
		return bounds;
	}

	/**
		Nine-slice a skin to fill `width` x `height`. The grid is given in the
		skin's native coordinates (the XFL `scaleGrid*` attributes); `nativeW/H`
		are the authored skin dimensions used to derive the fill scale.
	**/
	public static function nineSlice(skin:DisplayObject, grid:Rectangle, nativeW:Float, nativeH:Float, width:Float, height:Float):Void {
		// OpenFL's HTML5 renderer clips the right/bottom slices when a vector
		// Sprite with scale9Grid is scaled again by an authored component-instance
		// transform. TextInput, ComboBox, and Button all hit that path in the login
		// popups, leaving roughly the right 15% of the control undrawn. These skins
		// use one-pixel bevels and only resize modestly, so ordinary scaling is the
		// reliable cross-target behavior.
		try {
			skin.scale9Grid = null;
		} catch (_:Dynamic) {
			// Some targets reject scale9Grid on vector sprites; a plain scale still
			// fills the control (corners stretch a touch), matching FlButton.
		}
		skin.scaleX = nativeW <= 0 ? 1 : width / nativeW;
		skin.scaleY = nativeH <= 0 ? 1 : height / nativeH;
	}

	/**
		Nine-slice that keeps `scale9Grid` active, so the skin's bevels/borders hold
		their native thickness instead of stretching. Use this for skins that resize
		a lot in one axis (e.g. the multiline TextArea background, which scales ~14x
		vertically — plain scaling there turns the 1px top/bottom edges into thick
		grey bands across the text). Safe only when the skin carries no residual
		outer transform; controls that keep an authored instance scale must use
		`nineSlice` instead to dodge the HTML5 right/bottom-slice clipping bug.
	**/
	public static function nineSliceBordered(skin:DisplayObject, grid:Rectangle, nativeW:Float, nativeH:Float, width:Float, height:Float):Void {
		try {
			skin.scale9Grid = grid;
		} catch (_:Dynamic) {
			// Target rejected scale9Grid on a vector sprite; fall back to plain scale.
			nineSlice(skin, grid, nativeW, nativeH, width, height);
			return;
		}
		skin.scaleX = nativeW <= 0 ? 1 : width / nativeW;
		skin.scaleY = nativeH <= 0 ? 1 : height / nativeH;
	}

	private function new() {}
}
