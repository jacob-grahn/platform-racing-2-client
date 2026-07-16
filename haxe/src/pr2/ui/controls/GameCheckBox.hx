package pr2.ui.controls;

import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;

class GameCheckBox extends NativeControl {
	public var selected(default, set):Bool = false;
	public var onChange:Null<Bool->Void>;
	public final labelField:TextField;

	public function new(label:String = "", selected:Bool = false, ?skin:ControlSkin) {
		super(100, 22, skin);
		this.selected = selected;
		labelField = new TextField();
		labelField.mouseEnabled = false;
		labelField.selectable = false;
		labelField.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Body), 11, 0);
		labelField.text = label;
		labelField.x = 24;
		labelField.width = 76;
		labelField.height = 22;
		addChild(labelField);
		addEventListener(MouseEvent.CLICK, onClick);
	}

	override public function activate():Void { if (enabled && !disposed) toggleValue(); }
	override public function state():ControlState return !enabled ? Disabled : (selected ? Selected : super.state());
	override public function dispose():Void { removeEventListener(MouseEvent.CLICK, onClick); onChange = null; super.dispose(); }
	private function onClick(_):Void toggleValue();
	private function toggleValue():Void { if (!enabled || disposed) return; selected = !selected; if (onChange != null) onChange(selected); dispatchEvent(new Event(Event.CHANGE)); }
	private function set_selected(value:Bool):Bool { selected = value; redraw(); return value; }
}
