package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.NumberFormat;
import pr2.lobby.dialogs.Popup;
import pr2.runtime.EpicFlash;
import pr2.gameplay.PrizePopupView.PrizePartSymbol;
import pr2.gameplay.PrizePopupView.PrizePartSymbolChannel;
import pr2.util.DisplayUtil;

/**
	Port of Flash `gameplay.PrizePopup`.

	Announces a race prize over `PrizePopupGraphic`. The `type` selects which
	authored preview clip is shown (`hat`/`head`/`body`/`foot` for parts, `exp`
	for experience, `cancel` for a cancelled prize) and the body/title text is
	assembled exactly as Flash did: "You won …" when finished, "Anyone who
	finishes …" / "The winner of this race …" otherwise, plus an optional flavor
	description. Epic part upgrades (`eHat`/`eHead`/`eBody`/`eFeet`) shimmer via
	`EpicFlash`. A single instance is kept; constructing a new one removes the
	prior popup.
**/
class PrizePopup extends Popup {
	public static var instance:Null<PrizePopup>;

	private var art:Null<PrizePopupView>;
	private var target:Null<DisplayObjectContainer>;
	private var epicFlash:EpicFlash = new EpicFlash();
	private var closeBinding:Null<Binding>;
	private var contentData:Null<PrizeContent>;

	// Resolved state, exposed for tests/parity assertions.
	public var targetName(default, null):String = "";
	public var titleText(default, null):String = "";
	public var bodyText(default, null):String = "";
	public var flavorText(default, null):String = "";
	public var flavorVisible(default, null):Bool = false;
	// The exp/cancel detail line shown in the exp clip's own textBox.
	public var detailText(default, null):String = "";

