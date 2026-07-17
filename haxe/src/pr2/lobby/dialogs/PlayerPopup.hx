package pr2.lobby.dialogs;

#if js
import js.Browser;
#end
import haxe.Json;
import haxe.Timer;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.app.AppStage;
import pr2.gameplay.ExpGain;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyPopups;
import pr2.lobby.LobbyRight;
import pr2.lobby.LobbySession;
import pr2.lobby.account.AccountCharacter;
import pr2.lobby.players.SocialAction;
import pr2.lobby.players.SocialActions;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.ui.controls.GameButton;
import pr2.ui.GuildName;
import pr2.util.AsyncRemovalGuard;
import pr2.util.DisplayUtil;
import pr2.util.Dyn;

/**
	Port of Flash `dialogs.PlayerPopup`: the player profile popup raised by clicking
	a player's name in chat (and elsewhere). It loads the profile from the game
	socket (`get_player_info`) when connected, falling back to the
	`get_player_info.php` HTTP endpoint, then fills the authored `playerInfo` symbol
	— status, group, guild, rank, hats, join/active dates, the verified/Hall-of-Fame
	icons, the hat/head/body/feet character preview — and wires the follow / friend /
	ignore / message / view-levels buttons exactly as the original did.

	A profile that comes back as a guest (group <= 0) hands off to
	`PlayerGuestPopup`, matching Flash. The privileged side menus mirror Flash's
	moderator ban menu and temporary moderator warning/kick menu.
**/
class PlayerPopup extends Popup {
	public static var lookupUserHandler:Null<String->Void> = null;
	public static var instance:Null<PlayerPopup>;
	public static var hoverDelayFactory:(Void->Void, Int)->Null<Timer> = defaultHoverDelay;

	private static final MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
	private static final MONTHS_LONG = [
		"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
	];

	private var art:Null<PlayerView>;
	private var playerInfo:Null<DisplayObjectContainer>;
	private var nameBox:Null<TextField>;
	private var userName:String;
	private var userId:Int = 0;
	private var userIdShown:Bool = false;
	private var dataMode:String = "http";

	private var character:Null<AccountCharacter>;
	private var guildNameClip:Null<GuildName>;
	private var hover:Null<HoverPopup>;
	private var sendPmHover:Null<HoverPopup>;
	private var sendPmHoverTimer:Null<Timer>;
	private var registerTime:Float = 0;
	private var activeTime:Float = 0;
	private var expPoints:Int = 0;
	private var expToRank:Int = 0;
	private var rankValue:Int = 0;
	private var expGain:Null<ExpGain>;
	private var banMenu:Null<BanMenu>;
	private var adminMenu:Null<AdminMenu>;
	private var tempModMenu:Null<TempModMenu>;

	private var cm:CommandHandler = CommandHandler.commandHandler;
	private var cleanups:Array<Void->Void> = [];
	private var asyncGuard:AsyncRemovalGuard = new AsyncRemovalGuard();

	public function new(name:String, autoLoad:Bool = true) {
		if (PlayerPopup.instance != null) {
			PlayerPopup.instance.startFadeOut();
		}
		if (GuildPopup.instance != null) {
			GuildPopup.instance.startFadeOut();
		}
		super();
		PlayerPopup.instance = this;

		this.userName = name;
		art = new PlayerView();
		nameBox = LobbyArt.text(art, "nameBox");
		if (nameBox != null) {
			nameBox.text = "-- " + name + " --";
		}
		playerInfo = Std.downcast(DisplayUtil.findByName(art, "playerInfo"), DisplayObjectContainer);
		if (playerInfo != null) {
			playerInfo.visible = false;
		}
		bindClick(DisplayUtil.findByName(art, "close_bt"), clickClose);
		addChild(art);

		// `autoLoad` is only disabled by tests, which feed `applyReturnData` directly.
		if (autoLoad) {
			// Prefer the live socket, exactly like Flash; fall back to HTTP otherwise.
			if (LobbySocket.isConnected()) {
				cm.defineCommand("playerInfo", playerInfoFromSocket);
				LobbySocket.write("get_player_info`" + name);
			} else {
				playerInfoFromHTTP();
			}
		}
	}

	private function playerInfoFromSocket(a:Array<String>):Void {
		cm.defineCommand("playerInfo", null);
		try {
			var ret = a.length > 0 ? a[0] : "0";
			if (ret == "0" || ret == "") {
				throw "no socket data";
			}
			dataMode = "socket";
			applyReturnData(Json.parse(ret));
		} catch (_:Dynamic) {
			playerInfoFromHTTP();
		}
	}

