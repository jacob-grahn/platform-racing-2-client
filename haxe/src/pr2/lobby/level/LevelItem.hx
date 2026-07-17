package pr2.lobby.level;

import com.jiggmin.data.Data;
import haxe.Json;
import haxe.Timer;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyPopups;
import pr2.lobby.LobbySession;
import pr2.lobby.SecureData;
import pr2.lobby.account.AccountState;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.dialogs.HoverPopup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.lobby.level.LevelAccess.LevelAccessState;
import pr2.net.CampaignLevelInfo;
import pr2.net.FormPostClient;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;
import pr2.util.AsyncRemovalGuard;
import pr2.util.DisplayUtil;

typedef FavoriteUploadFactory = String->Map<String, String>->String->(Dynamic->Void)->Null<UploadingPopup>;
typedef FavoriteHoverDelayFactory = (Void->Void, Int)->Null<Timer>;
typedef LevelPassPostFactory = String->Map<String, String>->(String->Void)->(String->Void)->AsyncRemovable;

/**
	Port of Flash `level_browser.LevelItem` — one course tile in a listing grid.

	Renders the title, author (clickable), rating bar, and game-mode background;
	exposes four join `Slot`s wired to the gameserver `fill_slot`/`confirm_slot`/
	`clear_slot` round-trip; handles favorites add/remove POSTs; and gates play
	behind the access cover (password / rank / hat) using the pure `LevelAccess`
	logic. Clicking the info button opens the level popup.

	The password-check response follows Flash's encrypted `result` payload.
**/
class LevelItem extends Sprite {
	public static var favoriteUploadFactory:FavoriteUploadFactory = defaultFavoriteUpload;
	public static var favoriteHoverDelayFactory:FavoriteHoverDelayFactory = defaultFavoriteHoverDelay;
	public static var passPostFactory:LevelPassPostFactory = defaultPassPost;

	public final courseID:Int;
	public final version:Int;

	private var info:CampaignLevelInfo;
	private var art:LevelItemView;
	private var htmlNameMaker:HtmlNameMaker;
	private var slots:Array<Slot> = [];
	private var passOK:Bool;
	private var coverShown:Bool = false;
	private var passPending:Bool = false;

	private var infoButton:Null<DisplayObject>;
	private var plusButton:Null<DisplayObject>;
	private var minusButton:Null<DisplayObject>;
	private var accessCover:Null<LevelAccessCoverView>;
	private var coverText:Null<TextField>;
	private var passButton:Null<DisplayObject>;
	private var passBox:Null<DisplayObject>;
	private var passField:Null<TextField>;

	private var infoBinding:Null<LobbyArt.Binding>;
	private var favBinding:Null<LobbyArt.Binding>;
	private var passBinding:Null<LobbyArt.Binding>;
	private var infoPopup:Null<HoverPopup>;
	private var favPopup:Null<HoverPopup>;
	private var favHoverTimer:Null<Timer>;
	private var favHoverTarget:Null<DisplayObject>;
	private var uploading:Null<UploadingPopup>;
	private var asyncGuard:AsyncRemovalGuard = new AsyncRemovalGuard();

