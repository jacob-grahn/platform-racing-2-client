package pr2.page;

#if js
import js.Browser;
#end
import haxe.crypto.Md5;
import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.display.PixelSnapping;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.filters.GlowFilter;
import openfl.geom.ColorTransform;
import openfl.media.SoundMixer;
import openfl.media.SoundTransform;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.text.TextFieldType;
import openfl.utils.Assets;
import pr2.Constants;
import pr2.runtime.FontResolver;
import pr2.net.AccountCreationClient;
import pr2.net.LoginAuthClient;
import pr2.net.ServerInfo;
import pr2.net.ServerStatusClient;
import pr2.runtime.PR2MovieClip;

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
		if (pageHolder != null) {
			pageHolder.changePage(new LobbyStubPage(userName, server));
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

private class LoginBackground extends Sprite {
	private var layers:Array<LoginBackgroundLayer>;

	public function new() {
		super();
		layers = [
			new LoginBackgroundLayer("assets/login/bg_sky@4x.png", -245, -162, 4, 0, 0, 1.0, 1.00010681152344, 1, 0, 0),
			new LoginBackgroundLayer("assets/login/bg_far@4x.png", 46, 0, 4, -15.65, 240.25, 1.0, 1.0, 1508, 1276.0, -1276.0),
			new LoginBackgroundLayer("assets/login/bg_mid@4x.png", 119, -615, 4, -36.75, 263.4, 1.00004577636719, 1.0006103515625, 383, 1237.0, -1235.7),
			// bg_front is rasterized at 2x (5078px wide) rather than 4x (10158px).
			// At 4x it exceeds the WebGL MAX_TEXTURE_SIZE (8192 on many GPUs), so the
			// texture upload fails and the layer paints as an opaque black quad over
			// the sky. As a fast-scrolling foreground silhouette it does not need 4x
			// detail. See vector-art/raster-manifest-login.json for the trim values.
			new LoginBackgroundLayer("assets/login/bg_front@2x.png", -10, 1, 2, -7.2, 279.9, 1.0, 1.0, 134, -0.65, -1250.25),
		];

		for (layer in layers) {
			addChild(layer);
		}

		var stageMask = new Shape();
		stageMask.graphics.beginFill(0xFFFFFF);
		stageMask.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		stageMask.graphics.endFill();
		addChild(stageMask);
		mask = stageMask;
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	private function onEnterFrame(_:Event):Void {
		for (layer in layers) {
			layer.advance();
		}
	}
}

private class LoginBackgroundLayer extends Sprite {
	private var bitmap:Bitmap;
	private var parentX:Float;
	private var parentY:Float;
	private var parentScaleX:Float;
	private var parentScaleY:Float;
	private var totalFrames:Int;
	private var startTx:Float;
	private var endTx:Float;
	private var frame:Int = 0;

	public function new(
		assetPath:String,
		trimX:Int,
		trimY:Int,
		scale:Int,
		parentX:Float,
		parentY:Float,
		parentScaleX:Float,
		parentScaleY:Float,
		totalFrames:Int,
		startTx:Float,
		endTx:Float
	) {
		super();
		this.parentX = parentX;
		this.parentY = parentY;
		this.parentScaleX = parentScaleX;
		this.parentScaleY = parentScaleY;
		this.totalFrames = totalFrames;
		this.startTx = startTx;
		this.endTx = endTx;

		bitmap = new Bitmap(Assets.getBitmapData(assetPath), PixelSnapping.AUTO, true);
		bitmap.x = trimX / scale;
		bitmap.y = trimY / scale;
		bitmap.scaleX = 1 / scale;
		bitmap.scaleY = 1 / scale;
		addChild(bitmap);
		updatePosition();
	}

	public function advance():Void {
		if (totalFrames <= 1) {
			return;
		}
		frame = (frame + 1) % totalFrames;
		updatePosition();
	}

	private function updatePosition():Void {
		var tx = startTx;
		if (totalFrames > 1) {
			tx = startTx + (endTx - startTx) * (frame / (totalFrames - 1));
		}
		x = parentX + tx;
		y = parentY;
		scaleX = parentScaleX;
		scaleY = parentScaleY;
	}
}

private class LoginPageMenuButton extends Sprite {
	private static inline var HIT_WIDTH:Float = 116;
	private static inline var HIT_HEIGHT:Float = 20;

	private var label:String;
	private var clickHandler:Void->Void;
	private var frontText:TextField;
	private var shadowText:TextField;

	public function new(label:String, clickHandler:Void->Void) {
		super();
		this.label = label;
		this.clickHandler = clickHandler;

		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;
		alpha = 0.75;
		drawHitArea();

		shadowText = buildTextField(0xFFFFFF);
		shadowText.x = -HIT_WIDTH / 2 + 1;
		shadowText.y = 1;
		addChild(shadowText);

		frontText = buildTextField(0x333333);
		frontText.x = -HIT_WIDTH / 2;
		addChild(frontText);
		setLabel(label);

		addEventListener(MouseEvent.MOUSE_OVER, onOver);
		addEventListener(MouseEvent.MOUSE_OUT, onOut);
		addEventListener(MouseEvent.CLICK, onClick);
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_OVER, onOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onOut);
		removeEventListener(MouseEvent.CLICK, onClick);
	}

	private function buildTextField(color:Int):TextField {
		var text = new TextField();
		text.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 12, color, false, false, false, null, null, CENTER);
		text.selectable = false;
		text.mouseEnabled = false;
		text.autoSize = TextFieldAutoSize.NONE;
		text.width = HIT_WIDTH;
		text.height = HIT_HEIGHT;
		return text;
	}

	private function setLabel(value:String):Void {
		frontText.text = value;
		shadowText.text = value;
	}

	private function drawHitArea():Void {
		graphics.beginFill(0xFFFFFF, 0);
		graphics.drawRect(-HIT_WIDTH / 2, 0, HIT_WIDTH, HIT_HEIGHT);
		graphics.endFill();
	}

	private function onOver(_:MouseEvent):Void {
		alpha = 1;
		setLabel("- " + label + " -");
	}

	private function onOut(_:MouseEvent):Void {
		alpha = 0.75;
		setLabel(label);
	}

	private function onClick(_:MouseEvent):Void {
		clickHandler();
	}
}

