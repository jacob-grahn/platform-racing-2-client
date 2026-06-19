package pr2.lobby.tabs;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.app.AppStage;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.LobbySession;
import pr2.lobby.SecureData;
import pr2.lobby.account.AccountCharacter;
import pr2.lobby.account.AccountCustomizeData;
import pr2.lobby.account.AccountState;
import pr2.lobby.account.LoadoutsPopup;
import pr2.lobby.account.PlayerDisplay;
import pr2.lobby.account.Presets;
import pr2.lobby.account.StatsSelect;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.page.Page;
import pr2.runtime.PR2MovieClip;

/** Flash-compatible Account customization tab. */
class AccountTab extends Page {
	private var art:Null<PR2MovieClip>;
	private var character:Null<AccountCharacter>;
	private var characterHolder:Null<Sprite>;
	private var stats:Null<StatsSelect>;
	private var playerDisplay:Null<PlayerDisplay>;
	private var rank:Int = 0;
	private var rankTokensUsed:Int = 0;
	private var rankTokensAvailable:Int = 0;
	private var customizeInfo:String = "";
	private var rankUp:Null<DisplayObject>;
	private var rankDown:Null<DisplayObject>;
	private var loadouts:Null<DisplayObject>;
	private var upBinding:Null<Binding>;
	private var downBinding:Null<Binding>;
	private var loadoutsBinding:Null<Binding>;

	public function new() {
		super();
	}

