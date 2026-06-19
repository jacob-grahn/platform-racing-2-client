package pr2.page;

#if js
import js.Browser;
#end
import openfl.display.Bitmap;
import openfl.display.InteractiveObject;
import openfl.display.PixelSnapping;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.filters.GlowFilter;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.Assets;
import pr2.page.LoginSocketProbe.LoginProbeStatus;
import pr2.runtime.FontResolver;
import pr2.net.AccountCreationClient;
import pr2.net.LoginAuthClient;
import pr2.net.ServerInfo;
import pr2.net.ServerStatusClient;

/**
	Login menu ported from the Flash `menu.LoginPage`.

	The page art is baked through the Flash -> SVG -> PNG pipeline. The original
	Flash menu buttons are runtime text controls, so only those labels and hit
	areas are rebuilt in Haxe.
**/
class LoginPage extends Page {
	private static inline var LOGIN_PAGE_ASSET = "assets/login/login_page@4x.png";
	private static inline var LOGIN_PAGE_SCALE = 4;
	private static inline var LOGIN_PAGE_TRIM_X = 21;
	// Trim Y dropped from 370 once the Gwibble title (Layer 7) was removed from the
	// page art; the topmost remaining content is now the menu panel. See raster
	// manifest entry for login_page (vector-art/raster-manifest-other.json).
	private static inline var LOGIN_PAGE_TRIM_Y = 848;

	private static inline var MENU_X:Float = 275;
	private static inline var MENU_Y:Float = 228;
	private static inline var MENU_SPACING:Float = 22;

	private var background:Null<LoginBackground>;
	private var pageArt:Null<Bitmap>;
	private var titleText:Null<TextField>;
	private var buttons:Array<LoginPageMenuButton> = [];
	private var muteButton:Null<LoginMuteButton>;
	private var kongHitArea:Null<Sprite>;
	private var statusText:Null<TextField>;
	private var activePopup:Null<LoginFlashPopup>;
	private var servers:Array<ServerInfo> = [];
	private var selectedServerIndex:Int = 0;
	private var socketProbe:Null<LoginSocketProbe>;
	private var pendingCreatedUserName:String = "";
	private var pendingCreatedUserPass:String = "";

	public function new() {
		super();
	}

	override public function initialize():Void {
		background = new LoginBackground();
		addChild(background);

		pageArt = createBitmap(LOGIN_PAGE_ASSET, LOGIN_PAGE_TRIM_X, LOGIN_PAGE_TRIM_Y, LOGIN_PAGE_SCALE);
		addChild(pageArt);

		titleText = createTitle();
		addChild(titleText);

		addMenuButton("Log In", openLoginDialog);
		addMenuButton("Play as Guest", openGuestDialog);
		addMenuButton("Create Account", openCreateAccountDialog);
		addMenuButton("Instructions", openInstructions);
		addMenuButton("Credits", openCreditsDialog);

		kongHitArea = createHitArea(5, 364, 183, 31, openKongDialog);
		addChild(kongHitArea);

		muteButton = new LoginMuteButton();
		muteButton.x = 491;
		muteButton.y = 363;
		addChild(muteButton);

		statusText = makeText(10, 8, 530, 20, 11, 0x20354A, TextFormatAlign.CENTER);
		statusText.text = "Loading servers...";
		addChild(statusText);
		loadServers();
	}

