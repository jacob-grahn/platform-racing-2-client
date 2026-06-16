package pr2.page;

#if js
import js.Browser;
#end
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.Constants;
import pr2.runtime.FontResolver;
import pr2.net.ServerInfo;

/**
	Placeholder lobby shown after a successful login.

	The Flash client handed off to a full multiplayer lobby once the socket
	reported `loginSuccessful`. That lobby is not ported yet, so this page just
	confirms the authenticated state (user name + server) and offers a way back
	to the login screen. It exists so the login flow has a real destination
	instead of dead-ending on the "waiting for loginSuccessful" message.
**/
class LobbyStubPage extends Page {
	private var userName:String;
	private var server:Null<ServerInfo>;
	private var logOutButton:Null<LobbyButton>;

	public function new(userName:String, ?server:ServerInfo) {
		super();
		this.userName = userName;
		this.server = server;
	}

	override public function initialize():Void {
		var background = new Shape();
		background.graphics.beginFill(Constants.BACKGROUND_COLOR);
		background.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		background.graphics.endFill();
		addChild(background);

		addText(0, 120, Constants.STAGE_WIDTH, 18, "Lobby", 22, 0xFFFFFF);
		addText(0, 168, Constants.STAGE_WIDTH, 16, 'Logged in as $userName', 14, 0xC7D2E0);
		if (server != null) {
			addText(0, 192, Constants.STAGE_WIDTH, 16, 'Server: ${server.label()}', 12, 0x8B97A8);
		}
		addText(0, 232, Constants.STAGE_WIDTH, 16, "(The multiplayer lobby is not ported yet.)", 11, 0x6C7888);

		logOutButton = new LobbyButton("Log Out", onLogOut);
		logOutButton.x = Constants.STAGE_WIDTH / 2;
		logOutButton.y = 290;
		addChild(logOutButton);

		reportState('lobby:$userName');
	}

	override public function remove():Void {
		if (logOutButton != null) {
			logOutButton.remove();
			if (logOutButton.parent != null) {
				logOutButton.parent.removeChild(logOutButton);
			}
			logOutButton = null;
		}
		super.remove();
	}

	private function onLogOut():Void {
		if (pageHolder != null) {
			pageHolder.changePage(new LoginPage());
		}
	}

	private function addText(x:Float, y:Float, width:Float, height:Float, value:String, size:Int, color:Int):Void {
		var text = new TextField();
		text.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, size, color, true, false, false, null, null, TextFormatAlign.CENTER);
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.mouseEnabled = false;
		text.text = value;
		addChild(text);
	}

	private function reportState(state:String):Void {
		#if js
		Browser.document.body.setAttribute("data-pr2-page", state);
		#end
	}
}

private class LobbyButton extends Sprite {
	private static inline var WIDTH:Float = 120;
	private static inline var HEIGHT:Float = 28;

	private var clickHandler:Void->Void;

	public function new(label:String, clickHandler:Void->Void) {
		super();
		this.clickHandler = clickHandler;

		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;

		graphics.beginFill(0x3C4761);
		graphics.drawRoundRect(-WIDTH / 2, 0, WIDTH, HEIGHT, 8, 8);
		graphics.endFill();

		var text = new TextField();
		text.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 13, 0xFFFFFF, true, false, false, null, null, TextFormatAlign.CENTER);
		text.x = -WIDTH / 2;
		text.y = 5;
		text.width = WIDTH;
		text.height = HEIGHT;
		text.selectable = false;
		text.mouseEnabled = false;
		text.text = label;
		addChild(text);

		addEventListener(MouseEvent.CLICK, onClick);
	}

	public function remove():Void {
		removeEventListener(MouseEvent.CLICK, onClick);
	}

	private function onClick(_:MouseEvent):Void {
		clickHandler();
	}
}
