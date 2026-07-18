package pr2.ui.controls;

import openfl.events.Event;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

class GameButton extends NativeControl {
	public var label(get, set):String;
	public var selected(default, set):Bool = false;
	public var toggle:Bool = false;
	public var emphasized(default, set):Bool = false;
	public var onPress:Null<Void->Void>;
	public final labelField:TextField;
	private var _label:String;
	private var useAuthoredSkin:Bool = false;
	private var authoredBackground:Null<Sprite>;

	public function new(label:String = "Button", ?skin:ControlSkin) {
		super(100, 22, skin);
		useAuthoredSkin = skin == null;
		_label = label;
		if (useAuthoredSkin) {
			graphics.clear();
			authoredBackground = new Sprite();
			authoredBackground.mouseEnabled = false;
			authoredBackground.mouseChildren = false;
			addChild(authoredBackground);
		}
		labelField = new TextField();
		labelField.mouseEnabled = false;
		labelField.selectable = false;
		labelField.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Body), 11, 0, null, null, null, null, null, TextFormatAlign.CENTER);
		addChild(labelField);
		mouseChildren = false;
		useHandCursor = true;
		addEventListener(MouseEvent.CLICK, onClick);
		layoutLabel();
		redraw();
	}

	override public function setSize(width:Float, height:Float):Void { super.setSize(width, height); layoutLabel(); }
	override public function activate():Void { if (enabled && !disposed) commitPress(); }
	override public function state():ControlState return !enabled ? Disabled : (selected ? Selected : super.state());
	override public function redraw():Void {
		if (!useAuthoredSkin || authoredBackground == null) {
			super.redraw();
			return;
		}
		graphics.clear();
		// The authored SVG child is deliberately non-interactive so labels and
		// nested art cannot steal pointer events. Keep an explicit transparent
		// fill on the owning button; otherwise OpenFL gives the Sprite bounds but
		// has no interactive pixels to hit-test.
		// OpenFL HTML5 excludes fully transparent fills from pixel hit testing.
		// A subpixel alpha preserves an invisible authored hit surface.
		graphics.beginFill(0x000000, 0.01);
		graphics.drawRect(0, 0, controlWidth, controlHeight);
		graphics.endFill();
		while (authoredBackground.numChildren > 0) authoredBackground.removeChildAt(0);
		var asset = authoredAsset();
		var art = NativeAssets.svg(asset);
		authoredBackground.addChild(art);
		authoredBackground.scale9Grid = new Rectangle(7, 5, 68, 11);
		authoredBackground.width = controlWidth;
		authoredBackground.height = controlHeight;
	}
	override public function dispose():Void { removeEventListener(MouseEvent.CLICK, onClick); onPress = null; super.dispose(); }

	private function onClick(_):Void commitPress();
	private function commitPress():Void {
		if (!enabled || disposed) return;
		if (toggle) selected = !selected;
		if (onPress != null) onPress();
	}
	private function get_label():String return _label;
	private function set_label(value:String):String { _label = value == null ? "" : value; layoutLabel(); return _label; }
	private function set_selected(value:Bool):Bool { selected = value; redraw(); return value; }
	private function set_emphasized(value:Bool):Bool { emphasized = value; redraw(); return value; }
	private function layoutLabel():Void {
		labelField.text = _label;
		var format = new TextFormat(NativeAssets.font(FontAsset.Body), 11, enabled ? 0x000000 : 0x555555, false, false, false, null, null,
			TextFormatAlign.CENTER);
		labelField.defaultTextFormat = format;
		labelField.setTextFormat(format);
		labelField.width = Math.max(0, controlWidth - 10);
		labelField.height = labelField.textHeight + 4;
		labelField.x = 5;
		labelField.y = (controlHeight - labelField.height) / 2;
	}

	override public function enabledChanged(value:Bool):Void {
		layoutLabel();
	}

	private function authoredAsset():StaticSvg {
		if (selected) {
			if (!enabled) return StaticSvg.ButtonSelectedDisabled;
			if (pressed) return StaticSvg.ButtonSelectedDown;
			if (hovered) return StaticSvg.ButtonSelectedOver;
			return StaticSvg.ButtonSelectedUp;
		}
		if (!enabled) return StaticSvg.ButtonDisabled;
		if (pressed) return StaticSvg.ButtonDown;
		if (hovered) return StaticSvg.ButtonOver;
		if (emphasized) return StaticSvg.ButtonEmphasized;
		return StaticSvg.ButtonUp;
	}
}
