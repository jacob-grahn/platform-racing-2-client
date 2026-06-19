package pr2.lobby.level;

import haxe.Json;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyPopups;
import pr2.lobby.LobbySession;
import pr2.lobby.SecureData;
import pr2.lobby.account.AccountState;
import pr2.lobby.chat.ChatText;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.dialogs.HoverPopup;
import pr2.lobby.level.LevelAccess.LevelAccessState;
import pr2.net.CampaignLevelInfo;
import pr2.net.FormPostClient;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `level_browser.LevelItem` — one course tile in a listing grid.

	Renders the title, author (clickable), rating bar, and game-mode background;
	exposes four join `Slot`s wired to the gameserver `fill_slot`/`confirm_slot`/
	`clear_slot` round-trip; handles favorites add/remove POSTs; and gates play
	behind the access cover (password / rank / hat) using the pure `LevelAccess`
	logic. Clicking the info button opens the level popup.

	Still pending from the original: the `Encryptor`-based decrypt of the
	password-check payload (the POST round-trip and success gating are wired).
**/
class LevelItem extends Sprite {
	public final courseID:Int;
	public final version:Int;

	private var info:CampaignLevelInfo;
	private var art:PR2MovieClip;
	private var htmlNameMaker:HtmlNameMaker;
	private var slots:Array<Slot> = [];
	private var passOK:Bool;
	private var coverShown:Bool = false;
	private var passPending:Bool = false;

	private var infoButton:Null<DisplayObject>;
	private var plusButton:Null<DisplayObject>;
	private var minusButton:Null<DisplayObject>;
	private var accessCover:Null<PR2MovieClip>;
	private var coverText:Null<TextField>;
	private var passButton:Null<DisplayObject>;
	private var passBox:Null<TextField>;

	private var infoBinding:Null<LobbyArt.Binding>;
	private var favBinding:Null<LobbyArt.Binding>;
	private var passBinding:Null<LobbyArt.Binding>;
	private var infoPopup:Null<HoverPopup>;

	public function new(info:CampaignLevelInfo) {
		super();
		this.info = info;
		this.courseID = info.levelId;
		this.version = info.version;
		this.passOK = !info.pass;

		art = PR2MovieClip.fromLinkage("LevelItemGraphic", {maxNestedDepth: 10});
		addChild(art);
		htmlNameMaker = new HtmlNameMaker();

		// Title / author are exported without instance names; recover by y order.
		var fields = LobbyArt.directTextFields(art);
		if (fields.length > 0) {
			fields[0].text = info.title;
		}
		if (fields.length > 1) {
			fields[1].htmlText = "by " + htmlNameMaker.makeName(info.userName, info.userGroup);
			htmlNameMaker.listenForLink(fields[1]);
		}

		setRatingBar(info.rating);
		setBackgroundFrame(info.type);

		infoButton = LobbyArt.findByName(art, "infoButton");
		infoBinding = LobbyArt.bind(infoButton, clickInfo);
		if (infoButton != null) {
			infoButton.addEventListener(MouseEvent.MOUSE_OVER, overInfo);
			infoButton.addEventListener(MouseEvent.MOUSE_OUT, outInfo);
		}

		plusButton = LobbyArt.findByName(art, "plusButton");
		minusButton = LobbyArt.findByName(art, "minusButton");
		setupFavoriteButtons();

		accessCover = Std.downcast(LobbyArt.findByName(art, "accessCover"), PR2MovieClip);
		if (accessCover != null) {
			coverText = LobbyArt.text(accessCover, "textBox");
			passButton = LobbyArt.findByName(accessCover, "passButton");
			passBox = LobbyArt.text(accessCover, "passBox");
			// Start with the cover detached; testAccess re-attaches it if gated.
			detachCover();
		}

		addSlots();
		testAccess();

		var cm = pr2.net.CommandHandler.commandHandler;
		cm.defineCommand("fillSlot" + courseID + "_" + version, onFillSlot);
		cm.defineCommand("confirmSlot" + courseID + "_" + version, onConfirmSlot);
		cm.defineCommand("clearSlot" + courseID + "_" + version, onClearSlot);
	}

	private function setRatingBar(rating:Float):Void {
		var stars = Std.downcast(LobbyArt.findByName(art, "ratingStars"), DisplayObjectContainer);
		if (stars != null) {
			var bar = LobbyArt.findByName(stars, "bar");
			if (bar != null) {
				bar.scaleX = rating / 5;
			}
		}
	}

