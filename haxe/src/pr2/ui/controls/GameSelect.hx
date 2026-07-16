package pr2.ui.controls;

import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;

/** Typed collapsed select/list model with deterministic keyboard navigation. */
class GameSelect<T> extends NativeControl {
	public var selectedIndex(default, set):Int = -1;
	public var selectedOption(get, never):Null<SelectOption<T>>;
	public var open(default, null):Bool = false;
	public var onChange:Null<SelectOption<T>->Void>;
	public final labelField:TextField;
	private var options:Array<SelectOption<T>> = [];

	public function new(?skin:ControlSkin) {
		super(100, 22, skin);
		labelField = new TextField();
		labelField.mouseEnabled = false;
		labelField.selectable = false;
		labelField.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Body), 11, 0);
		labelField.x = 5;
		labelField.width = 90;
		labelField.height = 22;
		addChild(labelField);
		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(KeyboardEvent.KEY_DOWN, navigate);
	}

	public var length(get, never):Int;
	private function get_length():Int return options.length;
	public function addOption(label:String, value:T):SelectOption<T> { var option = new SelectOption(label, value); options.push(option); return option; }
	public function clear():Void { options = []; selectedIndex = -1; }
	public function selectFromUser(index:Int):Void {
		if (!enabled || disposed || index < 0 || index >= options.length || index == selectedIndex) return;
		selectedIndex = index;
		var option = selectedOption;
		if (option != null && onChange != null) onChange(option);
		dispatchEvent(new Event(Event.CHANGE));
	}
	public function close():Void { open = false; redraw(); }
	override public function activate():Void { if (enabled && !disposed) { open = !open; redraw(); } }
	override public function dispose():Void { removeEventListener(MouseEvent.CLICK, onClick); removeEventListener(KeyboardEvent.KEY_DOWN, navigate); onChange = null; options = []; super.dispose(); }
	private function get_selectedOption():Null<SelectOption<T>> return selectedIndex < 0 ? null : options[selectedIndex];
	private function set_selectedIndex(value:Int):Int { selectedIndex = value < -1 ? -1 : (value >= options.length ? options.length - 1 : value); labelField.text = selectedIndex < 0 ? "" : options[selectedIndex].label; return selectedIndex; }
	private function onClick(_):Void activate();
	private function navigate(event:KeyboardEvent):Void {
		if (!enabled || options.length == 0) return;
		if (event.keyCode == Keyboard.DOWN) selectFromUser(Std.int(Math.min(options.length - 1, selectedIndex + 1)));
		if (event.keyCode == Keyboard.UP) selectFromUser(Std.int(Math.max(0, selectedIndex - 1)));
		if (event.keyCode == Keyboard.HOME) selectFromUser(0);
		if (event.keyCode == Keyboard.END) selectFromUser(options.length - 1);
		if (event.keyCode == Keyboard.ESCAPE) close();
	}
}