	public function new(info:CampaignLevelInfo) {
		super();
		this.info = info;
		this.courseID = info.levelId;
		this.version = info.version;
		this.passOK = !info.pass;

		art = new LevelItemView();
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

		infoButton = DisplayUtil.findByName(art, "infoButton");
		infoBinding = LobbyArt.bind(infoButton, clickInfo);
		if (infoButton != null) {
			infoButton.addEventListener(MouseEvent.MOUSE_OVER, overInfo);
			infoButton.addEventListener(MouseEvent.MOUSE_OUT, outInfo);
		}

		plusButton = DisplayUtil.findByName(art, "plusButton");
		minusButton = DisplayUtil.findByName(art, "minusButton");
		setupFavoriteButtons();

		accessCover = art.accessCover;
		if (accessCover != null) {
			coverText = LobbyArt.text(accessCover, "textBox");
			passButton = DisplayUtil.findByName(accessCover, "passButton");
			// `passBox` is an fl.controls.TextInput component: keep the display object
			// itself for attach/detach (its inner field's parent is the wrapper, not
			// the cover) and the inner TextField for reading/writing the entered text.
			passBox = DisplayUtil.findByName(accessCover, "passBox");
			passField = accessCover.input.textField;
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
		var stars = Std.downcast(DisplayUtil.findByName(art, "ratingStars"), DisplayObjectContainer);
		if (stars != null) {
			var bar = DisplayUtil.findByName(stars, "bar");
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
		var bg = art.background;
		if (bg != null) {
			bg.render(frame);
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
			bindFavoriteButton(minusButton, "remove");
		} else {
			removeArtChild(minusButton);
			bindFavoriteButton(plusButton, "add");
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
		setPassControlsEnabled(true);
		if (accessCover != null) {
			removeChildFrom(accessCover, passButton);
			removeChildFrom(accessCover, passBox);
		}
	}

	private function clickPassEnter():Void {
		if (passPending || passField == null) {
			return;
		}
		passPending = true;
		var entered = passField.text;
		setPassControlsEnabled(false);
		passField.text = "checking...";
		var hash = haxe.crypto.Md5.encode(entered + ServerConfig.LEVEL_PASS_SALT);
		var fields = ["course_id" => Std.string(courseID), "hash" => hash];
		asyncGuard.watch(passPostFactory(ServerConfig.levelPassCheckUrl(), fields, asyncGuard.wrap(onPassResponse), asyncGuard.wrap(onPassError)));
	}

	private function onPassResponse(body:String):Void {
		passPending = false;
		var success = false;
		try {
			success = parsePasswordResponse(body, courseID);
		} catch (_:Dynamic) {
			success = false;
		}
		if (success) {
			passOK = true;
			testAccess();
		} else if (passField != null) {
			passField.text = "nope!";
			setPassControlsEnabled(true);
		}
	}

	public static function parsePasswordResponse(body:String, courseID:Int):Bool {
		var ret:Dynamic = Json.parse(body);
		if (Reflect.field(ret, "success") != true) {
			return false;
		}
		var encrypted = Std.string(Reflect.field(ret, "result"));
		var decrypted = PR2Encryptor.decryptBase64(encrypted, ServerConfig.LEVEL_PASS_KEY, ServerConfig.LEVEL_PASS_IV);
		decrypted = normalizePasswordJson(decrypted);
		var obj:Dynamic = Json.parse(decrypted);
		return Std.parseInt(Std.string(Reflect.field(obj, "level_id"))) == courseID
			&& Std.parseInt(Std.string(Reflect.field(obj, "access"))) == 1;
	}

	private static function normalizePasswordJson(value:String):String {
		var cleaned = StringTools.trim(value);
		var start = cleaned.indexOf("{");
		var end = cleaned.indexOf("}", start);
		if (start >= 0 && end >= start) {
			cleaned = cleaned.substring(start, end + 1);
		}
		return StringTools.trim(cleaned);
	}

	private function onPassError(_:String):Void {
		passPending = false;
		if (passField != null) {
			passField.text = "";
		}
		setPassControlsEnabled(true);
	}

	// ---- favorites -------------------------------------------------------

	private function clickFavorite(mode:String):Void {
		if (uploading != null) {
			return;
		}
		var fields = ["mode" => mode, "level_id" => Std.string(courseID)];
		uploading = favoriteUploadFactory(ServerConfig.favoriteModifyUrl(), fields, favoriteUploadLabel(mode), function(result:Dynamic):Void {
			var resultMode = result != null && Reflect.field(result, "mode") != null ? Std.string(Reflect.field(result, "mode")) : mode;
			onFavoriteResult(resultMode);
		});
	}

	private function onFavoriteResult(mode:String):Void {
		clearFavoriteButtonBinding();
		if (mode == "add") {
			if (!LobbySession.isFavorite(courseID)) {
				LobbySession.favoriteLevels.push(courseID);
			}
			removeArtChild(plusButton);
			if (minusButton != null && minusButton.parent != art) {
				art.addChild(minusButton);
			}
			bindFavoriteButton(minusButton, "remove");
		} else {
			LobbySession.favoriteLevels.remove(courseID);
			removeArtChild(minusButton);
			if (plusButton != null && plusButton.parent != art) {
				art.addChild(plusButton);
			}
			bindFavoriteButton(plusButton, "add");
		}
		if (uploading != null) {
			uploading.startFadeOut();
			uploading = null;
		}
	}

	private function bindFavoriteButton(target:Null<DisplayObject>, mode:String):Void {
		if (target == null) {
			return;
		}
		favHoverTarget = target;
		target.addEventListener(MouseEvent.MOUSE_OVER, overFavorite);
		target.addEventListener(MouseEvent.MOUSE_OUT, outFavorite);
		favBinding = LobbyArt.bind(target, function():Void clickFavorite(mode));
	}

	private function clearFavoriteButtonBinding():Void {
		LobbyArt.unbind(favBinding);
		favBinding = null;
		if (favHoverTarget != null) {
			favHoverTarget.removeEventListener(MouseEvent.MOUSE_OVER, overFavorite);
			favHoverTarget.removeEventListener(MouseEvent.MOUSE_OUT, outFavorite);
			favHoverTarget = null;
		}
		clearFavoriteHover();
	}

	private function overFavorite(?_:MouseEvent):Void {
		clearFavoriteHover();
		favHoverTimer = favoriteHoverDelayFactory(showFavoriteHover, 500);
	}

	private function outFavorite(?_:MouseEvent):Void {
		clearFavoriteHover();
	}

	private function showFavoriteHover():Void {
		stopFavoriteHoverTimer();
		var mode = activeFavoriteMode();
		var target = activeFavoriteButton();
		if (mode == "" || target == null) {
			return;
		}
		favPopup = new HoverPopup(favoriteHoverTitle(mode), favoriteHoverMessage(mode), target);
	}

	private function clearFavoriteHover():Void {
		stopFavoriteHoverTimer();
		if (favPopup != null) {
			favPopup.remove();
			favPopup = null;
		}
	}

	private function stopFavoriteHoverTimer():Void {
		if (favHoverTimer != null) {
			favHoverTimer.stop();
			favHoverTimer = null;
		}
	}

	private function activeFavoriteMode():String {
		return plusButton != null && plusButton.parent == art ? "add" : (minusButton != null && minusButton.parent == art ? "remove" : "");
	}

	private function activeFavoriteButton():Null<DisplayObject> {
		return activeFavoriteMode() == "add" ? plusButton : (activeFavoriteMode() == "remove" ? minusButton : null);
	}

	// ---- slots -----------------------------------------------------------

	private function addSlots():Void {
		var holder = Std.downcast(DisplayUtil.findByName(art, "slotsHolder"), DisplayObjectContainer);
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

	public function selectLevel():Void {
		LevelLaunch.select(courseID, version);
	}

	public function clearSelectedLevel():Void {
		LevelLaunch.clear(courseID, version);
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
		infoPopup = new HoverPopup(infoHoverTitle(info), infoHoverBody(info), infoButton);
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

	private static function infoHoverTitle(info:CampaignLevelInfo):String {
		return "-- " + Data.escapeString(info.title) + " --";
	}

	private static function infoHoverBody(info:CampaignLevelInfo):String {
		var noteText = "";
		if (Data.escapeString(info.note) != "") {
			noteText = "<br/>-----<br/><i>" + Data.escapeString(info.note, true) + "</i>";
		}
		return "By: " + Data.escapeString(info.userName) + "<br/>"
			+ "Version: " + Data.formatNumber(info.version) + "<br/>"
			+ "Updated: " + Data.getShortDateStr(info.time) + "<br/>"
			+ "Min Rank: " + info.minLevel + "<br/>"
			+ "Plays: " + Data.formatNumber(info.playCount) + "<br/>"
			+ "Rating: " + info.rating
			+ noteText
			+ "<br/>-----<br/>(click the \"?\" for more info)";
	}

	private static function favoriteUploadLabel(mode:String):String {
		return (mode == "add" ? "Adding to" : "Removing from") + " favorites...";
	}

	private static function favoriteHoverTitle(mode:String):String {
		return mode == "add" ? "Add to Favorites" : "Remove from Favorites";
	}

	private static function favoriteHoverMessage(mode:String):String {
		return mode == "add" ? "Add this level to your favorites list." : "Remove this level from your favorites list.";
	}

	private static function defaultFavoriteUpload(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult);
	}

	private static function defaultFavoriteHoverDelay(callback:Void->Void, delayMs:Int):Null<Timer> {
		return Timer.delay(callback, delayMs);
	}

	private static function defaultPassPost(url:String, fields:Map<String, String>, onResult:String->Void, onError:String->Void):AsyncRemovable {
		return FormPostClient.post(url, fields, onResult, onError);
	}

	private function setPassControlsEnabled(enabled:Bool):Void {
		setControlEnabled(passButton, enabled);
		setControlEnabled(passBox, enabled);
	}

	private static function setControlEnabled(control:Null<DisplayObject>, enabled:Bool):Void {
		if (control == null) {
			return;
		}
		try {
			Reflect.setProperty(control, "enabled", enabled);
		} catch (_:Dynamic) {
			var interactive = Std.downcast(control, openfl.display.InteractiveObject);
			if (interactive != null) {
				interactive.mouseEnabled = enabled;
			}
		}
	}

	private static function controlEnabled(control:Null<DisplayObject>):Bool {
		if (control == null) {
			return false;
		}
		try {
			var value:Dynamic = Reflect.getProperty(control, "enabled");
			if (value != null) {
				return value == true;
			}
		} catch (_:Dynamic) {}
		var interactive = Std.downcast(control, openfl.display.InteractiveObject);
		return interactive == null || interactive.mouseEnabled;
	}

	public function remove():Void {
		asyncGuard.remove();
		if (infoButton != null) {
			infoButton.removeEventListener(MouseEvent.MOUSE_OVER, overInfo);
			infoButton.removeEventListener(MouseEvent.MOUSE_OUT, outInfo);
		}
		if (infoPopup != null) {
			infoPopup.remove();
			infoPopup = null;
		}
		LobbyArt.unbind(infoBinding);
		LobbyArt.unbind(passBinding);
		clearFavoriteButtonBinding();
		if (uploading != null) {
			uploading.remove();
			uploading = null;
		}
		detachPassControls();
		detachCover();
		for (slot in slots) {
			slot.remove();
		}
		slots = [];
		accessCover = null;
		coverText = null;
		passButton = null;
		passBox = null;
		passField = null;
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

	public function coverShownForTests():Bool {
		return coverShown;
	}

	public function slotCountForTests():Int {
		return slots.length;
	}

	public static function infoHoverTitleForTests(info:CampaignLevelInfo):String {
		return infoHoverTitle(info);
	}

	public static function infoHoverBodyForTests(info:CampaignLevelInfo):String {
		return infoHoverBody(info);
	}

	public static function favoriteHoverTitleForTests(mode:String):String {
		return favoriteHoverTitle(mode);
	}

	public static function favoriteHoverMessageForTests(mode:String):String {
		return favoriteHoverMessage(mode);
	}

	public static function resetHooksForTests():Void {
		favoriteUploadFactory = defaultFavoriteUpload;
		favoriteHoverDelayFactory = defaultFavoriteHoverDelay;
		passPostFactory = defaultPassPost;
	}

	public function favoriteHoverVisibleForTests():Bool {
		return favPopup != null;
	}

	public function uploadingForTests():Null<UploadingPopup> {
		return uploading;
	}

	public function setPassTextForTests(value:String):Void {
		if (passField != null) {
			passField.text = value;
		}
	}

	public function passTextForTests():String {
		return passField == null ? "" : passField.text;
	}

	public function passButtonEnabledForTests():Bool {
		return controlEnabled(passButton);
	}

	public function passBoxEnabledForTests():Bool {
		return controlEnabled(passBox);
	}

	public function passPendingForTests():Bool {
		return passPending;
	}
}

private class LevelItemView extends NativeView {
	public final background:LevelItemBackground;
	public final accessCover:LevelAccessCoverView;

	public function new() {
		super();
		background = new LevelItemBackground();
		background.name = "bg";
		addChild(background);
		field(8, 5, 205, 19, 12, true, TextFormatAlign.LEFT);
		field(8, 24, 205, 17, 10, false, TextFormatAlign.LEFT);
		var rating = new Sprite();
		rating.name = "ratingStars";
		rating.x = 8;
		rating.y = 44;
		rating.graphics.beginFill(0x666666, 0.45);
		rating.graphics.drawRoundRect(0, 0, 92, 8, 4, 4);
		rating.graphics.endFill();
		var bar = new Sprite();
		bar.name = "bar";
		bar.graphics.beginFill(0xF1CB45);
		bar.graphics.drawRoundRect(0, 0, 92, 8, 4, 4);
		bar.graphics.endFill();
		rating.addChild(bar);
		addChild(rating);
		button("infoButton", "?", 218, 5, 25);
		button("plusButton", "+", 218, 34, 25);
		button("minusButton", "−", 218, 34, 25);
		var holder = new Sprite();
		holder.name = "slotsHolder";
		holder.x = 8;
		holder.y = 61;
		addChild(holder);
		accessCover = new LevelAccessCoverView();
		accessCover.name = "accessCover";
		addChild(accessCover);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		addChild(control);
	}

	private function field(x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):Void {
		var text = new TextField();
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		addChild(text);
	}
}

private class LevelItemBackground extends Sprite {
	public function new() {
		super();
		render(1);
	}

	public function render(frame:Int):Void {
		var color = switch (frame) {
			case 2: 0xDDE8F3;
			case 3: 0xE8DFF2;
			case 4: 0xE2F0DE;
			case 5: 0xF2E5D7;
			default: 0xEEEEEE;
		};
		graphics.clear();
		graphics.beginFill(color, 0.97);
		graphics.lineStyle(1, 0x777777);
		graphics.drawRoundRect(0, 0, 251, 137, 10, 10);
		graphics.endFill();
	}
}

private class LevelAccessCoverView extends NativeView {
	public final input:GameTextInput;

	public function new() {
		super();
		graphics.beginFill(0xF7F7F7, 0.96);
		graphics.lineStyle(1, 0x777777);
		graphics.drawRoundRect(3, 3, 245, 131, 9, 9);
		graphics.endFill();
		var message = new TextField();
		message.name = "textBox";
		message.x = 14;
		message.y = 18;
		message.width = 222;
		message.height = 50;
		message.multiline = true;
		message.wordWrap = true;
		message.selectable = false;
		message.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 11, 0x333333, false, null, null, null, null,
			TextFormatAlign.CENTER);
		addChild(message);
		input = ownControl(new GameTextInput());
		input.name = "passBox";
		input.x = 44;
		input.y = 79;
		input.setSize(105, 23);
		addChild(input);
		var submit = ownControl(new GameButton("Enter"));
		submit.name = "passButton";
		submit.x = 155;
		submit.y = 79;
		submit.setSize(54, 23);
		addChild(submit);
	}
}
