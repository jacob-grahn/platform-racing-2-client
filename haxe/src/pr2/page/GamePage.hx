package pr2.page;

import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import pr2.audio.AudioManager;
import pr2.Constants;
import pr2.gameplay.Course;
import pr2.gameplay.CowboyMode;
import pr2.gameplay.FinishedPage;
import pr2.gameplay.GameCommandShell;
import pr2.gameplay.GameCommandShell.GameCommandDelegate;
import pr2.gameplay.GameCommandShell.LocalCharacterInit;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.gameplay.HappyHour;
import pr2.gameplay.LevelConfig;
import pr2.gameplay.LevelEntry;
import pr2.gameplay.PrizePopup;
import pr2.gameplay.QuitButton;
import pr2.gameplay.SpecialEvent;
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
@:allow(pr2.gameplay.QuitButtonTest)
class GamePage extends Page implements GameCommandDelegate {
	public final levelId:Int;
	public final version:Int;
	private var entry:LevelEntry;
	private var course:Null<Course>;
	private var commandShell:Null<GameCommandShell>;
	private var loadingText:Null<TextField>;
	private var quitButton:Null<QuitButton>;
	private var finishedPage:Null<FinishedPage>;
	private var playerDone:Bool = false;
	private var pendingLocalInit:Null<LocalCharacterInit>;
	private var pendingRemoteInits:Array<RemoteCharacterInit> = [];
	private var pendingBeginRace:Bool = false;
	private var pendingEggSeed:Null<Int>;
	private var pendingEggAdds:Array<Int> = [];
	private var specialEvent:Null<SpecialEvent>;
	private var hatCountdownTimer:Null<haxe.Timer>;
	private var cowboyModes:Array<CowboyMode> = [];
	private var happyHours:Array<HappyHour> = [];
	public var prize(default, null):Dynamic;

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

		commandShell = new GameCommandShell(this);
		commandShell.install();
		specialEvent = new SpecialEvent();
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		if (stage != null) {
			attachSpecialEventListeners();
		}

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
			course.onFinish = onLocalFinish;
			if (pendingLocalInit != null) {
				course.createLocalCharacter(pendingLocalInit);
				pendingLocalInit = null;
			}
			for (init in pendingRemoteInits) {
				course.createRemoteCharacter(init);
			}
			pendingRemoteInits.resize(0);
			if (pendingBeginRace) {
				pendingBeginRace = false;
				course.beginRace();
			}
			if (pendingEggSeed != null) {
				course.setEggSeed(pendingEggSeed);
				pendingEggSeed = null;
			}
			for (count in pendingEggAdds) {
				course.addEggs(count);
			}
			pendingEggAdds.resize(0);
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
		pr2.app.DebugSignal.clear("race-phase");
		pr2.app.DebugSignal.clear("remote-count");
		if (commandShell != null) {
			commandShell.remove();
			commandShell = null;
		}
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		detachSpecialEventListeners();
		specialEvent = null;
		stopHatCountdown();
		for (mode in cowboyModes.copy()) {
			mode.remove();
		}
		cowboyModes.resize(0);
		for (happy in happyHours.copy()) {
			happy.remove();
		}
		happyHours.resize(0);
		if (finishedPage != null) {
			finishedPage.remove();
			finishedPage = null;
		}
		prize = null;
		if (PrizePopup.instance != null) {
			PrizePopup.instance.startFadeOut();
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

	private function onAddedToStage(_:Event):Void {
		attachSpecialEventListeners();
	}

	private function onRemovedFromStage(_:Event):Void {
		detachSpecialEventListeners();
	}

	private function attachSpecialEventListeners():Void {
		if (stage == null) {
			return;
		}
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onSpecialEventKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onSpecialEventKeyUp);
		stage.addEventListener(MouseEvent.CLICK, onSpecialEventClick);
	}