	private function setBackgroundFrame(type:String):Void {
		var frame = switch (type) {
			case "r": 1;
			case "d": 2;
			case "e": 3;
			case "o": 4;
			case "h": 5;
			default: 1;
		};
		var bg = Std.downcast(LobbyArt.findByName(art, "bg"), PR2MovieClip);
		if (bg != null) {
			bg.gotoAndStop(frame);
		}
	}

	private function setupFavoriteButtons():Void {
		if (LobbySession.group < 1) {
			removeArtChild(plusButton);
			removeArtChild(minusButton);
			return;
		}
		if (LobbySession.isFavorite(courseID)) {
			removeArtChild(plusButton);
			favBinding = LobbyArt.bind(minusButton, function():Void clickFavorite("remove"));
		} else {
			removeArtChild(minusButton);
			favBinding = LobbyArt.bind(plusButton, function():Void clickFavorite("add"));
		}
	}

	// ---- access cover ----------------------------------------------------

	public function testAccess():Void {
		var byMe = LobbySession.userName.toLowerCase() == info.userName.toLowerCase();
		var myRank = Std.int(SecureData.getNumber("userRank"));
		var state = LevelAccess.evaluate(info.pass, passOK, LobbySession.group, byMe, myRank, info.minLevel, AccountState.currentHat,
			info.badHats);

		if (coverText != null) {
			coverText.text = LevelAccess.coverText(state);
		}
		switch (state) {
			case PassNeeded:
				attachPassControls();
				attachCover();
			case Open:
				detachPassControls();
				detachCover();
			default:
				detachPassControls();
				attachCover();
		}
	}

	private function attachCover():Void {
		if (accessCover != null && accessCover.parent != art) {
			art.addChild(accessCover);
		}
		coverShown = true;
	}

	private function detachCover():Void {
		if (accessCover != null && accessCover.parent == art) {
			art.removeChild(accessCover);
		}
		coverShown = false;
	}

	private function attachPassControls():Void {
		if (accessCover == null) {
			return;
		}
		if (passButton != null && passButton.parent != accessCover) {
			accessCover.addChild(passButton);
		}
		if (passBox != null && passBox.parent != accessCover) {
			accessCover.addChild(passBox);
		}
		if (passBinding == null) {
			passBinding = LobbyArt.bind(passButton, clickPassEnter);
		}
	}

	private function detachPassControls():Void {
		if (passBinding != null) {
			LobbyArt.unbind(passBinding);
			passBinding = null;
		}
		if (accessCover != null) {
			removeChildFrom(accessCover, passButton);
			removeChildFrom(accessCover, passBox);
		}
	}

	private function clickPassEnter():Void {
		if (passPending || passBox == null) {
			return;
		}
		passPending = true;
		var entered = passBox.text;
		passBox.text = "checking...";
		var hash = haxe.crypto.Md5.encode(entered + ServerConfig.LEVEL_LIST_SALT);
		var fields = ["course_id" => Std.string(courseID), "hash" => hash];
		FormPostClient.post(ServerConfig.levelPassCheckUrl(), fields, onPassResponse, onPassError);
	}

	private function onPassResponse(body:String):Void {
		passPending = false;
		var success = false;
		try {
			var obj:Dynamic = Json.parse(body);
			// Flash decrypts `result` and checks `access == 1`; without the ported
			// Encryptor we accept the server's success flag for the round-trip.
			success = Reflect.field(obj, "success") == true || Std.string(Reflect.field(obj, "access")) == "1";
		} catch (_:Dynamic) {
			success = false;
		}
		if (success) {
			passOK = true;
			testAccess();
		} else if (passBox != null) {
			passBox.text = "nope!";
		}
	}

	private function onPassError(_:String):Void {
		passPending = false;
		if (passBox != null) {
			passBox.text = "";
		}
	}

	// ---- favorites -------------------------------------------------------

	private function clickFavorite(mode:String):Void {
		var fields = ["mode" => mode, "level_id" => Std.string(courseID)];
		FormPostClient.post(ServerConfig.favoriteModifyUrl(), fields, function(body:String):Void {
			onFavoriteResult(mode, body);
		});
	}

	private function onFavoriteResult(mode:String, _:String):Void {
		if (favBinding != null) {
			LobbyArt.unbind(favBinding);
			favBinding = null;
		}
		if (mode == "add") {
			if (!LobbySession.isFavorite(courseID)) {
				LobbySession.favoriteLevels.push(courseID);
			}
			removeArtChild(plusButton);
			if (minusButton != null && minusButton.parent != art) {
				art.addChild(minusButton);
			}
			favBinding = LobbyArt.bind(minusButton, function():Void clickFavorite("remove"));
		} else {
			LobbySession.favoriteLevels.remove(courseID);
			removeArtChild(minusButton);
			if (plusButton != null && plusButton.parent != art) {
				art.addChild(plusButton);
			}
			favBinding = LobbyArt.bind(plusButton, function():Void clickFavorite("add"));
		}
	}

