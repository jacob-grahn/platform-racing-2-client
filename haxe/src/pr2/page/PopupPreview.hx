package pr2.page;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import pr2.gameplay.FinishedPage;
import pr2.lobby.account.LoadoutsPopup;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.CreditsPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.PMRFCodesPopup;
import pr2.lobby.dialogs.SendMessagePopup;
import pr2.lobby.dialogs.LevelInfoView;
import pr2.lobby.dialogs.PlayerView;
import pr2.lobby.account.AccountCharacter;
import pr2.lobby.players.PlayerEntry;
import pr2.lobby.players.PlayersTabListView;
import pr2.lobby.level.LevelItem;
import pr2.net.CampaignLevelInfo;
import pr2.ui.view.StatusPopupView;

/** Deterministic visual-parity route: `?screen=popup&popup=<variant>`. */
class PopupPreview extends Sprite {
	private final variant:String;

	public function new(variant:Null<String>) {
		super();
		this.variant = variant == null ? "message" : variant;
		graphics.beginFill(0x88A6C5);
		graphics.drawRect(0, 0, 550, 400);
		graphics.endFill();
		addEventListener(Event.ADDED_TO_STAGE, show);
	}

	private function show(_:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, show);
		switch (variant) {
			case "confirm": new ConfirmPopup(function() {}, "Are you sure you want to continue?");
			case "nested":
				new ConfirmPopup(function() {}, "This parent must remain dimmed behind its child.");
				new MessagePopup("Nested popup focus and stacking check.");
			case "finished":
				var finished = new FinishedPage(6497936);
				finished.award("Level Completed", "+ 26");
				finished.setExpGain(520, 546, 546);
			case "send-message": new SendMessagePopup("Jiggmin", "Hello from Platform Racing 2!");
			case "codes": new PMRFCodesPopup();
			case "credits": new CreditsPopup();
			case "loadouts": new LoadoutsPopup(null, null, null);
			case "login": addChild(new LoginFlashPopup("LoginPopupGraphic"));
			case "connecting": addChild(new LoginFlashPopup("ConnectingPopupGraphic"));
			case "forgot-password": mountCentered(new ForgotPasswordView("Jiggmin"));
			case "create-account": mountCentered(new CreateAccountView("Jiggmin", "", "", ""));
			case "logging-in": mountCentered(new StatusPopupView("Logging In..."));
			case "player-lists": showPlayerLists();
			case "level-items": showLevelItems();
			case "level-info": showLevelInfo();
			case "player-info": showPlayerInfo();
			default: new MessagePopup("This is a representative popup message.");
		}
	}

	private function showPlayerInfo():Void {
		var view = new PlayerView();
		view.x = 275;
		view.y = 200;
		view.loadingGraphic.visible = false;
		view.playerInfo.visible = true;
		setDirectText(view, "nameBox", "-- Jiggmin --");
		setDirectText(view.playerInfo, "statusBox", "Online on Derron");
		setDirectText(view.playerInfo, "groupBox", "Administrator");
		setDirectText(view.playerInfo, "guildBox", "Jiggmin's Guild");
		setDirectText(view.playerInfo, "rankBox", "52");
		setDirectText(view.playerInfo, "hatBox", "8");
		setDirectText(view.playerInfo, "registerBox", "17/Sep/2013");
		setDirectText(view.playerInfo, "activeBox", "today");
		setDirectText(view.playerInfo, "supplText", "123,456 / 150,000 EXP");
		var character = new AccountCharacter(1, 1, 1, 1);
		character.scaleX = character.scaleY = 2;
		character.x = -75;
		character.y = 135;
		view.playerInfo.addChildAt(character, 1);
		var kick = view.playerInfo.getChildByName("kickButton");
		var kickBg = view.playerInfo.getChildByName("kickBg");
		var invite = view.playerInfo.getChildByName("inviteButton");
		if (kick != null) kick.visible = false;
		if (kickBg != null) kickBg.visible = false;
		if (invite != null) invite.visible = false;
		addChild(view);
	}

	private function showLevelInfo():Void {
		var view = new LevelInfoView();
		view.x = 275;
		view.y = 200;
		view.loading.visible = false;
		view.levelInfo.visible = true;
		setDirectText(view.levelInfo, "title", "The Golden Compass");
		setDirectText(view.levelInfo, "author", "by: Jiggmin");
		setDirectText(view.levelInfo, "note", "A source-authored level information preview.");
		setDirectText(view.levelInfo, "version", "21");
		setDirectText(view.levelInfo, "updated", "17/Mar/2020");
		setDirectText(view.levelInfo, "minRank", "0");
		setDirectText(view.levelInfo, "plays", "999,999");
		addChild(view);
	}

	private function setDirectText(parent:openfl.display.DisplayObjectContainer, name:String, value:String):Void {
		var field = Std.downcast(parent.getChildByName(name), TextField);
		if (field != null) field.text = value;
	}

	private function showLevelItems():Void {
		var modes = ["r", "d", "e", "o", "h"];
		for (i in 0...modes.length) {
			var info = new CampaignLevelInfo(9000 + i, 1, ["Race", "Deathmatch", "Alien Eggs", "Objective", "Hat Attack"][i],
				"Jiggmin", i == 2 ? 99 : 0, 1 + i, 12345, "3", "", i == 1, modes[i]);
			var item = new LevelItem(info);
			item.x = 15 + i * 107;
			item.y = 120;
			addChild(item);
		}
	}

	private function showPlayerLists():Void {
		var players = new PlayersTabListView(false);
		players.x = 80;
		players.y = 25;
		addChild(players);
		var playerRows = [
			new PlayerEntry("Jiggmin", "3", 52, 8, "Derron"),
			new PlayerEntry("Member", "1", 18, 2),
			new PlayerEntry("Guest", "0", 0, 0)
		];
		for (i in 0...playerRows.length) {
			playerRows[i].y = i * 16;
			players.listHolder.addChild(playerRows[i]);
		}

		var guilds = new PlayersTabListView(true);
		guilds.x = 296;
		guilds.y = 25;
		addChild(guilds);
	}

	private function mountCentered(view:openfl.display.DisplayObject):Void {
		view.x = 275;
		view.y = 200;
		addChild(view);
	}
}
