package pr2.ui.controls;

import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;

class GameTextInput extends NativeControl {
	public var text(get, set):String;
	public var editable(default, set):Bool = true;
	public var onChange:Null<String->Void>;
	public final textField:TextField;

	public function new(text:String = "", ?skin:ControlSkin) {
		super(100, 22, skin);
		buttonMode = false;
		textField = new TextField();
		textField.type = TextFieldType.INPUT;
		textField.selectable = true;
		textField.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Body), 11, 0);
		textField.text = text;
		textField.x = 5;
		textField.y = 2;
		addChild(textField);
		textField.addEventListener(Event.CHANGE, onTextChange);
		layoutField();
	}

	override public function setSize(width:Float, height:Float):Void { super.setSize(width, height); layoutField(); }
	override public function enabledChanged(value:Bool):Void { if (textField != null) { textField.type = value && editable ? TextFieldType.INPUT : TextFieldType.DYNAMIC; textField.selectable = value; } }
	override public function dispose():Void { textField.removeEventListener(Event.CHANGE, onTextChange); onChange = null; textField.type = TextFieldType.DYNAMIC; textField.selectable = false; super.dispose(); }
	private function get_text():String return textField.text;
	private function set_text(value:String):String { textField.text = value == null ? "" : value; return textField.text; }
	private function set_editable(value:Bool):Bool { editable = value; textField.type = value && enabled ? TextFieldType.INPUT : TextFieldType.DYNAMIC; return value; }
	private function onTextChange(event:Event):Void { if (event.target == textField && onChange != null) onChange(text); }
	private function layoutField():Void { textField.width = Math.max(0, controlWidth - 10); textField.height = Math.max(0, controlHeight - 4); }
}
