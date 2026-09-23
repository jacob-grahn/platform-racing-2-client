package pr2.page;

#if js
import js.Browser;
#end
import openfl.events.TimerEvent;
import openfl.utils.Timer;
import pr2.Constants;
import pr2.page.LoginSocketProbe.LoginProbeStatus;
import pr2.net.AccountCreationClient;
import pr2.net.ForgotPasswordClient;
import pr2.net.LoginAuthClient;
import pr2.net.LoginSessionGate;
import pr2.net.LoginSessionGate.LoginSessionResult;
import pr2.net.FormPostClient;
import pr2.net.SavedAccounts;
import pr2.lobby.SecureData;
import pr2.net.ServerInfo;
import pr2.net.ServerStatusClient;
import pr2.ui.controls.GameSelect;
import pr2.audio.AudioManager;
import pr2.lobby.LobbySession;
import pr2.lobby.account.Settings;
import pr2.lobby.messages.UnreadNotif;
import pr2.util.RequestGeneration;

/** Shared login workflow and dialog host. Title pages compose this flow; neither
 * presentation owns authentication, server refresh, or connection handoff.
 * Dialog creation is injected; classic and mobile share every request and transition. */
class LoginFlow extends pr2.display.Removable {
	public var onAuthenticated:Null<String->ServerInfo->Void>;
	private var activePopup:Null<pr2.page.auth.AuthDialog>;
	private var dialogFactory:String->String->Map<String, String>->pr2.page.auth.AuthDialog;
	private var viewportWidth:Float = 550;
	private var viewportHeight:Float = 400;
	private var recoveryGeneration = new RequestGeneration();
	private var serversLoading:Bool = false;
	private var serverError:String = "";
	private var disposing:Bool = false;
	private var servers:Array<ServerInfo> = [];
	private var selectedServerIndex:Int = 0;
	private var socketProbe:Null<LoginSocketProbe>;
	private var pendingCreatedUserName:String = "";
	private var pendingCreatedUserPass:String = "";
	private var accountGeneration:RequestGeneration = new RequestGeneration();
	private var loginGate:Null<LoginSessionGate>;
	private var loginServer:Null<ServerInfo>;
	private var loginRemember:Bool = false;
	private var loginServerMessage:String = "";
	private var loginToken:String = "";
	private var serverRefreshTimer:Null<Timer>;
	private var reloadCooldownTimer:Null<Timer>;
	private var serverGeneration:RequestGeneration = new RequestGeneration();

	public function new(?onAuthenticated:String->ServerInfo->Void, ?dialogFactory:String->String->Map<String, String>->pr2.page.auth.AuthDialog) {
		super();
		this.onAuthenticated = onAuthenticated;
		this.dialogFactory = dialogFactory == null ? pr2.app.ScreenFactory.authDialog : dialogFactory;
	}

	public function start():Void {
		SecureData.setNumber("userRank", 0);
		AudioManager.enterLogin();
		loadServers();
		serverRefreshTimer = new Timer(60000);
		serverRefreshTimer.addEventListener(TimerEvent.TIMER, onServerRefreshTimer);
		serverRefreshTimer.start();
	}

	override public function remove():Void {
		disposing = true;
		accountGeneration.cancel();
		recoveryGeneration.cancel();
		closePopup(true);
		for (child in [for (i in 0...numChildren) getChildAt(i)]) {
			var dialog = Std.downcast(child, pr2.page.auth.AuthDialog);
			if (dialog != null) dialog.dismiss(true);
		}
		closeSocketProbe();
		stopServerTimers();
		onAuthenticated = null;
		super.remove();
	}

	public function openInstructions():Void {
		#if js
		Browser.window.open("/instructions.php", "_blank");
		#end
	}

	public function openLoginDialog():Void {
		SecureData.setNumber("userRank", -1);
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
		updateActiveServerCombos();
		popup.bindComboBox("dropdown", function(combo:GameSelect<Dynamic>):Void {
			selectServerFromCombo(combo);
		});
		popup.bindButton("reload_bt", function():Void {
			startServerReload(popup);
		});
		popup.bindButton("forgotPass", function():Void {
			openForgotPasswordDialog(nameInput.text);
		});
		popup.bindButton("cancel_bt", returnToAccounts ? function():Void openServerSelectPopup(false, false) : function():Void closePopup());
		var submit = function():Void {
			if (selectedServer() == null) {
				return;
			}
			var userName = nameInput.text;
			var userPass = passInput.text;
			closePopup();
			openConnectingPopup(userName, userPass, rememberCheck != null && rememberCheck.selected);
		};
		popup.bindButton("login_bt", submit);
		popup.bindEnter("nameBox", submit);
		popup.bindEnter("passBox", submit);
	}

