package pr2.page;

#if js
import js.Browser;
#end
import openfl.display.Bitmap;
import openfl.display.InteractiveObject;
import openfl.display.PixelSnapping;
import openfl.events.TimerEvent;
import openfl.filters.GlowFilter;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.Assets;
import openfl.utils.Timer;
import pr2.Constants;
import pr2.page.LoginSocketProbe.LoginProbeStatus;
import pr2.runtime.FontResolver;
import pr2.net.AccountCreationClient;
import pr2.net.ForgotPasswordClient;
import pr2.net.LoginAuthClient;
import pr2.net.LoginSessionGate;
import pr2.net.LoginSessionGate.LoginSessionResult;
import pr2.net.FormPostClient;
import pr2.net.SavedAccounts;
import pr2.net.ServerInfo;
import pr2.net.ServerStatusClient;
import pr2.runtime.FlComboBox;
import pr2.audio.AudioManager;
import pr2.lobby.LobbySession;
import pr2.lobby.account.Settings;
import pr2.lobby.account.Presets;
import pr2.lobby.messages.UnreadNotif;
import pr2.util.RequestGeneration;

private typedef LoginPageArt = {
	final assetPath:String;
	final trimX:Int;
	final trimY:Int;
}

/**
	Login menu ported from the Flash `menu.LoginPage`.

	The page art is baked through the Flash -> SVG -> PNG pipeline. The original
	Flash menu buttons are runtime text controls, so only those labels and hit
	areas are rebuilt in Haxe.
**/
class LoginPage extends Page {
	private static inline var LOGIN_PAGE_NO_LOGO_ASSET = "assets/login/login_page_no_logo@4x.png";
	private static inline var LOGIN_PAGE_SCALE = 4;
	private static inline var LOGIN_PAGE_NO_LOGO_TRIM_X = 868;
	private static inline var LOGIN_PAGE_NO_LOGO_TRIM_Y = 846;

	private static inline var MENU_X:Float = 275;
	private static inline var MENU_Y:Float = 228;
	private static inline var MENU_SPACING:Float = 22;

	private var background:Null<LoginBackground>;
	private var pageArt:Null<Bitmap>;
	private var titleText:Null<TextField>;
	private var buttons:Array<LoginPageMenuButton> = [];
	private var activePopup:Null<LoginFlashPopup>;
	private var servers:Array<ServerInfo> = [];
	private var selectedServerIndex:Int = 0;
	private var socketProbe:Null<LoginSocketProbe>;
	private var pendingCreatedUserName:String = "";
	private var pendingCreatedUserPass:String = "";
	private var accountGeneration:RequestGeneration = new RequestGeneration();
	private var loginGate:Null<LoginSessionGate>;
	private var loginServer:Null<ServerInfo>;
	private var loginRemember:Bool = false;
	private var loginToken:String = "";
	private var serverRefreshTimer:Null<Timer>;
	private var reloadCooldownTimer:Null<Timer>;
	private var serverGeneration:RequestGeneration = new RequestGeneration();
	public final siteMode:String;

	public function new(?siteMode:String) {
		super();
		this.siteMode = siteMode == null ? "kongregate" : siteMode;
	}

	override public function initialize():Void {
		AudioManager.enterLogin();
		background = new LoginBackground();
		addChild(background);

		var art = loginPageArtFor(siteMode);
		pageArt = createBitmap(art.assetPath, art.trimX, art.trimY, LOGIN_PAGE_SCALE);
		addChild(pageArt);

		titleText = createTitle();
		addChild(titleText);

		addMenuButton("Log In", openLoginDialog);
		addMenuButton("Play as Guest", openGuestDialog);
		addMenuButton("Create Account", function():Void openCreateAccountDialog());
		addMenuButton("Instructions", openInstructions);
		addMenuButton("Credits", openCreditsDialog);

		loadServers();
		serverRefreshTimer = new Timer(60000);
		serverRefreshTimer.addEventListener(TimerEvent.TIMER, onServerRefreshTimer);
		serverRefreshTimer.start();
	}