	public function new(type:String, id:Int, prizeName:String, desc:String = "", universal:Bool = false, finished:Bool = false) {
		if (PrizePopup.instance != null) {
			PrizePopup.instance.remove();
		}
		super(false);
		art = new PrizePopupView();
		contentData = new PrizeContent(type,id,prizeName,desc,universal,finished);

		setVisible("exp", false);
		setVisible("hat", false);
		setVisible("head", false);
		setVisible("body", false);
		setVisible("foot", false);
		setVisible("flavorBg", false);
		setVisible("flavor", false);

		if (contentData.flavorVisible) showFlavor(contentData.flavorText,contentData.flavorHtml);

		if (type == "hat" || type == "eHat") {
			target = container("hat");
			targetName = contentData.targetName;
		} else if (type == "head" || type == "eHead") {
			target = container("head");
			targetName = contentData.targetName;
		} else if (type == "body" || type == "eBody") {
			target = container("body");
			targetName = contentData.targetName;
		} else if (type == "feet" || type == "eFeet") {
			target = container("foot");
			targetName = contentData.targetName;
		}

		if (type == "exp") {
			moveY("titleBox", -105);
			target = container("exp");
			targetName = "exp";
			if (desc != "" && target != null) target.y = -80;
			detailText = contentData.detailText;
			setText(textField(target, "textBox"), detailText);
		}

		if (type == "cancel") {
			moveY("bg", -120);
			setHeight("bg", 150);
			moveY("titleBox", -105);
			setVisible("textBox", false);
			moveY("close_bt", -10);
			target = container("exp");
			targetName = "exp";
			if (target != null) {
				target.y = -80;
			}
			detailText = contentData.detailText;
			setText(textField(target, "textBox"), detailText);
		}

		if (type == "eHat" || type == "eHead" || type == "eBody" || type == "eFeet") {
			activateEpicAnimation();
		} else if (type != "exp" && type != "cancel") {
			// cheese hat workaround: only the cheese hat (id 16) shows colorMC2.
			setChildVisible(target, "colorMC2", type == "hat" && id == 16);
		}

		if (target != null) {
			target.visible = true;
		}
		if (type != "exp" && type != "cancel") {
			gotoChild(target, id);
			gotoChild(child(target, "colorMC"), id);
			gotoChild(child(target, "colorMC2"), id);
			// `headsMC.gotoAndStop()` reapplies the authored properties of its
			// selected frame. In Flash, the four hat instances retain the visibility
			// assigned above the frame change; our timeline renderer reapplies their
			// authored `visible` value while rendering that frame. Hide them after
			// selecting the head so their auto-playing hatsMC timelines cannot show
			// through the prize preview.
			if (type == "head" || type == "eHead") {
				hideHeadHats();
			}
		}

		bodyText = contentData.bodyText;
		setText(textField(art, "textBox"), bodyText);

		titleText = contentData.titleText;
		setText(textField(art, "titleBox"), titleText);

		closeBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "close_bt"), function():Void startFadeOut());
		addChild(art);
		PrizePopup.instance = this;
	}

	private function activateEpicAnimation():Void {
		var colorMC2 = child(target, "colorMC2");
		if (colorMC2 != null) {
			epicFlash.addItem(colorMC2);
		}
		epicFlash.setDelay(300);
		epicFlash.start();
	}

	private function showFlavor(text:String, html:Bool):Void {
		flavorVisible = true;
		setVisible("flavorBg", true);
		setVisible("flavor", true);
		var field = textField(art, "flavor");
		if (field != null) {
			if (html) {
				field.htmlText = text;
			} else {
				field.text = text;
			}
			field.autoSize = openfl.text.TextFieldAutoSize.LEFT;
			flavorText = field.text;
			var bg = DisplayUtil.directChildByName(art, "flavorBg");
			if (bg != null) {
				bg.height = field.height + 15;
			}
		} else {
			flavorText = text;
		}
	}

	private function hideHeadHats():Void {
		var head = container("head");
		for (i in 1...5) {
			setChildVisible(head, "hat" + i, false);
		}
	}

	// --- authored-art helpers -------------------------------------------------

	private function container(name:String):Null<DisplayObjectContainer> {
		return Std.downcast(DisplayUtil.directChildByName(art, name), DisplayObjectContainer);
	}

	private function child(parent:Null<DisplayObjectContainer>, name:String):Null<DisplayObject> {
		return parent == null ? null : DisplayUtil.directChildByName(parent, name);
	}

	private function textField(parent:Null<DisplayObjectContainer>, name:String):Null<TextField> {
		return LobbyArt.directText(parent, name);
	}

	private function setText(field:Null<TextField>, value:String):Void {
		if (field != null) {
			field.text = value;
		}
	}

	private function setVisible(name:String, visible:Bool):Void {
		var d = DisplayUtil.directChildByName(art, name);
		if (d != null) {
			d.visible = visible;
		}
	}

	private function setChildVisible(parent:Null<DisplayObjectContainer>, name:String, visible:Bool):Void {
		var d = child(parent, name);
		if (d != null) {
			d.visible = visible;
		}
	}

	private function moveY(name:String, y:Float):Void {
		var d = DisplayUtil.directChildByName(art, name);
		if (d != null) {
			d.y = y;
		}
	}

	private function setHeight(name:String, height:Float):Void {
		var d = DisplayUtil.directChildByName(art, name);
		if (d != null) {
			d.height = height;
		}
	}

	private function gotoChild(target:Null<DisplayObject>, frame:Int):Void {
		var clip = Std.downcast(target, PrizePartSymbol);
		if (clip != null) {
			clip.setPartFrame(frame);
			return;
		}
		var channel = Std.downcast(target, PrizePartSymbolChannel);
		if (channel != null) channel.setPartFrame(frame);
	}

	/** Mirrors `Data.aOrAn`: "an" before a vowel, otherwise "a". */
	public static function aOrAnFor(s:String):String {
		if (s == null || s.length == 0) {
			return "a";
		}
		var first = s.charAt(0).toLowerCase();
		return (first == "a" || first == "e" || first == "i" || first == "o" || first == "u") ? "an" : "a";
	}

	override public function remove():Void {
		PrizePopup.instance = null;
		if (epicFlash != null) {
			epicFlash.remove();
			epicFlash = null;
		}
		if (closeBinding != null) {
			LobbyArt.unbind(closeBinding);
			closeBinding = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