	override public function initialize():Void {
		art = PR2MovieClip.fromLinkage("AccountInfoGraphic", {maxNestedDepth: 8});
		addChild(art);
		rankUp = LobbyArt.findByName(art, "rankTokenUp_bt");
		rankDown = LobbyArt.findByName(art, "rankTokenDown_bt");
		loadouts = LobbyArt.findByName(art, "loadouts_bt");
		upBinding = LobbyArt.bind(rankUp, useRankToken);
		downBinding = LobbyArt.bind(rankDown, unuseRankToken);
		loadoutsBinding = LobbyArt.bind(loadouts, openLoadouts);
		CommandHandler.commandHandler.defineCommand("setCustomizeInfo", setCustomizeInfo);
		LobbySession.onAccountChange(refresh);
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(MouseEvent.MOUSE_UP, saveCustomizeInfo);
			AppStage.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			AppStage.stage.focus = AppStage.stage;
		}
		LobbySocket.write("get_customize_info`");
	}

	public function setCustomizeInfo(args:Array<String>):Void {
		var data = AccountCustomizeData.parse(args);
		if (data == null) {
			return;
		}
		resetControls();
		rank = data.rank;
		rankTokensUsed = data.rankTokensUsed;
		rankTokensAvailable = data.rankTokensAvailable;
		SecureData.setNumber("userRank", rank);
		setHtml("nameBox", "Welcome, <b>" + StringTools.htmlEscape(LobbySession.userName) + "</b>");
		setHtml("hatBox", "Hats: <b>" + Std.int(Math.max(0, data.hats.length - 1)) + "</b>");
		setHtml("guildBox", LobbySession.guildId == 0 ? "Guild: <b>none</b>" : "Guild: <b>" + StringTools.htmlEscape(LobbySession.guildName) + "</b>");
		updateRankControls();

		character = new AccountCharacter(data.hat, data.head, data.body, data.feet);
		character.setColors(data.hatColor, data.hatColor2, data.headColor, data.headColor2, data.bodyColor, data.bodyColor2, data.feetColor,
			data.feetColor2);
		characterHolder = new Sprite();
		characterHolder.addChild(character);
		characterHolder.x = 80;
		characterHolder.y = 182;
		characterHolder.scaleX = characterHolder.scaleY = 1.5;
		addChild(characterHolder);

		var availableStats = data.happyHour ? 300 : 150 + rank;
		stats = new StatsSelect(availableStats, data.speed, data.acceleration, data.jumping);
		stats.x = 20;
		stats.y = 207;
		addChild(stats);
		playerDisplay = new PlayerDisplay(character, data.hats, data.heads, data.bodies, data.feetParts, data.hat, data.head, data.body, data.feet,
			data.hatColor, data.headColor, data.bodyColor, data.feetColor, data.epicHats, data.epicHeads, data.epicBodies, data.epicFeet,
			data.hatColor2, data.headColor2, data.bodyColor2, data.feetColor2);
		playerDisplay.x = 23;
		playerDisplay.y = 95;
		addChild(playerDisplay);
		AccountState.currentHat = data.hat;
		CommandHandler.commandHandler.dispatch("testLevelAccess", []);
	}

	private function saveCustomizeInfo(?_:MouseEvent):Void {
		if (character == null || stats == null) {
			return;
		}
		var command = "set_customize_info`" + character.getPartInfoStr() + "`" + stats.getInfoStr();
		if (command != customizeInfo) {
			customizeInfo = command;
			LobbySocket.write(command);
		}
	}

	private function useRankToken():Void {
		if (rankTokensUsed < rankTokensAvailable) {
			rankTokensUsed++;
			rank++;
			LobbySocket.write("use_rank_token`");
			LobbySocket.write("get_customize_info`");
			updateRankControls();
		}
	}

	private function unuseRankToken():Void {
		if (rankTokensUsed > 0) {
			rankTokensUsed--;
			rank--;
			LobbySocket.write("unuse_rank_token`");
			LobbySocket.write("get_customize_info`");
			updateRankControls();
		}
	}

	private function updateRankControls():Void {
		setHtml("rankBox", "Rank: <b>" + rank + "</b>");
		var unused = rankTokensAvailable - rankTokensUsed;
		if (rankUp != null) rankUp.visible = unused > 0;
		if (rankDown != null) rankDown.visible = rankTokensUsed > 0;
		setButtonText(rankUp, unused);
		setButtonText(rankDown, rankTokensUsed);
		if (rankUp != null) rankUp.x = 65;
		if (rankDown != null) rankDown.x = unused > 0 ? 95 : 65;
	}

	private function openLoadouts():Void {
		if (character != null && stats != null && playerDisplay != null) {
			new LoadoutsPopup(character, stats, playerDisplay);
		}
	}

	private function onKeyDown(e:KeyboardEvent):Void {
		if (character == null || stats == null || playerDisplay == null || pr2.lobby.dialogs.Popup.getOpen().length > 0
			|| Std.isOfType(e.target, TextField)) {
			return;
		}
		var slot = keyToSlot(e.keyCode);
		if (slot > 0) {
			var preset = Presets.getPreset(slot);
			new ConfirmPopup(function():Void {
				Presets.apply(preset, character, stats, playerDisplay);
			}, "Are you sure you want to apply this loadout? This will clear your current stats and character style.");
		}
	}

	public static function keyToSlot(keyCode:Int):Int {
		if (keyCode >= 48 && keyCode <= 57) return keyCode == 48 ? 10 : keyCode - 48;
		if (keyCode >= 96 && keyCode <= 105) return keyCode == 96 ? 10 : keyCode - 96;
		return -1;
	}

	private function refresh():Void {
		resetControls();
		LobbySocket.write("get_customize_info`");
	}

	private function setHtml(name:String, value:String):Void {
		var field = LobbyArt.text(art, name);
		if (field != null) field.htmlText = value;
	}

	private function setButtonText(button:Null<DisplayObject>, value:Int):Void {
		var container = Std.downcast(button, openfl.display.DisplayObjectContainer);
		var field = LobbyArt.text(container, "textBox");
		if (field != null) field.text = Std.string(value);
	}

	private function resetControls():Void {
		if (playerDisplay != null) playerDisplay.remove();
		if (stats != null) stats.remove();
		if (character != null) character.remove();
		if (characterHolder != null && characterHolder.parent != null) characterHolder.parent.removeChild(characterHolder);
		playerDisplay = null;
		stats = null;
		character = null;
		characterHolder = null;
	}

	override public function remove():Void {
		LobbySession.offAccountChange(refresh);
		CommandHandler.commandHandler.defineCommand("setCustomizeInfo", null);
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_UP, saveCustomizeInfo);
			AppStage.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		LobbyArt.unbind(upBinding);
		LobbyArt.unbind(downBinding);
		LobbyArt.unbind(loadoutsBinding);
		resetControls();
		if (art != null) art.dispose();
		art = null;
		super.remove();
	}
}