	override public function remove():Void {
		accountGeneration.cancel();
		closePopup();
		closeSocketProbe();
		stopServerTimers();

		for (button in buttons) {
			button.remove();
			if (button.parent != null) {
				button.parent.removeChild(button);
			}
		}
		buttons = [];

		if (titleText != null && titleText.parent != null) {
			titleText.parent.removeChild(titleText);
		}
		titleText = null;

		if (pageArt != null && pageArt.parent != null) {
			pageArt.parent.removeChild(pageArt);
		}
		pageArt = null;

		if (background != null) {
			background.remove();
			if (background.parent != null) {
				background.parent.removeChild(background);
			}
			background = null;
		}
		super.remove();
	}

	private function addMenuButton(label:String, clickHandler:Void->Void):Void {
		var button = new LoginPageMenuButton(label, clickHandler);
		button.x = MENU_X;
		button.y = MENU_Y + buttons.length * MENU_SPACING;
		buttons.push(button);
		addChild(button);
	}

	private function openInstructions():Void {
		#if js
		Browser.window.open("/instructions.php", "_blank");
		#end
	}

	private function openLoginDialog():Void {
		if (SavedAccounts.getAll().length > 0) {
			openServerSelectPopup(false, false);
			return;
		}
		openCredentialDialog();
	}

	private function openCredentialDialog(?returnToAccounts:Bool = false):Void {
		loginToken = "";
		var popup = openPopup("LoginPopupGraphic");
		var nameInput = popup.input("nameBox");
		var passInput = popup.input("passBox");
		var rememberCheck = popup.checkBox("rememberMe_chk");
		populateServerCombo(popup.comboBox("dropdown"));
		popup.bindComboBox("dropdown", function(combo:FlComboBox):Void {
			selectServerFromCombo(combo);
		});
		popup.bindButton("reload_bt", function():Void {
			startServerReload(popup);
		});
		popup.bindButton("forgotPass", function():Void {
			openForgotPasswordDialog(nameInput.text);
		});
		popup.bindButton("cancel_bt", returnToAccounts ? function():Void openServerSelectPopup(false, false) : closePopup);
		var submit = function():Void {
			if (selectedServer() == null) {
				return;
			}
			var userName = StringTools.trim(nameInput.text);
			var userPass = passInput.text;
			closePopup();
			openConnectingPopup(userName, userPass, rememberCheck != null && rememberCheck.selected);
		};
		popup.bindButton("login_bt", submit);
		popup.bindEnter("nameBox", submit);
		popup.bindEnter("passBox", submit);
	}

	private function openForgotPasswordDialog(prefilledName:String):Void {
		var popup = openPopup("ForgotPassPopupGraphic");
		var nameInput = popup.input("nameBox");
		var emailInput = popup.input("emailBox");
		nameInput.text = prefilledName;

		var submit = function():Void {
			var name = nameInput.text;
			var email = emailInput.text;
			var progress = openPopup("UploadingPopupGraphic");
			var canceled = false;
			progress.setText("textBox", "Checking your information...");
			progress.bindButton("close_bt", function():Void {
				canceled = true;
				closePopup();
			});
			ForgotPasswordClient.send(name, email, function(result):Void {
				if (!canceled) {
					openLoginMessage(result.message == "" ? "Your request was processed." : result.message);
				}
			}, function(message:String):Void {
				if (!canceled) {
					openLoginMessage("Error: " + message);
				}
			});
		};

		popup.bindButton("ok_bt", submit);
		popup.bindButton("cancel_bt", closePopup);
		popup.bindEnter("nameBox", submit);
		popup.bindEnter("emailBox", submit);
	}

	private function openLoginMessage(message:String, ?afterClose:Void->Void):Void {
		var popup = openPopup("MessagePopupGraphic");
		popup.setText("textBox", message);
		popup.bindButton("ok_bt", afterClose == null ? closePopup : afterClose);
	}

