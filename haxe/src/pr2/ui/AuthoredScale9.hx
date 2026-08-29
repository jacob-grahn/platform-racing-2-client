package pr2.ui;

import openfl.display.Shape;
import openfl.geom.Rectangle;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

typedef AuthoredPanelTransform = {
	var scaleX:Float;
	var scaleY:Float;
	@:optional var x:Float;
	@:optional var y:Float;
}

/**
	Scale-grid factories for the reusable XFL chrome.

	The grid must live on the vector that is resized. OpenFL's HTML5 renderer
	does not apply a child's scale grid when only a wrapper Sprite is scaled.
**/
final class AuthoredScale9 {
	public static inline final SQUARE_SYMBOL = "UI/Popups (outside levels)/BG";
	public static inline final SHADOW_SYMBOL = "UI/ShadowBG";

	public static function buttonSkin(art:Shape):Shape {
		art.scale9Grid = new Rectangle(7, 5, 68, 11);
		return art;
	}

	public static function halfSquarePanel(?transform:AuthoredPanelTransform):Shape {
		return applyTransform(NativeAssets.svg(StaticSvg.HalfSquarePanel), transform);
	}

	public static function shadowPanel(?transform:AuthoredPanelTransform):Shape {
		return applyTransform(NativeAssets.svg(StaticSvg.QuantityPanel), transform);
	}

	public static function squarePanel(?transform:AuthoredPanelTransform):Shape {
		var art = NativeAssets.svg(StaticSvg.SquarePanel);
		art.scale9Grid = new Rectangle(5.05, 5.05, 90, 90.1);
		return applyTransform(art, transform);
	}

	/**
		Applies an authored XFL instance transform by resizing the vector carrying
		the scale grid. Callers must not put the vector in a scaled wrapper.
	**/
	private static function applyTransform(art:Shape, transform:Null<AuthoredPanelTransform>):Shape {
		if (transform == null) return art;
		var naturalWidth = art.width;
		var naturalHeight = art.height;
		art.x = transform.x == null ? 0 : transform.x;
		art.y = transform.y == null ? 0 : transform.y;
		art.width = naturalWidth * transform.scaleX;
		art.height = naturalHeight * transform.scaleY;
		return art;
	}

	public static function colorPickerSkin(art:Shape):Shape {
		art.scale9Grid = new Rectangle(3, 3, 11, 13);
		return art;
	}
}