	private function playerInfoFromHTTP():Void {
		dataMode = "http";
		asyncGuard.watch(TextLoader.load(ServerConfig.getPlayerInfoUrl(userName), asyncGuard.wrap(function(body:String):Void {
			if (fadeOutStarted) {
				return;
			}
			try {
				applyReturnData(Json.parse(body));
			} catch (_:Dynamic) {
				startFadeOut();
			}
		}), asyncGuard.wrap(function(_:String):Void {
			startFadeOut();
		})));
	}

	/** Fill the popup from a parsed player-info object (socket or HTTP payload). */
	public function applyReturnData(ret:Dynamic):Void {
		if (art == null || playerInfo == null) {
			return;
		}
		userId = Dyn.int(ret, "userId");
		var group = Dyn.int(ret, "group");

		var groupText:String;
		if (group == 1) {
			groupText = Dyn.bool(ret, "ca") ? "Community Ambassador" : "Member";
		} else if (group == 2) {
			if (Dyn.bool(ret, "temp_mod")) {
				groupText = "Temporary Moderator";
			} else if (Dyn.bool(ret, "trial_mod")) {
				groupText = "Trial Moderator";
			} else {
				groupText = "Moderator";
			}
		} else if (group == 3) {
			groupText = "Admin";
		} else {
			// Guests get the simpler guest popup, matching Flash.
			startFadeOut();
			new PlayerGuestPopup(userName);
			return;
		}
		if (LobbySession.serverOwner == userId) {
			groupText = "Server Owner";
		}

		setText("statusBox", Dyn.string(ret, "status", ""));
		setText("groupBox", groupText);

		setupIcons(ret);

		rankValue = Dyn.int(ret, "rank");
		expPoints = Dyn.int(ret, "exp_points");
		expToRank = Dyn.int(ret, "exp_to_rank");
		setText("rankBox", Std.string(rankValue));
		setupExpGain();
		bindHover("rankBox", showRankSupplement, hideSupplement);
		setText("hatBox", Dyn.string(ret, "hats", ""));

		registerTime = Dyn.float(ret, "registerDate");
		activeTime = Dyn.float(ret, "loginDate");
		setText("registerBox", registerTime == 0 ? "Age of Heroes" : getShortDateStr(registerTime));
		if (registerTime != 0) {
			bindHover("registerBox", function():Void showDateSupplement(registerTime), hideSupplement);
		}
		setText("activeBox", getShortDateStr(activeTime));
		bindHover("activeBox", function():Void showDateSupplement(activeTime), hideSupplement);

		setupGuild(ret);
		setupCharacter(ret);
		hideSupplement();

		setupSocialButtons(ret, group);
		setupModMenus(group);

		playerInfo.visible = true;
		var loading = DisplayUtil.findByName(art, "loadingGraphic");
		if (loading != null) {
			loading.visible = false;
		}

		// Shift toggles the name box between the player name and their user id.
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(KeyboardEvent.KEY_DOWN, toggleUserIdShown);
			cleanups.push(function():Void {
				if (AppStage.stage != null) {
					AppStage.stage.removeEventListener(KeyboardEvent.KEY_DOWN, toggleUserIdShown);
				}
			});
		}
	}

	private function setupModMenus(targetGroup:Int):Void {
		if (LobbySession.group >= 2) {
			banMenu = new BanMenu(userName, this);
			addChild(banMenu);
			banMenu.x = banMenu.width / 2 + 40;
			if (art != null) {
				art.x -= 96;
			}
			if (LobbySession.group >= 3) {
				if (art != null) {
					art.x = -(art.width / 2) - 19;
				}
				banMenu.x = banMenu.width / 2 - 19;
				adminMenu = new AdminMenu(userName, this);
				adminMenu.x = 215;
				addChild(adminMenu);
			}
		} else if (LobbySession.group == 1 && LobbySession.isTempMod && targetGroup == 1) {
			tempModMenu = new TempModMenu(userName, this);
			addChild(tempModMenu);
			tempModMenu.x = tempModMenu.width / 2 + 47;
			if (art != null) {
				art.x -= 96;
			}
		}
	}

	private function setupIcons(ret:Dynamic):Void {
		var verified = DisplayUtil.findByName(playerInfo, "verifiedIcon");
		var hof = DisplayUtil.findByName(playerInfo, "hofIcon");
		var showVerified = Dyn.bool(ret, "verified");
		var showHof = Dyn.bool(ret, "hof");
		if (verified != null) {
			verified.visible = showVerified;
			if (showVerified) {
				bindIcon(verified, "Verified",
					"This account is verified due to its notability and prominence in the community.",
					"https://jiggmin2.com/forums/showthread.php?tid=4227");
			}
		}
		if (hof != null) {
			hof.visible = showHof;
			if (showHof) {
				if (!showVerified) {
					hof.x = -6;
				}
				bindIcon(hof, "Hall of Fame",
					"This player has been inducted into the Hall of Fame for their exceptional talent and dedication to the PR2 and Jiggmin community.",
					"https://jiggmin2.com/forums/showthread.php?tid=4226");
			}
		}
	}

	private function setupGuild(ret:Dynamic):Void {
		var guildId = Dyn.int(ret, "guildId");
		var guildBox = LobbyArt.text(playerInfo, "guildBox");
		if (guildBox == null) {
			return;
		}
		if (guildId == 0) {
			guildBox.text = "none";
			return;
		}
		if (guildBox.parent != null) {
			guildBox.parent.removeChild(guildBox);
		}
		guildNameClip = new GuildName(guildId, Dyn.string(ret, "guildName", ""), Dyn.string(ret, "emblem", ""), true, true);
		guildNameClip.x = -40;
		guildNameClip.y = 64;
		playerInfo.addChild(guildNameClip);
	}

	private function setupCharacter(ret:Dynamic):Void {
		var body = Dyn.int(ret, "body");
		character = new AccountCharacter(Dyn.int(ret, "hat"), Dyn.int(ret, "head"), body, Dyn.int(ret, "feet"));
		character.setHatColors(Dyn.int(ret, "hatColor"), Dyn.int(ret, "hatColor2"));
		character.setHeadColors(Dyn.int(ret, "headColor"), Dyn.int(ret, "headColor2"));
		character.setBodyColors(Dyn.int(ret, "bodyColor"), Dyn.int(ret, "bodyColor2"));
		character.setFeetColors(Dyn.int(ret, "feetColor"), Dyn.int(ret, "feetColor2"));
		character.scaleX = character.scaleY = 2;
		character.x = -75;
		character.y = 135;
		if (body == 29) {
			character.scaleX = character.scaleY -= 0.5;
			character.x -= 5;
			character.y -= 10;
		}
		playerInfo.addChildAt(character, 1);
	}

	private function setupSocialButtons(ret:Dynamic, group:Int):Void {
		var message = DisplayUtil.findByName(playerInfo, "messageButton");
		bindSendPmHover(message);
		bindClick(message, function():Void {
			clearSendPmHover();
			startFadeOut();
			new SendMessagePopup(userName);
		});
		bindClick(DisplayUtil.findByName(playerInfo, "levelsButton"), clickViewLevels);

		// Guild owners can invite guildless players or kick their own members.
		var guildId = Dyn.int(ret, "guildId");
		setVisible("inviteButton", false);
		setVisible("kickButton", false);
		setVisible("kickBg", false);
		if (LobbySession.guildOwner) {
			if (guildId == 0) {
				setVisible("inviteButton", true);
				bindClick(DisplayUtil.findByName(playerInfo, "inviteButton"), function():Void handleGuildUrl(ServerConfig.guildInviteUrl()));
			}
			if (guildId != 0 && guildId == LobbySession.guildId) {
				setVisible("kickButton", true);
				setVisible("kickBg", true);
				bindClick(DisplayUtil.findByName(playerInfo, "kickButton"), function():Void handleGuildUrl(ServerConfig.guildKickUrl()));
			}
		}

		var followBtn = flButton("followButton");
		if (followBtn != null) {
			if (Dyn.int(ret, "following") == 1) {
				followBtn.label = "Unfollow";
				bindClick(followBtn, function():Void doSocial(Unfollow));
			} else {
				followBtn.label = "Follow";
				bindClick(followBtn, function():Void doSocial(Follow));
			}
		}
		var friendBtn = flButton("friendButton");
		if (friendBtn != null) {
			if (Dyn.int(ret, "friend") == 1) {
				friendBtn.label = "Remove Friend";
				bindClick(friendBtn, function():Void doSocial(RemoveFriend));
			} else {
				friendBtn.label = "Add to Friends";
				bindClick(friendBtn, function():Void doSocial(AddFriend));
			}
		}
		var ignoreBtn = flButton("ignoreButton");
		if (ignoreBtn != null) {
			if (Dyn.int(ret, "ignored") == 1) {
				ignoreBtn.label = "Unignore";
				bindClick(ignoreBtn, function():Void doSocial(Unignore));
			} else {
				ignoreBtn.label = "Ignore";
				bindClick(ignoreBtn, function():Void doSocial(Ignore));
			}
		}

		// Guests cannot follow/friend/ignore.
		if (LobbySession.group <= 0) {
			if (followBtn != null) followBtn.enabled = false;
			if (friendBtn != null) friendBtn.enabled = false;
			if (ignoreBtn != null) ignoreBtn.enabled = false;
		}
	}

	private function doSocial(action:SocialAction):Void {
		SocialActions.perform(action, userId, userName);
		startFadeOut();
	}

	private function clickViewLevels():Void {
		if (lookupUserHandler != null) {
			lookupUserHandler(userName);
		} else if (LobbyRight.instance != null) {
			LobbyRight.instance.lookupUser(userName);
		}
		if (GuildPopup.instance != null) {
			GuildPopup.instance.startFadeOut();
		}
		if (LevelInfoPopup.instance != null) {
			LevelInfoPopup.instance.startFadeOut();
		}
		startFadeOut();
	}

	private function handleGuildUrl(url:String):Void {
		var fields = ["target_name" => userName, "user_id" => Std.string(userId)];
		new UploadingPopup(url, fields, "Uploading...");
		startFadeOut();
	}

	// --- Supplement (hover) box ----------------------------------------------

	private function showRankSupplement():Void {
		var supplBg = DisplayUtil.findByName(playerInfo, "supplBg");
		if (supplBg != null) supplBg.visible = true;
		setText("supplText", "");
		if (expGain != null && expGain.parent == null) {
			playerInfo.addChild(expGain);
		}
	}

	private function showDateSupplement(time:Float):Void {
		var supplBg = DisplayUtil.findByName(playerInfo, "supplBg");
		if (supplBg != null) supplBg.visible = true;
		setText("supplText", getDateTimeStr(time));
	}

	private function hideSupplement():Void {
		var supplBg = DisplayUtil.findByName(playerInfo, "supplBg");
		if (supplBg != null) supplBg.visible = false;
		if (expGain != null && expGain.parent == playerInfo) {
			playerInfo.removeChild(expGain);
		}
		setText("supplText", "");
	}

	private function setupExpGain():Void {
		if (expGain != null) {
			expGain.remove();
		}
		expGain = new ExpGain();
		expGain.x = playerInfo.x;
		var supplBg = DisplayUtil.findByName(playerInfo, "supplBg");
		expGain.y = (supplBg == null ? 0 : supplBg.y) + 3;
		expGain.start(expPoints, expPoints, expToRank);
	}

	private function toggleUserIdShown(e:KeyboardEvent):Void {
		if (e.keyCode != 16) {
			return;
		}
		if (nameBox != null) {
			nameBox.text = !userIdShown ? "-- User ID: " + userId + " --" : "-- " + userName + " --";
		}
		userIdShown = !userIdShown;
	}

	private function clickClose():Void {
		startFadeOut();
	}

	// --- Icon hover/click ----------------------------------------------------

	private function bindIcon(target:DisplayObject, title:String, desc:String, link:String):Void {
		var sprite = Std.downcast(target, Sprite);
		if (sprite != null) {
			sprite.buttonMode = true;
			sprite.useHandCursor = true;
		}
		var over = function(_:MouseEvent):Void {
			clearHover();
			hover = new HoverPopup(title, desc + " Click for more information.", target);
		};
		var out = function(_:MouseEvent):Void clearHover();
		var click = function(_:MouseEvent):Void navigate(link);
		target.addEventListener(MouseEvent.MOUSE_OVER, over);
		target.addEventListener(MouseEvent.MOUSE_OUT, out);
		target.addEventListener(MouseEvent.CLICK, click);
		cleanups.push(function():Void {
			target.removeEventListener(MouseEvent.MOUSE_OVER, over);
			target.removeEventListener(MouseEvent.MOUSE_OUT, out);
			target.removeEventListener(MouseEvent.CLICK, click);
		});
	}

	private function clearHover():Void {
		if (hover != null) {
			hover.remove();
			hover = null;
		}
	}

	private function bindSendPmHover(target:Null<DisplayObject>):Void {
		if (target == null) {
			return;
		}
		var over = function(_:MouseEvent):Void {
			clearSendPmHover();
			sendPmHoverTimer = hoverDelayFactory(function():Void {
				sendPmHoverTimer = null;
				clearSendPmHover();
				sendPmHover = new HoverPopup("Send PM", "Send a PM to this player.", target);
			}, 500);
		};
		var out = function(_:MouseEvent):Void clearSendPmHover();
		target.addEventListener(MouseEvent.MOUSE_OVER, over);
		target.addEventListener(MouseEvent.MOUSE_OUT, out);
		cleanups.push(function():Void {
			target.removeEventListener(MouseEvent.MOUSE_OVER, over);
			target.removeEventListener(MouseEvent.MOUSE_OUT, out);
		});
	}

	private function clearSendPmHover():Void {
		if (sendPmHoverTimer != null) {
			sendPmHoverTimer.stop();
			sendPmHoverTimer = null;
		}
		if (sendPmHover != null) {
			sendPmHover.remove();
			sendPmHover = null;
		}
	}

	public function hasSendPmHoverForTests():Bool {
		return sendPmHover != null;
	}

	private function navigate(url:String):Void {
		#if js
		Browser.window.open(url, "_blank");
		#end
	}

	// --- Small helpers -------------------------------------------------------

	private function setText(name:String, value:String):Void {
		var field = LobbyArt.text(playerInfo, name);
		if (field != null) {
			field.text = value;
		}
	}

	private function setVisible(name:String, value:Bool):Void {
		var target = DisplayUtil.findByName(playerInfo, name);
		if (target != null) {
			target.visible = value;
		}
	}

	private function flButton(name:String):Null<GameButton> {
		return Std.downcast(DisplayUtil.findByName(playerInfo, name), GameButton);
	}

	private function bindClick(target:Null<DisplayObject>, handler:Void->Void):Void {
		if (target == null) {
			return;
		}
		var sprite = Std.downcast(target, Sprite);
		if (sprite != null && !Std.isOfType(target, GameButton)) {
			sprite.buttonMode = true;
			sprite.useHandCursor = true;
			sprite.mouseChildren = false;
		}
		var listener = function(_:MouseEvent):Void handler();
		target.addEventListener(MouseEvent.CLICK, listener);
		cleanups.push(function():Void target.removeEventListener(MouseEvent.CLICK, listener));
	}

	private function bindHover(fieldName:String, over:Void->Void, out:Void->Void):Void {
		var field = LobbyArt.text(playerInfo, fieldName);
		if (field == null) {
			return;
		}
		var onOver = function(_:MouseEvent):Void over();
		var onOut = function(_:MouseEvent):Void out();
		field.addEventListener(MouseEvent.MOUSE_OVER, onOver);
		field.addEventListener(MouseEvent.MOUSE_OUT, onOut);
		cleanups.push(function():Void {
			field.removeEventListener(MouseEvent.MOUSE_OVER, onOver);
			field.removeEventListener(MouseEvent.MOUSE_OUT, onOut);
		});
	}

	private static function getShortDateStr(t:Float):String {
		var d = Date.fromTime(t * 1000);
		return d.getDate() + "/" + MONTHS[d.getMonth()] + "/" + d.getFullYear();
	}

	private static function getDateTimeStr(t:Float):String {
		var d = Date.fromTime(t * 1000);
		var hour = d.getHours();
		var ampm = hour >= 12 ? "PM" : "AM";
		var hour12 = hour % 12;
		if (hour12 == 0) {
			hour12 = 12;
		}
		var mins = StringTools.lpad(Std.string(d.getMinutes()), "0", 2);
		var secs = StringTools.lpad(Std.string(d.getSeconds()), "0", 2);
		return MONTHS_LONG[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear() + " " + hour12 + ":" + mins + ":" + secs + " " + ampm;
	}

	override public function remove():Void {
		asyncGuard.remove();
		if (PlayerPopup.instance == this) {
			PlayerPopup.instance = null;
		}
		clearHover();
		clearSendPmHover();
		if (banMenu != null) {
			banMenu.remove();
			banMenu = null;
		}
		if (adminMenu != null) {
			adminMenu.remove();
			adminMenu = null;
		}
		if (tempModMenu != null) {
			tempModMenu.remove();
			tempModMenu = null;
		}
		for (cleanup in cleanups) {
			cleanup();
		}
		cleanups = [];
		cm.defineCommand("playerInfo", null);
		if (character != null) {
			character.remove();
			character = null;
		}
		if (guildNameClip != null) {
			guildNameClip.remove();
			guildNameClip = null;
		}
		if (expGain != null) {
			expGain.remove();
			expGain = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		playerInfo = null;
		super.remove();
	}

	private static function defaultHoverDelay(callback:Void->Void, delayMs:Int):Null<Timer> {
		return Timer.delay(callback, delayMs);
	}
}