	private function openGuestDialog():Void {
		loginToken = "";
		openServerSelectPopup(true, false);
	}

	private function openCreateAccountDialog(
		?initialName:String = "",
		?initialPassword:String = "",
		?initialConfirmation:String = "",
		?initialEmail:String = ""
	):Void {
		loginToken = "";
		var popup = openPopup("CreateAccountPopupGraphic");
		var nameInput = popup.input("nameBox");
		var passInput = popup.input("passBox1");
		var confirmInput = popup.input("passBox2");
		var emailInput = popup.input("emailBox");
		nameInput.text = initialName;
		passInput.text = initialPassword;
		confirmInput.text = initialConfirmation;
		emailInput.text = initialEmail;
		popup.bindButton("cancel_bt", function():Void {
			accountGeneration.cancel();
			closePopup();
		});
		popup.bindButton("createAccount_bt", function():Void {
			var userName = nameInput.text;
			var userPass = passInput.text;
			var confirmation = confirmInput.text;
			var email = emailInput.text;
			var retry = function():Void openCreateAccountDialog(userName, userPass, confirmation, email);
			if (userPass != confirmation) {
				openLoginMessage("The passwords don't match. Please enter your password again.", retry);
				return;
			}

			var generation = accountGeneration.begin();
			var progress = openPopup("UploadingPopupGraphic");
			progress.setText("textBox", "Creating account...");
			progress.bindButton("close_bt", function():Void {
				if (!accountGeneration.claim(generation)) return;
				retry();
			});
			AccountCreationClient.create(userName, userPass, email, function(result):Void {
				if (!accountGeneration.claim(generation)) return;
				if (result.success) {
					pendingCreatedUserName = userName;
					pendingCreatedUserPass = userPass;
					openServerSelectPopup(false, true);
				} else {
					var message = result.message == ""
						? "Error: An unknown error occurred. I suspect evil aliens."
						: "Error: " + result.message;
					openLoginMessage(message, retry);
				}
			}, function(message:String):Void {
				if (!accountGeneration.claim(generation)) return;
				openLoginMessage("Error: " + message, retry);
			});
		});
	}

	private function openCreditsDialog():Void {
		var popup = openPopup("CreditsPopupGraphic");
		popup.bindButton("close_bt", closePopup);
	}

