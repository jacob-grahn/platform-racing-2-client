package pr2.ui.controls;

import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

class GameCheckBox extends NativeControl {
	public var selected(default, set):Bool = false;
	public var label(get, set):String;
	public var onChange:Null<Bool->Void>;
	public final labelField:TextField;
	private var useAuthoredSkin:Bool = false;
	private var iconHolder:Null<Sprite>;

	public function new(label:String = "", selected:Bool = false, ?skin:ControlSkin) {
		super(100, 22, skin);
		useAuthoredSkin = skin == null;
		this.selected = selected;
		if (useAuthoredSkin) {
			graphics.clear();
			iconHolder = new Sprite();
			iconHolder.mouseEnabled = false;
			iconHolder.mouseChildren = false;
			addChild(iconHolder);
		}
		labelField = new TextField();
		labelField.mouseEnabled = false;
		labelField.selectable = false;
		labelField.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Body), 11, 0);
		labelField.autoSize = TextFieldAutoSize.LEFT;
		labelField.multiline = false;
		labelField.text = label;
		addChild(labelField);
		mouseChildren = false;
		useHandCursor = true;
		addEventListener(MouseEvent.CLICK, onClick);
		redraw();
		layoutLabel();
	}

	override public function setSize(width:Float, height:Float):Void { super.setSize(width, height); layoutLabel(); }
	override public function activate():Void { if (enabled && !disposed) toggleValue(); }
	override public function state():ControlState return !enabled ? Disabled : (selected ? Selected : super.state());
	override public function redraw():Void {
		if (!useAuthoredSkin || iconHolder == null) {
			super.redraw();
			return;
		}
		graphics.clear();
		graphics.beginFill(0x000000, 0.001);
		graphics.drawRect(0, 0, controlWidth, controlHeight);
		graphics.endFill();
		while (iconHolder.numChildren > 0) iconHolder.removeChildAt(0);
		iconHolder.addChild(NativeAssets.svg(authoredAsset()));
		layoutLabel();
	}
	override public function dispose():Void { removeEventListener(MouseEvent.CLICK, onClick); onChange = null; super.dispose(); }
	private function onClick(_):Void toggleValue();
	private function toggleValue():Void { if (!enabled || disposed) return; selected = !selected; if (onChange != null) onChange(selected); dispatchEvent(new Event(Event.CHANGE)); }
	private function set_selected(value:Bool):Bool { selected = value; redraw(); return value; }
	private function get_label():String return labelField.text;
	private function set_label(value:String):String { labelField.text = value == null ? "" : value; layoutLabel(); return labelField.text; }

	private function authoredAsset():StaticSvg {
		if (selected) {
			if (!enabled) return StaticSvg.CheckBoxSelectedDisabled;
			if (pressed) return StaticSvg.CheckBoxSelectedDown;
			if (hovered) return StaticSvg.CheckBoxSelectedOver;
			return StaticSvg.CheckBoxSelectedUp;
		}
		if (!enabled) return StaticSvg.CheckBoxDisabled;
		if (pressed) return StaticSvg.CheckBoxDown;
		if (hovered) return StaticSvg.CheckBoxOver;
		return StaticSvg.CheckBoxUp;
	}

	private function layoutLabel():Void {
		if (labelField == null) return;
		var iconWidth = iconHolder == null || iconHolder.width <= 0 ? 14 : iconHolder.width;
		var iconHeight = iconHolder == null || iconHolder.height <= 0 ? 14 : iconHolder.height;
		labelField.x = iconWidth + 4;
		labelField.y = (iconHeight - labelField.height) / 2;
	}
}
