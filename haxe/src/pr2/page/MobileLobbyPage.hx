package pr2.page;

#if js
import js.Browser;
#end
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.app.AppStage;
import pr2.audio.AudioManager;
import pr2.lobby.LobbyPopups;
import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.lobby.dialogs.OptionsPopup;
import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.lobby.dialogs.PlayerPopup;
import pr2.lobby.store.StorePopup;
import pr2.lobby.tabs.AccountTab;
import pr2.lobby.tabs.ChatTab;
import pr2.lobby.tabs.MessagesTab;
import pr2.lobby.tabs.PlayersTab;
import pr2.mobile.MobileButton;
import pr2.mobile.MobileChatPage;
import pr2.mobile.MobileLevelBrowser;
import pr2.net.LobbySocket;
import pr2.runtime.FontResolver;

/**
	Touch-first lobby presentation. It deliberately does not inherit or resize the
	authored two-pane LobbyPage: only its existing session, socket, tab pages,
	popups, and game-launch coordinator are reused.
**/
class MobileLobbyPage extends Page {
	public static var instance(default, null):Null<MobileLobbyPage>;
	private static inline var HEADER_H:Float = 58;
	private static inline var PRIMARY_NAV_H:Float = 66;
	private static inline var PLAY_NAV_H:Float = 54;
	private static inline var MIN_TOUCH:Float = 46;

	private var background:Sprite;
	private var header:Sprite;
	private var content:Sprite;
	private var primaryNav:Sprite;
	private var playNav:Sprite;
	private var primaryButtons:Array<MobileButton> = [];
	private var playButtons:Array<MobileButton> = [];
	private var utilityButtons:Array<MobileButton> = [];
	private var mobileLevels:MobileLevelBrowser;
	private var hostedPage:Null<Page>;
	private var activePrimary:String = "play";
	private var activePlay:String = "campaign";
	private var title:TextField;

	public static function layoutMetricsForTests(width:Float, height:Float, play:Bool):Dynamic {
		var safeWidth = Math.max(320, width);
		var safeHeight = Math.max(320, height);
		var contentY = HEADER_H + (play ? PLAY_NAV_H : 0);
		return {
			primaryButtonWidth: safeWidth / 4,
			primaryButtonHeight: PRIMARY_NAV_H - 10,
			secondaryButtonHeight: MIN_TOUCH,
			contentY: contentY,
			contentHeight: safeHeight - contentY - PRIMARY_NAV_H
		};
	}

	public function new(?userName:String) {
		super();
		if (userName != null) LobbySession.userName = userName;
	}

	override public function initialize():Void {
		instance = this;
		LevelInfoPopup.lookupLevelHandler = lookupLevel;
		PlayerPopup.lookupUserHandler = lookupUser;
		AudioManager.enterLobby();
		background = new Sprite();
		addChild(background);
		header = new Sprite();
		addChild(header);
		content = new Sprite();
		addChild(content);
		playNav = new Sprite();
		addChild(playNav);
		primaryNav = new Sprite();
		addChild(primaryNav);

		title = new TextField();
		title.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 22, 0xFFFFFF, true);
		title.selectable = false;
		title.mouseEnabled = false;
		header.addChild(title);