	private function detachSpecialEventListeners():Void {
		if (stage == null) {
			return;
		}
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, onSpecialEventKeyDown);
		stage.removeEventListener(KeyboardEvent.KEY_UP, onSpecialEventKeyUp);
		stage.removeEventListener(MouseEvent.CLICK, onSpecialEventClick);
	}

	private function onSpecialEventKeyDown(event:KeyboardEvent):Void {
		if (specialEvent != null) {
			specialEvent.keyDown(event.keyCode);
		}
	}

	private function onSpecialEventKeyUp(event:KeyboardEvent):Void {
		if (specialEvent != null) {
			specialEvent.keyUp(event.keyCode);
		}
	}

	private function onSpecialEventClick(event:MouseEvent):Void {
		if (specialEvent != null) {
			specialEvent.click(event.stageX, event.stageY, course, prize);
		}
	}

	public function createRemoteCharacter(init:RemoteCharacterInit):Void {
		if (course == null) {
			pendingRemoteInits.push(init);
			return;
		}
		course.createRemoteCharacter(init);
	}

	public function createLocalCharacter(init:LocalCharacterInit):Void {
		if (course == null) {
			pendingLocalInit = init;
			return;
		}
		course.createLocalCharacter(init);
	}

	public function beginRace():Void {
		if (course == null) {
			pendingBeginRace = true;
			return;
		}
		course.beginRace();
	}

	public function award(args:Array<String>):Void {}
	public function setExpGain(expOld:Int, expNew:Int, expToRank:Int):Void {}
	public function setLuxGain(amount:Int):Void {}
	public function setPrize(prize:Dynamic):Void {
		this.prize = prize;
		showPrizePopup(prize, false);
	}

	public function cancelPrize(message:String):Void {
		prize = null;
		new PrizePopup("cancel", 0, "Prize Cancelled", message);
	}

	public function winPrize(prize:Dynamic):Void {
		this.prize = prize;
		showPrizePopup(prize, true);
	}

	public function cowboyMode():Void {
		var mode = new CowboyMode();
		cowboyModes.push(mode);
		addChild(mode);
	}
	public function happyHour():Void {
		var happy = new HappyHour(onHappyHourRemoved);
		happyHours.push(happy);
		addChild(happy);
	}

	private function onHappyHourRemoved(happy:HappyHour):Void {
		happyHours.remove(happy);
	}

	public function setEggSeed(seed:Int):Void {
		if (course == null) {
			pendingEggSeed = seed;
			return;
		}
		course.setEggSeed(seed);
	}
	public function addEggs(count:Int):Void {
		if (course == null) {
			pendingEggAdds.push(count);
			return;
		}
		course.addEggs(count);
	}
	public function superBooster(tempId:Int):Void {}
	public function maybeReturnHatToStart(hatId:Int):Void {}
	public function startHatCountdown():Void {
		stopHatCountdown();
		hatCountdownTimer = new haxe.Timer(1000);
		hatCountdownTimer.run = onHatCountdownTick;
	}

	public function cancelHatCountdown():Void {
		stopHatCountdown();
	}

	public function forceQuit():Void {
		quitGame();
	}

	private function onHatCountdownTick():Void {
		LobbySocket.write("check_hat_countdown`");
	}

	private function stopHatCountdown():Void {
		if (hatCountdownTimer != null) {
			hatCountdownTimer.stop();
			hatCountdownTimer = null;
		}
	}

	private function showPrizePopup(prize:Dynamic, finished:Bool):Void {
		if (prize == null) {
			return;
		}
		new PrizePopup(
			stringField(prize, "type"),
			intField(prize, "id"),
			stringField(prize, "name"),
			stringField(prize, "desc"),
			boolField(prize, "universal"),
			finished
		);
	}

	private static function stringField(value:Dynamic, field:String):String {
		var raw = Reflect.field(value, field);
		return raw == null ? "" : Std.string(raw);
	}

	private static function intField(value:Dynamic, field:String):Int {
		var raw = Reflect.field(value, field);
		if (raw == null) {
			return 0;
		}
		var parsed = Std.parseInt(Std.string(raw));
		return parsed == null ? 0 : parsed;
	}

	private static function boolField(value:Dynamic, field:String):Bool {
		var raw = Reflect.field(value, field);
		if (raw == true) {
			return true;
		}
		var text = raw == null ? "" : Std.string(raw).toLowerCase();
		return text == "1" || text == "true";
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
		// The course keeps ticking under the finished overlay; tell it the race is
		// over so its per-frame phase report does not clobber "finished".
		if (course != null) {
			course.raceEnded = true;
		}
		pr2.app.DebugSignal.set("race-phase", "finished");
	}

	// Course invokes this once the local player bumps a finish block (race-style
	// modes). It emits finish_race itself; here we mark the player done, glow the
	// quit button, and show the finished page (Flash Game.finish + the server's
	// maybeShowFinishedPage, which the award/exp command stubs don't yet drive).
	private function onLocalFinish(_:pr2.harness.LocalPlayerDebugState):Void {
		if (playerDone) {
			return;
		}
		playerDone = true;
		if (quitButton != null) {
			quitButton.startGlow();
		}
		if (finishedPage == null) {
			finishedPage = new FinishedPage(levelId, returnToLobby);
		}
		pr2.app.DebugSignal.set("race-phase", "finished");
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
