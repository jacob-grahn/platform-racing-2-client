package pr2.lobby.account;

import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.character.Parts;
import pr2.lobby.LobbyArt;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.tabs.AccountTab;
import pr2.runtime.EpicFlash;
import pr2.runtime.FlButton;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class PartPopup extends Popup {
	public static var instance:Null<PartPopup>;

	private var art:Null<PR2MovieClip>;
	private var closeBinding:Null<LobbyArt.Binding>;
	private var equipButton:Null<FlButton>;
	private var target:Null<PR2MovieClip>;
	private var djinnPreview:Null<AccountCharacter>;
	private var epicFlash:EpicFlash = new EpicFlash();
	private var nameMaker:HtmlNameMaker = new HtmlNameMaker();
	private var partType:String;
	private var partId:Int;
	private var partName:String;
	private var partDesc:String;
	private var partObtain:String;
	private var partOwned:Bool;
	private var partEpic:Bool;
	private var hasEpicEverything:Bool;

	public function new(type:String, id:Int, name:String, desc:String, obtain:String, has:Bool, hasEpic:Bool, hasEpicEverything:Bool = false) {
		var previous = instance;
		super();
		if (previous != null) {
			previous.startFadeOut();
		}
		instance = this;
		partType = Parts.validateType(type);
		if (partType == null) {
			partType = type == null ? "" : type.toUpperCase();
		}
		partId = id;
		partName = name;
		partDesc = desc == null ? "" : desc;
		partObtain = obtain == null ? "" : obtain;
		partOwned = has;
		partEpic = hasEpic;
		this.hasEpicEverything = hasEpicEverything;

		art = PR2MovieClip.fromLinkage("PartPopupGraphic", {maxNestedDepth: 8});
		addChild(art);
		var title = LobbyArt.text(art, "titleBox");
		var descBox = LobbyArt.text(art, "descBox");
		if (title != null) title.text = "-- " + partName + " " + ucfirst(partType) + " --";
		if (descBox != null) descBox.htmlText = partDesc;
		dynamicObtain();
		showPart();
		closeBinding = LobbyArt.bind(DisplayUtil.findByName(art, "close_bt"), startFadeOut);
	}

	public function targetForTests():Null<PR2MovieClip> {
		return target;
	}

	public function djinnPreviewForTests():Null<AccountCharacter> {
		return djinnPreview;
	}

	public function obtainHtmlForTests():String {
		var obtainBox = LobbyArt.text(art, "obtainBox");
		return obtainBox == null ? "" : obtainBox.htmlText;
	}

	public function epicTextForTests():String {
		var epicBox = LobbyArt.text(art, "epicBox");
		return epicBox == null ? "" : epicBox.text;
	}

	public function ownedTextForTests():String {
		var ownedBox = LobbyArt.text(art, "ownedBox");
		return ownedBox == null ? "" : ownedBox.text;
	}

	public function epicFlashHasItemsForTests():Bool {
		return !epicFlash.isEmpty();
	}

	public function colorMC2VisibleForTests():Bool {
		var colorMC2 = target == null ? null : DisplayUtil.findByName(target, "colorMC2");
		return colorMC2 != null && colorMC2.visible;
	}

	public function equipEnabledForTests():Bool {
		return equipButton != null && equipButton.enabled;
	}

	override public function remove():Void {
		if (instance == this) {
			instance = null;
		}
		epicFlash.remove();
		nameMaker.remove();
		LobbyArt.unbind(closeBinding);
		closeBinding = null;
		if (equipButton != null) {
			equipButton.removeEventListener(MouseEvent.CLICK, equipPart);
			equipButton = null;
		}
		if (djinnPreview != null) {
			djinnPreview.remove();
			djinnPreview = null;
		}
		target = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private function dynamicObtain():Void {
		var obtain = partObtain;
		var isHat = partType.toLowerCase() == "hat";
		if (isHat) {
			switch (partName) {
				case "Propeller":
					obtain = replaceLevel(obtain, "Hat Factory", 84156);
					obtain = replaceUser(obtain, "Jiggmin", "3");
					obtain = replaceLevel(obtain, "Volcanic Inferno", 4866546);
					obtain = replaceUser(obtain, "Pounce", "1");
				case "Top":
					obtain = replaceLevel(obtain, "The Golden Compass", 3236908);
					obtain = replaceUser(obtain, "-Shadowfax-", "1");
				case "Moon":
					obtain = replaceLevel(obtain, "Redemption", 5793214);
					obtain = replaceUser(obtain, "cooldude90", "1");
				case "Thief":
					obtain = replaceLevel(obtain, "Apocalypse", 5877893);
					obtain = replaceUser(obtain, "Divinity", "1");
				case "Jigg":
					obtain = replaceLevel(obtain, "Buto (EXACT)", 1738847);
					obtain = replaceUser(obtain, "ZePHiR", "1");
				case "Jellyfish":
					obtain = replaceLevel(obtain, "Deeper", 6493337);
					obtain = replaceUser(obtain, "Sothal", "1");
				case "Cheese":
					obtain = replaceLevel(obtain, "Moon is made w/ cheese", 6207945);
					obtain = replaceUser(obtain, "ktosss450", "1");
				default:
			}
		} else {
			switch (partName) {
				case "Slender":
					obtain = replaceLevel(obtain, "-Deliverance-", 1896157);
					obtain = replaceUser(obtain, "changelings", "1");
				case "Sea":
					obtain = replaceLevel(obtain, "~Under the sea~", 2255404);
					obtain = replaceUser(obtain, "Rammjet", "1");
				case "Blobfish":
					obtain = replaceLevel(obtain, "Underwater World", 5985129);
					obtain = replaceUser(obtain, "Odin0030", "1");
				case "Gladiator":
					obtain = replaceLevel(obtain, "Romªn Empire", 3385938);
					obtain = replaceUser(obtain, "Overbeing", "1");
				default:
			}
		}
		var obtainBox = LobbyArt.text(art, "obtainBox");
		if (obtainBox != null) {
			obtainBox.htmlText = "How to obtain: " + obtain;
			nameMaker.listenForLink(obtainBox);
		}
	}

	private function replaceLevel(obtain:String, levelName:String, id:Int):String {
		return StringTools.replace(obtain, levelName, nameMaker.makeLevel(levelName, id));
	}

	private function replaceUser(obtain:String, userName:String, group:String):String {
		return StringTools.replace(obtain, userName, nameMaker.makeName(userName, group));
	}

	private function showPart():Void {
		var ownedBox = LobbyArt.text(art, "ownedBox");
		var epicBox = LobbyArt.text(art, "epicBox");
		if (ownedBox != null) {
			ownedBox.text = "You don't own this part.";
		}
		if (epicBox != null) {
			epicBox.text = "You don't own this epic upgrade.";
		}
		target = setupPartPreview(art, partType, partId, partOwned, 1.8);
		djinnPreview = setupDjinnPreview(art, partType, partId, partOwned, -130, 10);
		var colorMC2 = target == null ? null : DisplayUtil.findByName(target, "colorMC2");
		if (partOwned) {
			if (target != null) target.alpha = 1;
			if (ownedBox != null) {
				ownedBox.text = "You own this part!";
				ownedBox.textColor = 0x006600;
			}
			if ((partEpic || hasEpicEverything) && colorMC2 != null) {
				colorMC2.visible = true;
				epicFlash.addItem(colorMC2);
			}
			equipButton = Std.downcast(DisplayUtil.findByName(art, "equip_bt"), FlButton);
			if (equipButton != null) {
				equipButton.enabled = true;
				equipButton.addEventListener(MouseEvent.CLICK, equipPart, false, 0, true);
			}
		}
		if (partEpic) {
			if (epicBox != null) {
				epicBox.text = "You own this epic upgrade!";
				epicFlash.addItem(epicBox);
			}
		} else if (hasEpicEverything && epicBox != null) {
			epicBox.text = "Epic Upgrade included with EE purchase!";
			epicBox.textColor = 0x006600;
		}
		if (!epicFlash.isEmpty()) {
			epicFlash.start();
		}
	}

	private function equipPart(_:MouseEvent):Void {
		AccountTab.setManualPart(partType.toLowerCase(), partId);
		startFadeOut();
		if (PartInfoPopup.instance != null) {
			PartInfoPopup.instance.startFadeOut();
		}
	}

	public static function setupPartPreview(root:PR2MovieClip, type:String, id:Int, has:Bool, fredScaleDivisor:Float):Null<PR2MovieClip> {
		var hat = clip(root, "hat");
		var head = clip(root, "head");
		var body = clip(root, "body");
		var foot = clip(root, "foot");
		for (part in [hat, head, body, foot]) {
			if (part != null) part.visible = false;
		}
		if (head != null) {
			for (name in ["hat1", "hat2", "hat3", "hat4"]) {
				var headHat = DisplayUtil.findByName(head, name);
				if (headHat != null) headHat.visible = false;
			}
		}
		var target = switch (type) {
			case "HAT": hat;
			case "HEAD": head;
			case "BODY": body;
			case "FEET": foot;
			default: null;
		}
		if (target == null) return null;
		if (id == 29 && type == "BODY") {
			target.y += 10;
			target.width = target.width / fredScaleDivisor;
			target.height = target.height / fredScaleDivisor;
		} else if (id == 14 && type == "HAT") {
			target.y += 10;
		}
		target.visible = true;
		target.alpha = has ? 1 : 0.1;
		target.gotoAndStop(id);
		var colorMC = clip(target, "colorMC");
		if (colorMC != null) colorMC.gotoAndStop(id);
		var colorMC2 = clip(target, "colorMC2");
		if (colorMC2 != null) {
			colorMC2.gotoAndStop(id);
			colorMC2.visible = type == "HAT" && id == 16;
		}
		return target;
	}

	public static function setupDjinnPreview(root:PR2MovieClip, type:String, id:Int, has:Bool, x:Float, y:Float):Null<AccountCharacter> {
		if (id != 35 || (type != "BODY" && type != "FEET")) {
			return null;
		}
		var bodyId = type == "BODY" ? 35 : 33;
		var feetId = type == "FEET" ? 35 : 33;
		var character = new AccountCharacter(1, 31, bodyId, feetId);
		character.setColors(0, -1, 0, -1, 255, 3329330, 255, 3329330);
		character.scaleX = character.scaleY = 1;
		character.x = x;
		character.y = y;
		if (!has) character.alpha = 0.1;
		var insert = Std.int(Math.min(2, root.numChildren));
		root.addChildAt(character, insert);
		return character;
	}

	private static function clip(root:Null<openfl.display.DisplayObjectContainer>, name:String):Null<PR2MovieClip> {
		return Std.downcast(DisplayUtil.findByName(root, name), PR2MovieClip);
	}

	private static function ucfirst(value:String):String {
		if (value == null || value == "") return "";
		return value.charAt(0).toUpperCase() + value.substr(1).toLowerCase();
	}
}