private class LoginFlashPopup extends Sprite {
	private var art:PR2MovieClip;
	private var messageText:TextField;
	private var buttonHandlers:Array<{target:DisplayObject, handler:MouseEvent->Void}> = [];

	public function new(linkage:String) {
		super();
		graphics.beginFill(0x000000, 0.55);
		graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		graphics.endFill();

		art = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 6});
		art.x = Constants.STAGE_WIDTH / 2;
		art.y = Constants.STAGE_HEIGHT / 2;
		addChild(art);

		messageText = new TextField();
		messageText.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 11, 0x7B2D26, false, false, false, null, null, TextFormatAlign.CENTER);
		messageText.x = 118;
		messageText.y = 346;
		messageText.width = 314;
		messageText.height = 42;
		messageText.wordWrap = true;
		messageText.multiline = true;
		messageText.selectable = false;
		messageText.mouseEnabled = false;
		addChild(messageText);
	}

	public function child(name:String):Null<DisplayObject> {
		return findByName(art, name);
	}

	public function input(name:String):TextField {
		var field = Std.downcast(child(name), TextField);
		if (field == null) {
			throw 'Popup ${art.symbol.linkageClassName} missing TextInput $name';
		}
		return field;
	}

	public function bindButton(name:String, clickHandler:Void->Void):Void {
		var target = child(name);
		if (target == null) {
			return;
		}
		var interactive = Std.downcast(target, InteractiveObject);
		if (interactive != null) {
			interactive.mouseEnabled = true;
		}
		var sprite = Std.downcast(target, Sprite);
		if (sprite != null) {
			sprite.buttonMode = true;
			sprite.useHandCursor = true;
			sprite.mouseChildren = false;
		}
		var handler = function(_:MouseEvent):Void {
			clickHandler();
		};
		target.addEventListener(MouseEvent.CLICK, handler);
		buttonHandlers.push({target: target, handler: handler});
	}

	public function setComponentLabel(name:String, value:String):Void {
		var target = Std.downcast(child(name), DisplayObjectContainer);
		if (target == null) {
			return;
		}
		var text = firstTextField(target);
		if (text != null) {
			text.text = value;
		}
	}

	public function setMessage(message:String):Void {
		messageText.text = message;
	}

	public function remove():Void {
		for (entry in buttonHandlers) {
			entry.target.removeEventListener(MouseEvent.CLICK, entry.handler);
		}
		buttonHandlers = [];
		art.dispose();
	}

	private function findByName(container:DisplayObjectContainer, name:String):Null<DisplayObject> {
		for (i in 0...container.numChildren) {
			var display = container.getChildAt(i);
			if (display.name == name) {
				return display;
			}
			var childContainer = Std.downcast(display, DisplayObjectContainer);
			if (childContainer != null) {
				var found = findByName(childContainer, name);
				if (found != null) {
					return found;
				}
			}
		}
		return null;
	}

	private function firstTextField(container:DisplayObjectContainer):Null<TextField> {
		for (i in 0...container.numChildren) {
			var display = container.getChildAt(i);
			var text = Std.downcast(display, TextField);
			if (text != null) {
				return text;
			}
			var childContainer = Std.downcast(display, DisplayObjectContainer);
			if (childContainer != null) {
				var found = firstTextField(childContainer);
				if (found != null) {
					return found;
				}
			}
		}
		return null;
	}
}

private enum LoginProbeStatus {
	Message(message:String);
	LoginId(loginId:String);
	LoginSuccessful(userName:String);
}

private class LoginSocketProbe {
	private static inline var END_CHAR:String = "\x04";
	private static inline var COMM_PASS:String = "QHE0NSNwKWZZQVEhU19xMA==";
	private static inline var COMM_PASS_SERVER_10:String = "ayo3JnBGQCZVRiEhVjFAQA==";

