package pr2.lobby.account;

import com.jiggmin.data.Objects;
import haxe.Timer;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.level.ObjectCodes;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.dialogs.HoverDelayPopup;
import pr2.lobby.dialogs.HoverPopup;
import pr2.net.CommandHandler;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `player_profile.PlayerDisplay`: the hat/head/body/feet part
	selectors plus a randomize-style button. Each selector change is pushed into
	the live `AccountCharacter`, and when the equipped hat changes it updates
	`AccountState.currentHat` and re-runs level-access checks (the Flash
	`testLevelAccess` dispatch), so password/rank/hat gating stays in sync.

	The per-part info button uses Flash's delayed hover and opens the singleton
	part-catalog popup.
**/
class PlayerDisplay extends Sprite {
	public final hatSelect:PartSelector;
	public final headSelect:PartSelector;
	public final bodySelect:PartSelector;
	public final feetSelect:PartSelector;

	private var charPreview:AccountCharacter;
	private var randomButton:Null<HoverDelayPopup>;
	private var randomGraphic:Null<DisplayObject>;
	private var randomBinding:Null<Binding>;
	private var hover:Null<HoverPopup>;
	private var hoverTimer:Null<Timer>;
	private final yStart:Float = 24;
	private var hasHatRow:Bool;

	public function new(c:AccountCharacter, hatArray:Array<String>, headArray:Array<String>, bodyArray:Array<String>, feetArray:Array<String>,
			hatSel:Int, headSel:Int, bodySel:Int, feetSel:Int, hatCol:Int, headCol:Int, bodyCol:Int, feetCol:Int, hatArray2:Array<String>,
			headArray2:Array<String>, bodyArray2:Array<String>, feetArray2:Array<String>, hatCol2:Int, headCol2:Int, bodyCol2:Int, feetCol2:Int) {
		super();
		this.charPreview = c;
		this.hasHatRow = hatArray.length > 1;

		hatSelect = new PartSelector(hatArray, hatSel, hatCol, hatArray2, hatCol2);
		headSelect = new PartSelector(headArray, headSel, headCol, headArray2, headCol2);
		bodySelect = new PartSelector(bodyArray, bodySel, bodyCol, bodyArray2, bodyCol2);
		feetSelect = new PartSelector(feetArray, feetSel, feetCol, feetArray2, feetCol2);
		hatSelect.y = 0;
		headSelect.y = yStart * 1;
		bodySelect.y = yStart * 2;
		feetSelect.y = yStart * 3;

		hatSelect.addEventListener(Event.CHANGE, updateDisplay);
		headSelect.addEventListener(Event.CHANGE, updateDisplay);
		bodySelect.addEventListener(Event.CHANGE, updateDisplay);
		feetSelect.addEventListener(Event.CHANGE, updateDisplay);

		bindInfo(hatSelect, "hat");
		bindInfo(headSelect, "head");
		bindInfo(bodySelect, "body");
		bindInfo(feetSelect, "feet");

		randomButton = new HoverDelayPopup("Randomize Style",
			"Create a random style for your character. Remember to save your current style if you like it first!");
		randomGraphic = Objects.getFromCode(ObjectCodes.BLOCK_ITEM);
		if (randomGraphic != null) {
			randomGraphic.width = randomGraphic.height = 15;
			randomButton.addChild(randomGraphic);
		}
		randomButton.x = 122.5;
		randomButton.y = (hasHatRow ? -yStart : 0) + 4.5;
		randomBinding = LobbyArt.bind(randomButton, onRandomClick);
		addChild(randomButton);

		if (hasHatRow) {
			addChild(hatSelect);
		}
		addChild(headSelect);
		addChild(bodySelect);
		addChild(feetSelect);

		updateDisplay(null);
	}

	private function bindInfo(selector:PartSelector, partType:String):Void {
		selector.infoButton.buttonMode = true;
		selector.infoButton.useHandCursor = true;
		selector.infoButton.addEventListener(MouseEvent.MOUSE_OVER, onInfoMouseEvent);
		selector.infoButton.addEventListener(MouseEvent.MOUSE_OUT, onInfoMouseEvent);
		selector.infoButton.addEventListener(MouseEvent.CLICK, onInfoMouseEvent);
	}

