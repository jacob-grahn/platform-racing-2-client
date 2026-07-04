package pr2.lobby.account;

import openfl.display.DisplayObject;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import pr2.character.Parts;
import pr2.display.Removable;
import pr2.lobby.LobbyArt;
import pr2.runtime.EpicFlash;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class PartInfoListing extends Removable {
	private var art:Null<PR2MovieClip>;
	private var fallbackArt:Null<Sprite>;
	private var cover:Null<DisplayObject>;
	private var bg:Null<DisplayObject>;
	private var ownedBox:Null<DisplayObject>;
	private var epicBox:Null<TextField>;
	private var target:Null<PR2MovieClip>;
	private var djinnPreview:Null<AccountCharacter>;
	private var hasEpicEverything:Bool;
	private var partType:String;
	private var partId:Int;
	private var partName:String;
	private var partDesc:String;
	private var partObtain:String;
	private var partOwned:Bool;
	private var partEpic:Bool;

	public function new(type:String, id:Int, name:String, descText:String, obtain:String, has:Bool, hasEpic:Bool, hasEpicEverything:Bool = false) {
		super();
		partType = type;
		partId = id;
		partName = name;
		partDesc = descText;
		partObtain = obtain;
		partOwned = has;
		partEpic = hasEpic;
		this.hasEpicEverything = hasEpicEverything;
		try {
			art = PR2MovieClip.fromLinkage("PartInfoListingGraphic", {maxNestedDepth: 8});
			addChild(art);
		} catch (_:Dynamic) {
			fallbackArt = createFallbackArt();
			addChild(fallbackArt);
		}

		var root = art != null ? art : fallbackArt;
		bg = DisplayUtil.findByName(root, "bg");
		cover = DisplayUtil.findByName(root, "cover");
		ownedBox = DisplayUtil.findByName(root, "ownedBox");
		epicBox = LobbyArt.text(root, "epicBox");
		var title = LobbyArt.text(root, "titleBox");
		var desc = LobbyArt.text(root, "descBox");
		if (title != null) {
			title.text = name + " " + ucfirst(type);
			title.mouseEnabled = false;
		}
		if (desc != null) {
			desc.htmlText = descText;
		}
		showPartPreview();
		if (bg != null) {
			bg.visible = false;
			var bgInteractive = Std.downcast(bg, InteractiveObject);
			if (bgInteractive != null) bgInteractive.mouseEnabled = false;
		}
		if (ownedBox != null) {
			ownedBox.visible = has;
		}
		if (epicBox != null) {
			epicBox.visible = has && (hasEpic || hasEpicEverything);
			if (!hasEpicEverything || hasEpic) {
				epicBox.text = "Upgraded!";
			}
		}
		if (cover != null) {
			cover.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			cover.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			cover.addEventListener(MouseEvent.CLICK, clickHandler);
			var button = Std.downcast(cover, Sprite);
			if (button != null) {
				button.buttonMode = true;
				button.useHandCursor = true;
			}
		}
	}

	public function partTypeForTests():String {
		return partType;
	}

	public function partIdForTests():Int {
		return partId;
	}

	public function ownedVisibleForTests():Bool {
		return ownedBox != null && ownedBox.visible;
	}

	public function epicVisibleForTests():Bool {
		return epicBox != null && epicBox.visible;
	}

	public function epicTextForTests():String {
		return epicBox == null ? "" : epicBox.text;
	}

	public function targetForTests():Null<PR2MovieClip> {
		return target;
	}

	public function djinnPreviewForTests():Null<AccountCharacter> {
		return djinnPreview;
	}

	public function colorMC2VisibleForTests():Bool {
		var colorMC2 = target == null ? null : DisplayUtil.findByName(target, "colorMC2");
		return colorMC2 != null && colorMC2.visible;
	}

	public function addEpicFlash(epicFlash:EpicFlash):Void {
		if (epicBox != null) {
			epicFlash.addItem(epicBox);
		}
	}

	override public function remove():Void {
		if (cover != null) {
			cover.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			cover.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			cover.removeEventListener(MouseEvent.CLICK, clickHandler);
			cover = null;
		}
		bg = null;
		ownedBox = null;
		epicBox = null;
		target = null;
		if (djinnPreview != null) {
			djinnPreview.remove();
			djinnPreview = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (fallbackArt != null) {
			fallbackArt = null;
		}
		super.remove();
	}

	private function onMouseOver(_:MouseEvent):Void {
		if (bg != null) bg.visible = true;
	}

	private function onMouseOut(_:MouseEvent):Void {
		if (bg != null) bg.visible = false;
	}

	private function clickHandler(_:MouseEvent):Void {
		new PartPopup(partType, partId, partName, partDesc, partObtain, partOwned, partEpic, hasEpicEverything);
	}

	private function showPartPreview():Void {
		if (art == null) {
			return;
		}
		if (ownedBox != null) {
			ownedBox.y = 23.55;
		}
		if (epicBox != null) {
			epicBox.y = partType == "FEET" ? 23.55 : 75.35;
		}
		target = PartPopup.setupPartPreview(art, partType, partId, partOwned, 2);
		djinnPreview = PartPopup.setupDjinnPreview(art, partType, partId, partOwned, 65, 85);
	}

	private static function ucfirst(value:String):String {
		if (value == null || value == "") return "";
		return value.charAt(0).toUpperCase() + value.substr(1).toLowerCase();
	}

	private static function createFallbackArt():Sprite {
		var root = new Sprite();
		var bg = new Sprite();
		bg.name = "bg";
		bg.graphics.beginFill(0xE3E2C3);
		bg.graphics.drawRect(0, 0, 122, 145);
		bg.graphics.endFill();
		root.addChild(bg);
		var title = field("titleBox", 10, 5, 109);
		root.addChild(title);
		var owned = field("ownedBox", 10, 25.55, 42);
		owned.text = "Owned!";
		root.addChild(owned);
		var epic = field("epicBox", 65.05, 77.35, 55.95);
		epic.text = "Purchased!";
		root.addChild(epic);
		var desc = field("descBox", 10, 96, 108);
		desc.wordWrap = true;
		desc.multiline = true;
		root.addChild(desc);
		var cover = new Sprite();
		cover.name = "cover";
		cover.graphics.beginFill(0, 0);
		cover.graphics.drawRect(0, 0, 122, 145);
		cover.graphics.endFill();
		root.addChild(cover);
		return root;
	}

	private static function field(name:String, x:Float, y:Float, width:Float):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = 70;
		text.autoSize = TextFieldAutoSize.LEFT;
		text.selectable = false;
		return text;
	}
}
