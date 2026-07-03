package pr2.lobby.account;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.runtime.FlSlider;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Port of Flash `ui.StatSlider`: one labelled 0–100 stat row with a slider, a
	numeric entry box, and decrement/increment buttons, all kept in sync and
	clamped against the shared points budget via the owning `StatsSelect`.

	The original's press-and-hold acceleration is reduced to a single step per
	click; slider drag and direct text entry behave as in the source.
**/
class StatSlider extends Sprite {
	public var value:Int = 0;

	private var m:PR2MovieClip;
	private var target:StatsSelect;
	private var slider:Null<FlSlider>;
	private var textBox:Null<TextField>;
	private var decButton:Null<DisplayObject>;
	private var incButton:Null<DisplayObject>;
	private var decBinding:Null<Binding>;
	private var incBinding:Null<Binding>;

	public function new(statName:String, ss:StatsSelect) {
		super();
		this.target = ss;
		m = PR2MovieClip.fromLinkage("StatSliderGraphic", {maxNestedDepth: 6});
		addChild(m);

		var nameBox = LobbyArt.text(m, "nameBox");
		if (nameBox != null) {
			nameBox.text = statName;
		}
		textBox = LobbyArt.text(m, "textBox");
		if (textBox != null) {
			textBox.restrict = "0123456789";
			textBox.type = openfl.text.TextFieldType.INPUT;
			textBox.addEventListener(Event.CHANGE, onTextChange);
		}
		slider = Std.downcast(DisplayUtil.findByName(m, "slider"), FlSlider);
		if (slider != null) {
			slider.minimum = 0;
			slider.maximum = 100;
			slider.addEventListener(Event.CHANGE, onSliderChange);
		}
		decButton = DisplayUtil.findByName(m, "decBtn");
		incButton = DisplayUtil.findByName(m, "incBtn");
		decBinding = LobbyArt.bind(decButton, function():Void step(-1));
		incBinding = LobbyArt.bind(incButton, function():Void step(1));
	}

	private function step(delta:Int):Void {
		if (target != null) {
			target.noteUserStatChange();
		}
		setValue(value + delta);
		if (target != null) {
			target.saveLEStats();
		}
	}

	private function onSliderChange(_:Event):Void {
		if (slider != null) {
			if (target != null) {
				target.noteUserStatChange();
			}
			setValue(Std.int(slider.value));
			if (target != null) {
				target.saveLEStats();
			}
		}
	}

	private function onTextChange(_:Event):Void {
		if (textBox != null) {
			if (target != null) {
				target.noteUserStatChange();
			}
			var parsed = Std.parseInt(textBox.text);
			setValue(parsed == null ? 0 : parsed);
			if (target != null) {
				target.saveLEStats();
			}
		}
	}

	public function setValue(v:Int):Void {
		value = clamp(v, 0, 100);
		if (target != null) {
			var remaining = target.getPointsRemaining();
			if (remaining < 0) {
				value += remaining;
			}
		}
		if (textBox != null) {
			textBox.text = Std.string(value);
		}
		if (slider != null) {
			slider.value = value;
		}
		if (target != null) {
			target.updateStatsDisplay();
		}
	}

	private static inline function clamp(v:Int, lo:Int, hi:Int):Int {
		return v < lo ? lo : (v > hi ? hi : v);
	}

	public function remove():Void {
		if (textBox != null) {
			textBox.removeEventListener(Event.CHANGE, onTextChange);
		}
		if (slider != null) {
			slider.removeEventListener(Event.CHANGE, onSliderChange);
		}
		LobbyArt.unbind(decBinding);
		LobbyArt.unbind(incBinding);
		if (m != null) {
			m.dispose();
			m = null;
		}
		target = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
