package pr2.ui.controls;

import openfl.display.Shape;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

/** The exact four-state XFL `Buttons/ArrowButton`, optionally mirrored left. */
class AuthoredArrowButton extends NativeControl {
	private final pointsRight:Bool;
	private var action:Void->Void;
	private var visual:Null<Shape>;

	public function new(pointsRight:Bool, action:Void->Void) {
		super(10, 16);
		this.pointsRight = pointsRight;
		this.action = action;
		redraw();
	}

	override public function activate():Void {
		if (enabled && !disposed) action();
	}

	override public function redraw():Void {
		graphics.clear();
		if (visual != null && visual.parent == this) removeChild(visual);
		if (disposed) return;
		visual = NativeAssets.svg(assetForState());
		if (!pointsRight) {
			visual.scaleX = -1;
			visual.x = 10;
		}
		addChild(visual);
	}

	override public function dispose():Void {
		action = function():Void {};
		super.dispose();
	}

	private function assetForState():StaticSvg {
		return switch (state()) {
			case Disabled: StaticSvg.ArrowButtonDisabled;
			case Hovered | Focused: StaticSvg.ArrowButtonOver;
			case Pressed: StaticSvg.ArrowButtonDown;
			case Normal | Selected: StaticSvg.ArrowButtonUp;
		};
	}
}
