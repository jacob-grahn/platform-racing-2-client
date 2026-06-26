package pr2.page;

import pr2.audio.AudioManager;
import pr2.Constants;
import pr2.gameplay.FinishedPage;
import pr2.gameplay.QuitButton;
import pr2.lobby.LobbySession;
import pr2.net.LobbySocket;

/** Real in-session level page entered only after the server sends `startGame`. */
class GamePage extends Page {
	public final levelId:Int;
	public final version:Int;
	private var level:Null<CampaignTestScreen>;
	private var quitButton:Null<QuitButton>;
	private var finishedPage:Null<FinishedPage>;
	private var playerDone:Bool = false;

	public function new(levelId:Int, version:Int) {
		super();
		this.levelId = levelId;
		this.version = version;
	}

	override public function initialize():Void {
		AudioManager.leaveMenu();
		level = new CampaignTestScreen(null, Std.string(levelId), version);
		addChild(level);
		quitButton = new QuitButton(quitGame, function():Bool return playerDone);
		quitButton.x = Constants.STAGE_WIDTH / 2;
		quitButton.y = Constants.STAGE_HEIGHT / 2;
		addChild(quitButton);
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
		if (level != null) {
			level.remove();
			level = null;
		}
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
}