	override public function remove():Void {
		closePopup();
		closeSocketProbe();

		for (button in buttons) {
			button.remove();
			if (button.parent != null) {
				button.parent.removeChild(button);
			}
		}
		buttons = [];

		if (muteButton != null) {
			muteButton.remove();
			if (muteButton.parent != null) {
				muteButton.parent.removeChild(muteButton);
			}
			muteButton = null;
		}

		if (kongHitArea != null && kongHitArea.parent != null) {
			kongHitArea.parent.removeChild(kongHitArea);
		}
		kongHitArea = null;

		if (statusText != null && statusText.parent != null) {
			statusText.parent.removeChild(statusText);
		}
		statusText = null;

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
		var popup = openPopup("LoginPopupGraphic");
		var remember = false;
		var nameInput = popup.input("nameBox");
		var passInput = popup.input("passBox");
		var updateServer = function():Void {
			var server = selectedServer();
			popup.setComponentLabel("dropdown", server == null ? "No servers" : server.label());
		};
		updateServer();
		popup.bindButton("dropdown", function():Void {
			shiftServer(1);
			updateServer();
		});
		popup.bindButton("reload_bt", function():Void {
			loadServers();
			popup.setMessage("Reloading servers...");
		});
		popup.bindButton("rememberMe_chk", function():Void {
			remember = !remember;
			popup.setComponentLabel("rememberMe_chk", remember ? "Remember Me: Yes" : "Remember Me");
		});
		popup.bindButton("forgotPass", function():Void {
			popup.setMessage("Password reset is not ported yet.");
		});
		popup.bindButton("cancel_bt", closePopup);
		popup.bindButton("login_bt", function():Void {
			if (StringTools.trim(nameInput.text) == "" || passInput.text == "") {
				popup.setMessage("Enter a username and password.");
				return;
			}
			if (selectedServer() == null) {
				popup.setMessage("No server is available yet.");
				return;
			}
			var userName = StringTools.trim(nameInput.text);
			var userPass = passInput.text;
			closePopup();
			openConnectingPopup(userName, userPass, remember);
		});
	}

	private function openGuestDialog():Void {
		openServerSelectPopup(true, false);
	}

	private function openCreateAccountDialog():Void {
		var popup = openPopup("CreateAccountPopupGraphic");
		var nameInput = popup.input("nameBox");
		var passInput = popup.input("passBox1");
		var confirmInput = popup.input("passBox2");
		var emailInput = popup.input("emailBox");
		popup.bindButton("cancel_bt", closePopup);
		popup.bindButton("createAccount_bt", function():Void {
			var userName = StringTools.trim(nameInput.text);
			var userPass = passInput.text;
			if (userName == "" || userPass == "") {
				popup.setMessage("Fill in username and password.");
			} else if (userPass != confirmInput.text) {
				popup.setMessage("The passwords don't match. Please enter your password again.");
			} else {
				popup.setMessage("Creating account...");
				AccountCreationClient.create(userName, userPass, StringTools.trim(emailInput.text), function(result):Void {
					if (result.success) {
						pendingCreatedUserName = userName;
						pendingCreatedUserPass = userPass;
						openServerSelectPopup(false, true);
					} else {
						popup.setMessage(result.message == "" ? "Account creation failed." : result.message);
					}
				}, function(message:String):Void {
					popup.setMessage(message);
				});
			}
		});
	}

	private function openCreditsDialog():Void {
		var popup = openPopup("CreditsPopupGraphic");
		popup.bindButton("close_bt", closePopup);
	}

	private function openKongDialog():Void {
		var popup = openPopup("LoggingInPopupGraphic");
		popup.setMessage("Kongregate outfit linking is not available in this standalone port yet.");
		popup.bindButton("close_bt", closePopup);
	}

