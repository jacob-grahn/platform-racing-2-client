package pr2.lobby.tabs;

import haxe.Timer;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
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
import pr2.lobby.dialogs.HoverPopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.level.CourseMenu;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.page.Page;
import pr2.runtime.PR2MovieClip;
import pr2.ui.GuildName;
import pr2.ui.StageFocus;
import pr2.util.DisplayUtil;

/** Flash-compatible Account customization tab. */
class AccountTab extends Page {
	public static inline var SET_MANUAL_PART:String = "manualPart";
	public static var partToSet:Array<Dynamic> = [];

	private static final manualPartDispatcher:EventDispatcher = new EventDispatcher();

	private var art:Null<PR2MovieClip>;
	private var character:Null<AccountCharacter>;
	private var characterHolder:Null<Sprite>;
	private var stats:Null<StatsSelect>;
	private var playerDisplay:Null<PlayerDisplay>;
	private var guildName:Null<GuildName>;
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
	private var loadoutsHover:Null<HoverPopup>;
	private var loadoutsHoverTimer:Null<Timer>;

	public function new() {
		super();
	}

	public static function setManualPart(partType:String, partId:Int):Void {
		partToSet = [partType, partId];
		dispatchManualPart();
	}

	public static function dispatchManualPart():Void {
		manualPartDispatcher.dispatchEvent(new Event(SET_MANUAL_PART));
	}

	override public function initialize():Void {
		art = PR2MovieClip.fromLinkage("AccountInfoGraphic", {maxNestedDepth: 8});
		addChild(art);
		rankUp = DisplayUtil.findByName(art, "rankTokenUp_bt");
		rankDown = DisplayUtil.findByName(art, "rankTokenDown_bt");
		loadouts = DisplayUtil.findByName(art, "loadouts_bt");
		upBinding = LobbyArt.bind(rankUp, useRankToken);
		downBinding = LobbyArt.bind(rankDown, unuseRankToken);
		loadoutsBinding = LobbyArt.bind(loadouts, openLoadouts);
		if (loadouts != null) {
			loadouts.addEventListener(MouseEvent.MOUSE_OVER, loadoutsMouseOver);
			loadouts.addEventListener(MouseEvent.MOUSE_OUT, loadoutsMouseOut);
		}
		CommandHandler.commandHandler.defineCommand("setCustomizeInfo", setCustomizeInfo);
		manualPartDispatcher.addEventListener(SET_MANUAL_PART, saveManualPart);
		LobbySession.onAccountChange(refresh);
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(MouseEvent.MOUSE_UP, saveCustomizeInfo);
			AppStage.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			StageFocus.reset();
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
		renderGuild();
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
		retestLevelAccess();
	}

	private function saveCustomizeInfo(?_:MouseEvent):Void {
		if (character == null || stats == null) {
			return;
		}
		writeCustomizeInfo(character.getPartInfoStr());
	}

	private function saveManualPart(_:Event):Void {
		if (character == null || stats == null) {
			return;
		}
		writeCustomizeInfo(partInfoWithManualOverride());
		refresh();
	}

	private function writeCustomizeInfo(partInfo:String):Void {
		var command = "set_customize_info`" + partInfo + "`" + stats.getInfoStr();
		if (command != customizeInfo) {
			customizeInfo = command;
			LobbySocket.write(command);
		}
	}

	private function partInfoWithManualOverride():String {
		var hat = character.hat1;
		var head = character.head;
		var body = character.body;
		var feet = character.feet;
		if (partToSet.length == 2) {
			var partId = Std.parseInt(Std.string(partToSet[1]));
			if (partId != null) {
				switch (Std.string(partToSet[0])) {
					case "hat":
						hat = partId;
					case "head":
						head = partId;
					case "body":
						body = partId;
					case "feet":
						feet = partId;
					default:
				}
			}
		}
		return character.hat1Color
			+ "`" + character.headColor
			+ "`" + character.bodyColor
			+ "`" + character.feetColor
			+ "`" + character.hat1Color2
			+ "`" + character.headColor2
			+ "`" + character.bodyColor2
			+ "`" + character.feetColor2
			+ "`" + hat
			+ "`" + head
			+ "`" + body
			+ "`" + feet;
	}