	private function openForgotPasswordDialog(prefilledName:String):Void {
		var popup = mountForgotPasswordView(prefilledName);
		var nameInput = popup.input("nameBox");
		var emailInput = popup.input("emailBox");

		var submit = function():Void {
			var name = nameInput.text;
			var email = emailInput.text;
			var generation = recoveryGeneration.begin();
			openProgressPopup("Checking your information...", function():Void {
				recoveryGeneration.cancel();
				closePopup();
			});
			ForgotPasswordClient.send(name, email, function(result):Void {
				if (recoveryGeneration.claim(generation)) {
					openLoginMessage(result.message == "" ? "Your request was processed." : result.message);
				}
			}, function(message:String):Void {
				if (recoveryGeneration.claim(generation)) {
					openLoginMessage("Error: " + message);
				}
			});
		};

		popup.onSubmit = submit;
		popup.onCancel = function():Void closePopup();
	}

	private function openLoginMessage(message:String, ?afterClose:Void->Void):Void {
		closePopup();
		showNotice(message, afterClose);
	}

	public function openGuestDialog():Void {
		SecureData.setNumber("userRank", 0);
		loginToken = "";
		openServerSelectPopup(true, false);
	}

	public function openCreateAccountDialog(
		?initialName:String = "",
		?initialPassword:String = "",
		?initialConfirmation:String = "",
		?initialEmail:String = ""
	):Void {
		loginToken = "";
		var popup = mountCreateAccountView(initialName, initialPassword, initialConfirmation, initialEmail);
		popup.onCancel = function():Void {
			accountGeneration.cancel();
			closePopup();
		};
		popup.onSubmit = function():Void {
			var userName = popup.input("nameBox").text;
			var userPass = popup.input("passBox1").text;
			var confirmation = popup.input("passBox2").text;
			var email = popup.input("emailBox").text;
			var retry = function():Void openCreateAccountDialog(userName, userPass, confirmation, email);
			if (userPass != confirmation) {
				openLoginMessage("The passwords don't match. Please enter your password again.", retry);
				return;
			}

			var generation = accountGeneration.begin();
			openProgressPopup("Creating account...", function():Void {
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
		};
	}

	public function openCreditsDialog():Void {
		// Credits is not a passive authored graphic: its art and music columns each
		// have page state and TextEvent-driven navigation. Use the dedicated popup
		// here just as the lobby does, rather than displaying the raw linkage (which
		// leaves every authored page visible at once).
		pr2.app.ScreenFactory.credits();
	}

	private function openServerSelectPopup(guestLogin:Bool, createdAccount:Bool):Void {
		var popup = openPopup("ServerSelectPopupGraphic");
		populateServerCombo(popup.comboBox("serverSelect"));
		updateActiveServerCombos();
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
			popup.bindComboBox("userSelect", function(combo:GameSelect<Dynamic>):Void {
				selectedName = Reflect.field(combo.selectedItem, "label");
				selectedToken = Reflect.field(combo.selectedItem, "token");
				if (selectedToken == "") openCredentialDialog(true);
			});
		}
		popup.setButtonEnabled("user_del_bt", !(guestLogin || createdAccount), guestLogin || createdAccount ? 0.1 : 1);
			popup.bindComboBox("serverSelect", function(combo:GameSelect<Dynamic>):Void {
			selectServerFromCombo(combo);
		});
		popup.bindButton("reload_bt", function():Void {
			startServerReload(popup);
		});
		popup.bindButton("cancel_bt", function():Void closePopup());
		if (!guestLogin && !createdAccount) popup.bindButton("user_del_bt", function():Void {
			if (selectedToken == "") return;
			var name = selectedName;
			var token = selectedToken;
			openConfirm('Are you sure you want to delete "$name" from your saved accounts?', function():Void openServerSelectPopup(false, false), function():Void {
				FormPostClient.post(pr2.net.ServerConfig.logoutUrl(), ["token" => token], function(_):Void {}, function(_):Void {});
				if (!SavedAccounts.deleteAccount(name)) {
					openLoginMessage("Error: Invalid account specified.");
					return;
				}
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
		var popup = openLoggingInView();
		popup.onClose = function():Void {
			closeSocketProbe();
			closePopup();
		};
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

	private function createDialog(kind:String, message:String = "", ?values:Map<String, String>):pr2.page.auth.AuthDialog {
		var dialog = dialogFactory(kind, message, values == null ? [] : values);
		addChild(dialog);
		dialog.resizeViewport(viewportWidth, viewportHeight);
		return dialog;
	}

	public function resizeViewport(width:Float, height:Float):Void {
		viewportWidth = width; viewportHeight = height;
		for (i in 0...numChildren) {
			var dialog = Std.downcast(getChildAt(i), pr2.page.auth.AuthDialog);
			if (dialog != null) dialog.resizeViewport(width, height);
		}
	}

	private function openPopup(kind:String, message:String = "", ?values:Map<String, String>):pr2.page.auth.AuthDialog {
		closePopup();
		activePopup = createDialog(kind, message, values);
		activePopup.setButtonEnabled("reload_bt", reloadCooldownTimer == null, reloadCooldownTimer == null ? 1 : 0.4);
		return activePopup;
	}

	private function showNotice(message:String, ?afterClose:Void->Void):Void {
		if (disposing) return;
		var notice = createDialog("Message", message);
		notice.onClose = function():Void {
			notice.dismiss(true);
			if (!disposing && afterClose != null) afterClose();
		};
	}

	private function openConfirm(message:String, onCancel:Void->Void, onConfirm:Void->Void):Void {
		var view = openPopup("Confirm", message);
		view.onCancel = function():Void { closePopup(); onCancel(); };
		view.onConfirm = function():Void { closePopup(); onConfirm(); };
	}

	private function openLoggingInView():pr2.page.auth.AuthDialog return openPopup("Logging");

	private function openProgressPopup(message:String, onClose:Void->Void):pr2.page.auth.AuthDialog {
		var view = openPopup("Progress", message);
		view.onClose = onClose;
		return view;
	}

	private function mountForgotPasswordView(prefilledName:String):pr2.page.auth.AuthDialog {
		return openPopup("Recover", "", ["nameBox" => prefilledName]);
	}

	private function mountCreateAccountView(name:String, password:String, confirmation:String, email:String):pr2.page.auth.AuthDialog {
		return openPopup("Register", "", ["nameBox" => name, "passBox1" => password, "passBox2" => confirmation, "emailBox" => email]);
	}

	private function closePopup(immediate:Bool = false):Void {
		if (activePopup == null) return;
		var popup = activePopup;
		activePopup = null;
		popup.dismiss(immediate);
	}

	private function loadServers():Void {
		var previousServer = selectedServer();
		var generation = serverGeneration.begin();
		serversLoading = true;
		serverError = "";
		setActiveServerCombosLoading();
		ServerStatusClient.fetch(function(result):Void {
			if (serverGeneration.isStale(generation)) return;
			serversLoading = false;
			servers = ServerStatusClient.selectList(result.servers, LobbySession.guildId, Constants.BETA);
			selectedServerIndex = previousServer == null
				? ServerStatusClient.preferredIndex(servers, LobbySession.guildId)
				: findServerIndex(previousServer);
			updateActiveServerCombos();
		}, function(message:String):Void {
			if (serverGeneration.isStale(generation)) return;
			serversLoading = false;
			servers = [];
			serverError = "Could not load servers. Try Reload.";
			selectedServerIndex = -1;
			updateActiveServerCombos();
		});
	}

	private function startServerReload(popup:pr2.page.auth.AuthDialog):Void {
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
		if (serversLoading || servers.length == 0) {
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

	private function selectServerFromCombo(combo:GameSelect<Dynamic>):Void {
		if (combo.selectedIndex < 0 || combo.selectedIndex >= servers.length) {
			return;
		}
		selectedServerIndex = combo.selectedIndex;
		updateActiveServerCombos();
	}

	private function populateServerCombo(combo:Null<GameSelect<Dynamic>>):Void {
		if (combo == null) {
			return;
		}
		combo.removeAll();
		if (serversLoading || servers.length == 0) {
			combo.prompt = serversLoading ? "Loading..." : "No servers found. :(";
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
		activePopup.setButtonEnabled("login_bt", false, 0.4);
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
		if (activePopup.comboBox("serverSelect") == null && activePopup.comboBox("dropdown") == null) return;
		populateServerCombo(activePopup.comboBox("serverSelect"));
		populateServerCombo(activePopup.comboBox("dropdown"));
		activePopup.setButtonEnabled("login_bt", selectedServer() != null, selectedServer() == null ? 0.4 : 1);
		activePopup.setMessage(serversLoading ? "Loading servers..." : servers.length == 0 ? (serverError == "" ? "No servers are available. Try Reload." : serverError) : "");
	}

	private function attemptConnection(userName:String, userPass:String, remember:Bool, popup:pr2.page.auth.AuthDialog):Void {
		var server = selectedServer();
		if (server == null) {
			popup.setMessage("No server is available yet.");
			return;
		}
		closeSocketProbe();
		loginServerMessage = "";
		popup.setMessage('Connecting to ${server.label()}...');
		socketProbe = new LoginSocketProbe(server, function(status:LoginProbeStatus):Void {
			switch (status) {
				case Message(message):
					popup.setMessage(message);
				case LoginId(loginId):
					openLoggingInPopup(loginId, userName, userPass, remember, server);
				case LoginSuccessful(group, socketUserName):
					if (loginGate != null) loginGate.acceptSocket(group, socketUserName == "" ? userName : socketUserName);
				case ServerMessageReceived(message):
					receiveLoginServerMessage(message);
				case LoginFailed(message):
					failLogin(message);
				case ConnectionClosed(message):
					failLogin(loginServerMessage == "" ? message : loginServerMessage);
			}
		});
		socketProbe.connect();
	}

	private function receiveLoginServerMessage(message:String):Void {
		if (message == "") return;
		loginServerMessage = message;
		showNotice(message);
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
		loginServerMessage = "";
		if (onAuthenticated != null) onAuthenticated(session.userName, server);
	}

	private function failLogin(message:String):Void {
		loginGate = null;
		loginServer = null;
		loginServerMessage = "";
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

}
