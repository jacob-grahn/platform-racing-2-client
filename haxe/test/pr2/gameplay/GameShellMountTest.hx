package pr2.gameplay;

import haxe.crypto.Md5;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.geom.Point;
import pr2.Constants;
import pr2.character.CharacterState;
import pr2.character.PhysicsParticle;
import pr2.effects.BlockPiece;
import pr2.effects.ShotEffect;
import pr2.effects.StingEffect;
import pr2.gameplay.GameCommandShell.LocalCharacterInit;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.gameplay.player.LocalPlayerController;
import pr2.gameplay.player.LocalPlayerInput;
import pr2.gameplay.player.LocalPlayerState;
import pr2.gameplay.presentation.CharacterPresentationLayer;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.level.BlockType;
import pr2.level.Level.LevelBlock;
import pr2.level.ObjectCodes;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;
import pr2.level.LevelDecoder;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerLevelData;
import pr2.net.ServerConfig;
import pr2.runtime.FrameClock;
import pr2.runtime.FrameRateDiagnostics;
import pr2.runtime.FrameRateSettings;

/**
	A3 coverage: the production `Course` shell mounts a decoded level plus the
	authored HUD at Course's verified holder->stage offsets, hosts a character
	layer, and tears everything down on `remove`. Built from a small in-memory m3
	fixture so no network fetch is needed.
**/
@:access(pr2.gameplay.Course)
@:access(pr2.gameplay.MiniMap)
@:access(pr2.level.LevelRenderer)
class GameShellMountTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var course = buildCourse();

		pr2.DeterministicTestMode.runTest("GameShellMountTest.testItemDisplayX", function():Void {
		assertClose(Course.ITEM_X, course.itemDisplay.x, "item display x");
		});
		course.remove();
		if (pr2.DeterministicTestMode.finishSmokeSuite("GameShellMountTest")) return;
		pr2.DeterministicTestMode.runTest("GameShellMountTest.testLevelLoadErrorUsesMessagePopup", testLevelLoadErrorUsesMessagePopup);

		trace('GameShellMountTest passed $assertions assertions');
	}

	private static function testLevelLoadErrorUsesMessagePopup():Void {
		var page = new pr2.page.GamePage(123, 1);
		@:privateAccess page.showError("Error: The course did not load.");
		var open = Popup.getOpen();
		var message = Std.downcast(open[open.length - 1], MessagePopup);
		assertEquals(true, message != null, "gameplay level-load failure opens Flash MessagePopup");
		message.remove();
		page.remove();
	}

	private static function runItemFinishLifecycle(smooth:Bool):{
		states:String,
		commands:String,
		stageFrames:Int,
		simulationFrames:Int,
		finished:Bool
	} {
		var course = buildCourse();
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		@:privateAccess course.onCountdownFinish();
		course.localCharacter.grantItemForDebug(1);
		var clock = new FrameClock(FrameRateSettings.fromQuery(smooth ? "?smooth60=1" : null, true),
			new FrameRateDiagnostics(function():Float return 0));
		@:privateAccess FrameClock.setCurrentForTests(clock);
		LobbySocket.resetSent();
		var states:Array<String> = [];
		var commands:Array<String> = [];
		var commandCursor = 0;
		var simulationIndex = 0;
		while (simulationIndex < 40) {
			clock.advanceFrame();
			if (clock.isSimulationFrame) {
				@:privateAccess course.input.item = simulationIndex == 1;
				if (simulationIndex == 20) {
					@:privateAccess course.localCharacter.controller.finish(new LevelBlock(1, 1, BlockType.Finish));
				}
			}
			@:privateAccess course.onEnterFrame(new Event(Event.ENTER_FRAME));
			if (clock.isSimulationFrame) {
				states.push(course.localCharacter.stateSnapshot().serialize());
				while (commandCursor < LobbySocket.sentCommands.length) {
					commands.push('$simulationIndex:' + LobbySocket.sentCommands[commandCursor]);
					commandCursor++;
				}
				simulationIndex++;
			}
		}
		var finished = @:privateAccess course.localFinishHandled && course.timer.debugPaused();
		var result = {
			states: states.join("|"),
			commands: commands.join("|"),
			stageFrames: clock.stageFrameNumber,
			simulationFrames: clock.simulationFrameNumber,
			finished: finished
		};
		course.remove();
		@:privateAccess FrameClock.setCurrentForTests(null);
		return result;
	}

	private static function runRotationLifecycle(smooth:Bool):{
		result:String,
		stageFrames:Int,
		simulationFrames:Int
	} {
		var course = buildRotateCourse();
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		@:privateAccess course.onCountdownFinish();
		var clock = new FrameClock(FrameRateSettings.fromQuery(smooth ? "?smooth60=1" : null, true),
			new FrameRateDiagnostics(function():Float return 0));
		@:privateAccess FrameClock.setCurrentForTests(clock);
		var simulationIndex = 0;
		var complete = false;
		while (!complete && simulationIndex < 100) {
			clock.advanceFrame();
			if (clock.isSimulationFrame) {
				var before = course.localCharacter.stateSnapshot();
				@:privateAccess course.input.jump = before.courseRotation == 0 && before.mode != "freeze";
			}
			@:privateAccess course.onEnterFrame(new Event(Event.ENTER_FRAME));
			if (clock.isSimulationFrame) {
				simulationIndex++;
				var after = course.localCharacter.stateSnapshot();
				complete = after.courseRotation == 90 && after.mode != "freeze";
			}
		}
		var state = course.localCharacter.stateSnapshot();
		var result = '${state.courseRotation}:${state.mode}:${course.localCharacter.rotation}:'
			+ '${course.levelRenderer.debugArtCachingEnabled()}:${course.debugStageQualityForTests()}';
		var output = {
			result: result,
			stageFrames: clock.stageFrameNumber,
			simulationFrames: clock.simulationFrameNumber
		};
		course.remove();
		@:privateAccess FrameClock.setCurrentForTests(null);
		return output;
	}

	private static function runTwinReplay(smooth:Bool):{
		states:Array<String>,
		commandTimeline:Array<String>,
		stageFrames:Int,
		simulationFrames:Int
	} {
		var course = buildCourse();
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		course.createRemoteCharacter(remoteInit(9));
		@:privateAccess course.onCountdownFinish();
		LobbySocket.resetSent();
		var query = smooth ? "?smooth60=1" : null;
		var clock = new FrameClock(FrameRateSettings.fromQuery(query, true), new FrameRateDiagnostics(function():Float return 0));
		@:privateAccess FrameClock.setCurrentForTests(clock);
		var states:Array<String> = [];
		var commandTimeline:Array<String> = [];
		var commandCursor = 0;
		var simulationIndex = 0;
		while (simulationIndex < 180) {
			clock.advanceFrame();
			if (clock.isSimulationFrame) applyTwinReplayInput(course, simulationIndex);
			@:privateAccess course.onEnterFrame(new Event(Event.ENTER_FRAME));
			if (clock.isSimulationFrame) {
				states.push(course.localCharacter.stateSnapshot().serialize());
				while (commandCursor < LobbySocket.sentCommands.length) {
					commandTimeline.push('$simulationIndex:' + LobbySocket.sentCommands[commandCursor]);
					commandCursor++;
				}
				simulationIndex++;
			}
		}
		var result = {
			states: states,
			commandTimeline: commandTimeline,
			stageFrames: clock.stageFrameNumber,
			simulationFrames: clock.simulationFrameNumber
		};
		course.remove();
		@:privateAccess FrameClock.setCurrentForTests(null);
		return result;
	}

	private static function applyTwinReplayInput(course:Course, tick:Int):Void {
		@:privateAccess course.input.left = tick >= 60 && tick < 100;
		@:privateAccess course.input.right = tick < 60 || (tick >= 100 && tick < 150);
		@:privateAccess course.input.jump = (tick >= 8 && tick < 14) || (tick >= 72 && tick < 78) || (tick >= 132 && tick < 138);
		@:privateAccess course.input.down = tick >= 108 && tick < 116;
		@:privateAccess course.input.item = false;
	}

	private static function hasSentCommand(prefix:String):Bool {
		for (command in LobbySocket.sentCommands) {
			if (StringTools.startsWith(command, prefix)) {
				return true;
			}
		}
		return false;
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
		var remotePose = @:privateAccess remote.presentationPose;
		remotePose.beginSimulationTick(remote.x - 4, remote.y - 2, remote.rotation, 1, CharacterPresentationLayer.Front);
		remotePose.finishSimulationTick(remote.x - 2, remote.y - 1, remote.rotation, 1, CharacterPresentationLayer.Front);
		remotePose.beginSimulationTick(remote.x - 2, remote.y - 1, remote.rotation, 1, CharacterPresentationLayer.Front);
		remotePose.finishSimulationTick(remote.x, remote.y, remote.rotation, 1, CharacterPresentationLayer.Front);
		remote.renderPresentationFrame();
		assertEquals(true, remote.display.x != 0 || remote.display.y != 0,
			"fixture establishes a remote presentation offset before a water-layer switch");
		remote.onParentChange("backBackground");
		assertEquals(course.backCharacterLayer, remote.parent, "remote water parent moves behind blocks");
		assertEquals(false, course.characterLayer.contains(remote), "remote water switch removes the character from the front layer");
		assertEquals(true, course.backCharacterLayer.contains(remote), "remote water switch leaves exactly one back-layer character instance");
		remote.renderPresentationFrame();
		assertClose(0, remote.display.x, "remote water switch invalidates stale presented x");
		assertClose(0, remote.display.y, "remote water switch invalidates stale presented y");
		remote.onParentChange("frontBackground");
		assertEquals(course.characterLayer, remote.parent, "remote front parent returns above blocks");
		assertEquals(false, course.backCharacterLayer.contains(remote), "remote front switch removes the character from the back layer");
		assertEquals(true, course.characterLayer.contains(remote), "remote front switch leaves exactly one front-layer character instance");
		course.removeRemoteCharacter(9);
	}

	private static function testLocalWaterParentLayerSwitch(course:Course):Void {
		var state = course.localCharacter.stateSnapshot();
		var pose = @:privateAccess course.localPresentationPose;
		pose.beginSimulationTick(state.x - 4, state.y - 2, course.localCharacter.characterRotation, 1, CharacterPresentationLayer.Front);
		pose.finishSimulationTick(state.x - 2, state.y - 1, course.localCharacter.characterRotation, 1, CharacterPresentationLayer.Front);
		pose.beginSimulationTick(state.x - 2, state.y - 1, course.localCharacter.characterRotation, 1, CharacterPresentationLayer.Front);
		pose.finishSimulationTick(state.x, state.y, course.localCharacter.characterRotation, 1, CharacterPresentationLayer.Front);
		@:privateAccess course.localPresentationDeltaX = 4;
		@:privateAccess course.localPresentationDeltaY = 2;
		@:privateAccess course.renderLocalPresentationFrame();
		assertEquals(true, course.localCharacter.display.x != 0 || course.localCharacter.display.y != 0,
			"fixture establishes a local presentation offset before a water-layer switch");
		@:privateAccess course.beginLocalPresentationPoseCapture(state);
		@:privateAccess course.localCharacter.controller.touchedBlock = new LevelBlock(0, 0, BlockType.Water);
		@:privateAccess course.finishLocalPresentationPoseCapture(course.localCharacter.stateSnapshot());
		var waterDx = @:privateAccess course.localPresentationDeltaX;
		var waterDy = @:privateAccess course.localPresentationDeltaY;
		course.updatePlayerDisplay();
		assertEquals(course.backCharacterLayer, course.localCharacter.parent, "local water touch moves behind blocks");
		assertEquals(true, pose.discontinuity, "local water-layer transition marks the presentation pose discontinuous");
		assertEquals(false, course.characterLayer.contains(course.localCharacter),
			"local water switch removes the character from the front layer");
		assertEquals(true, course.backCharacterLayer.contains(course.localCharacter),
			"local water switch leaves exactly one back-layer character instance");
		@:privateAccess course.renderLocalPresentationFrame();
		assertClose(waterDx * 0.5, course.localCharacter.display.x,
			"local water switch discards stale x history but preserves the fresh movement prediction");
		assertClose(waterDy * 0.5, course.localCharacter.display.y,
			"local water switch discards stale y history but preserves the fresh movement prediction");

		@:privateAccess course.beginLocalPresentationPoseCapture(course.localCharacter.stateSnapshot());
		@:privateAccess course.localCharacter.controller.touchedBlock = null;
		@:privateAccess course.finishLocalPresentationPoseCapture(course.localCharacter.stateSnapshot());
		course.updatePlayerDisplay();
		assertEquals(course.characterLayer, course.localCharacter.parent, "local non-water touch returns above blocks");
		assertEquals(true, pose.discontinuity, "local return-to-front transition also marks a presentation snap");
		assertEquals(false, course.backCharacterLayer.contains(course.localCharacter),
			"local front switch removes the character from the back layer");
		assertEquals(true, course.characterLayer.contains(course.localCharacter),
			"local front switch leaves exactly one front-layer character instance");
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

	private static function localInit(tempId:Int):LocalCharacterInit {
		return {
			tempId: tempId,
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
			hatColor2: -1,
			headColor2: -1,
			bodyColor2: -1,
			feetColor2: -1,
			group: ""
		};
	}

	private static function buildCourse(gameMode:String = "race"):Course {
		var dataString = "m3`e0c8b8`334;335;11,1;0;12,0;1;0,1;0";
		var level = LevelDecoder.decode(dataString);

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
		var blocks:Array<LevelBlock> = [LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_START1, 0, 0)];
		for (i in 0...120) {
			blocks.push(LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, i * 30, 90));
		}
		var level = Level.fromDecoded(0xFFFFFF, blocks);
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

	private static function localCharacterFeetOnStage(course:Course):Point {
		return course.localCharacter.localToGlobal(new Point());
	}

	private static function assertLocalCharacterFeetAnchored(course:Course, message:String):Void {
		var state = course.localCharacter.stateSnapshot();
		var worldX = state.x;
		var worldY = state.y;
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

	private static function buildRotateCourse():Course {
		var level = Level.fromDecoded(0xFFFFFF, [
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_START1, 60, 90),
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_ROTATE_RIGHT, 60, 30),
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 60, 120),
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_FINISH, 120, 120)
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
