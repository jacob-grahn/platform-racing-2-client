package pr2.page;

import openfl.display.Shape;
import openfl.events.Event;
import pr2.app.AppStage;
import pr2.app.ScreenFactory;
import pr2.assets.NativeAssets;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.audio.AudioManager;
import pr2.lobby.LobbyActions;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.lobby.players.ProfileActions;
import pr2.lobby.messages.UnreadNotif;
import pr2.mobile.LobbyView;
import pr2.mobile.MobileLevelBrowser;
import pr2.mobile.MobileScrollPane;
import pr2.mobile.MobileChatPage;
import pr2.net.CommandHandler;
import pr2.runtime.SvgAsset;
import pr2.page.auth.AuthDialog;

/** Landscape lobby shell; all session transitions live in LobbyActions. */
class MobileLobbyPage extends Page {
	public static var instance(default, null):Null<MobileLobbyPage>;
	private var sky:Shape;
	private var ground:Shape;
	private var header:LobbyView;
	private var menu:LobbyView;
	private var rotateHint:LobbyView;
	private var menuScroll:MobileScrollPane;
	private var content:MobileLevelBrowser;
	private var hosted:Page;
	private var hostedScroll:MobileScrollPane;
	private var actions:LobbyActions;
	private var modal:AuthDialog;
	private var section:String = "play";
	private var menuOpen:Bool = false;
	private var w:Float = 844;
	private var h:Float = 390;
	private var inset:Float = 44;