	private function openServerSelectPopup(guestLogin:Bool, createdAccount:Bool):Void {
		var popup = openPopup("ServerSelectPopupGraphic");
		populateServerCombo(popup.comboBox("serverSelect"));
		var accountCombo = popup.comboBox("userSelect");
		var selectedToken = "";
		var selectedName = "";
		if (guestLogin || createdAccount) {
			popup.setComponentLabel("userSelect", guestLogin ? "Guest" : pendingCreatedUserName);
			if (accountCombo != null) accountCombo.enabled = false;
		} else if (accountCombo != null) {
			accountCombo.removeAll();
			for (account in SavedAccounts.getAll()) accountCombo.addItem({label: account.name, token: account.token});
			accountCombo.addItem({label: "Use Other Account...", token: ""});
			accountCombo.selectedIndex = 0;
			accountCombo.enabled = true;
			selectedName = Reflect.field(accountCombo.selectedItem, "label");
			selectedToken = Reflect.field(accountCombo.selectedItem, "token");
			popup.bindComboBox("userSelect", function(combo:FlComboBox):Void {
				selectedName = Reflect.field(combo.selectedItem, "label");
				selectedToken = Reflect.field(combo.selectedItem, "token");
				if (selectedToken == "") openCredentialDialog(true);
			});
		}
		var userDelete = popup.child("user_del_bt");
		if (userDelete != null) {
			userDelete.alpha = guestLogin || createdAccount ? 0.1 : 1;
			var userDeleteInteractive = Std.downcast(userDelete, InteractiveObject);
			if (userDeleteInteractive != null) {
				userDeleteInteractive.mouseEnabled = !(guestLogin || createdAccount);
			}
		}
		popup.bindComboBox("serverSelect", function(combo:FlComboBox):Void {
			selectServerFromCombo(combo);
		});
		popup.bindButton("reload_bt", function():Void {
			startServerReload(popup);
		});
		popup.bindButton("cancel_bt", closePopup);
		if (!guestLogin && !createdAccount) popup.bindButton("user_del_bt", function():Void {
			if (selectedToken == "") return;
			var name = selectedName;
			var token = selectedToken;
			var confirm = openPopup("ConfirmPopupGraphic");
			confirm.setText("textBox", 'Are you sure you want to delete "$name" from your saved accounts?');
			confirm.bindButton("cancel_bt", function():Void openServerSelectPopup(false, false));
			confirm.bindButton("ok_bt", function():Void {
				FormPostClient.post(pr2.net.ServerConfig.logoutUrl(), ["token" => token], function(_):Void {}, function(_):Void {});
				SavedAccounts.deleteAccount(name);
				if (SavedAccounts.getAll().length == 0) openCredentialDialog(); else openServerSelectPopup(false, false);
			});
		});
		popup.bindButton("login_bt", function():Void {
			if (selectedServer() == null) {
				popup.setMessage("No server is available yet.");
				return;
			}
			closePopup();
			if (guestLogin) {
				openConnectingPopup("Guest", "", false);
			} else if (createdAccount) {
				openConnectingPopup(pendingCreatedUserName, pendingCreatedUserPass, false);
			} else {
				loginToken = selectedToken;
				openConnectingPopup(selectedName, "", true);
			}
		});
	}

	private function openConnectingPopup(userName:String, userPass:String, remember:Bool):Void {
		var popup = openPopup("ConnectingPopupGraphic");
		popup.setMessage('Connecting as $userName...');
		popup.bindButton("var_1", function():Void {
			closeSocketProbe();
			closePopup();
		});
		attemptConnection(userName, userPass, remember, popup);
	}

	private function openLoggingInPopup(loginId:String, userName:String, userPass:String, remember:Bool, server:ServerInfo):Void {
		var popup = openPopup("LoggingInPopupGraphic");
		popup.bindButton("close_bt", function():Void {
			closeSocketProbe();
			closePopup();
		});
		var parsedLoginId = Std.parseInt(loginId);
		if (parsedLoginId == null) {
			popup.setMessage('Invalid login id from server: $loginId');
			return;
		}
		popup.setMessage("Sending encrypted login...");
		loginServer = server;
		loginRemember = remember;
		var gate = new LoginSessionGate(enterLobby);
		loginGate = gate;
		// Token logins authenticate purely from the saved `token` field. Flash's
		// remembered-account path never sets `Main.userName`, so it posts an empty
		// user_name; the server rejects a name supplied without a password ("You
		// must enter a name and password.") before it consults the token, so we
		// must send an empty name here too. `userName` is still used elsewhere
		// (connecting message, socket-username fallback).
		var payloadUserName = loginToken != "" ? "" : userName;
		LoginAuthClient.login(payloadUserName, userPass, server, remember, parsedLoginId, function(result):Void {
			if (loginGate != gate) return;
			if (result.success) {
				popup.setMessage("Account accepted. Waiting for server confirmation...");
				gate.acceptHttp(result);
			} else {
				if (Reflect.field(result.data, "resetToken") == true && loginToken != "") SavedAccounts.deleteAccount(loginToken, true);
				failLogin(result.message == "" ? "Login failed." : result.message);
			}
		}, function(message:String):Void {
			if (loginGate != gate) return;
			failLogin(message);
		}, loginToken);
	}

	private function openPopup(linkage:String):LoginFlashPopup {
		closePopup();
		var popup = new LoginFlashPopup(linkage);
		activePopup = popup;
		addChild(popup);
		return popup;
	}