	private function openServerSelectPopup(guestLogin:Bool, createdAccount:Bool):Void {
		var popup = openPopup("ServerSelectPopupGraphic");
		var updateServer = function():Void {
			var server = selectedServer();
			popup.setComponentLabel("serverSelect", server == null ? "No servers" : server.label());
		};
		updateServer();
		popup.setComponentLabel("userSelect", guestLogin ? "Guest" : (createdAccount ? pendingCreatedUserName : "Use Other Account..."));
		var userDelete = popup.child("user_del_bt");
		if (userDelete != null) {
			userDelete.alpha = guestLogin || createdAccount ? 0.1 : 1;
			var userDeleteInteractive = Std.downcast(userDelete, InteractiveObject);
			if (userDeleteInteractive != null) {
				userDeleteInteractive.mouseEnabled = !(guestLogin || createdAccount);
			}
		}
		popup.bindButton("serverSelect", function():Void {
			shiftServer(1);
			updateServer();
		});
		popup.bindButton("reload_bt", function():Void {
			loadServers();
			popup.setMessage("Reloading servers...");
		});
		popup.bindButton("cancel_bt", closePopup);
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
				openLoginDialog();
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
		LoginAuthClient.login(userName, userPass, server, remember, parsedLoginId, function(result):Void {
			if (result.success) {
				var message = userName == "Guest"
					? "Guest auth accepted. Lobby handoff is not ported yet."
					: "Account auth accepted. Waiting for socket loginSuccessful/lobby handoff.";
				popup.setMessage(message);
				setStatus(message);
			} else {
				var message = result.message == "" ? "Login failed." : result.message;
				popup.setMessage(message);
				setStatus(message);
			}
		}, function(message:String):Void {
			popup.setMessage(message);
			setStatus(message);
		});
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
		ServerStatusClient.fetch(function(result):Void {
			servers = result.servers.filter(function(server):Bool {
				return server.address != "" && server.port > 0;
			});
			selectedServerIndex = 0;
			setStatus(servers.length == 0 ? "No usable servers found." : 'Loaded ${servers.length} servers. Selected ${servers[0].label()}.');
			updateActiveServerLabels();
		}, function(message:String):Void {
			servers = [];
			setStatus(message);
			updateActiveServerLabels();
		});
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

	private function shiftServer(delta:Int):Void {
		if (servers.length == 0) {
			return;
		}
		selectedServerIndex = (selectedServerIndex + delta + servers.length) % servers.length;
		var server = servers[selectedServerIndex];
		setStatus('Selected ${server.label()}.');
		updateActiveServerLabels();
	}

	private function updateActiveServerLabels():Void {
		if (activePopup == null) {
			return;
		}
		var server = selectedServer();
		var label = server == null ? "No servers" : server.label();
		activePopup.setComponentLabel("serverSelect", label);
		activePopup.setComponentLabel("dropdown", label);
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
					setStatus(message);
				case LoginId(loginId):
					setStatus('Received login id $loginId from ${server.label()}.');
					openLoggingInPopup(loginId, userName, userPass, remember, server);
				case LoginSuccessful(socketUserName):
					// The server confirms the session over the socket after
					// login.php succeeds; hand off to the lobby once it arrives.
					enterLobby(socketUserName == "" ? userName : socketUserName, server);
			}
		});
		socketProbe.connect();
	}

	private function enterLobby(userName:String, server:ServerInfo):Void {
		closeSocketProbe();
		closePopup();
		setStatus('Logged in as $userName.');
		// Guests connect with no account group; real members would carry their
		// group/id from the login response. Until that is parsed, treat named
		// logins as members so the member lobby (PMs/Account/Favorites) is shown.
		var group = userName == "Guest" ? 0 : 1;
		pr2.lobby.LobbySession.begin(userName, group, server);
		if (pageHolder != null) {
			pageHolder.changePage(new LobbyPage(userName, server));
		}
	}

	private function closeSocketProbe():Void {
		if (socketProbe != null) {
			socketProbe.close();
			socketProbe = null;
		}
	}

	private function setStatus(message:String):Void {
		if (statusText != null) {
			statusText.text = message;
		}
	}

	private static function createBitmap(assetPath:String, trimX:Int, trimY:Int, scale:Int):Bitmap {
		var bitmap = new Bitmap(Assets.getBitmapData(assetPath), PixelSnapping.AUTO, true);
		bitmap.x = trimX / scale;
		bitmap.y = trimY / scale;
		bitmap.scaleX = 1 / scale;
		bitmap.scaleY = 1 / scale;
		return bitmap;
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
		text.filters = [new GlowFilter(0xFFFFFF, 1, 4, 4, 2, 3)];
		return text;
	}

	private static function createHitArea(x:Float, y:Float, width:Float, height:Float, clickHandler:Void->Void):Sprite {
		var hitArea = new Sprite();
		hitArea.x = x;
		hitArea.y = y;
		hitArea.buttonMode = true;
		hitArea.useHandCursor = true;
		hitArea.graphics.beginFill(0xFFFFFF, 0);
		hitArea.graphics.drawRect(0, 0, width, height);
		hitArea.graphics.endFill();
		hitArea.addEventListener(MouseEvent.CLICK, function(_):Void {
			clickHandler();
		});
		return hitArea;
	}

	private static function makeText(x:Float, y:Float, width:Float, height:Float, size:Int, color:Int, align:TextFormatAlign):TextField {
		var text = new TextField();
		text.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, size, color, false, false, false, null, null, align);
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.mouseEnabled = false;
		return text;
	}
}
