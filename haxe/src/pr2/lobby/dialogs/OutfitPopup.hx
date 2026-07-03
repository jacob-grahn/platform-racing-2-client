package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.account.AccountCharacter;
import pr2.lobby.account.Preset.Outfit;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/** Port of Flash `dialogs.OutfitPopup`: confirm an outfit with a live preview. */
class OutfitPopup extends Popup {
	public static var instance:Null<OutfitPopup>;

	private static inline var STATS_HIDDEN_SHIFT:Float = 32.8;

	public var art(default, null):Null<PR2MovieClip>;
	public var preview(default, null):Null<AccountCharacter>;

	private var confirmFunction:Void->Void;
	private var okBinding:Null<Binding>;
	private var cancelBinding:Null<Binding>;

	public function new(confirmFunction:Void->Void, outfit:Outfit, message:String = "Are you sure?") {
		if (instance != null) instance.startFadeOut();
		super();
		instance = this;
		this.confirmFunction = confirmFunction;
		art = PR2MovieClip.fromLinkage("OutfitPopupGraphic", {maxNestedDepth: 6});
		addChild(art);

		var textBox = LobbyArt.text(art, "textBox");
		if (textBox != null) textBox.htmlText = message;
		buildPreview(outfit);
		applyStats(outfit);

		okBinding = LobbyArt.bind(DisplayUtil.findByName(art, "ok_bt"), clickOk);
		cancelBinding = LobbyArt.bind(DisplayUtil.findByName(art, "cancel_bt"), startFadeOut);
	}

	private function clickOk():Void {
		confirmFunction();
		startFadeOut();
	}

	private function buildPreview(outfit:Outfit):Void {
		if (art == null) return;
		preview = new AccountCharacter(firstHat(outfit), intOr(outfit.head, 1), intOr(outfit.body, 1), intOr(outfit.feet, 1));
		preview.setColors(intOr(outfit.hatColor, 0xFFFFFF), intOr(outfit.hatColor2, -1), intOr(outfit.headColor, 0),
			intOr(outfit.headColor2, -1), intOr(outfit.bodyColor, 0), intOr(outfit.bodyColor2, -1), intOr(outfit.feetColor, 0),
			intOr(outfit.feetColor2, -1));
		preview.x = 172;
		preview.y = 7.5;
		preview.scaleX = preview.scaleY = 1.5;
		art.addChild(preview);
	}

	private function applyStats(outfit:Outfit):Void {
		var hasStats = outfit.speed != null || outfit.acceleration != null || outfit.jumping != null;
		if (hasStats) {
			setText("speedBox", "Speed:" + intOr(outfit.speed, 0));
			setText("accelBox", "Acceleration:" + intOr(outfit.acceleration, 0));
			setText("jumpnBox", "Jumping:" + intOr(outfit.jumping, 0));
			return;
		}
		hide("speedBox");
		hide("accelBox");
		hide("jumpnBox");
		hide("statsBg");
		if (preview != null) preview.y += STATS_HIDDEN_SHIFT;
		var characterBg = DisplayUtil.findByName(art, "characterBg");
		if (characterBg != null) characterBg.y += STATS_HIDDEN_SHIFT;
	}

	private function setText(name:String, value:String):Void {
		var field:Null<TextField> = LobbyArt.text(art, name);
		if (field != null) field.text = value;
	}

	private function hide(name:String):Void {
		var target:Null<DisplayObject> = DisplayUtil.findByName(art, name);
		if (target != null) target.visible = false;
	}

	private static function firstHat(outfit:Outfit):Int {
		if (outfit.hats != null && outfit.hats.length > 0) return outfit.hats[0];
		return intOr(outfit.hat, 1);
	}

	private static function intOr(value:Null<Int>, fallback:Int):Int {
		return value == null ? fallback : value;
	}

	override public function remove():Void {
		if (instance == this) instance = null;
		LobbyArt.unbind(okBinding);
		LobbyArt.unbind(cancelBinding);
		okBinding = null;
		cancelBinding = null;
		if (preview != null) {
			preview.remove();
			preview = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
