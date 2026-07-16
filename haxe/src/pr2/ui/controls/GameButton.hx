package pr2.ui.controls;

import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;

class GameButton extends NativeControl {
	public var label(get, set):String;
	public var selected(default, set):Bool = false;
	public var toggle:Bool = false;
	public var onPress:Null<Void->Void>;
	public final labelField:TextField;
	private var _label:String;

	public function new(label:String = "Button", ?skin:ControlSkin) {
		super(100, 22, skin);
		_label = label;
		labelField = new TextField();
		labelField.mouseEnabled = false;
		labelField.selectable = false;
		labelField.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Body), 11, 0, null, null, null, null, null, TextFormatAlign.CENTER);
		addChild(labelField);
		addEventListener(MouseEvent.CLICK, onClick);
		layoutLabel();
	}

	override public function setSize(width:Float, height:Float):Void { super.setSize(width, height); layoutLabel(); }
	override public function activate():Void { if (enabled && !disposed) commitPress(); }
	override public function state():ControlState return !enabled ? Disabled : (selected ? Selected : super.state());
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
	private function layoutLabel():Void { labelField.text = _label; labelField.width = controlWidth; labelField.height = controlHeight; labelField.y = 3; }
}
