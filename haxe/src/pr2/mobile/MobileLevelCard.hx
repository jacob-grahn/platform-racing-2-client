package pr2.mobile;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import pr2.lobby.LobbyPopups;
import pr2.lobby.LobbySession;
import pr2.lobby.SecureData;
import pr2.lobby.account.AccountState;
import pr2.lobby.level.LevelAccess;
import pr2.lobby.level.LevelAccess.LevelAccessState;
import pr2.lobby.level.LevelLaunch;
import pr2.lobby.level.LevelListingState;
import pr2.lobby.level.LevelItem;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.CampaignLevelInfo;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.runtime.FontResolver;
import pr2.util.AsyncRemovalGuard;

/** A full-width, touch-first replacement for the authored desktop level tile. */
class MobileLevelCard extends Sprite {
	public static inline var CARD_HEIGHT:Float = 112;
	private var info:CampaignLevelInfo;
	private var cardWidth:Float;
	private var joinButtons:Array<MobileButton> = [];
	private var bindings:Array<{name:String, handler:Array<String>->Void}> = [];
	private var selectedSlot:Int = -1;
	private var passOK:Bool = false;
	private var passwordInput:Null<TextField>;
	private var unlockButton:Null<MobileButton>;
	private var favoriteButton:Null<MobileButton>;
	private var asyncGuard:AsyncRemovalGuard = new AsyncRemovalGuard();

	public function new(info:CampaignLevelInfo, width:Float) {
		super();
		this.info = info;
		this.cardWidth = width;
		name = "mobileLevelCard";
		drawCard();
		installCommands();
	}

	private function drawCard():Void {
		graphics.lineStyle(2, 0x788BAA);
		graphics.beginFill(modeColor(info.type), 0.96);
		graphics.drawRoundRect(1, 1, cardWidth - 2, CARD_HEIGHT - 4, 14, 14);
		graphics.endFill();
		graphics.lineStyle(1, 0xFFFFFF, 0.15);
		graphics.moveTo(10, 5);
		graphics.lineTo(cardWidth - 10, 5);

		var actionWidth = LobbySession.isMember() ? 218 : 112;
		addText(info.title, 14, 9, cardWidth - actionWidth, 27, 20, 0xFFFFFF, true);
		addText('by ${info.userName}  •  rank ${info.minLevel}  •  ★ ${roundedRating()}', 14, 38, cardWidth - actionWidth, 22, 14, 0xD9E6FA, false);

		var infoButton = new MobileButton("Info", 92, 46, function():Void LobbyPopups.showLevel(Std.string(info.levelId)), 0x607CA4);
		infoButton.x = cardWidth - 106;
		infoButton.y = 10;
		addChild(infoButton);
		if (LobbySession.isMember()) {
			favoriteButton = new MobileButton(LobbySession.isFavorite(info.levelId) ? "★ Saved" : "☆ Save", 98, 46, toggleFavorite, 0x735E91);
			favoriteButton.x = cardWidth - 210;
			favoriteButton.y = 10;
			addChild(favoriteButton);
		}

		var access = LevelAccess.evaluate(info.pass, false, LobbySession.group, LobbySession.userName.toLowerCase() == info.userName.toLowerCase(),
			Std.int(SecureData.getNumber("userRank")), info.minLevel, AccountState.currentHat, info.badHats);
		buildAccessControls(access);
	}

