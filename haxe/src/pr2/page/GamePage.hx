package pr2.page;

import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import pr2.audio.AudioManager;
import pr2.Constants;
import pr2.gameplay.Course;
import pr2.gameplay.FinishedPage;
import pr2.gameplay.LevelConfig;
import pr2.gameplay.LevelEntry;
import pr2.gameplay.QuitButton;
import pr2.lobby.LobbySession;
import pr2.net.LobbySocket;
import pr2.net.LevelDataClient;
import pr2.net.ServerConfig;
import pr2.net.ServerLevelData;
import pr2.runtime.FontResolver;
import pr2.level.ServerLevelDecoder;

/**
	Real in-session level page entered only after the server sends `startGame`.

	Fetches the selected level over HTTP, decodes it, and mounts the production
	`pr2.gameplay.Course` shell (the same shell the campaign debug harness uses).
	The fuller loading/access/error state machine lands with the level-entry task
	(A4); this is the baseline load + mount + quit/finish lifecycle.
**/
class GamePage extends Page {
	public final levelId:Int;
	public final version:Int;
	private var entry:LevelEntry;
	private var course:Null<Course>;
	private var loadingText:Null<TextField>;
	private var quitButton:Null<QuitButton>;
	private var finishedPage:Null<FinishedPage>;
	private var playerDone:Bool = false;

	public function new(levelId:Int, version:Int) {
		super();
		this.levelId = levelId;
		this.version = version;
		// We are constructed only after `LevelLaunch` accepted the server
		// `startGame`, so the entry machine is already past selection and waiting
		// on the level payload.
		this.entry = new LevelEntry();
		this.entry.select(levelId, version);
		this.entry.startGame(levelId);
	}

	override public function initialize():Void {
		AudioManager.leaveMenu();
		createLoadingText('Loading level $levelId...');

		quitButton = new QuitButton(quitGame, function():Bool return playerDone);
		quitButton.x = Constants.STAGE_WIDTH / 2;
		quitButton.y = Constants.STAGE_HEIGHT / 2;
		addChild(quitButton);

		#if html5
		if (!ServerConfig.hasProxyHost()) {
			showError('Level fetch requires a same-origin API proxy on HTML5.');
			return;
		}
		#end
		LevelDataClient.fetch(levelId, version, onLevelData, onLevelError);
	}

	private function onLevelData(data:ServerLevelData):Void {
		// Resolve the load through the entry machine so the player sees the same
		// "did not download correctly" / "did not load" wording as Flash.
		var dataEmpty = data.data == null || data.data == "";
		switch (entry.onLoadOutcome(data.hashValid, dataEmpty)) {
			case Failed(message):
				showError(message);
				return;
			default:
		}
		try {
			var level = ServerLevelDecoder.decode(data.data);
			var config = LevelConfig.fromServerData(data);
			course = new Course(level, data, config);
			// Below the quit button / finish overlay, above nothing else yet.
			addChildAt(course, 0);
			clearLoadingText();
		} catch (error:Dynamic) {
			showError('Level $levelId could not be decoded:\n${Std.string(error)}');
		}
	}

	private function onLevelError(message:String):Void {
		showError('Could not load level $levelId:\n$message');
	}

	override public function remove():Void {
		if (finishedPage != null) {
			finishedPage.remove();
			finishedPage = null;
		}
		if (quitButton != null) {
			quitButton.remove();
			quitButton = null;
		}
		if (course != null) {
			course.remove();
			course = null;
		}
		clearLoadingText();
		super.remove();
	}

	private function quitGame():Void {
		if (!playerDone) {
			LobbySocket.write("quit_race`");
			playerDone = true;
		}
		if (finishedPage == null) {
			if (quitButton != null) {
				quitButton.stopGlow();
			}
			finishedPage = new FinishedPage(levelId, returnToLobby);
		}
	}

	private function returnToLobby():Void {
		LobbySocket.write("set_game_room`none");
		if (pageHolder != null) {
			pageHolder.changePage(new LobbyPage(LobbySession.userName, LobbySession.server));
		}
	}

	private function createLoadingText(message:String):Void {
		loadingText = new TextField();
		loadingText.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 14, 0xFFFFFF);
		loadingText.selectable = false;
		loadingText.mouseEnabled = false;
		loadingText.multiline = true;
		loadingText.wordWrap = true;
		loadingText.autoSize = TextFieldAutoSize.NONE;
		loadingText.x = 16;
		loadingText.y = 16;
		loadingText.width = Constants.STAGE_WIDTH - 32;
		loadingText.height = 80;
		loadingText.text = message;
		addChild(loadingText);
	}

	private function showError(message:String):Void {
		if (loadingText == null) {
			createLoadingText(message);
		} else {
			loadingText.text = message;
		}
	}

	private function clearLoadingText():Void {
		if (loadingText != null) {
			if (loadingText.parent != null) {
				loadingText.parent.removeChild(loadingText);
			}
			loadingText = null;
		}
	}
}