	private function closePopup():Void {
		if (activePopup != null) {
			activePopup.remove();
			if (activePopup.parent != null) {
				activePopup.parent.removeChild(activePopup);
			}
			activePopup = null;
		}
	}

	private function loadServers():Void {
		var previousServer = selectedServer();
		var generation = serverGeneration.begin();
		setActiveServerCombosLoading();
		ServerStatusClient.fetch(function(result):Void {
			if (serverGeneration.isStale(generation)) return;
			servers = ServerStatusClient.selectList(result.servers, LobbySession.guildId, Constants.BETA);
			selectedServerIndex = previousServer == null
				? ServerStatusClient.preferredIndex(servers, LobbySession.guildId)
				: findServerIndex(previousServer);
			updateActiveServerCombos();
		}, function(message:String):Void {
			if (serverGeneration.isStale(generation)) return;
			servers = [];
			selectedServerIndex = -1;
			updateActiveServerCombos();
		});
	}

	private function startServerReload(popup:LoginFlashPopup):Void {
		if (reloadCooldownTimer != null) return;
		popup.setButtonEnabled("reload_bt", false, 0.1);
		loadServers();
		reloadCooldownTimer = new Timer(10000, 1);
		reloadCooldownTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onReloadCooldownComplete);
		reloadCooldownTimer.start();
	}

	private function onReloadCooldownComplete(_:TimerEvent):Void {
		if (reloadCooldownTimer != null) {
			reloadCooldownTimer.stop();
			reloadCooldownTimer = null;
		}
		if (activePopup != null) activePopup.setButtonEnabled("reload_bt", true, 1);
	}

	private function onServerRefreshTimer(_:TimerEvent):Void {
		loadServers();
	}

	private function stopServerTimers():Void {
		if (serverRefreshTimer != null) {
			serverRefreshTimer.stop();
			serverRefreshTimer.removeEventListener(TimerEvent.TIMER, onServerRefreshTimer);
			serverRefreshTimer = null;
		}
		if (reloadCooldownTimer != null) {
			reloadCooldownTimer.stop();
			reloadCooldownTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onReloadCooldownComplete);
			reloadCooldownTimer = null;
		}
		serverGeneration.cancel();
	}

	private function selectedServer():Null<ServerInfo> {
		if (servers.length == 0) {
			return null;
		}
		if (selectedServerIndex < 0 || selectedServerIndex >= servers.length) {
			selectedServerIndex = 0;
		}
		return servers[selectedServerIndex];
	}

	private function findServerIndex(previous:Null<ServerInfo>):Int {
		if (previous != null) {
			for (i in 0...servers.length) {
				if (servers[i].serverId == previous.serverId) {
					return i;
				}
			}
		}
		return ServerStatusClient.preferredIndex(servers, LobbySession.guildId);
	}

	private function selectServerFromCombo(combo:FlComboBox):Void {
		if (combo.selectedIndex < 0 || combo.selectedIndex >= servers.length) {
			return;
		}
		selectedServerIndex = combo.selectedIndex;
		updateActiveServerCombos();
	}

	private function populateServerCombo(combo:Null<FlComboBox>):Void {
		if (combo == null) {
			return;
		}
		combo.removeAll();
		if (servers.length == 0) {
			combo.prompt = "No servers found. :(";
			combo.enabled = false;
			return;
		}
		combo.prompt = "";
		for (server in servers) {
			combo.addItem({label: server.label(), server: server});
		}
		combo.selectedIndex = selectedServerIndex;
		combo.enabled = true;
	}

	private function setActiveServerCombosLoading():Void {
		if (activePopup == null) {
			return;
		}
		for (name in ["serverSelect", "dropdown"]) {
			var combo = activePopup.comboBox(name);
			if (combo != null) {
				combo.removeAll();
				combo.prompt = "Loading...";
				combo.enabled = false;
			}
		}
	}

	private function updateActiveServerCombos():Void {
		if (activePopup == null) {
			return;
		}
		populateServerCombo(activePopup.comboBox("serverSelect"));
		populateServerCombo(activePopup.comboBox("dropdown"));
	}

	private function attemptConnection(userName:String, userPass:String, remember:Bool, popup:LoginFlashPopup):Void {
		var server = selectedServer();
		if (server == null) {
			popup.setMessage("No server is available yet.");
			return;
		}
		closeSocketProbe();
		popup.setMessage('Connecting to ${server.label()}...');
		socketProbe = new LoginSocketProbe(server, function(status:LoginProbeStatus):Void {
			switch (status) {
				case Message(message):
					popup.setMessage(message);
				case LoginId(loginId):
					openLoggingInPopup(loginId, userName, userPass, remember, server);
				case LoginSuccessful(group, socketUserName):
					if (loginGate != null) loginGate.acceptSocket(group, socketUserName == "" ? userName : socketUserName);
				case LoginFailed(message), ConnectionClosed(message):
					failLogin(message);
			}
		});
		socketProbe.connect();
	}

	private function enterLobby(session:LoginSessionResult):Void {
		// Hand the live connection to the lobby: detach the login-phase hooks but
		// keep the socket open (the Flash original reuses the single Main.socket),
		// so the lobby's get_customize_info etc. run on the same session.
		if (socketProbe != null) {
			socketProbe.release();
			socketProbe = null;
		}
		closePopup();
		var server = loginServer;
		LoginSessionInstaller.install(session, server, loginRemember);
		loginToken = "";
		if (pageHolder != null) {
			pageHolder.changePage(new LobbyPage(session.userName, server));
		}
	}

	private function failLogin(message:String):Void {
		loginGate = null;
		loginServer = null;
		closeSocketProbe();
		pr2.lobby.LobbySession.clear();
		Settings.clear();
		UnreadNotif.reset();
		openLoginMessage(message == "" ? "Login failed." : message);
	}

	private function closeSocketProbe():Void {
		if (socketProbe != null) {
			socketProbe.close();
			socketProbe = null;
		}
		loginGate = null;
	}

	private static function createBitmap(assetPath:String, trimX:Int, trimY:Int, scale:Int):Bitmap {
		var bitmap = new Bitmap(Assets.getBitmapData(assetPath), PixelSnapping.AUTO, true);
		bitmap.x = trimX / scale;
		bitmap.y = trimY / scale;
		bitmap.scaleX = 1 / scale;
		bitmap.scaleY = 1 / scale;
		return bitmap;
	}

	private static function loginPageArtFor(_siteMode:String):LoginPageArt {
		return {assetPath: LOGIN_PAGE_NO_LOGO_ASSET, trimX: LOGIN_PAGE_NO_LOGO_TRIM_X, trimY: LOGIN_PAGE_NO_LOGO_TRIM_Y};
	}

	// The "Platform Racing 2" logo. In the original Flash menu this is live
	// Gwibble text with a white glow (XFL LoginPage symbol, Layer 7); the baked
	// page art no longer includes it. Geometry mirrors the DOMStaticText:
	// tx/ty 81.4/92.4, box 386.8 wide, size 43, centered, lineSpacing -3.
	private static function createTitle():TextField {
		var text = new TextField();
		var format = new TextFormat(FontResolver.resolve("Gwibble"), 43, 0x000000, false, false, false, null, null, TextFormatAlign.CENTER, 0, 0, 0, -3);
		text.defaultTextFormat = format;
		text.embedFonts = true;
		text.x = 81.4;
		text.y = 92.4;
		text.width = 386.8;
		text.height = 120;
		text.autoSize = TextFieldAutoSize.NONE;
		text.selectable = false;
		text.mouseEnabled = false;
		text.multiline = true;
		text.wordWrap = false;
		text.text = "Platform Racing\n-- 2 --";
		text.setTextFormat(format);
		text.filters = [new GlowFilter(0xFFFFFF, 1, 6, 6, 2, 3)];
		return text;
	}

}
