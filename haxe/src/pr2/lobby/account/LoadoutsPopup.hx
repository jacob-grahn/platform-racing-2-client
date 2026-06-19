package pr2.lobby.account;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.lobby.dialogs.Popup;
import pr2.runtime.FontResolver;

/** Loadout chooser/editor used by the Account tab. */
class LoadoutsPopup extends Popup {
	private var character:AccountCharacter;
	private var stats:StatsSelect;
	private var display:PlayerDisplay;

	public function new(character:AccountCharacter, stats:StatsSelect, display:PlayerDisplay) {
		super();
		this.character = character;
		this.stats = stats;
		this.display = display;
		var panel = new Sprite();
		panel.graphics.lineStyle(1, 0x20334A);
		panel.graphics.beginFill(0xE8F1FA);
		panel.graphics.drawRoundRect(-145, -170, 290, 340, 8, 8);
		panel.graphics.endFill();
		addChild(panel);
		addLabel(panel, "-- Loadouts --", -125, -157, 250, 18, true);
		for (i in 0...Presets.NUM_PRESETS) {
			var y = -130 + i * 27;
			addLabel(panel, "Loadout " + (i + 1), -125, y + 3, 95, 20, false);
			addButton(panel, "Apply", -20, y, function():Void apply(i + 1));
			addButton(panel, "Save", 55, y, function():Void save(i + 1));
		}
		addButton(panel, "Close", -35, 140, startFadeOut);
	}

	private function apply(slot:Int):Void {
		Presets.apply(Presets.getPreset(slot), character, stats, display);
		startFadeOut();
	}

	private function save(slot:Int):Void {
		var preset = Presets.getPreset(slot);
		var values = stats.getStats();
		preset.speed = values.speed;
		preset.acceleration = values.acceleration;
		preset.jumping = values.jumping;
		preset.hat = character.hat1;
		preset.head = character.head;
		preset.body = character.body;
		preset.feet = character.feet;
		preset.hatColor = character.hat1Color;
		preset.headColor = character.headColor;
		preset.bodyColor = character.bodyColor;
		preset.feetColor = character.feetColor;
		preset.hatColor2 = display.hatSelect.getColorCP2();
		preset.headColor2 = display.headSelect.getColorCP2();
		preset.bodyColor2 = display.bodySelect.getColorCP2();
		preset.feetColor2 = display.feetSelect.getColorCP2();
		Presets.savePresets();
		startFadeOut();
	}

	private function addButton(parent:Sprite, label:String, x:Float, y:Float, action:Void->Void):Void {
		var button = new Sprite();
		button.graphics.lineStyle(1, 0x20334A);
		button.graphics.beginFill(0xFFFFFF);
		button.graphics.drawRoundRect(0, 0, 65, 22, 4, 4);
		button.graphics.endFill();
		button.x = x;
		button.y = y;
		button.buttonMode = true;
		button.addEventListener(MouseEvent.CLICK, function(_:MouseEvent):Void action());
		addLabel(button, label, 0, 3, 65, 18, false);
		parent.addChild(button);
	}

	private function addLabel(parent:Sprite, value:String, x:Float, y:Float, width:Float, height:Float, bold:Bool):Void {
		var field = new TextField();
		field.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 11, 0x20334A, bold, null, null, null, null, "center");
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.mouseEnabled = false;
		field.text = value;
		parent.addChild(field);
	}

	override public function remove():Void {
		character = null;
		stats = null;
		display = null;
		super.remove();
	}
}
