package pr2.lobby.account;

import openfl.display.DisplayObjectContainer;
import pr2.character.Parts;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.runtime.EpicFlash;
import pr2.lobby.store.StorePopupView;
import pr2.util.DisplayUtil;

/**
	Entry popup for Flash `player_profile.PartInfo.PartInfoPopup`.

	This owns the singleton shell and selected part arrays; catalog row rendering
	is filled by the part-listing/store TODOs.
**/
class PartInfoPopup extends Popup {
	public static var instance:Null<PartInfoPopup>;

	private var art:Null<StorePopupView>;
	private var closeBinding:Null<LobbyArt.Binding>;
	private var holder:Null<DisplayObjectContainer>;
	private var listings:Array<PartInfoListing> = [];
	private var epicFlash:EpicFlash = new EpicFlash();

	public var mode(default, null):String = "";
	public var ownedParts(default, null):Array<String> = [];
	public var ownedEpics(default, null):Array<String> = [];
	public var hasEpicEverything(default, null):Bool = false;

	public function new(type:String, parts:Array<String>, epics:Array<String>) {
		var previous = instance;
		super();
		if (previous != null) {
			previous.startFadeOut();
		}
		instance = this;
		mode = type;
		ownedParts = parts.copy();
		ownedEpics = epics.copy();
		hasEpicEverything = ownedEpics.indexOf("*") != -1;

		art = new StorePopupView();
		art.y += 20;
		addChild(art);
		holder = Std.downcast(DisplayUtil.directChildByName(art, "itemsHolder"), DisplayObjectContainer);
		var title = LobbyArt.directText(art, "titleBox");
		if (title != null) {
			title.text = "-- " + ucfirst(Parts.getPlural(type)) + " --";
		}
		var coinsBg = DisplayUtil.directChildByName(art, "coinsLeftBg");
		var coins = LobbyArt.directText(art, "coinsLeftBox");
		if (coinsBg != null) coinsBg.visible = false;
		if (coins != null) coins.visible = false;
		closeBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "close_bt"), startFadeOut);
		populateParts();
		if (!epicFlash.isEmpty()) {
			epicFlash.start();
		}
	}

	public function holderForTests():Null<DisplayObjectContainer> {
		return holder;
	}

	public function listingsForTests():Array<PartInfoListing> {
		return listings.copy();
	}

	override public function remove():Void {
		if (instance == this) {
			instance = null;
		}
		epicFlash.remove();
		for (listing in listings) {
			listing.remove();
		}
		listings.resize(0);
		LobbyArt.unbind(closeBinding);
		closeBinding = null;
		holder = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private static function ucfirst(value:String):String {
		if (value == null || value == "") {
			return "";
		}
		return value.charAt(0).toUpperCase() + value.substr(1).toLowerCase();
	}

	private function populateParts():Void {
		var ids = Parts.getPartArray(mode);
		if (ids == null) {
			new MessagePopup("Error: Invalid part mode specified.");
			remove();
			return;
		}
		for (id in ids) {
			createListing(id);
		}
	}

	private function createListing(id:Int):Void {
		var type = Parts.validateType(mode);
		if (type == null) {
			return;
		}
		var desc = Parts.getDesc(mode, id);
		var obtain = Parts.getObtain(mode, id);
		var listing = new PartInfoListing(type, id, Parts.getName(mode, id), desc == null ? "" : desc, obtain == null ? "" : obtain,
			ownedParts.indexOf(Std.string(id)) != -1, ownedEpics.indexOf(Std.string(id)) != -1, hasEpicEverything);
		if (ownedEpics.indexOf(Std.string(id)) != -1) {
			listing.addEpicFlash(epicFlash);
		}
		listing.x = (listings.length % 3) * 137;
		listing.y = Math.floor(listings.length / 3) * 160;
		if (holder != null) {
			holder.addChild(listing);
		}
		listings.push(listing);
	}
}
