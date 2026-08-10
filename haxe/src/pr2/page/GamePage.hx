package pr2.page;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import pr2.audio.AudioManager;
import pr2.Constants;
import pr2.gameplay.CatCaptcha;
import pr2.gameplay.Course;
import pr2.gameplay.CowboyMode;
import pr2.gameplay.FinishedPage;
import pr2.gameplay.FinishedPageAssets;
import pr2.gameplay.GameCommandShell;
import pr2.gameplay.GameCommandShell.GameCommandDelegate;
import pr2.gameplay.GameCommandShell.LocalCharacterInit;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.gameplay.HappyHour;
import pr2.gameplay.ItemDisplay;
import pr2.gameplay.LevelConfig;
import pr2.gameplay.LevelEntry;
import pr2.gameplay.LuxPopup;
import pr2.gameplay.PlaceArtifact;
import pr2.gameplay.PrizePopup;
import pr2.gameplay.QuitButton;
import pr2.gameplay.SpecialEvent;
import pr2.gameplay.player.LocalPlayerState;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.MessagePopup;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.LevelDataClient;
import pr2.net.ServerLevelData;
import pr2.runtime.FontResolver;
import pr2.runtime.FrameClock;
import pr2.level.LevelDecoder;

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
	private var finishedPageAssets:Null<FinishedPageAssets>;
	private var warmupHost:Null<Sprite>;
	private var warmupCover:Null<Shape>;
	private var warmupStep:Int = -1;
	private var warmupWaitForFirstRender:Bool = false;
	private var warmupItemIndex:Int = -1;
	private var warmupCharacterViewIndex:Int = -1;
	private var warmupCharacterViewX:Float = 0;
	private var warmupCharacterViewY:Float = 0;
	private var playerDone:Bool = false;
	private var pendingLocalInit:Null<LocalCharacterInit>;
	private var pendingRemoteInits:Array<RemoteCharacterInit> = [];
	private var pendingHatUpdates:Map<Int, Array<String>> = [];
	private var pendingHatCommandIds:Map<Int, Bool> = [];
	private var pendingBeginRace:Bool = false;
	private var pendingEggSeed:Null<Int>;
	private var pendingEggAdds:Array<Int> = [];
	private var pendingLife:Null<Int>;
	private var pendingAwards:Array<Array<String>> = [];
	private var raceStartReceived:Bool = false;
	private var raceStartPhysicsFrame:Null<Int>;
	private var finishedPhysicsFrames:Null<Int>;
	private var expOld:Int = 0;
	private var expNew:Int = 0;
	private var expToRank:Int = 0;
	private var specialEvent:Null<SpecialEvent>;
	private var hatCountdownTimer:Null<haxe.Timer>;
	private var cowboyModes:Array<CowboyMode> = [];
	private var happyHours:Array<HappyHour> = [];
	private var luxPop:Null<LuxPopup>;
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
			var level = LevelDecoder.decode(data.data);
			var config = LevelConfig.fromServerData(data);
			course = new Course(level, data, config, null, onCourseFrame);
			course.onFinish = onLocalFinish;
			course.onOutOfTime = onCourseOutOfTime;
			if (pendingLocalInit != null) {
				var localInit = pendingLocalInit;
				course.createLocalCharacter(localInit);
				pendingLocalInit = null;
				replayPendingHatUpdate(localInit.tempId);
			}
			for (init in pendingRemoteInits) {
				course.createRemoteCharacter(init);
				replayPendingHatUpdate(init.tempId);
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
			if (pendingLife != null) {
				course.setLife(pendingLife);
				pendingLife = null;
			}
			prepareGameplayAssets();
		} catch (error:Dynamic) {
			showError('Level $levelId could not be decoded:\n${Std.string(error)}');
		}
	}

	private function onLevelError(message:String):Void {
		showError('Could not load level $levelId:\n$message');
	}

	/**
		Render cold gameplay UI behind the loading screen, one asset group per
		frame. Reusing these exact instances avoids paying their first-render cost
		when an item is awarded or the race ends.
	**/
	private function prepareGameplayAssets():Void {
		if (course == null) return;
		finishedPageAssets = new FinishedPageAssets(levelId);

		// Headless deterministic tests do not have a renderer to warm. Keep their
		// synchronous mount behavior and let FinishedPage finish lazy preparation.
		if (stage == null) {
			mountCourse();
			return;
		}

		var item = course.itemDisplay;
		warmupItemIndex = item.parent == course ? course.getChildIndex(item) : -1;
		if (item.parent != null) item.parent.removeChild(item);

		warmupHost = new Sprite();
		warmupHost.x = Constants.STAGE_WIDTH / 2;
		warmupHost.y = Constants.STAGE_HEIGHT / 2;
		addChildAt(warmupHost, 0);

		// OpenFL still renders the display objects below this opaque cover, while
		// the player continues to see the ordinary loading state.
		warmupCover = new Shape();
		warmupCover.graphics.beginFill(0x000000);
		warmupCover.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		warmupCover.graphics.endFill();
		addChildAt(warmupCover, 1);

		item.x = -Constants.STAGE_WIDTH / 2 + 5;
		item.y = -Constants.STAGE_HEIGHT / 2 + 5;
		item.setItemCode(1);
		warmupHost.addChild(item);
		var characterView = course.localCharacter.display;
		warmupCharacterViewIndex = characterView.parent == course.localCharacter
			? course.localCharacter.getChildIndex(characterView)
			: -1;
		warmupCharacterViewX = characterView.x;
		warmupCharacterViewY = characterView.y;
		if (characterView.parent != null) characterView.parent.removeChild(characterView);
		warmupStep = 0;
		warmupWaitForFirstRender = true;
		addEventListener(Event.ENTER_FRAME, advanceGameplayWarmup);
	}

	private function advanceGameplayWarmup(_:Event):Void {
		if (course == null || finishedPageAssets == null || warmupHost == null) {
			cancelGameplayWarmup(false);
			return;
		}
		if (warmupWaitForFirstRender) {
			warmupWaitForFirstRender = false;
			return;
		}
		try {
			warmupStep++;
			if (warmupStep < 10) {
				course.itemDisplay.setItemCode(warmupStep + 1);
				return;
			}

			clearWarmupHost();
			switch (warmupStep) {
				case 10:
					restoreWarmupItemDisplay();
					presentCharacterItem(1);
				case 11, 12, 13, 14, 15, 16, 17, 18, 19:
					presentCharacterItem(warmupStep - 9);
				case 20:
					restoreWarmupCharacterView();
					presentWarmupAsset(finishedPageAssets.prepareShell(), 0, 0);
				case 21:
					presentWarmupAsset(finishedPageAssets.prepareRating(), 6, 87);
				case 22:
					presentWarmupAsset(finishedPageAssets.prepareExpGain(), 0, 47);
				default:
					finishGameplayWarmup();
			}
		} catch (_:Dynamic) {
			// Warmup is an optimization. If a renderer/backend cannot perform it,
			// preserve the normal lazy construction path and start the race.
			cancelGameplayWarmup(true);
			mountCourse();
		}
	}

	private function presentWarmupAsset(asset:DisplayObject, x:Float, y:Float):Void {
		if (warmupHost == null) return;
		asset.x = x;
		asset.y = y;
		warmupHost.addChild(asset);
	}

	private function clearWarmupHost():Void {
		if (warmupHost == null) return;
		while (warmupHost.numChildren > 0) warmupHost.removeChildAt(0);
	}

	private function presentCharacterItem(itemCode:Int):Void {
		if (course == null || warmupHost == null) return;
		var characterView = course.localCharacter.display;
		characterView.setItemFrameName(ItemDisplay.itemNameFromCode(itemCode));
		characterView.x = 0;
		characterView.y = 0;
		warmupHost.addChild(characterView);
	}

	private function restoreWarmupCharacterView():Void {
		if (course == null || course.localCharacter == null || warmupCharacterViewIndex < 0) return;
		var characterView = course.localCharacter.display;
		if (characterView.parent != null) characterView.parent.removeChild(characterView);
		characterView.setItemFrameName("None");
		characterView.x = warmupCharacterViewX;
		characterView.y = warmupCharacterViewY;
		var index = Std.int(Math.min(warmupCharacterViewIndex, course.localCharacter.numChildren));
		course.localCharacter.addChildAt(characterView, index);
		warmupCharacterViewIndex = -1;
	}

	private function restoreWarmupItemDisplay():Void {
		if (course == null || course.itemDisplay == null || warmupItemIndex < 0) return;
		var item = course.itemDisplay;
		if (item.parent != null) item.parent.removeChild(item);
		item.setItemCode(0);
		item.x = Course.ITEM_X;
		item.y = Course.ITEM_Y;
		var index = Std.int(Math.min(warmupItemIndex, course.numChildren));
		course.addChildAt(item, index);
		warmupItemIndex = -1;
	}

	private function finishGameplayWarmup():Void {
		removeEventListener(Event.ENTER_FRAME, advanceGameplayWarmup);
		clearWarmupHost();
		if (warmupHost != null && warmupHost.parent != null) warmupHost.parent.removeChild(warmupHost);
		warmupHost = null;
		if (warmupCover != null && warmupCover.parent != null) warmupCover.parent.removeChild(warmupCover);
		warmupCover = null;
		warmupStep = -1;
		mountCourse();
	}

	private function cancelGameplayWarmup(disposeFinishedAssets:Bool):Void {
		removeEventListener(Event.ENTER_FRAME, advanceGameplayWarmup);
		restoreWarmupItemDisplay();
		restoreWarmupCharacterView();
		clearWarmupHost();
		if (warmupHost != null && warmupHost.parent != null) warmupHost.parent.removeChild(warmupHost);
		warmupHost = null;
		if (warmupCover != null && warmupCover.parent != null) warmupCover.parent.removeChild(warmupCover);
		warmupCover = null;
		warmupStep = -1;
		warmupWaitForFirstRender = false;
		if (disposeFinishedAssets && finishedPageAssets != null) {
			finishedPageAssets.dispose();
			finishedPageAssets = null;
		}
	}

	private function mountCourse():Void {
		if (course != null && course.parent != this) {
			// Below the quit button / finish overlay.
			addChildAt(course, 0);
		}
		clearLoadingText();
	}

	private function onCourseFrame(state:LocalPlayerState):Void {
		pr2.app.DebugSignal.set("debug-state", 'phase=playable;${state.serialize()}');
	}

	override public function remove():Void {
		pr2.app.DebugSignal.clear("race-phase");
		pr2.app.DebugSignal.clear("remote-count");
		pr2.app.DebugSignal.clear("debug-state");
		if (commandShell != null) {
			commandShell.remove();
			commandShell = null;
		}
		clearPendingHatCommands();
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		detachSpecialEventListeners();
		specialEvent = null;
		stopHatCountdown();
		cancelGameplayWarmup(true);
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
		if (PlaceArtifact.instance != null) {
			PlaceArtifact.instance.startFadeOut();
		}
		if (luxPop != null) {
			luxPop.remove();
			luxPop = null;
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
			bufferHatCommand(init.tempId);
			pendingRemoteInits.push(init);
			return;
		}
		course.createRemoteCharacter(init);
	}

	public function createLocalCharacter(init:LocalCharacterInit):Void {
		if (course == null) {
			if (pendingLocalInit != null && pendingLocalInit.tempId != init.tempId) {
				discardPendingHatCommand(pendingLocalInit.tempId);
			}
			bufferHatCommand(init.tempId);
			pendingLocalInit = init;
			return;
		}
		course.createLocalCharacter(init);
	}

	private function bufferHatCommand(tempId:Int):Void {
		if (pendingHatCommandIds.exists(tempId)) {
			return;
		}
		pendingHatCommandIds.set(tempId, true);
		CommandHandler.commandHandler.defineCommand("setHats" + tempId, function(args:Array<String>):Void {
			pendingHatUpdates.set(tempId, args.copy());
		});
	}

	private function replayPendingHatUpdate(tempId:Int):Void {
		pendingHatCommandIds.remove(tempId);
		var args = pendingHatUpdates.get(tempId);
		pendingHatUpdates.remove(tempId);
		if (args != null) {
			CommandHandler.commandHandler.dispatch("setHats" + tempId, args);
		}
	}

	private function discardPendingHatCommand(tempId:Int):Void {
		if (pendingHatCommandIds.remove(tempId)) {
			CommandHandler.commandHandler.defineCommand("setHats" + tempId, null);
		}
		pendingHatUpdates.remove(tempId);
	}

	private function clearPendingHatCommands():Void {
		for (tempId in pendingHatCommandIds.keys()) {
			CommandHandler.commandHandler.defineCommand("setHats" + tempId, null);
		}
		pendingHatCommandIds = [];
		pendingHatUpdates = [];
	}

	public function beginRace():Void {
		closePrizePopup();
		if (!raceStartReceived) {
			raceStartReceived = true;
			var clock = FrameClock.current;
			if (clock != null) {
				raceStartPhysicsFrame = clock.simulationFrameNumber;
			}
		}
		if (course == null) {
			pendingBeginRace = true;
			return;
		}
		course.beginRace();
	}

	public function award(args:Array<String>):Void {
		pendingAwards.push(args);
		if (finishedPage != null) {
			applyAwardToFinishedPage(args);
		}
	}

	public function setExpGain(expOld:Int, expNew:Int, expToRank:Int):Void {
		this.expOld = expOld;
		this.expNew = expNew;
		this.expToRank = expToRank;
		var finishedPageAlreadyOpen = finishedPage != null;
		markPlayerDone();
		maybeShowFinishedPage();
		if (finishedPageAlreadyOpen && finishedPage != null) {
			finishedPage.setExpGain(this.expOld, this.expNew, this.expToRank);
		}
	}
	public function setLuxGain(amount:Int):Void {
		luxPop = new LuxPopup(amount);
	}
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
		mode.x = Constants.STAGE_WIDTH / 2;
		mode.y = Constants.STAGE_HEIGHT / 2;
		cowboyModes.push(mode);
		addChild(mode);
	}
	public function happyHour():Void {
		var happy = new HappyHour(onHappyHourRemoved);
		happy.x = Constants.STAGE_WIDTH / 2;
		happy.y = Constants.STAGE_HEIGHT / 2;
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
	public function setLife(lives:Int):Void {
		if (course == null) {
			pendingLife = lives;
			return;
		}
		course.setLife(lives);
	}
	public function superBooster(tempId:Int):Void {}
	public function maybeReturnHatToStart(hatId:Int):Void {
		if (course != null) {
			course.maybeReturnHatToStart(hatId);
		}
	}
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

	public function areYouHuman():Void {
		new CatCaptcha();
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

	private function closePrizePopup():Void {
		if (PrizePopup.instance != null) {
			PrizePopup.instance.startFadeOut();
		}
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
		var raw:Dynamic = Reflect.field(value, field);
		if (raw == true) {
			return true;
		}
		var text = raw == null ? "" : Std.string(raw).toLowerCase();
		return text == "1" || text == "true";
	}

	private function quitGame():Void {
		if (!playerDone) {
			LobbySocket.write("quit_race`");
		}
		captureFinishedPhysicsFrames();
		markPlayerDone();
		maybeShowFinishedPage();
		// The course keeps ticking under the finished overlay; tell it the race is
		// over so its per-frame phase report does not clobber "finished".
		if (course != null) {
			course.raceEnded = true;
		}
		pr2.app.DebugSignal.set("race-phase", "finished");
	}

	// Course invokes this once the local player bumps a finish block (race-style
	// modes). It emits finish_race itself; here we mark the player done, glow the
	// quit button, and show the finished page (Flash Game.finish +
	// maybeShowFinishedPage).
	private function onLocalFinish(_:pr2.gameplay.player.LocalPlayerState):Void {
		if (playerDone) {
			return;
		}
		// Course calls us immediately after emitting finish_race, while the
		// authoritative physics-frame number is still the one that finished.
		captureFinishedPhysicsFrames();
		markPlayerDone();
		if (quitButton != null) {
			quitButton.startGlow();
		}
		maybeShowFinishedPage();
		pr2.app.DebugSignal.set("race-phase", "finished");
	}

	private function onCourseOutOfTime():Void {
		cancelHatCountdown();
		if (course != null && course.gameMode() == "egg") {
			onLocalFinish(null);
			maybeShowFinishedPage();
		} else {
			quitGame();
		}
	}

	private function markPlayerDone():Void {
		playerDone = true;
	}

	private function maybeShowFinishedPage():Void {
		if (finishedPage != null) {
			return;
		}
		markPlayerDone();
		if (quitButton != null) {
			quitButton.stopGlow();
		}
		captureFinishedPhysicsFrames();
		var physicsFrames = finishedPhysicsFrames == null ? 0 : finishedPhysicsFrames;
		finishedPage = new FinishedPage(levelId, returnToLobby, clearFinishedPage, physicsFrames, finishedPageAssets);
		finishedPageAssets = null;
		for (awardArgs in pendingAwards) {
			applyAwardToFinishedPage(awardArgs);
		}
		if (expToRank != 0) {
			finishedPage.setExpGain(expOld, expNew, expToRank);
		}
	}

	private function applyAwardToFinishedPage(args:Array<String>):Void {
		if (finishedPage == null || args == null) {
			return;
		}
		finishedPage.award(arg(args, 0), arg(args, 1));
	}

	private function clearFinishedPage(page:FinishedPage):Void {
		if (finishedPage == page) {
			finishedPage = null;
		}
	}

	private function captureFinishedPhysicsFrames():Void {
		if (finishedPhysicsFrames != null) {
			return;
		}
		var clock = FrameClock.current;
		if (raceStartPhysicsFrame != null && clock != null) {
			var elapsed = clock.simulationFrameNumber - raceStartPhysicsFrame;
			finishedPhysicsFrames = elapsed < 0 ? 0 : elapsed;
			return;
		}
		// Deterministic/unit contexts may not install the application clock.
		// Course's counter has the same beginRace-to-finish boundaries there.
		finishedPhysicsFrames = course == null ? 0 : course.framesPlaying;
	}

	private static function arg(args:Array<String>, index:Int):String {
		return index >= 0 && index < args.length && args[index] != null ? args[index] : "";
	}

	private function returnToLobby():Void {
		if (!LobbySocket.isConnected()) {
			return;
		}
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
		new MessagePopup(message);
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
