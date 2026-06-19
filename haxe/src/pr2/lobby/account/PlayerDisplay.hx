package pr2.lobby.account;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.dialogs.HoverPopup;
import pr2.net.CommandHandler;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `player_profile.PlayerDisplay`: the hat/head/body/feet part
	selectors plus a randomize-style button. Each selector change is pushed into
	the live `AccountCharacter`, and when the equipped hat changes it updates
	`AccountState.currentHat` and re-runs level-access checks (the Flash
	`testLevelAccess` dispatch), so password/rank/hat gating stays in sync.

	The per-part info button shows a `HoverPopup` (the original's external
	part-catalog popup is out of scope for the lobby port).
**/
class PlayerDisplay extends Sprite {
	public final hatSelect:PartSelector;
	public final headSelect:PartSelector;
	public final bodySelect:PartSelector;
	public final feetSelect:PartSelector;

	private var charPreview:AccountCharacter;
	private var randomButton:Null<PR2MovieClip>;
	private var randomBinding:Null<Binding>;
	private var hover:Null<HoverPopup>;
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

		randomButton = PR2MovieClip.fromLinkage("RandomizeStyleButtonGraphic", {maxNestedDepth: 4});
		randomButton.width = randomButton.height = 15;
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
		selector.infoButton.addEventListener(MouseEvent.CLICK, function(_:MouseEvent):Void {
			showInfo(partType, selector.infoButton);
		});
	}

	private function showInfo(partType:String, target:DisplayObject):Void {
		if (hover != null) {
			hover.remove();
			hover = null;
		}
		var plural = partType == "body" ? "bodies" : (partType == "feet" ? partType : partType + "s");
		var title = partType.charAt(0).toUpperCase() + partType.substr(1) + " Information";
		hover = new HoverPopup(title, "See and learn how to obtain all the " + plural + " in Platform Racing 2.", target);
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
		if (hover != null) {
			hover.remove();
			hover = null;
		}
		LobbyArt.unbind(randomBinding);
		if (randomButton != null) {
			randomButton.dispose();
			randomButton = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function removeSelector(ps:PartSelector):Void {
		ps.removeEventListener(Event.CHANGE, updateDisplay);
		ps.remove();
	}
}