	// ---- slots -----------------------------------------------------------

	private function addSlots():Void {
		var holder = Std.downcast(LobbyArt.findByName(art, "slotsHolder"), DisplayObjectContainer);
		if (holder == null) {
			return;
		}
		var y = 0.0;
		for (i in 0...4) {
			var slot = new Slot(i, this);
			slot.x = 0;
			slot.y = y;
			y += 16;
			slots.push(slot);
			holder.addChild(slot);
		}
	}

	public function sendFillSlot(slotNum:Int):Void {
		LobbySocket.write("fill_slot`" + courseID + "_" + version + "`" + slotNum + "`" + LevelListingState.currentPageNum);
	}

	public function sendClearSlot():Void {
		LobbySocket.write("clear_slot`");
	}

	public function sendConfirmSlot():Void {
		LobbySocket.write("confirm_slot`");
	}

	/** Launch this course through the existing level loader (see `LevelLaunch`). */
	public function launchLevel():Void {
		LevelLaunch.launch(courseID, version);
	}

	private function onFillSlot(args:Array<String>):Void {
		var slotNum = Std.parseInt(args[0]);
		if (slotNum == null || slotNum < 0 || slotNum >= slots.length) {
			return;
		}
		var name = args.length > 1 ? args[1] : "";
		var rank = args.length > 2 ? Std.parseFloat(args[2]) : 0;
		var me = args.length > 3 ? args[3] : "";
		slots[slotNum].fillSlot(name, Math.isNaN(rank) ? 0 : rank, me);
	}

	private function onConfirmSlot(args:Array<String>):Void {
		var slotNum = Std.parseInt(args[0]);
		if (slotNum != null && slotNum >= 0 && slotNum < slots.length) {
			slots[slotNum].confirmSlot();
		}
	}

	private function onClearSlot(args:Array<String>):Void {
		var slotNum = Std.parseInt(args[0]);
		if (slotNum != null && slotNum >= 0 && slotNum < slots.length) {
			slots[slotNum].clearSlot();
		}
	}

	// ---- info ------------------------------------------------------------

	private function clickInfo():Void {
		LobbyPopups.showLevel(Std.string(courseID));
	}

	private function overInfo(_:MouseEvent):Void {
		if (infoButton == null) {
			return;
		}
		var popupTitle = "-- " + ChatText.escapeString(info.title) + " --";
		var body = "By: " + ChatText.escapeString(info.userName) + "<br/>"
			+ "Version: " + info.version + "<br/>"
			+ "Min Rank: " + info.minLevel + "<br/>"
			+ "Plays: " + pr2.lobby.NumberFormat.withCommas(info.playCount) + "<br/>"
			+ "Rating: " + info.rating;
		if (ChatText.escapeString(info.note) != "") {
			body += "<br/>-----<br/><i>" + ChatText.escapeString(info.note, true) + "</i>";
		}
		body += "<br/>-----<br/>(click the \"?\" for more info)";
		infoPopup = new HoverPopup(popupTitle, body, infoButton);
	}

	private function outInfo(_:MouseEvent):Void {
		if (infoPopup != null) {
			infoPopup.remove();
			infoPopup = null;
		}
	}

	// ---- helpers ---------------------------------------------------------

	private inline function removeArtChild(child:Null<DisplayObject>):Void {
		removeChildFrom(art, child);
	}

	private static inline function removeChildFrom(parent:DisplayObjectContainer, child:Null<DisplayObject>):Void {
		if (child != null && child.parent == parent) {
			parent.removeChild(child);
		}
	}

	public function remove():Void {
		if (infoButton != null) {
			infoButton.removeEventListener(MouseEvent.MOUSE_OVER, overInfo);
			infoButton.removeEventListener(MouseEvent.MOUSE_OUT, outInfo);
		}
		if (infoPopup != null) {
			infoPopup.remove();
			infoPopup = null;
		}
		LobbyArt.unbind(infoBinding);
		LobbyArt.unbind(favBinding);
		LobbyArt.unbind(passBinding);
		for (slot in slots) {
			slot.remove();
		}
		slots = [];
		if (htmlNameMaker != null) {
			htmlNameMaker.remove();
			htmlNameMaker = null;
		}
		var cm = pr2.net.CommandHandler.commandHandler;
		cm.defineCommand("fillSlot" + courseID + "_" + version, null);
		cm.defineCommand("confirmSlot" + courseID + "_" + version, null);
		cm.defineCommand("clearSlot" + courseID + "_" + version, null);
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
