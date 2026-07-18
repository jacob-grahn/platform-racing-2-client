package pr2.lobby.account;

import openfl.display.DisplayObject;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.display.Removable;
import pr2.lobby.LobbyArt;
import pr2.runtime.EpicFlash;
import pr2.util.DisplayUtil;

class PartInfoListing extends Removable {
	private var art:Null<PartInfoListingView>;
	private var cover:Null<DisplayObject>;
	private var bg:Null<DisplayObject>;
	private var ownedBox:Null<DisplayObject>;
	private var epicBox:Null<TextField>;
	private var target:Null<PartPreview>;
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
		art = new PartInfoListingView();
		addChild(art);
		var root = art;
		bg = DisplayUtil.directChildByName(root, "bg");
		cover = DisplayUtil.directChildByName(root, "cover");
		ownedBox = DisplayUtil.directChildByName(root, "ownedBox");
		epicBox = LobbyArt.directText(root, "epicBox");
		var title = LobbyArt.directText(root, "titleBox");
		var desc = LobbyArt.directText(root, "descBox");
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

	public function targetForTests():Null<PartPreview> {
		return target;
	}

	public function djinnPreviewForTests():Null<AccountCharacter> {
		return djinnPreview;
	}

	public function colorMC2VisibleForTests():Bool {
		return target != null && target.secondaryVisible;
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
		if (art == null) return;
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

}
