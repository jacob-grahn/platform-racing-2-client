package pr2.gameplay;

import haxe.crypto.Md5;
import openfl.events.Event;
import openfl.geom.Point;
import pr2.character.CharacterState;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.harness.LocalPlayerController;
import pr2.harness.LocalPlayerInput;
import pr2.harness.LocalPlayerDebugState;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.level.BlockType;
import pr2.level.FixtureLevel.LevelBlock;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevel;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevelDecoder;
import pr2.net.LobbySocket;
import pr2.net.ServerLevelData;
import pr2.net.ServerConfig;

/**
	A3 coverage: the production `Course` shell mounts a decoded level plus the
	authored HUD at Course's verified holder->stage offsets, hosts a character
	layer, and tears everything down on `remove`. Built from a small in-memory m3
	fixture so no network fetch is needed.
**/
@:access(pr2.gameplay.Course)
class GameShellMountTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var course = buildCourse();

		assertClose(Course.ITEM_X, course.itemDisplay.x, "item display x");
		assertClose(Course.ITEM_Y, course.itemDisplay.y, "item display y");
		assertClose(Course.MINIMAP_X, course.miniMap.x, "minimap x");
		assertClose(Course.MINIMAP_Y, course.miniMap.y, "minimap y");
		assertClose(Course.STATS_X, course.statsDisplay.x, "stats x");
		assertClose(Course.STATS_Y, course.statsDisplay.y, "stats y");
		assertClose(Course.HEARTS_X, course.hearts.x, "hearts x");
		assertClose(Course.HEARTS_Y, course.hearts.y, "hearts y");
		assertEquals(false, course.hearts.visible, "hearts hidden until deathmatch lives reported");
		assertClose(Course.MUSIC_X, course.musicSelection.x, "music x");
		assertClose(Course.MUSIC_Y, course.musicSelection.y, "music y");
		assertClose(Course.TIMER_X, course.timer.x, "timer x");
		assertClose(Course.TIMER_Y, course.timer.y, "timer y");
		assertEquals("", course.timer.debugText(), "timer starts blank before race init");
		assertClose(Course.CHAT_X, course.raceChat.x, "chat x");
		assertClose(Course.CHAT_Y, course.raceChat.y, "chat y");
		assertClose(Course.DRAWING_X, course.drawingInfo.x, "drawing info x");
		assertClose(Course.DRAWING_Y, course.drawingInfo.y, "drawing info y");

		assertEquals(true, course.levelRenderer != null, "level renderer mounted");
		assertEquals(true, course.characterLayer != null, "character layer present");
		assertEquals(true, course.backCharacterLayer != null, "back character layer present");
		assertEquals(true, course.localCharacter != null, "local character bridge mounted");
		assertEquals(course.localCharacter, course.characterLayer.getChildAt(0), "local character owns display-list slot");
		var start = @:privateAccess course.level.startBlocks()[0];
		var initialState = course.localCharacter.debugState();
		assertClose(start.x + 15, @:privateAccess course.serverFixture.fixturePixelToWorldX(initialState.x),
			"local character spawns at Flash start center x");
		assertClose(start.y + 15, @:privateAccess course.serverFixture.fixturePixelToWorldY(initialState.y),
			"local character spawns at Flash start center y");
		assertEquals(true, course.levelRenderer.worldChildDepth(course.backCharacterLayer) >= 0,
			"back character layer sits inside the rotating world (above the background art)");
		assertBelow(course.levelRenderer.worldChildDepth(course.backCharacterLayer), course.levelRenderer.blockLayerDepth(),
			"back character layer renders below the blocks");
		assertEquals(true, course.levelRenderer.worldChildDepth(course.characterLayer) > course.levelRenderer.blockLayerDepth(),
			"front character layer sits inside the rotating world above the blocks");
		assertBelow(course.levelRenderer.worldChildDepth(course.characterLayer), course.levelRenderer.artLayerDepth(3),
			"front character layer renders below art 0");
		assertBelow(course.levelRenderer.worldChildDepth(course.characterLayer), course.levelRenderer.artLayerDepth(4),
			"front character layer renders below art 00");
		assertEquals(true, course.levelRenderer.worldChildDepth(course.effectBackground) > course.levelRenderer.worldChildDepth(course.characterLayer),
			"effect layer renders above the characters");
		assertBelow(course.levelRenderer.worldChildDepth(course.effectBackground), course.levelRenderer.artLayerDepth(3),
			"effect layer renders below art 0 like Flash");
		testRemoteParentLayerSwitch(course);
		testLocalWaterParentLayerSwitch(course);

		// With no chat interceptor supplied, the shell does not swallow chat.
		assertEquals(false, course.handleRaceChatLine("/debug"), "no interceptor leaves chat unhandled");
		LevelInfoPopup.autoLoadOnCreate = false;
		assertEquals(true, course.handleRaceChatLine(" /level "), "race chat /level opens current level info");
		assertEquals(false, LevelInfoPopup.instance == null, "race chat /level creates a LevelInfoPopup");
		assertEquals(42, LevelInfoPopup.instance.levelId, "race chat /level uses the current course id");
		LevelInfoPopup.instance.remove();
		LevelInfoPopup.autoLoadOnCreate = true;

		course.remove();
		assertEquals(true, course.miniMap == null, "minimap torn down");
		assertEquals(true, course.itemDisplay == null, "item display torn down");
		assertEquals(true, course.statsDisplay == null, "stats display torn down");
		assertEquals(true, course.hearts == null, "hearts torn down");
		assertEquals(true, course.musicSelection == null, "music selection torn down");
		assertEquals(true, course.timer == null, "timer torn down");
		assertEquals(true, course.raceChat == null, "race chat torn down");
		assertEquals(true, course.drawingInfo == null, "drawing info torn down");
		assertEquals(true, course.levelRenderer == null, "level renderer torn down");
		assertEquals(true, course.localCharacter == null, "local character torn down");

		testDeathmatchHeartsShowInitialLives();
		testRoguelikeHudAndInitialState();
		testRoguelikeOnlyEmitsTerminalFinishOnNinthHit();
		testRenderingUsesFreeMoveCamera();
		testFinishDrawingReadinessEmission();
		testLocalFinishBeginsCharacterRemoval();
		testTestModeFinishDelegatesWithoutRaceRemoval();
		testObjectiveModeReportsEachFinishOnce();
		testRotateBlockDisplayKeepsLocalCharacterCentered();
		testCountdownKeepsCameraStill();
		testTournamentStartForcesFirstStartPosition();
		testTimerBeginRaceAndTimeoutBoundary();
		testLiveRaceEmitsMultiplayerUpdates();

		trace('GameShellMountTest passed $assertions assertions');
	}

	private static function testDeathmatchHeartsShowInitialLives():Void {
		var course = buildCourse("deathmatch");
		assertEquals(true, course.hearts.visible, "deathmatch course shows hearts immediately");
		assertEquals(3, course.hearts.getHeartCount(), "deathmatch course starts with three lives");
		course.setLife(2);
		assertEquals(2, course.hearts.getHeartCount(), "setLife updates deathmatch hearts");
		assertEquals(2, course.localCharacter.debugState().lives, "setLife updates local controller lives");
		course.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(2, course.hearts.getHeartCount(), "setLife value survives the next frame sync");
		LobbySocket.resetSent();
		var zeroLives = new LocalPlayerDebugState(0, 0, 0, 0, false, false, CharacterState.Bumped, null, "hurt", null, null, null, 50, 50,
			50, 0, true, null, null, null, 0);
		@:privateAccess course.maybeHandleLocalFinish(zeroLives);
		assertEquals("finish_race`-1`0`0|set_var`beginRemove`1", LobbySocket.sentCommands.join("|"),
			"deathmatch zero lives emits finish and starts local removal");
		course.remove();
	}

	private static function testRoguelikeHudAndInitialState():Void {
		var course = buildCourse("roguelike");
		var state = course.localCharacter.debugState();
		assertEquals(true, course.hearts.visible, "roguelike course shows hearts immediately");
		assertEquals(1, course.hearts.getHeartCount(), "roguelike course starts with one heart");
		assertClose(0, state.speedStat, "roguelike live character starts with zero speed");
		assertClose(0, state.accelerationStat, "roguelike live character starts with zero acceleration");
		assertClose(0, state.jumpStat, "roguelike live character starts with zero jumping");
		assertEquals("Finish: 0/9", course.roguelikeProgressText.text, "roguelike HUD shows finish progress");
		course.localCharacter.setHats([6, 0xFFFFFF, -1]);
		assertEquals(1, course.localCharacter.hat1, "roguelike rejects local hat updates");
		var remote = course.createRemoteCharacter(remoteInit(9));
		remote.setHats([7, 0xFFFFFF, -1]);
		assertEquals(1, remote.hat1, "roguelike rejects remote hat updates");
		course.remove();
		assertEquals(true, course.roguelikeProgressText == null, "roguelike progress HUD tears down");
	}

	private static function testRoguelikeOnlyEmitsTerminalFinishOnNinthHit():Void {
		var course = buildCourse("roguelike");
		var finishBlock = new LevelBlock(1, 1, BlockType.Finish);
		course.localCharacter.setLife(9);
		LobbySocket.resetSent();
		for (_ in 1...LocalPlayerController.ROGUELIKE_REQUIRED_FINISH_HITS) {
			@:privateAccess course.localCharacter.controller.finish(finishBlock);
			@:privateAccess course.maybeHandleLocalFinish(course.localCharacter.debugState());
		}
		assertEquals("", LobbySocket.sentCommands.join("|"), "first eight roguelike hits emit no finish event");
		@:privateAccess course.localCharacter.controller.finish(finishBlock);
		@:privateAccess course.maybeHandleLocalFinish(course.localCharacter.debugState());
		assertEquals(true, StringTools.startsWith(LobbySocket.sentCommands.join("|"), "finish_race`"),
			"ninth roguelike hit emits the existing finish event");
		course.remove();
	}

	private static function testTimerBeginRaceAndTimeoutBoundary():Void {
		var course = buildCourse();
		var timeoutCalls = 0;
		course.onOutOfTime = function():Void timeoutCalls++;
		course.beginRace();
		assertEquals("2:00", course.timer.debugText(), "beginRace initializes the course timer display");
		course.outOfTimeHandler();
		assertEquals(1, timeoutCalls, "course outOfTimeHandler routes to the host callback");
		course.remove();
	}

	private static function testLiveRaceEmitsMultiplayerUpdates():Void {
		var course = buildCourse();
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		course.createRemoteCharacter(remoteInit(9));
		assertEquals(2, course.localCharacter.networkPlayerCount, "remote creation enables multiplayer update cadence");
		@:privateAccess course.onCountdownFinish();
		LobbySocket.resetSent();
		for (_ in 0...5) {
			@:privateAccess course.onEnterFrame(new Event(Event.ENTER_FRAME));
		}
		assertEquals(true, hasSentCommand("p`"), "live race loop emits local position updates for remote players");
		assertEquals(true, hasSentCommand("set_var`state`"), "live race loop emits local appearance state for remote players");
		course.removeRemoteCharacter(9);
		assertEquals(1, course.localCharacter.networkPlayerCount, "remote removal restores solo update cadence");
		course.remove();
	}

	private static function hasSentCommand(prefix:String):Bool {
		for (command in LobbySocket.sentCommands) {
			if (StringTools.startsWith(command, prefix)) {
				return true;
			}
		}
		return false;
	}

	private static function testRenderingUsesFreeMoveCamera():Void {
		var course = buildLargeCourse();
		assertEquals(false, course.levelRenderer.isDrawingComplete(), "large course starts in incremental render mode");
		@:privateAccess course.scrollRight = true;
		var beforeX = @:privateAccess course.camera.posX;

		course.dispatchEvent(new Event(Event.ENTER_FRAME));

		assertEquals(true, course.debugKeyScrollActive(), "rendering course enables free-move camera");
		assertBelow(@:privateAccess course.camera.posX, beforeX, "right arrow free-scrolls the loading level");
		course.remove();
	}

	private static function testRemoteParentLayerSwitch(course:Course):Void {
		var remote = course.createRemoteCharacter(remoteInit(9));
		assertEquals(course.characterLayer, remote.parent, "remote character starts in front character layer");
		var start = @:privateAccess course.startPositions[0];
		assertClose(start.x, remote.x, "remote character keeps its world start x before Go");
		assertClose(start.y, remote.y, "remote character keeps its world start y before Go");
		remote.pos(["30", "15"]);
		for (_ in 0...5) {
			remote.stepFrame();
		}
		assertClose(remote.posX, remote.x, "live remote x remains in Flash-compatible world coordinates");
		assertClose(remote.posY, remote.y, "live remote y remains in Flash-compatible world coordinates");
		remote.onParentChange("backBackground");
		assertEquals(course.backCharacterLayer, remote.parent, "remote water parent moves behind blocks");
		remote.onParentChange("frontBackground");
		assertEquals(course.characterLayer, remote.parent, "remote front parent returns above blocks");
		course.removeRemoteCharacter(9);
	}

	private static function testLocalWaterParentLayerSwitch(course:Course):Void {
		@:privateAccess course.localCharacter.controller.touchedBlock = new LevelBlock(0, 0, BlockType.Water);
		course.updatePlayerDisplay();
		assertEquals(course.backCharacterLayer, course.localCharacter.parent, "local water touch moves behind blocks");

		@:privateAccess course.localCharacter.controller.touchedBlock = null;
		course.updatePlayerDisplay();
		assertEquals(course.characterLayer, course.localCharacter.parent, "local non-water touch returns above blocks");
	}

	private static function remoteInit(tempId:Int):RemoteCharacterInit {
		return {
			tempId: tempId,
			userName: "Remote",
			hatId: 1,
			headId: 1,
			bodyId: 1,
			feetId: 1,
			group: "g",
			hatColor: 1,
			hatColor2: 2,
			headColor: 3,
			headColor2: 4,
			bodyColor: 5,
			bodyColor2: 6,
			feetColor: 7,
			feetColor2: 8
		};
	}

	private static function buildCourse(gameMode:String = "race"):Course {
		var dataString = "m3`e0c8b8`334;335;11,1;0;12,0;1;0,1;0";
		var level = ServerLevelDecoder.decode(dataString);

		var vars:Map<String, String> = new Map();
		vars.set("level_id", "42");
		vars.set("title", "Mount Test");
		vars.set("song", "song1");
		vars.set("gravity", "2.5");
		vars.set("max_time", "120");
		vars.set("gameMode", gameMode);
		vars.set("items", "all");
		vars.set("data", dataString);

		var data = new ServerLevelData(vars, true);
		var config = LevelConfig.fromServerData(data);
		return new Course(level, data, config);
	}

	private static function buildLargeCourse():Course {
		var blocks:Array<DecodedBlock> = [new DecodedBlock(ObjectCodes.BLOCK_START1, 0, 0)];
		for (i in 0...120) {
			blocks.push(new DecodedBlock(ObjectCodes.BLOCK_BASIC1, i * 30, 90));
		}
		var level = new ServerLevel(0xFFFFFF, blocks);
		var vars:Map<String, String> = new Map();
		vars.set("level_id", "44");
		vars.set("title", "Large Render Test");
		vars.set("song", "song1");
		vars.set("gravity", "1");
		vars.set("max_time", "120");
		vars.set("gameMode", "race");
		vars.set("items", "all");
		vars.set("data", "large-render-test");
		var data = new ServerLevelData(vars, true);
		return new Course(level, data, LevelConfig.fromServerData(data));
	}

	private static function testTournamentStartForcesFirstStartPosition():Void {
		var previousTournamentMode = LobbySession.tournamentMode;
		LobbySession.tournamentMode = true;
		var level = new ServerLevel(0xFFFFFF, [
			new DecodedBlock(ObjectCodes.BLOCK_START1, 0, 0),
			new DecodedBlock(ObjectCodes.BLOCK_START2, 210, 0),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 0, 30),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 210, 30)
		]);
		var vars:Map<String, String> = new Map();
		vars.set("level_id", "45");
		vars.set("title", "Tournament Start Test");
		vars.set("song", "song1");
		vars.set("gravity", "1");
		vars.set("max_time", "120");
		vars.set("gameMode", "race");
		vars.set("items", "all");
		vars.set("data", "tournament-start-test");
		var data = new ServerLevelData(vars, true);
		var course = new Course(level, data, LevelConfig.fromServerData(data));
		course.createLocalCharacter({
			tempId: 1,
			speed: 50,
			accel: 50,
			jump: 50,
			hatColor: 1,
			headColor: 2,
			bodyColor: 3,
			feetColor: 4,
			hatId: 1,
			headId: 1,
			bodyId: 1,
			feetId: 1,
			hatColor2: 5,
			headColor2: 6,
			bodyColor2: 7,
			feetColor2: 8,
			group: ""
		});
		var state = course.localCharacter.debugState();
		assertClose(15, @:privateAccess course.serverFixture.fixturePixelToWorldX(state.x), "tournament local temp 1 uses first start x");
		assertClose(15, @:privateAccess course.serverFixture.fixturePixelToWorldY(state.y), "tournament local temp 1 uses first start y");
		course.remove();
		LobbySession.tournamentMode = previousTournamentMode;
	}

	private static function testFinishDrawingReadinessEmission():Void {
		var dataString = "m3`e0c8b8`0;0;11,1;0;16";
		var level = ServerLevelDecoder.decode(dataString);
		var saveString = "level_id=42&version=7&title=Draw Ready&song=song1&gravity=1&max_time=120&gameMode=race&cowboyChance=25&badHats=4,6&data="
			+ dataString;

		var vars:Map<String, String> = new Map();
		vars.set("level_id", "42");
		vars.set("version", "7");
		vars.set("title", "Draw Ready");
		vars.set("song", "song1");
		vars.set("gravity", "1");
		vars.set("max_time", "120");
		vars.set("gameMode", "race");
		vars.set("cowboyChance", "25");
		vars.set("badHats", "4,6");
		vars.set("data", dataString);

		var data = new ServerLevelData(vars, true, saveString);
		var course = new Course(level, data, LevelConfig.fromServerData(data));
		LobbySocket.resetSent();
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		course.dispatchEvent(new Event(Event.ENTER_FRAME));
		course.dispatchEvent(new Event(Event.ENTER_FRAME));

		var hash = Md5.encode(saveString + "42" + "7" + ServerConfig.LEVEL_HASH_SALT);
		assertEquals(
			'finish_drawing`$hash`race`[{"id":1,"x":45,"y":15}]`1`25`4,6',
			LobbySocket.sentCommands.join("|"),
			"finish_drawing emitted after all drawing completes"
		);
		assertEquals(false, course.drawingInfo.isDrawing(0), "local drawing spinner hidden after readiness emission");
		course.remove();
	}

	private static function testLocalFinishBeginsCharacterRemoval():Void {
		var course = buildCourse("race");
		course.beginRace();
		assertEquals(false, course.timer.debugPaused(), "race timer runs once beginRace arrives");
		LobbySocket.resetSent();
		var finish = new LocalPlayerDebugState(0, 0, 0, 0, false, false, CharacterState.Stand, null, "land", null, null, null, 50, 50,
			50, 0, true, 1, 45, 15);
		@:privateAccess course.maybeHandleLocalFinish(finish);
		assertEquals("finish_race`1`9945`9945|set_var`beginRemove`1", LobbySocket.sentCommands.join("|"),
			"race finish reports world coordinates and starts local removal");
		assertEquals(true, course.timer.debugPaused(), "race finish freezes the HUD timer");
		assertEquals(false, course.localCharacter.removed, "finish starts fade-out instead of immediate removal");
		assertEquals(true, course.debugKeyScrollActive(), "finish switches camera to free-move mode");
		var x = course.localCharacter.debugState().x;
		var y = course.localCharacter.debugState().y;
		@:privateAccess course.input.right = true;
		course.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(x, course.localCharacter.debugState().x, "finished character no longer steps horizontally");
		assertClose(y, course.localCharacter.debugState().y, "finished character no longer steps vertically");
		course.remove();
	}

	private static function testTestModeFinishDelegatesWithoutRaceRemoval():Void {
		var course = buildCourse("race");
		course.testMode = true;
		var callbacks = 0;
		course.onFinish = function(_):Void callbacks++;
		LobbySocket.resetSent();
		var finish = new LocalPlayerDebugState(0, 0, 0, 0, false, false, CharacterState.Stand, null, "land", null, null, null, 50, 50,
			50, 0, true, 1, 45, 15);
		@:privateAccess course.maybeHandleLocalFinish(finish);

		assertEquals(1, callbacks, "test-mode finish delegates to the level tester once");
		assertEquals("", LobbySocket.sentCommands.join("|"), "test-mode finish emits no race network commands");
		var alphaBefore = course.localCharacter.alpha;
		course.localCharacter.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(alphaBefore, course.localCharacter.alpha, "test-mode finish does not fade out the character");
		course.remove();
	}

	private static function testObjectiveModeReportsEachFinishOnce():Void {
		var course = buildCourse("objective");
		course.beginRace();
		LobbySocket.resetSent();
		var first = new LocalPlayerDebugState(0, 0, 0, 0, false, false, CharacterState.Stand, null, "land", null, null, null, 50, 50,
			50, 0, true, 1, 45, 15);
		var second = new LocalPlayerDebugState(0, 0, 0, 0, false, false, CharacterState.Stand, null, "land", null, null, null, 50, 50,
			50, 0, true, 2, 75, 15);
		@:privateAccess course.maybeHandleLocalFinish(first);
		@:privateAccess course.maybeHandleLocalFinish(first);
		@:privateAccess course.maybeHandleLocalFinish(second);
		assertEquals("objective_reached`1`9945`9945|objective_reached`2`9975`9945", LobbySocket.sentCommands.join("|"),
			"objective mode reports each objective in world coordinates once without ending race");
		assertEquals(false, course.localFinishHandled, "objective mode does not latch the race finished");
		assertEquals(false, course.timer.debugPaused(), "objective progress leaves the HUD timer running");
		course.remove();
	}

	private static function testRotateBlockDisplayKeepsLocalCharacterCentered():Void {
		var course = buildRotateCourse();
		for (_ in 0...40) {
			course.localCharacter.step(new LocalPlayerInput(false, false, true));
			if (course.localCharacter.debugState().mode == "jump") {
				break;
			}
		}
		assertEquals("jump", course.localCharacter.debugState().mode, "local character reaches rotate jump state");

		course.localCharacter.step(new LocalPlayerInput());
		course.updatePlayerDisplay();
		assertEquals(-3, course.localCharacter.rotation, "local character counter-rotates during course tween");
		assertEquals(false, course.levelRenderer.debugArtCachingEnabled(), "rotate tween disables background art caching");
		assertEquals(openfl.display.StageQuality.LOW, course.debugStageQualityForTests(), "rotate tween lowers stage quality");
		assertEquals(course.characterLayer, course.localCharacter.parent, "local character stays in the rotating front layer during tween");
		assertLocalCharacterFeetAnchored(course, "rotate tween keeps local character feet as the visual pivot");
		var tweenFeet = localCharacterFeetOnStage(course);
		assertBetween(0, 550, tweenFeet.x,
			"local character x stays on-stage while the world tween is active");
		assertBetween(0, 400, tweenFeet.y,
			"local character y stays on-stage while the world tween is active");

		for (_ in 0...29) {
			course.localCharacter.step(new LocalPlayerInput());
			course.updatePlayerDisplay();
		}

		var state = course.localCharacter.debugState();
		assertEquals(90, state.courseRotation, "rotate block commits course rotation");
		assertEquals(0, course.localCharacter.rotation, "local character rotation resets after tween");
		assertEquals(true, course.levelRenderer.debugArtCachingEnabled(), "completed rotate restores background art caching");
		assertEquals(openfl.display.StageQuality.HIGH, course.debugStageQualityForTests(), "completed rotate restores high stage quality");
		var settledFeet = localCharacterFeetOnStage(course);
		assertClose(275, settledFeet.x, "camera snaps local x after rotation");
		assertClose(245, settledFeet.y, "camera snaps local y after rotation");
		course.remove();
	}

	private static function localCharacterFeetOnStage(course:Course):Point {
		return course.localCharacter.localToGlobal(new Point());
	}

	private static function assertLocalCharacterFeetAnchored(course:Course, message:String):Void {
		var state = course.localCharacter.debugState();
		var worldX = @:privateAccess course.serverFixture.fixturePixelToWorldX(state.x);
		var worldY = @:privateAccess course.serverFixture.fixturePixelToWorldY(state.y);
		var expected = course.levelRenderer.worldToScreen(worldX, worldY);
		var actual = localCharacterFeetOnStage(course);
		assertClose(expected.x, actual.x, '$message x');
		assertClose(expected.y, actual.y, '$message y');
	}

	// Regression: during the 3-2-1 countdown the race has not started, so the
	// local player is never stepped or synced from its controller. Each
	// updatePlayerDisplay still runs and PlayerDisplayPlacement.place() overwrites
	// localCharacter.x/y with the on-screen (feet) coordinate. The camera must
	// therefore follow the controller's authoritative position, not the mutated
	// localCharacter.x/y — otherwise it feeds the previous frame's screen coord
	// back into its target and scrolls away from the player every frame, snapping
	// back only at "Go" (the "player teleports far away during the countdown" bug).
	private static function testCountdownKeepsCameraStill():Void {
		var course = buildCourse("race");
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		// One display frame settles the camera on the player; capture it, then run
		// more countdown frames (no step/sync) and assert the camera does not move.
		course.updatePlayerDisplay();
		// The non-solid start block leaves the player airborne at spawn, so without
		// the wait-state handling the motion state would derive a "jumpAnim"; the
		// countdown must show the idle stand pose instead (Flash mode="wait").
		assertEquals(false, course.localCharacter.grounded, "start block leaves the player airborne at spawn");
		assertEquals("standAnim", @:privateAccess course.localCharacter.display.activeStateName,
			"local player shows the idle stand pose during the countdown, not a jump");
		var camX = @:privateAccess course.camera.posX;
		var camY = @:privateAccess course.camera.posY;
		for (_ in 0...10) {
			course.updatePlayerDisplay();
		}
		assertClose(camX, @:privateAccess course.camera.posX, "camera x holds steady through the countdown");
		assertClose(camY, @:privateAccess course.camera.posY, "camera y holds steady through the countdown");
		course.remove();
	}

	private static function buildRotateCourse():Course {
		var level = new ServerLevel(0xFFFFFF, [
			new DecodedBlock(ObjectCodes.BLOCK_START1, 60, 90),
			new DecodedBlock(ObjectCodes.BLOCK_ROTATE_RIGHT, 60, 30),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 60, 120),
			new DecodedBlock(ObjectCodes.BLOCK_FINISH, 120, 120)
		]);

		var vars:Map<String, String> = new Map();
		vars.set("level_id", "43");
		vars.set("title", "Rotate Display Test");
		vars.set("song", "song1");
		vars.set("gravity", "1");
		vars.set("max_time", "120");
		vars.set("gameMode", "race");
		vars.set("items", "all");
		vars.set("data", "rotate-display-test");

		var data = new ServerLevelData(vars, true);
		return new Course(level, data, LevelConfig.fromServerData(data));
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.001) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertBelow(actual:Float, expectedUpperBound:Float, message:String):Void {
		assertions++;
		if (!(actual < expectedUpperBound)) {
			throw '$message: expected $actual to be below $expectedUpperBound';
		}
	}

	private static function assertBetween(min:Float, max:Float, actual:Float, message:String):Void {
		assertions++;
		if (actual < min || actual > max) {
			throw '$message: expected $actual to be between $min and $max';
		}
	}
}