	public function new(?userName:String, ?server:pr2.net.ServerInfo) {
		super(); fullViewport = true;
		if (userName != null) LobbySession.userName = userName;
		if (server != null) LobbySession.server = server;
		actions = new LobbyActions(function(page) { if (pageHolder != null) pageHolder.changePage(page); }, confirm,
			function(message) { new pr2.lobby.dialogs.MessagePopup(message); });
	}
	override public function initialize():Void {
		instance = this;
		LevelInfoPopup.lookupLevelHandler = lookupLevel; ProfileActions.lookupUserHandler = lookupUser;
		AudioManager.enterLobby();
		sky = NativeAssets.svg(StaticSvg.LoginBackgroundSky); addChild(sky);
		ground = SvgAsset.create("assets/mobile/lobby-ground.svg"); addChild(ground);
		header = new LobbyView(); addChild(header);
		menu = new LobbyView();
		rotateHint = new LobbyView();
		if (LobbySession.isMember()) CommandHandler.commandHandler.defineCommand("pmNotify", onPmNotify);
		if (AppStage.stage != null) AppStage.stage.addEventListener(Event.RESIZE, layout);
		#if js
		var self = this;
		untyped js.Browser.window.__pr2OpenLevelEditorForTests = function():Void self.actions.editor();
		#end
		openSection("play"); layout();
	}
	public static function layoutMetricsForTests(width:Float, height:Float, play:Bool):Dynamic {
		var margin = width >= 760 ? 44 : 16;
		return {inset:margin, contentWidth:width - margin * 2, contentY:76, contentHeight:Math.max(210, height - 106), headerButtonHeight:44};
	}
	private function openSection(value:String):Void {
		closeModal(); menuOpen = false; clearHosted();
		if (content != null) { content.remove(); content = null; }
		section = value;
		if (value == "play") {
			content = new MobileLevelBrowser(); content.onState = function() {
				if (menuOpen && content.racing) { menuOpen = false; layout(); } else updateHeader();
			}; addChild(content);
		} else {
			hosted = switch (value) {
				case "chat": new MobileChatPage();
				case "players": ScreenFactory.players();
				case "guilds": ScreenFactory.players(true);
				case "messages": ScreenFactory.messages();
				default: ScreenFactory.racer();
			};
			hostedScroll = new MobileScrollPane(); addChild(hostedScroll);
			hosted.pageHolder = pageHolder; hosted.initialize(); hostedScroll.content.addChild(hosted);
		}
		if (value != "account") {
			CommandHandler.commandHandler.defineCommand("setCustomizeInfo", function(args) {
				var data = pr2.lobby.account.AccountCustomizeData.parse(args);
				if (data != null) pr2.lobby.account.AccountState.applyCustomize(data);
			});
			pr2.net.LobbySocket.write("get_customize_info`");
		}
		layout(); report();
	}
	private function showMenu():Void { menuOpen = true; layout(); report(); }
	private function hideMenu():Void { menuOpen = false; layout(); report(); }
	private function onPmNotify(args:Array<String>):Void {
		var time = args.length == 0 ? Math.NaN : Std.parseFloat(args[0]);
		if (!Math.isNaN(time)) UnreadNotif.notifyUser(time);
		if (menuOpen) renderMenu(); updateHeader();
	}
	private function updateHeader():Void {
		if (header == null) return;
		header.clear();
		var title = menuOpen ? "GAME MENU" : section != "play" ? switch section { case "chat": "CHAT"; case "players": "PLAYERS"; case "guilds": "GUILDS"; case "messages": "MESSAGES"; default: "MY RACER"; } : content.racing ? "GET READY!" : content.browsing ? "FIND A LEVEL" : "LET’S RACE!";
		var width = w - inset * 2;
		header.label(title, inset, 12, Math.max(150, width - 306), 48, width < 660 ? 27 : 34, true, 0xFFFFFF);
		if (menuOpen) header.button("Back to game", w - inset - 180, 12, 180, hideMenu);
		else if (section == "play" && content.racing) header.button("Leave race", w - inset - 180, 12, 180, content.leaveRace);
		else {
			header.button(section == "play" && !content.browsing ? "My racer" : "Back to races", w - inset - 300, 12, 180, function() {
				if (section != "play") openSection("play"); else if (content.browsing) content.back(); else openSection("account");
			});
			header.button(UnreadNotif.numUnread() > 0 ? "Menu •" : "Menu", w - inset - 104, 12, 104, showMenu);
		}
		var server = LobbySession.server == null ? "" : " • " + LobbySession.server.name;
		header.label(LobbySession.userName + server, inset, h - 24, width, 22, 13, false, 0x18334B);
		report();
	}
	private function renderMenu():Void {
		if (menuScroll != null) menuScroll.remove();
		menu.clear();
		var width = w - inset * 2; var height = Math.max(210, h - 106);
		menuScroll = new MobileScrollPane(); menu.addChild(menuScroll);
		var v = menuScroll.content;
		var columns = width >= 550 ? 3 : 1; var columnW = (width - (columns - 1) * 16) / columns;
		var labels = ["Play & create", "Hang out", "Game & account"];
		for (i in 0...3) {
			var x = columns == 1 ? 0 : i * (columnW + 16); var y = columns == 1 ? i * 300 : 0;
			v.panel(x, y, columnW, 284); v.label(labels[i], x + 14, y + 14, columnW - 28, 38, width < 680 ? 22 : 25, true);
		}
		function item(col:Int, row:Int, label:String, action:Void->Void, enabled:Bool = true, primary:Bool = false):Void {
			var x = columns == 1 ? 0 : col * (columnW + 16); var y = columns == 1 ? col * 300 : 0;
			v.button(label, x + 14, y + 58 + row * 56, columnW - 28, action, primary).enabled = enabled;
		}
		item(0, 0, "Race!", function() openSection("play"), true, true);
		item(0, 1, "My racer", function() openSection("account"));
		item(0, 2, "Level editor", function() actions.editor());
		item(1, 0, "Chat", function() openSection("chat"));
		item(1, 1, UnreadNotif.numUnread() > 0 ? 'Messages (${UnreadNotif.numUnread()})' : "Messages", function() openSection("messages"), LobbySession.isMember());
		item(1, 2, "Players", function() openSection("players"));
		item(1, 3, "Guilds", function() openSection("guilds"));
		item(2, 0, "Options", function() { ScreenFactory.options(); });
		item(2, 1, "Account", function() { ScreenFactory.options("account"); });
		item(2, 2, "Credits", function() { ScreenFactory.credits(); });
		item(2, 3, "Log out", function() actions.logout());
		menuScroll.setSize(width, height + 6, columns == 1 ? 884 : 290);
	}
	public function lookupUser(name:String):Void showSearch(name, "user");
	public function lookupLevel(id:String):Void showSearch(id, "id");
	private function showSearch(value:String, mode:String):Void {
		if (section != "play") openSection("play");
		menuOpen = false; content.showSearch(value, mode); layout();
	}
	private function confirm(message:String, proceed:Void->Void):Void {
		closeModal();
		modal = ScreenFactory.authDialog("Confirm", message, ["heading" => "Leave the lobby?", "confirmLabel" => "Continue", "cancelLabel" => "Stay here"]);
		modal.onCancel = closeModal; modal.onConfirm = function() { closeModal(); proceed(); };
		addChild(modal); modal.resizeViewport(w, h);
	}
	private function closeModal():Void { if (modal != null) modal.dismiss(true); modal = null; }
	private function layout(?_:Event):Void {
		if (header == null) return;
		w = AppStage.stage == null ? 844 : AppStage.stage.stageWidth; h = AppStage.stage == null ? 390 : AppStage.stage.stageHeight;
		var metrics = layoutMetricsForTests(w, h, section == "play"); inset = metrics.inset;
		graphics.clear(); graphics.beginFill(0x0B519E); graphics.drawRect(0, 0, w, h); graphics.endFill();
		sky.width = w; sky.height = h * 1.57; ground.width = w; ground.height = h * .256; ground.y = h - ground.height;
		if (content != null) { content.visible = !menuOpen; content.x = inset; content.y = 76; content.setLayout(metrics.contentWidth, metrics.contentHeight); }
		if (hostedScroll != null) {
			hostedScroll.visible = !menuOpen; hostedScroll.x = inset; hostedScroll.y = 76;
			var chat = Std.downcast(hosted, MobileChatPage);
			var racer = Std.downcast(hosted, pr2.mobile.MobileRacerPage);
			var messages = Std.downcast(hosted, pr2.mobile.MobileMessagesPage);
			var players = Std.downcast(hosted, pr2.mobile.MobilePlayersPage);
			if (chat != null) { chat.setLayout(metrics.contentWidth, metrics.contentHeight); hostedScroll.setSize(metrics.contentWidth, metrics.contentHeight, metrics.contentHeight); }
			else if (racer != null) { racer.setLayout(metrics.contentWidth, metrics.contentHeight); hostedScroll.setSize(metrics.contentWidth, metrics.contentHeight, metrics.contentHeight); }
			else if (messages != null) { messages.setLayout(metrics.contentWidth, metrics.contentHeight); hostedScroll.setSize(metrics.contentWidth, metrics.contentHeight, metrics.contentHeight); }
			else if (players != null) { players.setLayout(metrics.contentWidth, metrics.contentHeight); hostedScroll.setSize(metrics.contentWidth, metrics.contentHeight, metrics.contentHeight); }
			else {
				// Existing feature pages remain usable while their mobile flows migrate.
				hosted.scaleX = hosted.scaleY = 1.5; hosted.x = (metrics.contentWidth - 194 * 1.5) / 2;
				hostedScroll.setSize(metrics.contentWidth, metrics.contentHeight, 394 * 1.5);
			}
		}
		if (menuOpen) { addChild(menu); menu.x = inset; menu.y = 76; renderMenu(); } else if (menu.parent != null) removeChild(menu);
		addChild(header); updateHeader();
		rotateHint.clear();
		if (h > w) {
			rotateHint.graphics.beginFill(0x0B519E); rotateHint.graphics.drawRect(0, 0, w, h); rotateHint.graphics.endFill();
			rotateHint.label("Turn your device sideways to race", 24, h / 2 - 70, w - 48, 140, 30, true, 0xFFFFFF);
			addChild(rotateHint);
		} else if (rotateHint.parent != null) removeChild(rotateHint);
		if (modal != null) { addChild(modal); modal.resizeViewport(w, h); }
	}
	private function clearHosted():Void {
		if (hosted != null) hosted.remove(); hosted = null;
		if (hostedScroll != null) hostedScroll.remove(); hostedScroll = null;
	}
	private function report():Void {
		#if js
		js.Browser.document.body.setAttribute("data-pr2-page", "mobile-lobby:" + LobbySession.userName);
		js.Browser.document.body.setAttribute("data-pr2-mobile-pane", menuOpen ? "menu" : section);
		js.Browser.document.body.setAttribute("data-pr2-mobile-play", content == null ? "" : content.mode);
		#end
	}
	override public function remove():Void {
		#if js
		untyped js.Browser.window.__pr2OpenLevelEditorForTests = null;
		#end
		if (instance == this) instance = null;
		actions.remove(); closeModal(); clearHosted();
		if (content != null) content.remove(); content = null;
		if (header != null) header.remove(); if (menuScroll != null) menuScroll.remove(); if (menu != null) menu.remove();
		if (rotateHint != null) rotateHint.remove();
		if (AppStage.stage != null) AppStage.stage.removeEventListener(Event.RESIZE, layout);
		CommandHandler.commandHandler.defineCommand("pmNotify", null);
		CommandHandler.commandHandler.defineCommand("setCustomizeInfo", null);
		LevelInfoPopup.lookupLevelHandler = null; ProfileActions.lookupUserHandler = null;
		AudioManager.leaveMenu(); super.remove();
	}
}