	private function buildAccessControls(access:LevelAccessState):Void {
		if (access == PassNeeded) {
			passwordInput = new TextField();
			passwordInput.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 18, 0x172137);
			passwordInput.type = TextFieldType.INPUT;
			passwordInput.displayAsPassword = true;
			passwordInput.background = true;
			passwordInput.backgroundColor = 0xFFFFFF;
			passwordInput.border = true;
			passwordInput.borderColor = 0x8192AD;
			passwordInput.x = 14;
			passwordInput.y = 64;
			passwordInput.width = cardWidth - 132;
			passwordInput.height = 44;
			addChild(passwordInput);
			unlockButton = new MobileButton("Unlock", 100, 44, submitPassword, 0x4D78B7);
			unlockButton.x = cardWidth - 114;
			unlockButton.y = 64;
			addChild(unlockButton);
			return;
		}
		var open = access == Open;
		var gap = 6.0;
		var slotWidth = (cardWidth - 28 - gap * 3) / 4;
		for (i in 0...4) {
			var index = i;
			var button = new MobileButton(open ? 'Join ${i + 1}' : LevelAccess.coverText(access), slotWidth, 44,
				open ? function():Void clickSlot(index) : function():Void LobbyPopups.showLevel(Std.string(info.levelId)), 0x4D78B7);
			button.x = 14 + i * (slotWidth + gap);
			button.y = 64;
			joinButtons.push(button);
			addChild(button);
		}
	}

	private function submitPassword():Void {
		if (passwordInput == null || unlockButton == null) return;
		unlockButton.setLabel("Checking…");
		var hash = haxe.crypto.Md5.encode(passwordInput.text + ServerConfig.LEVEL_PASS_SALT);
		var fields = ["course_id" => Std.string(info.levelId), "hash" => hash];
		asyncGuard.watch(LevelItem.passPostFactory(ServerConfig.levelPassCheckUrl(), fields, asyncGuard.wrap(function(body:String):Void {
			var valid = false;
			try {
				valid = LevelItem.parsePasswordResponse(body, info.levelId);
			} catch (_:Dynamic) {}
			if (!valid) {
				unlockButton.setLabel("Try Again");
				passwordInput.text = "";
				return;
			}
			passOK = true;
			removePasswordControls();
			buildAccessControls(LevelAccess.evaluate(info.pass, passOK, LobbySession.group,
				LobbySession.userName.toLowerCase() == info.userName.toLowerCase(), Std.int(SecureData.getNumber("userRank")), info.minLevel,
				AccountState.currentHat, info.badHats));
		}), asyncGuard.wrap(function(_:String):Void {
			unlockButton.setLabel("Try Again");
		})));
	}

	private function removePasswordControls():Void {
		if (passwordInput != null && passwordInput.parent == this) removeChild(passwordInput);
		passwordInput = null;
		if (unlockButton != null) unlockButton.remove();
		unlockButton = null;
	}

	private function toggleFavorite():Void {
		var adding = !LobbySession.isFavorite(info.levelId);
		new UploadingPopup(ServerConfig.favoriteModifyUrl(), ["mode" => adding ? "add" : "remove", "level_id" => Std.string(info.levelId)],
			adding ? "Adding to favorites…" : "Removing from favorites…", function(_:Dynamic):Void {
				if (adding && !LobbySession.isFavorite(info.levelId)) LobbySession.favoriteLevels.push(info.levelId);
				if (!adding) LobbySession.favoriteLevels.remove(info.levelId);
				if (favoriteButton != null) favoriteButton.setLabel(adding ? "★ Saved" : "☆ Save");
			});
	}

	private function clickSlot(slot:Int):Void {
		if (selectedSlot == slot) {
			LobbySocket.write("confirm_slot`");
			joinButtons[slot].setLabel("Ready!");
			joinButtons[slot].selected = true;
			return;
		}
		LobbySocket.write("fill_slot`" + info.levelId + "_" + info.version + "`" + slot + "`" + LevelListingState.currentPageNum);
		joinButtons[slot].setLabel("Joining…");
	}

	private function installCommands():Void {
		bindCommand("fillSlot" + info.levelId + "_" + info.version, function(args:Array<String>):Void {
			var slot = args.length > 0 ? Std.parseInt(args[0]) : null;
			if (slot == null || slot < 0 || slot >= joinButtons.length) return;
			var player = args.length > 1 ? args[1] : "Player";
			var me = args.length > 3 && args[3] == "me";
			joinButtons[slot].setLabel(me ? "Tap Ready" : player);
			joinButtons[slot].selected = me;
			if (me) {
				selectedSlot = slot;
				LevelLaunch.select(info.levelId, info.version);
			}
		});
		bindCommand("confirmSlot" + info.levelId + "_" + info.version, function(args:Array<String>):Void {
			var slot = args.length > 0 ? Std.parseInt(args[0]) : null;
			if (slot != null && slot >= 0 && slot < joinButtons.length) joinButtons[slot].setLabel("Ready!");
		});
		bindCommand("clearSlot" + info.levelId + "_" + info.version, function(args:Array<String>):Void {
			var slot = args.length > 0 ? Std.parseInt(args[0]) : null;
			if (slot == null || slot < 0 || slot >= joinButtons.length) return;
			joinButtons[slot].setLabel('Join ${slot + 1}');
			joinButtons[slot].selected = false;
			if (selectedSlot == slot) {
				selectedSlot = -1;
				LevelLaunch.clear(info.levelId, info.version);
			}
		});
	}

	private function bindCommand(name:String, handler:Array<String>->Void):Void {
		CommandHandler.commandHandler.defineCommand(name, handler);
		bindings.push({name: name, handler: handler});
	}

	private function addText(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, color:Int, bold:Bool):Void {
		var field = new TextField();
		field.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, size, color, bold);
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.mouseEnabled = false;
		field.text = value;
		addChild(field);
	}

	private function roundedRating():String return Std.string(Math.round(info.rating * 10) / 10);

	private static function modeColor(type:String):Int {
		return switch (type) {
			case "d": 0x4D455F;
			case "e": 0x3B5B56;
			case "o": 0x5C4E38;
			case "h": 0x5A4053;
			default: 0x3B4D69;
		};
	}

	public function remove():Void {
		asyncGuard.remove();
		removePasswordControls();
		if (favoriteButton != null) favoriteButton.remove();
		favoriteButton = null;
		for (binding in bindings) CommandHandler.commandHandler.defineCommand(binding.name, null);
		bindings = [];
		for (button in joinButtons) button.remove();
		joinButtons = [];
		if (selectedSlot >= 0) LevelLaunch.clear(info.levelId, info.version);
		if (parent != null) parent.removeChild(this);
	}
}