	private function onInfoMouseEvent(e:MouseEvent):Void {
		var partType = partTypeForButton(e.currentTarget);
		clearInfoHover();
		if (partType == "") {
			return;
		}
		if (e.type == MouseEvent.MOUSE_OVER) {
			hoverTimer = Timer.delay(function():Void showInfo(partType), 500);
		} else if (e.type == MouseEvent.CLICK) {
			new PartInfoPopup(partType, selectorForType(partType).partArray, selectorForType(partType).epicArray);
		}
	}

	private function showInfo(partType:String):Void {
		var plural = partType == "body" ? "bodies" : (partType == "feet" ? partType : partType + "s");
		var title = partType.charAt(0).toUpperCase() + partType.substr(1) + " Information";
		hover = new HoverPopup(title, "See and learn how to obtain all the " + plural + " in Platform Racing 2.", selectorForType(partType).infoButton);
		hover.x += hover.width + 25;
	}

	private function clearInfoHover():Void {
		if (hoverTimer != null) {
			hoverTimer.stop();
			hoverTimer = null;
		}
		if (hover != null) {
			hover.remove();
			hover = null;
		}
	}

	private function partTypeForButton(target:Dynamic):String {
		if (target == hatSelect.infoButton) return "hat";
		if (target == headSelect.infoButton) return "head";
		if (target == bodySelect.infoButton) return "body";
		if (target == feetSelect.infoButton) return "feet";
		return "";
	}

	private function selectorForType(partType:String):PartSelector {
		return switch (partType) {
			case "hat": hatSelect;
			case "head": headSelect;
			case "body": bodySelect;
			case "feet": feetSelect;
			default: headSelect;
		}
	}

	private function onRandomClick():Void {
		hatSelect.randomize();
		headSelect.randomize();
		bodySelect.randomize();
		feetSelect.randomize();
		updateDisplay(null);
	}

	/** Re-apply the current selector state to the character (used after Presets). */
	public function refreshFromCharacter():Void {
		updateDisplay(null);
	}

	private function updateDisplay(_:Event):Void {
		charPreview.setHatId(hatSelect.getValue());
		charPreview.setHeadId(headSelect.getValue());
		charPreview.setBodyId(bodySelect.getValue());
		charPreview.setFeetId(feetSelect.getValue());
		charPreview.setHatColors(hatSelect.getColor(), hatSelect.getColor2());
		charPreview.setHeadColors(headSelect.getColor(), headSelect.getColor2());
		charPreview.setBodyColors(bodySelect.getColor(), bodySelect.getColor2());
		charPreview.setFeetColors(feetSelect.getColor(), feetSelect.getColor2());

		var hat1val = charPreview.hat1;
		if (hat1val != AccountState.currentHat) {
			AccountState.currentHat = hat1val;
			CommandHandler.commandHandler.dispatch("testLevelAccess", []);
		}
	}

	public function remove():Void {
		charPreview = null;
		removeSelector(hatSelect);
		removeSelector(headSelect);
		removeSelector(bodySelect);
		removeSelector(feetSelect);
		clearInfoHover();
		LobbyArt.unbind(randomBinding);
		if (randomGraphic != null) {
			var clip = Std.downcast(randomGraphic, PR2MovieClip);
			if (clip != null) {
				clip.dispose();
			}
			randomGraphic = null;
		}
		if (randomButton != null) {
			randomButton.remove();
			randomButton = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function removeSelector(ps:PartSelector):Void {
		ps.removeEventListener(Event.CHANGE, updateDisplay);
		ps.infoButton.removeEventListener(MouseEvent.MOUSE_OVER, onInfoMouseEvent);
		ps.infoButton.removeEventListener(MouseEvent.MOUSE_OUT, onInfoMouseEvent);
		ps.infoButton.removeEventListener(MouseEvent.CLICK, onInfoMouseEvent);
		ps.remove();
	}
}