	private function useRankToken():Void {
		if (rankTokensUsed < rankTokensAvailable) {
			rankTokensUsed++;
			rank++;
			SecureData.setNumber("userRank", rank);
			LobbySocket.write("use_rank_token`");
			LobbySocket.write("get_customize_info`");
			updateRankControls();
			retestLevelAccess();
		}
	}

	private function unuseRankToken():Void {
		if (rankTokensUsed > 0) {
			rankTokensUsed--;
			rank--;
			SecureData.setNumber("userRank", rank);
			LobbySocket.write("unuse_rank_token`");
			LobbySocket.write("get_customize_info`");
			updateRankControls();
			retestLevelAccess();
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
		hideLoadoutsHover();
		if (character != null && stats != null && playerDisplay != null) {
			new LoadoutsPopup(character, stats, playerDisplay);
		}
	}

	private function onKeyDown(e:KeyboardEvent):Void {
		var textTarget = Std.downcast(e.target, TextField);
		if (character == null || stats == null || playerDisplay == null || Popup.getOpen().length > 0
			|| (textTarget != null && textTarget.selectable) || CourseMenu.instance != null) {
			e.preventDefault();
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

	private function loadoutsMouseOver(_:MouseEvent):Void {
		hideLoadoutsHover();
		loadoutsHoverTimer = Timer.delay(showLoadoutsHover, 500);
	}

	private function loadoutsMouseOut(_:MouseEvent):Void {
		hideLoadoutsHover();
	}

	private function showLoadoutsHover():Void {
		loadoutsHoverTimer = null;
		if (loadouts == null) {
			return;
		}
		loadoutsHover = new HoverPopup("Loadouts",
			"Save up to " + Presets.NUM_PRESETS + " of your favorite styles. Use the numbers on your keyboard for quick switching.", loadouts);
		loadoutsHover.x += loadoutsHover.width + 27.5;
	}

	private function hideLoadoutsHover():Void {
		if (loadoutsHoverTimer != null) {
			loadoutsHoverTimer.stop();
			loadoutsHoverTimer = null;
		}
		if (loadoutsHover != null) {
			loadoutsHover.remove();
			loadoutsHover = null;
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

	private function retestLevelAccess():Void {
		CommandHandler.commandHandler.dispatch("testLevelAccess", []);
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

	private function renderGuild():Void {
		if (LobbySession.guildId == 0) {
			setHtml("guildBox", "Guild: <b>none</b>");
			return;
		}
		setHtml("guildBox", "Guild: ");
		guildName = new GuildName(LobbySession.guildId, LobbySession.guildName, LobbySession.emblem, true);
		guildName.makeWidth(145);
		guildName.x = 40;
		guildName.y = 54;
		if (art != null) {
			art.addChild(guildName);
		}
	}

	private function resetControls():Void {
		partToSet = [];
		if (guildName != null) guildName.remove();
		if (playerDisplay != null) playerDisplay.remove();
		if (stats != null) stats.remove();
		if (character != null) character.remove();
		if (characterHolder != null && characterHolder.parent != null) characterHolder.parent.removeChild(characterHolder);
		playerDisplay = null;
		stats = null;
		character = null;
		characterHolder = null;
		guildName = null;
	}

	override public function remove():Void {
		LobbySession.offAccountChange(refresh);
		CommandHandler.commandHandler.defineCommand("setCustomizeInfo", null);
		manualPartDispatcher.removeEventListener(SET_MANUAL_PART, saveManualPart);
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_UP, saveCustomizeInfo);
			AppStage.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		LobbyArt.unbind(upBinding);
		LobbyArt.unbind(downBinding);
		LobbyArt.unbind(loadoutsBinding);
		if (loadouts != null) {
			loadouts.removeEventListener(MouseEvent.MOUSE_OVER, loadoutsMouseOver);
			loadouts.removeEventListener(MouseEvent.MOUSE_OUT, loadoutsMouseOut);
		}
		hideLoadoutsHover();
		resetControls();
		if (art != null) art.dispose();
		art = null;
		super.remove();
	}
}