	private var server:ServerInfo;
	private var onStatus:LoginProbeStatus->Void;
	private var sendNum:Int = 0;
	private var buffer:String = "";
	#if js
	private var socket:Null<js.html.WebSocket>;
	#end

	public function new(server:ServerInfo, onStatus:LoginProbeStatus->Void) {
		this.server = server;
		this.onStatus = onStatus;
	}

	public function connect():Void {
		#if js
		var secure = Browser.location.protocol == "https:";
		var url = server.websocketUrl(secure);
		try {
			socket = new js.html.WebSocket(url);
			socket.onopen = function(_):Void {
				onStatus(Message('Connected to ${server.label()}; requesting login id...'));
				write("request_login_id`");
			};
			socket.onmessage = function(event):Void {
				buffer += Std.string(event.data);
				readBufferedMessages();
			};
			socket.onerror = function(_):Void {
				onStatus(Message('Could not connect to ${server.label()} over WebSocket.'));
			};
			socket.onclose = function(_):Void {
				if (buffer == "") {
					onStatus(Message('Connection to ${server.label()} closed.'));
				}
			};
		} catch (error:Dynamic) {
			onStatus(Message('Could not open WebSocket: ${Std.string(error)}'));
		}
		#else
		onStatus(Message("Server connection probing is available on the html5 target."));
		#end
	}

	public function close():Void {
		#if js
		if (socket != null) {
			socket.close();
			socket = null;
		}
		#end
	}

	private function write(command:String):Void {
		#if js
		if (socket == null || socket.readyState != js.html.WebSocket.OPEN) {
			return;
		}
		sendNum++;
		if (sendNum == 12) {
			sendNum++;
		}
		var payload = sendNum + "`" + command;
		var hash = Md5.encode(socketToken() + payload).substr(0, 3);
		socket.send(hash + "`" + payload + END_CHAR);
		#end
	}

	private function readBufferedMessages():Void {
		var endIndex = buffer.indexOf(END_CHAR);
		while (endIndex >= 0) {
			var message = buffer.substr(0, endIndex);
			buffer = buffer.substr(endIndex + 1);
			handleMessage(message);
			endIndex = buffer.indexOf(END_CHAR);
		}
	}

	private function handleMessage(message:String):Void {
		var parts = message.split("`");
		if (parts.length < 3) {
			return;
		}
		var command = parts[2];
		if (command == "setLoginID" && parts.length >= 4) {
			onStatus(LoginId(parts[3]));
		} else if (command == "loginSuccessful") {
			// Frame layout matches the e2e read in LiveLoginE2ETest: the args are
			// parts.slice(3), so parts[4] is the canonical user name.
			onStatus(LoginSuccessful(parts.length >= 5 ? parts[4] : ""));
		} else if (command == "loginFailure") {
			onStatus(Message('Server rejected login: ${parts.slice(3).join(" ")}'));
		} else {
			onStatus(Message('Received $command from ${server.label()}.'));
		}
	}

	private function socketToken():String {
		return server.serverId == 10 ? COMM_PASS_SERVER_10 : COMM_PASS;
	}
}

private class LoginMuteButton extends Sprite {
	private static inline var MUTE_BUTTON_ASSET = "assets/login/mute_button@4x.png";
	private static inline var MUTE_BUTTON_SCALE = 4;
	private static inline var MUTE_BUTTON_TRIM_X = -57;
	private static inline var MUTE_BUTTON_TRIM_Y = -73;
	private static var muted:Bool = false;

	private var bitmap:Bitmap;

	public function new() {
		super();
		bitmap = new Bitmap(Assets.getBitmapData(MUTE_BUTTON_ASSET), PixelSnapping.AUTO, true);
		bitmap.x = MUTE_BUTTON_TRIM_X / MUTE_BUTTON_SCALE;
		bitmap.y = MUTE_BUTTON_TRIM_Y / MUTE_BUTTON_SCALE;
		bitmap.scaleX = 1 / MUTE_BUTTON_SCALE;
		bitmap.scaleY = 1 / MUTE_BUTTON_SCALE;
		addChild(bitmap);

		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;

		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(MouseEvent.MOUSE_OVER, onOver);
		addEventListener(MouseEvent.MOUSE_OUT, onOut);
		applyMutedState();
	}

	public function remove():Void {
		removeEventListener(MouseEvent.CLICK, onClick);
		removeEventListener(MouseEvent.MOUSE_OVER, onOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onOut);
	}

	private function onClick(_:MouseEvent):Void {
		muted = !muted;
		applyMutedState();
	}

	private function onOver(_:MouseEvent):Void {
		transform.colorTransform = new ColorTransform(0.5, 0.5, 0.5, 1, 127, 127, 127, 0);
	}

	private function onOut(_:MouseEvent):Void {
		transform.colorTransform = new ColorTransform();
	}

	private function applyMutedState():Void {
		alpha = muted ? 0.7 : 1;
		SoundMixer.soundTransform = new SoundTransform(muted ? 0 : 1);
	}
}