		mobileLevels = new MobileLevelBrowser();
		content.addChild(mobileLevels);
		buildNavigation();
		activePrimary = Memory.getString("mobileLobbyPrimary", "play");
		if (["play", "chat", "players", "account"].indexOf(activePrimary) < 0) activePrimary = "play";
		activePlay = Memory.getString("mobileLobbyPlay", "campaign");
		if (!LobbySession.isMember() && activePlay == "favorites") activePlay = "campaign";
		selectPrimary(activePrimary);
		if (AppStage.stage != null) AppStage.stage.addEventListener(Event.RESIZE, onResize);
		layout();
		reportState();
	}

	private function buildNavigation():Void {
		var primary = ["Play", "Chat", "Players", "Account"];
		var keys = ["play", "chat", "players", "account"];
		for (i in 0...primary.length) {
			var key = keys[i];
			var button = new MobileButton(primary[i], 100, PRIMARY_NAV_H - 10, function():Void selectPrimary(key));
			button.name = "mobilePrimary_" + key;
			primaryButtons.push(button);
			primaryNav.addChild(button);
		}

		var labels = ["Campaign", "All Time", "Week's Best", "Newest", "Search"];
		var playKeys = ["campaign", "best", "best_week", "newest", "search"];
		if (LobbySession.isMember()) {
			labels.push("Favorites");
			playKeys.push("favorites");
		}
		for (i in 0...labels.length) {
			var key = playKeys[i];
			var button = new MobileButton(labels[i], 90, MIN_TOUCH, function():Void selectPlay(key), 0x596E99);
			button.name = "mobilePlay_" + key;
			playButtons.push(button);
			playNav.addChild(button);
		}

		if (LobbySession.isMember()) addUtility("PMs", showMessages);
		addUtility("Store", function():Void new StorePopup());
		addUtility("Options", function():Void new OptionsPopup());
		addUtility("Logout", logout);
	}

	private function addUtility(label:String, callback:Void->Void):Void {
		var button = new MobileButton(label, 82, MIN_TOUCH, callback, 0x53627D);
		utilityButtons.push(button);
		header.addChild(button);
	}

	private function selectPrimary(key:String):Void {
		activePrimary = key;
		Memory.set("mobileLobbyPrimary", key);
		for (i in 0...primaryButtons.length) primaryButtons[i].selected = ["play", "chat", "players", "account"][i] == key;
		playNav.visible = key == "play";
		clearHostedPage();
		mobileLevels.visible = key == "play";
		if (key == "play") {
			selectPlay(activePlay);
		} else {
			var page:Page = switch (key) {
				case "chat": new MobileChatPage();
				case "players": new PlayersTab();
				default: new AccountTab();
			};
			hostPage(page);
		}
		layout();
		reportState();
	}

	private function selectPlay(key:String):Void {
		activePlay = key;
		Memory.set("mobileLobbyPlay", key);
		for (i in 0...playButtons.length) {
			var keys = LobbySession.isMember() ? ["campaign", "best", "best_week", "newest", "search", "favorites"] : ["campaign", "best", "best_week", "newest", "search"];
			playButtons[i].selected = keys[i] == key;
		}
		if (mobileLevels != null) mobileLevels.showMode(key);
		reportState();
	}

	private function showMessages():Void {
		activePrimary = "account";
		for (i in 0...primaryButtons.length) primaryButtons[i].selected = i == 3;
		playNav.visible = false;
		mobileLevels.visible = false;
		clearHostedPage();
		hostPage(new MessagesTab());
		layout();
	}

	public function lookupUser(userName:String):Void showSearch(userName, "user");
	public function lookupLevel(levelId:String):Void showSearch(levelId, "id");

	private function showSearch(query:String, mode:String):Void {
		activePrimary = "play";
		for (i in 0...primaryButtons.length) primaryButtons[i].selected = i == 0;
		playNav.visible = true;
		clearHostedPage();
		mobileLevels.visible = true;
		activePlay = "search";
		Memory.set("mobileLobbyPrimary", "play");
		Memory.set("mobileLobbyPlay", "search");
		for (button in playButtons) button.selected = button.name == "mobilePlay_search";
		mobileLevels.showSearch(query, mode);
		layout();
		reportState();
	}

	private function hostPage(page:Page):Void {
		hostedPage = page;
		page.pageHolder = pageHolder;
		page.initialize();
		content.addChild(page);
	}

	private function clearHostedPage():Void {
		if (hostedPage != null) {
			hostedPage.remove();
			if (hostedPage.parent != null) hostedPage.parent.removeChild(hostedPage);
			hostedPage = null;
		}
	}

	private function layout():Void {
		if (AppStage.stage == null || background == null) return;
		var width = Math.max(320, AppStage.stage.stageWidth);
		var height = Math.max(320, AppStage.stage.stageHeight);
		drawBackground(width, height);
		header.y = 0;
		title.text = width < 720 ? "PR2" : "PLATFORM RACING 2";
		title.x = 14;
		title.y = 14;
		title.width = Math.max(100, width - utilityButtons.length * 88 - 20);
		title.height = 35;
		for (i in 0...utilityButtons.length) {
			utilityButtons[i].x = width - (utilityButtons.length - i) * 88;
			utilityButtons[i].y = 6;
		}

		primaryNav.y = height - PRIMARY_NAV_H;
		var primaryW = width / primaryButtons.length;
		for (i in 0...primaryButtons.length) {
			primaryButtons[i].scaleX = primaryW / 100;
			primaryButtons[i].x = i * primaryW;
			primaryButtons[i].y = 5;
		}

		var playY = HEADER_H;
		playNav.y = playY;
		var playW = width / playButtons.length;
		for (i in 0...playButtons.length) {
			playButtons[i].scaleX = playW / 90;
			playButtons[i].x = i * playW;
			playButtons[i].y = 3;
		}

		var contentY = HEADER_H + (activePrimary == "play" ? PLAY_NAV_H : 0);
		var contentH = height - contentY - PRIMARY_NAV_H;
		content.x = 0;
		content.y = contentY;
		if (mobileLevels != null) mobileLevels.setLayout(width, contentH);
		if (hostedPage != null) {
			var mobileChat = Std.downcast(hostedPage, MobileChatPage);
			if (mobileChat != null) {
				mobileChat.scaleX = mobileChat.scaleY = 1;
				mobileChat.x = mobileChat.y = 0;
				mobileChat.setLayout(width, contentH);
				return;
			}
			// Authored single-pane pages are reused at a much larger density inside
			// the mobile shell. Their 186x374 design bounds remain aspect-correct.
			var scale = Math.min(width / 194, contentH / 374);
			scale = Math.max(1, scale);
			hostedPage.scaleX = hostedPage.scaleY = scale;
			hostedPage.x = Math.max(0, (width - 194 * scale) * 0.5);
			hostedPage.y = Math.max(0, (contentH - 374 * scale) * 0.5);
		}
	}

	private function drawBackground(width:Float, height:Float):Void {
		background.graphics.clear();
		background.graphics.beginFill(0x242A3A);
		background.graphics.drawRect(0, 0, width, height);
		background.graphics.endFill();
		background.graphics.beginFill(0x2F3A52);
		background.graphics.drawRect(0, HEADER_H, width, height - HEADER_H - PRIMARY_NAV_H);
		background.graphics.endFill();
		background.graphics.lineStyle(2, 0x7588AA, 0.7);
		background.graphics.moveTo(0, HEADER_H);
		background.graphics.lineTo(width, HEADER_H);
		background.graphics.moveTo(0, height - PRIMARY_NAV_H);
		background.graphics.lineTo(width, height - PRIMARY_NAV_H);
	}

	private function logout():Void {
		LobbySession.clear();
		LobbySocket.close();
		if (pageHolder != null) pageHolder.changePage(new LoginPage());
	}

	private function onResize(_:Event):Void layout();

	private function reportState():Void {
		#if js
		Browser.document.body.setAttribute("data-pr2-page", "mobile-lobby:" + LobbySession.userName);
		Browser.document.body.setAttribute("data-pr2-mobile-pane", activePrimary);
		Browser.document.body.setAttribute("data-pr2-mobile-play", activePlay);
		#end
	}

	override public function remove():Void {
		if (instance == this) instance = null;
		LevelInfoPopup.lookupLevelHandler = null;
		PlayerPopup.lookupUserHandler = null;
		if (AppStage.stage != null) AppStage.stage.removeEventListener(Event.RESIZE, onResize);
		clearHostedPage();
		if (mobileLevels != null) {
			mobileLevels.remove();
			mobileLevels = null;
		}
		for (button in primaryButtons) button.remove();
		for (button in playButtons) button.remove();
		for (button in utilityButtons) button.remove();
		primaryButtons = [];
		playButtons = [];
		utilityButtons = [];
		AudioManager.leaveMenu();
		super.remove();
	}
}
