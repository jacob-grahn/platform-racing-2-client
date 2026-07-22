package pr2.gameplay;

import openfl.events.Event;
import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.ui.Keyboard;
import pr2.character.Character;
import pr2.display.Removable;
import pr2.effects.Effect;
import pr2.effects.LaserShotView;
import pr2.effects.Slash;
import pr2.effects.StingEffect;
import pr2.effects.ZapEffect;
import pr2.level.ObjectCodes;
import pr2.level.BlockType;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;
import pr2.level.LevelDecoder;
import pr2.effects.MineAppear;
import pr2.effects.TeleportPop;
import pr2.gameplay.GameCommandShell.GameCommandDelegate;
import pr2.gameplay.GameCommandShell.LocalCharacterInit;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.gameplay.player.BlockVisualEvent;
import pr2.gameplay.player.BlockVisualEvent.BlockVisualEventKind;
import pr2.gameplay.player.LocalPlayerInput;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerLevelData;
import pr2.lobby.account.Settings;
import pr2.runtime.PR2MovieClip;
import pr2.util.TestDisplayUtil as DisplayUtil;

@:access(pr2.gameplay.Course)
@:access(pr2.level.LevelRenderer)
class CharacterLifecycleTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		Settings.disablePersistenceForTests();
		testLocalAndRemoteLifecycle();
		if (pr2.DeterministicTestMode.finishSmokeSuite("CharacterLifecycleTest")) return;
		testFocusLossClearsHeldGameplayInput();
		testCountdownLocksLocalMovement();
		testLocalJumpPlaysSound();
		testRemoteJumpPlaysSound();
		testCharacterEffectSounds();
		testLocalCharacterCommandHandlers();
		testLocalHeartGainUpdatesDeathmatchHud();
		testLocalArrowSparkleEmitterLifecycle();
		testArtifactHatMountsSilentFlashOnlyZapEffect();
		testJetEngineSoundLifecycle();
		testMovementItemNetworkSideEffects();
		testSnakeLifecycleAndNetworking();
		testLocalSwordEmitsSlashEffect();
		testLocalWeaponItemsEmitFlashPayloads();
		testLocalTeleportAndLightningItemEffects();
		testEffectBackgroundAddEffectCommand();
		testLaserStopsOnBlockAndPlaysHitSound();
		testSharedEffectLifecycle();
		testEggVisualRandomization();
		testServerActivateCommandLifecycle();
		testMoveBlockDisplayTracksFixtureCoordinates();
		testLocalBlockActivationNetworking();
		testLocalTeleportBlockEffects();
		testEggRoundCommandLifecycle();
		testMinionEggBlocksSpawnAuthoredEggs();
		testHatReturnToStartLifecycle();
		testLooseHatPhysicsAndPickup();
		trace('CharacterLifecycleTest passed $assertions assertions');
	}

	private static function testLocalAndRemoteLifecycle():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler);
		var shell = new GameCommandShell(new CourseDelegate(course), handler);
		shell.install();

		handler.dispatch("createLocalCharacter", ["7", "80", "70", "60", "101", "102", "103", "104", "2", "3", "4", "5", "201", "202", "203", "204", "g"]);
		assertEquals(7, course.localCharacter.tempID, "local temp id applied");
		assertEquals("g", course.localCharacter.groupStr, "local group applied");
		assertEquals(2, course.localCharacter.hat1, "local hat applied");
		assertEquals(3, course.localCharacter.head, "local head applied");
		assertEquals(4, course.localCharacter.body, "local body applied");
		assertEquals(5, course.localCharacter.feet, "local feet applied");
		assertEquals(80.0, course.localCharacter.stateSnapshot().speedStat, "local speed stat applied");
		assertEquals(70.0, course.localCharacter.stateSnapshot().accelerationStat, "local accel stat applied");
		assertEquals(60.0, course.localCharacter.stateSnapshot().jumpStat, "local jump stat applied");

		var startPos = course.localCharacter.getPos();
		var expectedStartCommand = 'exact_pos`${Math.round(startPos.x)}`${Math.round(startPos.y)}';
		LobbySocket.resetSent();
		handler.dispatch("beginRace", []);
		assertTrue(course.countdown != null, "beginRace mounts countdown");
		assertEquals(false, course.raceStarted, "race waits for countdown finish");
		assertEquals(expectedStartCommand, LobbySocket.sentCommands[0], "beginRace emits starting exact position");
		while (course.countdown != null && course.countdown.parent != null) {
			course.countdown.advance();
		}
		assertEquals(true, course.raceStarted, "countdown finish starts race");
		assertEquals("p`0`0", LobbySocket.lastSent(), "countdown finish initializes local network emission");

		handler.dispatch("createRemoteCharacter", ["9", "Rival", "111", "112", "113", "114", "6", "7", "8", "9", "211", "212", "213", "214", "mod"]);
		var remote = course.getRemoteCharacter(9);
		assertTrue(remote != null, "remote stored by temp id");
		assertEquals(2, course.characterLayer.numChildren, "remote added beside local character");
		assertTrue(remote == course.characterLayer.getChildAt(1), "remote owns display-list slot");
		assertEquals("Rival", remote.userName, "remote name applied");
		assertEquals("mod", remote.groupStr, "remote group applied");
		assertEquals(6, remote.hat1, "remote hat applied");
		assertEquals(7, remote.head, "remote head applied");
		assertTrue(handler.hasCommand("p9"), "remote temp position command registered");

		course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		var arrow = course.levelRenderer.arrowFrameAt(30, 0);
		remote.onBlockTouch(1, 0);
		assertTrue(course.levelRenderer.arrowFrameAt(30, 0) != arrow, "remote block activation adapter wired");

		course.removeRemoteCharacter(9);
		assertEquals(1, course.characterLayer.numChildren, "remote removed from display list");
		assertEquals(null, course.getRemoteCharacter(9), "remote removed from course map");
		assertTrue(!handler.hasCommand("p9"), "remote temp position command removed");

		handler.dispatch("createRemoteCharacter", ["10", "Other", "1", "1", "1", "1", "1", "1", "1", "1", "-1", "-1", "-1", "-1", "0"]);
		assertEquals(1, course.remoteCharacterCount(), "second remote mounted");
		shell.remove();
		assertTrue(!handler.hasCommand("createRemoteCharacter"), "game command shell removed");
		course.remove();
		assertEquals(0, course.remoteCharacterCount(), "course teardown clears remotes");
		assertEquals(null, course.localCharacter, "course teardown clears local character");
	}

	private static function testCountdownLocksLocalMovement():Void {
		var course = buildCourse(new CommandHandler());
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		LobbySocket.resetSent();
		course.beginRace();
		var startX = course.localCharacter.stateSnapshot().x;
		var startY = course.localCharacter.stateSnapshot().y;

		course.setKey(Keyboard.RIGHT, true);
		for (_ in 0...5) {
			course.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(startX, course.localCharacter.stateSnapshot().x, "countdown blocks local horizontal movement");
		assertEquals(startY, course.localCharacter.stateSnapshot().y, "countdown blocks local vertical movement");

		while (course.countdown != null && course.countdown.parent != null) {
			course.countdown.advance();
		}
		assertEquals(true, course.raceStarted, "countdown finish starts race before movement resumes");
		for (_ in 0...10) {
			course.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertTrue(course.localCharacter.stateSnapshot().x > startX, "local movement resumes after countdown");
		course.remove();
	}

	private static function testFocusLossClearsHeldGameplayInput():Void {
		var course = buildCourse(new CommandHandler());
		@:privateAccess course.setKey(Keyboard.RIGHT, true);
		@:privateAccess course.setKey(Keyboard.UP, true);
		@:privateAccess course.setKey(Keyboard.SPACE, true);
		assertTrue(@:privateAccess course.input.right, "right input is held before focus loss");
		assertTrue(@:privateAccess course.input.jump, "jump input is held before focus loss");
		assertTrue(@:privateAccess course.input.item, "item input is held before focus loss");

		@:privateAccess course.resetInput(new Event(Event.DEACTIVATE));
		assertTrue(!@:privateAccess course.input.left, "focus loss clears left");
		assertTrue(!@:privateAccess course.input.right, "focus loss clears right");
		assertTrue(!@:privateAccess course.input.jump, "focus loss clears jump");
		assertTrue(!@:privateAccess course.input.down, "focus loss clears down");
		assertTrue(!@:privateAccess course.input.item, "focus loss clears item");
		course.remove();
	}

	private static function testLocalJumpPlaysSound():Void {
		var course = buildCourse(new CommandHandler());
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		var sounds:Array<String> = [];
		course.onPlayJumpSound = function(x:Float, y:Float):Void {
			sounds.push('${Math.round(x)},${Math.round(y)}');
		}
		var start = course.localCharacter.getPos();
		course.localCharacter.velY = 0;
		course.localCharacter.changeState("stand");
		course.localCharacter.changeState("jump");
		assertEquals(1, sounds.length, "entering local jump state plays the local jump sound");
		assertEquals(
			'${Math.round(start.x)},${Math.round(start.y)}',
			sounds[0],
			"jump sound uses the local character world position"
		);
		course.localCharacter.changeState("jump");
		assertEquals(1, sounds.length, "holding jump does not retrigger the sound every frame");
		course.remove();
	}

	private static function testRemoteJumpPlaysSound():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler);
		var shell = new GameCommandShell(new CourseDelegate(course), handler);
		shell.install();
		var sounds:Array<String> = [];
		course.onPlayJumpSound = function(x:Float, y:Float):Void {
			sounds.push('${Math.round(x)},${Math.round(y)}');
		};

		handler.dispatch("createRemoteCharacter", ["9", "Rival", "1", "1", "1", "1", "1", "1", "1", "1", "-1", "-1", "-1", "-1", "0"]);
		var remote = course.getRemoteCharacter(9);
		remote.velY = 0;
		remote.setPos(44, 55);
		remote.changeState("jump");
		remote.changeState("jump");
		remote.changeState("stand");
		remote.velY = 12;
		remote.changeState("jump");

		assertEquals("44,55", sounds.join("|"), "remote jump state plays Flash JumpSound once at the remote world position");
		shell.remove();
		course.remove();
	}

	private static function testLocalBlockActivationNetworking():Void {
		var course = buildCourse(new CommandHandler());
		var event = new BlockVisualEvent(BlockVisualEventKind.LocalActivate, 6, 7, 1, null, null, 0, -15, "left");
		var expectedSegX = 6;
		var expectedSegY = 7;

		LobbySocket.resetSent();
		course.emitLocalBlockActivation(event);
		assertEquals('activate`$expectedSegX`$expectedSegY`left', LobbySocket.lastSent(),
			"local block activation emits Flash activate command with server segments and payload");
		course.remove();
	}

	private static function testLocalTeleportBlockEffects():Void {
		var course = buildCourse(new CommandHandler());
		var startX = 135.0;
		var startY = 95.0;
		var destX = 195.0;
		var destY = 95.0;
		var expectedStartX = Std.int(Math.round(startX));
		var expectedStartY = Std.int(Math.round(startY));
		var expectedDestX = Std.int(Math.round(destX));
		var expectedDestY = Std.int(Math.round(destY));

		var initialChildren = course.levelRenderer.blockLayer.numChildren;
		LobbySocket.resetSent();
		course.emitLocalTeleportPop(new BlockVisualEvent(BlockVisualEventKind.TeleportBlockPop, 0, 0, 1, null, null, startX, startY));
		course.emitLocalTeleportPop(new BlockVisualEvent(BlockVisualEventKind.TeleportBlockPop, 0, 0, 1, null, null, destX, destY));

		assertEquals(initialChildren + 2, course.levelRenderer.blockLayer.numChildren,
			"local teleport block mounts start and destination TeleportPop visuals");
		assertTrue(Std.downcast(course.levelRenderer.blockLayer.getChildAt(initialChildren), TeleportPop) != null,
			"local teleport block start visual uses TeleportPop");
		assertTrue(Std.downcast(course.levelRenderer.blockLayer.getChildAt(initialChildren + 1), TeleportPop) != null,
			"local teleport block destination visual uses TeleportPop");
		assertEquals(2, LobbySocket.sentCommands.length, "local teleport block emits two Flash add_effect commands");
		assertEquals('add_effect`Teleport`$expectedStartX`$expectedStartY|add_effect`Teleport`$expectedDestX`$expectedDestY', LobbySocket.sentCommands.join("|"),
			"local teleport block emits start and destination world pop positions");
		course.remove();
	}

	private static function testArtifactHatMountsSilentFlashOnlyZapEffect():Void {
		var course = buildCourse(new CommandHandler());
		var initialChildren = course.characterLayer.numChildren;
		var oldMusicLevel = Settings.musicLevel;
		Settings.setValue(Settings.MUSIC_VOLUME, 0);

		course.localCharacter.setHats([14, 0xFFFFFF, -1]);

		assertEquals(initialChildren + 1, course.characterLayer.numChildren, "artifact activation mounts one zap effect");
		var zap = Std.downcast(course.characterLayer.getChildAt(course.characterLayer.numChildren - 1), ZapEffect);
		assertTrue(zap != null, "artifact activation mounts a zap effect");
		assertEquals(false, zap.hasTimelineChild("lightning"), "artifact zap hides the bolt");
		assertEquals(true, zap.hasTimelineChild("bg"), "artifact zap keeps the blue flash");

		course.localCharacter.x += 12;
		course.localCharacter.y += 7;
		zap.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(course.localCharacter.x, zap.x, "artifact zap follows the local character x");
		assertEquals(course.localCharacter.y, zap.y, "artifact zap follows the local character y");
		for (_ in 0...10) {
			zap.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertTrue(zap.parent == null, "artifact zap removes itself after fading out");

		Settings.setValue(Settings.MUSIC_VOLUME, oldMusicLevel);
		course.remove();
	}

	private static function testCharacterEffectSounds():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler);
		var shell = new GameCommandShell(new CourseDelegate(course), handler);
		shell.install();
		var sounds:Array<String> = [];
		course.onPlayCharacterSound = function(request):Void {
			sounds.push(request.kind + ":" + request.volume + ":" + Math.round(request.x) + ":" + Math.round(request.y));
		};

		course.localCharacter.beginSparklesNetwork();
		course.localCharacter.endSparkles(true);
		handler.dispatch("createRemoteCharacter", ["9", "Rival", "1", "1", "1", "1", "1", "1", "1", "1", "-1", "-1", "-1", "-1", "0"]);
		handler.dispatch("heart9", []);

		assertEquals("speedUp:1:15:15|slowDown:1:15:15|bumpHappy:0.75:15:15", sounds.join("|"),
			"Course routes local and remote character effect sounds through spatial playback");
		shell.remove();
		course.remove();
	}

	private static function testLocalCharacterCommandHandlers():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler);
		course.createLocalCharacter(localInit(4));
		var remote = course.createRemoteCharacter(remoteInit(9));
		remote.setPos(course.localCharacter.x - 20, course.localCharacter.y);
		var sounds:Array<String> = [];
		course.onPlayCharacterSound = function(request):Void {
			sounds.push(request.kind + ":" + request.volume);
		};

		assertTrue(handler.hasCommand("zap"), "local character registers zap command");
		assertTrue(handler.hasCommand("setHats4"), "local character keeps local setHats command");
		assertTrue(handler.hasCommand("squash4"), "local character registers squash command");
		assertTrue(handler.hasCommand("sting4"), "local character registers sting command");

		handler.dispatch("squash4", []);
		assertEquals("crouch", course.localCharacter.state, "incoming squash command crouches local character");
		assertEquals("squash:0.66", sounds.join("|"), "incoming squash command plays squash sound");

		var stingChild = course.characterLayer.numChildren;
		handler.dispatch("sting4", ["9"]);
		var sting = Std.downcast(course.characterLayer.getChildAt(stingChild), StingEffect);
		assertTrue(sting != null, "incoming sting command mounts StingEffect");
		assertEquals(true, sting.hasTimelineChild("leftSting"), "sting from the left keeps left graphic");
		assertEquals(false, sting.hasTimelineChild("rightSting"), "sting from the left removes right graphic");
		assertEquals("hurt", course.localCharacter.stateSnapshot().mode, "incoming sting command hurts vulnerable local player");
		course.localCharacter.setPos(123, 234);
		sting.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(123.0, sting.x, "sting follows owner x each frame");
		assertEquals(234.0, sting.y, "sting follows owner y each frame");
		assertEquals(0.95, sting.alpha, "sting fades by Flash alpha delta");
		for (_ in 0...19) {
			sting.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(null, sting.parent, "sting removes after fading out");

		var zapChild = course.characterLayer.numChildren;
		handler.dispatch("zap", ["9"]);
		assertEquals(zapChild + 2, course.characterLayer.numChildren, "incoming zap mounts one bolt effect and one local flash effect");
		assertTrue(Std.downcast(course.characterLayer.getChildAt(zapChild), ZapEffect) != null, "incoming zap mounts bolt-only effect");
		assertTrue(Std.downcast(course.characterLayer.getChildAt(zapChild + 1), ZapEffect) != null, "incoming zap mounts local flash effect");

		course.remove();
		assertTrue(!handler.hasCommand("zap"), "course teardown unregisters zap command");
		assertTrue(!handler.hasCommand("setHats4"), "course teardown unregisters local setHats command");
		assertTrue(!handler.hasCommand("squash4"), "course teardown unregisters squash command");
		assertTrue(!handler.hasCommand("sting4"), "course teardown unregisters sting command");
	}

	private static function testLocalHeartGainUpdatesDeathmatchHud():Void {
		var course = buildCourse(new CommandHandler(), "deathmatch");
		LobbySocket.resetSent();

		course.localCharacter.gainHeart();
		@:privateAccess course.syncHearts(course.localCharacter.stateSnapshot());

		assertEquals(4, course.localCharacter.stateSnapshot().lives, "local heart gain increments deathmatch lives");
		assertEquals(4, course.hearts.getHeartCount(), "local heart gain updates deathmatch HUD hearts");
		assertEquals("heart`", LobbySocket.lastSent(), "local heart gain emits Flash heart payload");
		course.remove();
	}

	private static function testLocalArrowSparkleEmitterLifecycle():Void {
		var course = buildCourse(new CommandHandler());

		course.localCharacter.beginSparkles();
		assertEquals(1, course.activeParticleEmitterCount(), "local sparkles create a concrete star particle emitter");
		course.localCharacter.endSparkles();
		assertEquals(0, course.activeParticleEmitterCount(), "ending sparkles clears the concrete star particle emitter");
		course.localCharacter.gainHeart();
		assertEquals(1, course.activeParticleEmitterCount(), "local heart recovery creates a concrete rainbow-star emitter");
		course.localCharacter.endSparkles();
		assertEquals(0, course.activeParticleEmitterCount(), "ending sparkles clears the concrete rainbow-star emitter");
		course.localCharacter.beginArrowSparkles();
		assertEquals(1, course.activeParticleEmitterCount(), "local arrow sparkles create a concrete particle emitter");
		course.localCharacter.endSparkles();
		assertEquals(0, course.activeParticleEmitterCount(), "ending sparkles clears the concrete particle emitter");
		course.localCharacter.setBodyId(35);
		assertEquals(1, course.activeDjinnEmitterCount(), "Frost Djinn body starts a positioned particle emitter");
		course.localCharacter.setFeetId(35);
		assertEquals(3, course.activeDjinnEmitterCount(), "Frost Djinn feet start separate positioned particle emitters");
		course.remove();
	}

	private static function testJetEngineSoundLifecycle():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler);
		var shell = new GameCommandShell(new CourseDelegate(course), handler);
		shell.install();
		var starts:Array<String> = [];
		var stops:Array<Int> = [];
		course.onStartJetSound = function(request):Void {
			starts.push(request.kind + ":" + request.volume + ":" + request.target.tempID + ":" + Math.round(request.x) + ":" + Math.round(request.y));
		};
		course.onStopJetSound = function(character):Void {
			stops.push(character.tempID);
		};

		course.localCharacter.tempID = 7;
		course.localCharacter.beginJetNetwork();
		course.localCharacter.endJetNetwork();
		handler.dispatch("createRemoteCharacter", ["9", "Rival", "1", "1", "1", "1", "1", "1", "1", "1", "-1", "-1", "-1", "-1", "0"]);
		var remote = course.getRemoteCharacter(9);
		remote.x = 44;
		remote.y = 55;
		remote.beginJet();
		course.remove();

		assertEquals("engine:0.6:7:15:15|engine:0.6:9:44:55", starts.join("|"),
			"Course routes local and remote Jet Pack EngineSound start requests");
		assertEquals("7,9", [for (id in stops) Std.string(id)].join(","), "endJet and Course teardown stop active EngineSound loops");
		shell.remove();
	}

	private static function testMovementItemNetworkSideEffects():Void {
		var jet = collectAndUseLocalItem(6);
		assertEquals("set_var`jet`1", LobbySocket.lastSent(), "Jet Pack item press starts the Flash jet var");
		LobbySocket.resetSent();
		jet.onEnterFrame(new Event(Event.ENTER_FRAME));
		assertEquals("set_var`jet`0", LobbySocket.lastSent(), "Jet Pack item release stops the Flash jet var");
		jet.remove();

		var speed = collectAndUseLocalItem(7);
		assertEquals("set_var`sparkle`1", LobbySocket.lastSent(), "Speed Burst item starts the Flash sparkle var");
		assertEquals(1, speed.activeParticleEmitterCount(), "Speed Burst item mounts local sparkles");
		LobbySocket.resetSent();
		for (_ in 0...135) {
			speed.onEnterFrame(new Event(Event.ENTER_FRAME));
		}
		assertTrue(LobbySocket.sentCommands.indexOf("set_var`sparkle`0") != -1, "Speed Burst expiry stops the Flash sparkle var");
		assertEquals(0, speed.activeParticleEmitterCount(), "Speed Burst expiry clears local sparkles");
		speed.remove();
	}

	private static function testSnakeLifecycleAndNetworking():Void {
		assertEquals(135, SnakeManager.USE_FRAMES, "Snake has five seconds of use at 27 FPS");
		assertEquals(135, SnakeManager.TRAIL_FRAMES, "Snake trails remain five seconds behind the head");
		var course = collectAndUseLocalItem(Items.SNAKE);
		assertTrue(course.snakeManager.localActive(), "Snake item press starts a local snake");
		assertTrue(course.snakeManager.localSpriteIsEmpty(), "the in-use Snake controller sprite has no visual children");
		assertEquals(1, course.snakeManager.trailCount(), "Snake starts as an eyed Snake block in the adjacent tile");
		var firstHead = course.snakeManager.localHeadTile();
		assertTrue(course.snakeManager.trailHasEyes(firstHead.x, firstHead.y), "the newest Snake block is the head and has eyes");
		assertTrue(LobbySocket.sentCommands.join("|").indexOf("add_effect`SnakeStart`") >= 0,
			"Snake start uses the existing add_effect relay");
		assertEquals(null, course.localCharacter.stateSnapshot().itemId, "starting Snake consumes the held item");

		var playerFacing = course.localCharacter.facingScaleX;
		var cameraTargetBeforeMove = course.snakeManager.localHeadWorld();
		course.setKey(playerFacing < 0 ? Keyboard.RIGHT : Keyboard.LEFT, true);
		course.onEnterFrame(new Event(Event.ENTER_FRAME));
		assertEquals(playerFacing, course.localCharacter.facingScaleX, "arrow keys steer Snake without steering the player");
		var cameraTargetDuringMove = course.snakeManager.localHeadWorld();
		assertTrue(cameraTargetDuringMove.x != cameraTargetBeforeMove.x || cameraTargetDuringMove.y != cameraTargetBeforeMove.y,
			"the empty Snake sprite moves smoothly every frame for camera follow");
		assertEquals(1, course.snakeManager.trailCount(), "moving between tile centers does not run a block-entry check early");
		for (_ in 0...SnakeManager.MOVE_FRAMES_PER_TILE) course.onEnterFrame(new Event(Event.ENTER_FRAME));
		assertEquals(2, course.snakeManager.trailCount(), "entering the next tile adds a new Snake block and leaves the old block as trail");
		var secondHead = course.snakeManager.localHeadTile();
		assertTrue(!course.snakeManager.trailHasEyes(firstHead.x, firstHead.y), "the previous head loses its eyes after the Snake enters a new tile");
		assertTrue(course.snakeManager.trailHasEyes(secondHead.x, secondHead.y), "the most recent Snake block receives the head eyes");
		assertTrue(LobbySocket.sentCommands.join("|").indexOf("add_effect`SnakeStep`") >= 0,
			"Snake movement sends authoritative tile steps");

		course.setKey(Keyboard.SPACE, false);
		course.onEnterFrame(new Event(Event.ENTER_FRAME));
		assertTrue(course.snakeManager.localActive(), "releasing Space leaves the launched snake running");
		for (_ in 0...SnakeManager.USE_FRAMES) {
			if (!course.snakeManager.localActive()) break;
			course.onEnterFrame(new Event(Event.ENTER_FRAME));
		}
		assertTrue(!course.snakeManager.localActive(), "Snake runs until its timeout or collision end condition");
		assertTrue(LobbySocket.sentCommands.join("|").indexOf("add_effect`SnakeStop`") >= 0,
			"Snake end relays a stop event");

		var worldX = 2;
		var worldY = 2;
		course.applySnakeNetwork(["SnakeStart", "8", "0", Std.string(worldX), Std.string(worldY), "1", "0"]);
		assertEquals(1, course.snakeManager.activeSnakeCount(), "remote SnakeStart mounts a remote head");
		course.applySnakeNetwork(["SnakeStep", "8", "1", Std.string(worldX + 1), Std.string(worldY), "1", "0"]);
		assertTrue(course.snakeManager.hasTrail(2, 2), "remote SnakeStep reconstructs its vacated trail tile");
		var trailCount = course.snakeManager.trailCount();
		course.applySnakeNetwork(["SnakeStep", "8", "1", Std.string(worldX + 2), Std.string(worldY), "1", "0"]);
		assertEquals(trailCount, course.snakeManager.trailCount(), "duplicate SnakeStep sequence is ignored");
		course.applySnakeNetwork(["SnakeStop", "8", "2"]);
		assertEquals(0, course.snakeManager.activeSnakeCount(), "remote SnakeStop removes its head but leaves timed trails");
		for (_ in 0...SnakeManager.TRAIL_FRAMES) course.snakeManager.step();
		assertEquals(0, course.snakeManager.trailCount(), "Snake trails expire after five seconds");
		course.remove();
	}

	private static function testLocalSwordEmitsSlashEffect():Void {
		var course = buildCourse(new CommandHandler(), "race", "m4`ffffff`2;5;11,0;-2;10;8,0;3;0,1;0;0,1;0;0,1;0;0");
		finishDrawing(course);
		course.beginRace();
		finishCountdown(course);
		course.setKey(Keyboard.UP, true);
		for (_ in 0...40) {
			course.onEnterFrame(new Event(Event.ENTER_FRAME));
			if (course.localCharacter.stateSnapshot().itemId == 8) break;
		}
		course.setKey(Keyboard.UP, false);
		assertEquals(8, course.localCharacter.stateSnapshot().itemId, "local player collects sword");

		LobbySocket.resetSent();
		course.onEnterFrame(new Event(Event.ENTER_FRAME));
		course.setKey(Keyboard.SPACE, true);
		var effectChildren = course.effectBackground.numChildren;
		course.onEnterFrame(new Event(Event.ENTER_FRAME));

		assertTrue(LobbySocket.lastSent().indexOf("add_effect`Slash`") == 0, "sword emits Slash effect command");
		assertTrue(LobbySocket.lastSent().indexOf("`right`0") > 0, "sword Slash payload includes direction and temp id");
		assertEquals(effectChildren + 1, course.effectBackground.numChildren, "sword mounts the authored Slash effect");
		assertTrue(Std.downcast(course.effectBackground.getChildAt(effectChildren), Slash) != null, "sword uses concrete Slash effect");
		course.setKey(Keyboard.SPACE, false);
		course.remove();
	}

	private static function testLocalWeaponItemsEmitFlashPayloads():Void {
		var laser = collectAndUseLocalItem(1);
		assertTrue(LobbySocket.lastSent().indexOf("add_effect`Laser`") == 0, "laser emits Flash add_effect payload");
		assertTrue(LobbySocket.lastSent().indexOf("`right`0`0") > 0, "laser payload includes direction, rotation, and temp id");
		assertEquals(1, laser.eggRound.activeAttackVisualCount(), "laser mounts the authored local shot visual");
		var laserClip = Std.downcast(laser.effectBackground.getChildAt(laser.effectBackground.numChildren - 1), LaserShotView);
		assertTrue(laserClip != null, "local laser item uses the native laser visual");
		assertEquals(2, laserClip.currentFrame, "local laser item starts stopped on idle frame 2");
		assertTrue(laserClip.getChildByName(LaserShotView.TRAVEL_BEAM_NAME) != null,
			"local laser item has a guaranteed visible travel beam");
		assertEquals("assets/effects/laser.lottie.json", laserClip.timeline.sourcePath, "laser travel uses semantic Lottie data");
		assertEquals(2, laserClip.currentFrame, "laser travel uses authored stop frame");
		var laserCameraOffset = laser.levelRenderer.cameraOffset();
		assertEquals(laserCameraOffset.x, laser.effectBackground.transform.matrix.tx,
			"attack effect layer follows the editor/world camera x offset");
		assertEquals(laserCameraOffset.y, laser.effectBackground.transform.matrix.ty,
			"attack effect layer follows the editor/world camera y offset");
		laserClip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(2, laserClip.currentFrame, "local laser item does not auto-play while idle");
		laserClip.playHit();
		for (_ in 0...20) {
			laserClip.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(18, laserClip.currentFrame, "laser impact reaches exact authored stop frame");
		assertEquals(18, laserClip.currentFrame, "local laser item hit animation stops on authored frame 18");
		laser.remove();

		var ice = collectAndUseLocalItem(9);
		assertTrue(LobbySocket.lastSent().indexOf("add_effect`IceWave`") == 0, "ice wave emits Flash add_effect payload");
		assertTrue(LobbySocket.lastSent().indexOf("`0`0`0") > 0, "ice wave payload includes angle, rotation, and temp id");
		assertEquals(3, ice.eggRound.activeAttackVisualCount(), "ice wave mounts the three authored local wave visuals");
		var firstIce = Std.downcast(ice.effectBackground.getChildAt(ice.effectBackground.numChildren - 3), Sprite);
		var secondIce = Std.downcast(ice.effectBackground.getChildAt(ice.effectBackground.numChildren - 2), Sprite);
		var thirdIce = Std.downcast(ice.effectBackground.getChildAt(ice.effectBackground.numChildren - 1), Sprite);
		assertTrue(firstIce != null && secondIce != null && thirdIce != null, "local ice wave item uses native visuals");
		assertTrue(firstIce.getChildByName("iceWaveCore") != null && secondIce.getChildByName("iceWaveCore") != null
			&& thirdIce.getChildByName("iceWaveCore") != null, "local ice wave shots have visible beam cores");
		assertEquals(0.0, firstIce.rotation, "local ice wave item centers the first wave");
		assertEquals(30.0, secondIce.rotation, "local ice wave item angles the second wave up");
		assertEquals(-30.0, thirdIce.rotation, "local ice wave item angles the third wave down");
		ice.remove();

		var mine = collectAndUseLocalItem(2);
		var mineEffect = Std.downcast(mine.levelRenderer.blockLayer.getChildAt(mine.levelRenderer.blockLayer.numChildren - 1), MineAppear);
		assertTrue(mineEffect != null, "local mine mounts its placement animation");
		var mineParts = mine.localCharacter.stateSnapshot().lastItemEffect.split(":");
		var mineWorldCoords = mineParts[1].split(",");
		assertEquals(Std.parseFloat(mineWorldCoords[0]), mineEffect.x,
			"local mine uses authored world x");
		assertEquals(Std.parseFloat(mineWorldCoords[1]), mineEffect.y,
			"local mine uses authored world y");
		mine.remove();
	}

	private static function testLocalTeleportAndLightningItemEffects():Void {
		var teleport = collectAndUseLocalItem(4);
		var teleportCommands = [for (command in LobbySocket.sentCommands) if (command.indexOf("add_effect`Teleport`") == 0) command];
		assertEquals(2, teleportCommands.length, "teleport item emits start and destination add_effect payloads");
		assertTrue(teleportCommands[0].indexOf("add_effect`Teleport`") == 0, "teleport start payload uses Flash command");
		assertTrue(teleportCommands[1].indexOf("add_effect`Teleport`") == 0, "teleport destination payload uses Flash command");
		assertTrue(Std.downcast(teleport.levelRenderer.blockLayer.getChildAt(teleport.levelRenderer.blockLayer.numChildren - 2), TeleportPop) != null,
			"teleport item mounts the start TeleportPop");
		assertTrue(Std.downcast(teleport.levelRenderer.blockLayer.getChildAt(teleport.levelRenderer.blockLayer.numChildren - 1), TeleportPop) != null,
			"teleport item mounts the destination TeleportPop");
		teleport.remove();

		var lightning = collectAndUseLocalItem(3);
		assertEquals("zap`", LobbySocket.lastSent(), "lightning item emits Flash zap command");
		assertTrue(Std.downcast(lightning.characterLayer.getChildAt(lightning.characterLayer.numChildren - 1), ZapEffect) != null,
			"lightning item mounts a local ZapEffect");
		lightning.remove();
	}

	private static function testEggRoundCommandLifecycle():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler, "egg");
		var shell = new GameCommandShell(new CourseDelegate(course), handler);
		shell.install();

		LobbySocket.resetSent();
		handler.dispatch("setEggSeed", ["777"]);
		handler.dispatch("addEggs", ["2"]);
		assertEquals(2, course.eggRound.count(), "egg mode spawns requested eggs");
		assertEquals(1, course.eggRound.ids()[0], "egg ids start at one");
		assertEquals(2, course.eggRound.ids()[1], "egg ids increment");
		assertTrue(handler.hasCommand("removeEgg1"), "first egg remote remove command registered");
		assertTrue(handler.hasCommand("removeEgg2"), "second egg remote remove command registered");
		assertEquals(3, course.eggRound.currentMode(), "seeded mode clamps Flash random value");
		var first = course.eggRound.egg(1);
		assertTrue(first != null, "first egg state stored");
		assertEquals(2, course.effectBackground.numChildren, "egg graphics mount on the Flash effect layer");
		assertTrue(first.display.parent == course.effectBackground, "egg graphic is added to the effect layer");
		assertEquals(first.x, Std.int(first.display.x), "egg graphic uses seeded x");
		assertEquals(first.y, Std.int(first.display.y), "egg graphic uses seeded y");
		assertEquals(first.rot, Std.int(first.display.rotation), "egg graphic uses seeded rotation");
		for (_ in 0...24) {
			first.display.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		}
		assertEquals(1, first.display.currentFrame, "egg walk animation loops from frame 25 back to walk label");

		assertEquals(true, course.eggRound.collectEgg(1), "collecting active egg succeeds");
		assertEquals("grab_egg`1", LobbySocket.lastSent(), "collecting egg emits grab_egg");
		assertEquals(2, course.eggRound.count(), "collected egg remains during squash animation");
		assertTrue(first.removing, "collected egg enters squash removal state");
		assertEquals(30, first.display.currentFrame, "collected egg starts authored squash animation");
		assertTrue(first.display.parent == course.effectBackground, "collected egg graphic remains during squash animation");
		assertTrue(handler.hasCommand("removeEgg1"), "collected egg keeps remote remove command during squash animation");
		assertEquals(false, course.eggRound.collectEgg(1), "squashing egg cannot be collected twice");
		for (_ in 0...16) {
			first.display.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		}
		assertEquals(46, first.display.currentFrame, "egg squash animation reaches authored stop frame");
		first.display.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		assertEquals(46, first.display.currentFrame, "egg squash animation stays stopped on frame 46");
		var lifecycleLevel = LevelDecoder.decode("m3`ffffff`0;0;11,1;0;8,0;1;0");
		for (_ in 0...26) {
			course.eggRound.step(lifecycleLevel);
		}
		assertTrue(first.display.parent == course.effectBackground, "squash animation persists before Flash timeout");
		course.eggRound.step(lifecycleLevel);
		assertEquals(1, course.eggRound.count(), "collected egg removed after squash timeout");
		assertTrue(first.display.parent == null, "squashed egg graphic removed");
		assertTrue(!handler.hasCommand("removeEgg1"), "squashed egg unregisters remote remove");

		var second = course.eggRound.egg(2);
		assertEquals(true, handler.dispatch("removeEgg2", []), "remote remove command dispatches");
		assertEquals(0, course.eggRound.count(), "remote remove clears egg");
		assertTrue(second.display.parent == null, "remote remove clears egg graphic");
		assertTrue(!handler.hasCommand("removeEgg2"), "remote remove unregisters itself");

		handler.dispatch("addEggs", ["1"]);
		assertEquals(1, course.eggRound.count(), "egg mode can spawn after remote remove");
		var third = course.eggRound.egg(3);
		course.remove();
		assertTrue(third.display.parent == null, "course teardown removes egg graphic");
		assertTrue(!handler.hasCommand("removeEgg3"), "course teardown unregisters remaining egg");
		shell.remove();

		var raceCourse = buildCourse(new CommandHandler(), "race");
		raceCourse.addEggs(3);
		assertEquals(0, raceCourse.eggRound.count(), "non-egg game mode ignores addEggs");
		raceCourse.remove();

		var soundPositions:Array<String> = [];
		var soundRound = new EggRound(new CommandHandler(), function(_):Void {}, null, null, function(x:Int, y:Int):Void {
			soundPositions.push('$x,$y');
		});
		soundRound.initRound(777);
		soundRound.addEggs(1, LevelDecoder.decode("m3`ffffff`0;0;11,1;0;8,0;1;0"));
		var soundEgg = soundRound.egg(1);
		assertTrue(soundEgg != null, "sound test egg spawned");
		assertEquals(true, soundRound.collectEgg(1), "sound test egg collects");
		assertEquals('${soundEgg.x},${soundEgg.y}', soundPositions[0], "collecting an egg plays its collection sound at the egg position");

		var physicsRound = new EggRound(new CommandHandler(), function(_):Void {}, null, null, function(_, _):Void {});
		var physicsLevel = Level.fromDecoded(0xffffff, [
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 0, 0),
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 30, -30)
		]);
		physicsRound.initRound(777);
		physicsRound.addEggs(1, physicsLevel);
		var physicsEgg = physicsRound.egg(1);
		assertTrue(physicsEgg != null, "physics test egg spawned");
		physicsEgg.posX = 15;
		physicsEgg.posY = -20;
		physicsEgg.velX = 0;
		physicsEgg.velY = 0;
		physicsRound.step(physicsLevel);
		assertEquals(-19, Std.int(physicsEgg.posY), "egg gravity advances vertical position before landing");
		assertTrue(physicsEgg.display.alpha > 0, "egg fades in during movement step");

		physicsEgg.posX = 15;
		physicsEgg.posY = -1;
		physicsEgg.velY = 1;
		physicsRound.step(physicsLevel);
		assertEquals(0, Std.int(physicsEgg.posY), "egg lands on active block top");
		assertEquals(0, Std.int(physicsEgg.velY), "egg landing clears falling velocity");
		assertTrue(physicsEgg.grounded, "egg landing sets grounded state");

		physicsEgg.posX = 29;
		physicsEgg.posY = 0;
		physicsEgg.velX = 1;
		physicsEgg.velY = 0;
		physicsEgg.grounded = true;
		physicsRound.step(physicsLevel);
		assertEquals(-1, Std.int(physicsEgg.velX), "grounded egg reverses on wall touch");
		assertEquals(29, Std.int(physicsEgg.posX), "wall touch snaps egg beside block");

		physicsEgg.posX = 331;
		physicsEgg.posY = 0;
		physicsEgg.velX = 0;
		physicsEgg.velY = 0;
		physicsRound.step(physicsLevel);
		assertEquals(-300, Std.int(physicsEgg.posX), "egg wraps past level movement max x");

		var collectedIds:Array<Int> = [];
		var touchRound = new EggRound(new CommandHandler(), function(id):Void {
			collectedIds.push(id);
		}, null, null, function(_, _):Void {});
		touchRound.initRound(777);
		touchRound.addEggs(1, physicsLevel);
		var touchEgg = touchRound.egg(1);
		touchEgg.posX = 10;
		touchEgg.posY = 10;
		touchEgg.velX = 0;
		touchEgg.velY = 0;
		touchRound.step(physicsLevel, 0, 10, 20, false, false);
		assertEquals(1, touchRound.count(), "egg movement step starts squash removal near local player");
		assertTrue(touchEgg.removing, "touch-collected egg enters squash removal state");
		assertEquals(1, collectedIds[0], "egg movement step emits collected egg id");
		for (_ in 0...27) {
			touchRound.step(physicsLevel);
		}
		assertEquals(0, touchRound.count(), "touch-collected egg is removed after squash timeout");

		var attackRound = new EggRound(new CommandHandler(), function(_):Void {}, null, null, function(_, _):Void {});
		attackRound.initRound(18);
		assertEquals(0, attackRound.currentMode(), "attack test seed selects ice mode");
		attackRound.addEggs(1, Level.fromDecoded(0xffffff, []));
		var attackEgg = attackRound.egg(1);
		assertTrue(attackEgg != null, "attack test egg spawned");
		attackEgg.posX = 100;
		attackEgg.posY = 100;
		attackEgg.velX = 0;
		attackEgg.velY = 0;
		LobbySocket.resetSent();
		attackRound.step(Level.fromDecoded(0xffffff, []), 0, 150, 120, false, false);
		assertEquals("add_effect`IceWave`100`90`180`0`-1", LobbySocket.lastSent(), "egg attack emits Flash add_effect payload");
		assertEquals(120, attackEgg.attackCooldown, "egg attack starts Flash cooldown");
		attackRound.step(Level.fromDecoded(0xffffff, []), 0, 150, 120, false, false);
		assertEquals(1, LobbySocket.sentCommands.length, "egg attack cooldown suppresses repeat emission");
		assertEquals(119, attackEgg.attackCooldown, "egg attack cooldown ticks down each frame");

		assertEggAttackVisual(14, "IceWave", 3, "ice wave attacks mount three authored shot graphics");
		assertEggAttackVisual(1, "Slash", 1, "slash attacks mount the authored slash animation");
		assertEggAttackVisual(9, "Laser", 1, "laser attacks mount the authored laser shot graphic");
	}

	private static function testEffectBackgroundAddEffectCommand():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler, "race");
		assertTrue(handler.hasCommand("addEffect"), "course registers EffectBackground addEffect command");
		assertTrue(course.effectBackground.parent != null && course.effectBackground.parent != course,
			"effect background is mounted in the renderer's rotating world");

		var characterChildren = course.characterLayer.numChildren;
		var effectChildren = course.effectBackground.numChildren;
		handler.dispatch("addEffect", ["Slash", "100", "90", "left", "5"]);
		assertEquals(effectChildren + 1, course.effectBackground.numChildren, "remote slash mounts an effect visual");
		assertTrue(Std.downcast(course.effectBackground.getChildAt(effectChildren), Slash) != null, "remote slash uses concrete Slash");
		assertEquals(characterChildren, course.characterLayer.numChildren, "remote slash no longer mounts the old character-layer placeholder");

		handler.dispatch("addEffect", ["Laser", "100", "90", "right", "0", "6"]);
		assertEquals(1, course.eggRound.activeAttackVisualCount(), "remote laser mounts an attack visual");
		var laser = Std.downcast(course.effectBackground.getChildAt(course.effectBackground.numChildren - 1), LaserShotView);
		assertTrue(laser != null, "remote laser uses the native laser visual");
		assertEquals(2, laser.currentFrame, "remote laser starts on the stopped idle frame");
		assertTrue(laser.getBounds(laser).width > 1, "remote laser travel frame has visible authored artwork");

		var iceWaveSounds:Array<String> = [];
		course.effectBackground.remove();
		course.effectBackground = new EffectBackground(course, handler, function(x:Int, y:Int):Void {
			iceWaveSounds.push('$x,$y');
		});
		handler.dispatch("addEffect", ["IceWave", "120", "80", "180", "0", "7"]);
		assertEquals(4, course.eggRound.activeAttackVisualCount(), "remote ice wave fans out three shot visuals");
		assertEquals("120,80", iceWaveSounds[0], "remote ice wave plays its world-position sound");

		var blockChildren = course.levelRenderer.blockLayer.numChildren;
		handler.dispatch("addEffect", ["Mine", "975", "975", "90"]);
		assertEquals(blockChildren + 1, course.levelRenderer.blockLayer.numChildren, "remote mine mounts MineAppear on the block layer");
		var mineAppear = Std.downcast(course.levelRenderer.blockLayer.getChildAt(blockChildren), MineAppear);
		assertTrue(mineAppear != null, "remote mine uses MineAppear");
		for (_ in 0...33) {
			mineAppear.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(BlockType.Mine, @:privateAccess course.level.blockAt(32, 32).type,
			"remote MineAppear completion adds the mine to the live gameplay map");
		assertEquals(ObjectCodes.BLOCK_MINE, BlockCollision.blockFromPos(@:privateAccess course.level, 960, 960, 0).code,
			"remote MineAppear completion adds the mine to the effect collision map");

		handler.dispatch("addEffect", ["Teleport", "90", "60", "0"]);
		assertEquals(blockChildren + 1, course.levelRenderer.blockLayer.numChildren, "remote teleport mounts TeleportPop on the block layer");
		assertTrue(Std.downcast(course.levelRenderer.blockLayer.getChildAt(blockChildren), TeleportPop) != null,
			"remote teleport uses TeleportPop");

		handler.dispatch("addEffect", ["Hat", "40", "50", "90", "5", "1193046", "-1", "3"]);
		var hat = course.looseHats.get(3);
		assertTrue(hat != null, "remote hat creates a loose hat");
		assertEquals(5, hat.num, "remote hat preserves hat id");
		assertEquals(0x123456, hat.color, "remote hat preserves primary color");
		assertEquals(-1, hat.color2, "remote hat preserves secondary color sentinel");
		assertTrue(handler.hasCommand("removeHat3"), "remote hat registers its removal command");

		finishDrawing(course);
		course.raceStarted = true;
		for (_ in 0...6) {
			course.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertTrue(course.eggRound.activeAttackVisualCount() < 5, "race frames tick server effect lifetimes outside egg mode");

		course.remove();
		assertTrue(!handler.hasCommand("addEffect"), "course teardown unregisters addEffect");
		assertTrue(!handler.hasCommand("removeHat3"), "course teardown unregisters remote hat removal command");
	}

	private static function testLaserStopsOnBlockAndPlaysHitSound():Void {
		var layer = new Sprite();
		var hitSounds:Array<String> = [];
		var round = new EggRound(new CommandHandler(), function(_):Void {}, layer, null, function(_, _):Void {}, null, null, null,
			function(x:Int, y:Int):Void hitSounds.push('$x,$y'));
		var level = Level.fromDecoded(0xffffff, [LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 30, 0)]);
		round.mountAttackVisual("Laser`0`15`right`0`7");
		var laser = Std.downcast(layer.getChildAt(0), LaserShotView);

		round.step(level);
		assertEquals(29.0, laser.x, "laser continues travelling before reaching a block");
		assertEquals(0, hitSounds.length, "laser does not play its hit sound before impact");
		round.step(level);
		assertEquals(58.0, laser.x, "laser stops at its detected block impact position");
		assertTrue(laser.currentFrame > 2, "laser starts the authored hit animation on block impact");
		assertEquals("58,15", hitSounds[0], "laser block impact plays Flash's hit sound at the collision position");

		round.step(level);
		assertEquals(58.0, laser.x, "laser remains stopped while its hit animation finishes");
		assertEquals(1, hitSounds.length, "laser hit sound only plays once");
		for (_ in 0...15) {
			round.step(level);
		}
		assertEquals(1, round.activeAttackVisualCount(), "laser impact remains mounted through Flash's 18-frame timeout");
		round.step(level);
		assertEquals(0, round.activeAttackVisualCount(), "laser impact is removed after Flash's 18-frame timeout");
		assertTrue(laser.parent == null, "removed laser impact leaves the effect layer");
	}

	private static function testSharedEffectLifecycle():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler, "race");
		var effect = new TestSharedEffect(12, 34);
		var removes = 0;
		effect.addEventListener(Removable.REMOVE, function(_:Event):Void removes++);

		assertTrue(effect.parent == course.effectBackground, "shared Effect mounts on EffectBackground.instance");
		assertEquals(12.0, effect.x, "shared Effect preserves start x");
		assertEquals(34.0, effect.y, "shared Effect preserves start y");
		effect.armRemoval(24);
		assertEquals(1000, effect.lastScheduledMs(), "shared Effect converts Flash frames to milliseconds at 24fps");
		assertEquals(true, effect.hasRemoveTimer(), "shared Effect stores scheduled removal timer");

		effect.remove();
		assertEquals(false, effect.hasRemoveTimer(), "shared Effect clears scheduled removal on remove");
		assertEquals(null, effect.parent, "shared Effect detaches from effect background on remove");
		assertEquals(1, removes, "shared Effect dispatches Flash remove event once");

		var cleared = new TestSharedEffect(5, 6);
		assertEquals(1, course.effectBackground.numChildren, "shared Effect remounts after manual remove");
		course.effectBackground.clear();
		assertEquals(true, cleared.isRemoved(), "effect background clear removes Removable children");
		assertEquals(0, course.effectBackground.numChildren, "effect background clear empties display children");

		course.remove();
		assertEquals(null, EffectBackground.instance, "course teardown clears EffectBackground singleton");
	}

	private static function testEggVisualRandomization():Void {
		var layer = new Sprite();
		var values = [0.10, 0.20, 0.30];
		var index = 0;
		var round = new EggRound(new CommandHandler(), function(_):Void {}, layer, null, function(_, _):Void {}, function():Float {
			return values[index++];
		});
		round.initRound(777);
		round.addEggs(1, Level.fromDecoded(0xffffff, []));
		var egg = round.egg(1);
		assertTrue(egg != null, "visual test egg spawned");
		var display = egg.display;
		assertEquals(3, index, "egg visual randomization consumes Flash's three color randoms");
		assertEquals("assets/effects/egg_fixed.lottie.json", display.fixedTimeline.sourcePath, "egg uses semantic Lottie data");
		assertEquals(1, display.currentFrame, "egg starts on authored frame one");
		assertTrue(display.fixedTimeline.width > 0, "egg renders reusable source artwork after named-channel tinting");

		var footColor = Std.int(Math.floor(0.10 * 0xFFFFFF));
		var baseColor = Std.int(Math.floor(0.20 * 0xFFFFFF));
		var dotsColor = Std.int(Math.floor(0.30 * 0xFFFFFF));
		assertEggFoot(display, "var_165", footColor);
		assertEggFoot(display, "var_152", footColor);
		assertDisplayColor(DisplayUtil.findByName(Std.downcast(DisplayUtil.findByName(display, "egg"), Sprite), "base"), baseColor,
			"egg base uses second random color");
		assertDisplayColor(DisplayUtil.findByName(Std.downcast(DisplayUtil.findByName(display, "egg"), Sprite), "dots"), dotsColor,
			"egg dots use third random color");
		round.clear();
	}

	private static function testServerActivateCommandLifecycle():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler, "race", "m3`ffffff`0;0;11,1;0;8,1;0;18,1;0;20,1;0;4,1;0;9,1;0;23,2;0;17");
		assertTrue(handler.hasCommand("activate"), "course registers Map activate command");
		finishDrawing(course);
		var arrowFrame = course.levelRenderer.arrowFrameAt(30, 0);
		handler.dispatch("activate", ["1", "0", ""]);
		assertTrue(course.levelRenderer.arrowFrameAt(30, 0) != arrowFrame, "server activate animates arrow blocks by segment");

		handler.dispatch("activate", ["2", "0", ""]);
		assertEquals(1.0, course.localCharacter.blockAlphaAt(2, 0), "remote vanish activation enters shared fade state");
		course.localCharacter.step(new LocalPlayerInput());
		course.localCharacter.step(new LocalPlayerInput());
		@:privateAccess course.syncBlockVisuals();
		assertEquals(0.9, course.levelRenderer.blockAlphaAt(60, 0), "remote vanish follows Flash's frame-by-frame fade");

		var waterAlpha = course.levelRenderer.blockAlphaAt(90, 0);
		handler.dispatch("activate", ["3", "0", ""]);
		assertTrue(course.levelRenderer.blockAlphaAt(90, 0) < waterAlpha, "server activate ripples water blocks by segment");

		handler.dispatch("activate", ["4", "0", ""]);
		assertEquals(null, course.levelRenderer.blockAlphaAt(120, 0), "server activate removes brick block display");
		assertEquals(0.0, course.localCharacter.blockAlphaAt(4, 0), "remote brick removal updates local collision state");
		assertEquals(null, BlockCollision.blockFromPos(@:privateAccess course.level, 120, 0, 0),
			"remote brick removal evicts the effect collision entry");

		handler.dispatch("activate", ["5", "0", ""]);
		assertEquals(null, course.levelRenderer.blockAlphaAt(150, 0), "server activate removes mine block display");
		assertEquals(0.0, course.localCharacter.blockAlphaAt(5, 0), "remote mine removal updates local collision state");
		assertEquals(null, BlockCollision.blockFromPos(@:privateAccess course.level, 150, 0, 0),
			"remote mine removal evicts the effect collision entry");

		handler.dispatch("activate", ["6", "0", "right"]);
		assertEquals(null, course.levelRenderer.blockAlphaAt(180, 0), "server activate moves push block away from source segment");
		assertTrue(course.levelRenderer.blockAlphaAt(210, 0) != null, "server activate moves push block to payload direction segment");
		assertEquals(null, @:privateAccess course.level.blockAt(6, 0), "remote push leaves the source collision tile");
		assertEquals(BlockType.Push, @:privateAccess course.level.blockAt(7, 0).type,
			"remote push updates the destination collision tile");
		assertEquals(null, BlockCollision.blockFromPos(@:privateAccess course.level, 180, 0, 0),
			"remote push clears its source from the effect collision map");
		assertEquals(ObjectCodes.BLOCK_PUSH, BlockCollision.blockFromPos(@:privateAccess course.level, 210, 0, 0).code,
			"remote push updates its destination in the effect collision map");

		handler.dispatch("activate", ["8", "0", "20"]);
		assertEquals(1.0, course.localCharacter.blockAlphaAt(8, 0), "first remote crumble hit retains remaining life");
		handler.dispatch("activate", ["8", "0", "20"]);
		assertEquals(0.0, course.localCharacter.blockAlphaAt(8, 0), "cumulative remote crumble damage removes collision state");
		assertEquals(null, course.levelRenderer.blockAlphaAt(240, 0), "cumulative remote crumble damage removes the display");
		assertEquals(null, BlockCollision.blockFromPos(@:privateAccess course.level, 240, 0, 0),
			"spent crumble is evicted from the effect collision map");
		var effectsAfterRemoval = course.levelRenderer.worldEffectLayer().numChildren;
		handler.dispatch("activate", ["8", "0", "20"]);
		assertEquals(effectsAfterRemoval, course.levelRenderer.worldEffectLayer().numChildren,
			"late crumble activation cannot spawn particles after Map removal");

		course.remove();
		assertTrue(!handler.hasCommand("activate"), "course teardown unregisters Map activate command");
	}

	private static function testMoveBlockDisplayTracksFixtureCoordinates():Void {
		var course = buildCourse(new CommandHandler(), "race", "m3`ffffff`0;0;11,1;0;19,1;0;0");
		course.syncMoveBlockDisplays();
		var moveBlock = @:privateAccess course.level.blockAt(1, 0);
		var tracked = course.displayedMoveBlockPositions.get(moveBlock);
		assertEquals(30, tracked.worldX, "move display tracking starts at the move block, not the omitted start-marker index");
		moveBlock.x = 3;
		course.syncMoveBlockDisplays();
		assertEquals(null, BlockCollision.blockFromPos(@:privateAccess course.level, 30, 0, 0),
			"move block clears its original effect collision tile");
		assertEquals(ObjectCodes.BLOCK_MOVE, BlockCollision.blockFromPos(@:privateAccess course.level, 90, 0, 0).code,
			"move block occupies its new effect collision tile");
		course.remove();
	}

	private static function assertEggAttackVisual(seed:Int, expectedType:String, expectedCount:Int, message:String):Void {
		var layer = new Sprite();
		var round = new EggRound(new CommandHandler(), function(_):Void {}, layer, null, function(_, _):Void {});
		round.initRound(seed);
		round.addEggs(1, Level.fromDecoded(0xffffff, []));
		var egg = round.egg(1);
		assertTrue(egg != null, '$message: egg spawned');
		egg.posX = 100;
		egg.posY = 100;
		egg.velX = 0;
		egg.velY = 0;
		var probe = RotationMath.rotatePoint(150, 100, -RotationMath.normalizeDisplayRotation(-egg.rot));
		LobbySocket.resetSent();
		round.step(Level.fromDecoded(0xffffff, []), 0, probe.x, probe.y + 20, false, false);
		assertTrue(LobbySocket.lastSent().indexOf('add_effect`$expectedType`') == 0, '$message: expected payload type');
		assertEquals(expectedCount, round.activeAttackVisualCount(), message);
		assertEquals(expectedCount + 1, layer.numChildren, '$message: visuals share the egg display layer');
		var visual = layer.getChildAt(1);
		var laserClip = Std.downcast(visual, LaserShotView);
		if (expectedType == "Laser") {
			assertEquals(2, laserClip.currentFrame, "laser attack visual starts stopped on idle frame 2");
			laserClip.dispatchEvent(new Event(Event.ENTER_FRAME));
			assertEquals(2, laserClip.currentFrame, "laser attack visual does not auto-play while idle");
			laserClip.playHit();
			for (_ in 0...20) {
				laserClip.dispatchEvent(new Event(Event.ENTER_FRAME));
			}
			assertEquals(18, laserClip.currentFrame, "laser hit animation stops on authored frame 18");
		}
		var initialX = visual.x;
		round.step(Level.fromDecoded(0xffffff, []), 0, probe.x, probe.y + 20, false, false);
		assertTrue(visual.x != initialX || expectedType == "Slash", '$message: projectile visuals advance after mounting');
		round.clear();
		assertEquals(0, layer.numChildren, '$message: clear removes mounted visuals');
	}

	private static function assertEggFoot(display:EggView, name:String, expectedColor:Int):Void {
		var foot = Std.downcast(DisplayUtil.findByName(display, name), pr2.gameplay.EggView.EggPartView);
		assertTrue(foot != null, '$name foot exists');
		assertEquals(1, foot.currentFrame, '$name foot stops on frame 1');
		var colorMC = Std.downcast(DisplayUtil.findByName(foot, "colorMC"), pr2.gameplay.EggView.EggPartChannel);
		assertTrue(colorMC != null, '$name colorMC exists');
		assertEquals(1, colorMC.currentFrame, '$name colorMC stops on frame 1');
		assertEquals(expectedColor, colorMC.transform.colorTransform.color, '$name colorMC uses first random color');
		var colorMC2 = Std.downcast(DisplayUtil.findByName(foot, "colorMC2"), pr2.gameplay.EggView.EggPartChannel);
		assertTrue(colorMC2 != null, '$name colorMC2 exists');
		assertEquals(1, colorMC2.currentFrame, '$name colorMC2 stops on frame 1');
		assertEquals(false, colorMC2.visible, '$name colorMC2 is hidden');
	}

	private static function assertDisplayColor(target:DisplayObject, expectedColor:Int, message:String):Void {
		assertTrue(target != null, message + " target exists");
		assertEquals(expectedColor, target.transform.colorTransform.color, message);
	}

	private static function testHatReturnToStartLifecycle():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler, "hat", "m3`ffffff`0;0;11,1;0;8,0;1;11,0;2;0,11,0;4;0");
		var shell = new GameCommandShell(new CourseDelegate(course), handler);
		shell.install();

		var hat = course.addLooseHat(15, course.level.maxY + 501, 0, 5, 0x123456, -1, 1);
		assertEquals(1, countLooseHats(course), "loose hat is registered");
		assertTrue(handler.hasCommand("removeHat1"), "loose hat registers remote remove command");
		assertTrue(hat.display.parent == course.effectBackground, "loose hat display mounts to the Flash effect layer");
		assertEquals("assets/svg/character/hat/005_cowboy/primary.svg", hat.display.colorMC.getChildAt(0).name,
			"loose cowboy hat uses its exact authored primary channel");
		var primaryArt = Std.downcast(hat.display.colorMC.getChildAt(0), Shape);
		assertTrue(primaryArt != null, "loose cowboy hat primary channel contains tintable shape artwork");
		assertEquals(0x123456, primaryArt.transform.colorTransform.color,
			"loose cowboy hat applies its primary color to the artwork shape");
		assertEquals("assets/svg/character/hat/005_cowboy/static.svg", hat.display.fixedArt.getChildAt(0).name,
			"loose cowboy hat preserves its exact authored untinted channel");

		handler.dispatch("maybeReturnHatToStart", ["1"]);
		var returned = course.looseHats.get(1);
		assertTrue(returned != null, "out-of-bounds loose hat respawns at matching start");
		assertTrue(returned != hat, "return to start replaces the old hat instance");
		assertEquals(45, Std.int(returned.posX), "returned hat uses start block center x");
		assertEquals(45, Std.int(returned.posY), "returned hat uses start block center y");
		assertEquals(0, returned.rot, "returned hat resets rotation");
		assertEquals(5, returned.num, "returned hat preserves hat id");
		assertEquals(0x123456, returned.color, "returned hat preserves primary color");
		assertEquals(-1, returned.color2, "returned hat preserves secondary color sentinel");
		assertTrue(hat.display.parent == null, "old loose hat display is removed");
		assertTrue(returned.display.parent == course.effectBackground, "returned loose hat display mounts to the Flash effect layer");
		assertTrue(handler.hasCommand("removeHat1"), "returned hat keeps remote remove command registered");

		handler.dispatch("removeHat1", []);
		assertEquals(0, countLooseHats(course), "remote remove clears returned loose hat");
		assertTrue(returned.display.parent == null, "remote remove detaches returned display");
		assertTrue(!handler.hasCommand("removeHat1"), "remote remove unregisters command");

		var localObserved = course.addLooseHat(15, course.level.maxY + 510, 0, 5, 0xABCDEF, -1, 1);
		LobbySocket.resetSent();
		course.stepLooseHats();
		assertEquals("hat_to_start`1", LobbySocket.lastSent(), "local bounds check emits hat_to_start");
		assertEquals(1, countLooseHats(course), "local emit leaves loose hat until server echo");
		assertTrue(localObserved.sentReturnToStart, "local bounds check marks return request sent");
		LobbySocket.resetSent();
		localObserved.posY = course.level.maxY + 510;
		localObserved.velY = 0;
		course.stepLooseHats();
		assertEquals("", LobbySocket.lastSent(), "local bounds check emits hat_to_start only once");
		handler.dispatch("maybeReturnHatToStart", ["1"]);
		var locallyReturned = course.looseHats.get(1);
		assertTrue(locallyReturned != null, "server echo respawns locally returned hat");
		assertTrue(locallyReturned != localObserved, "server echo replaces locally returned hat instance");
		assertEquals(45, Std.int(locallyReturned.posX), "server echo uses matching start block center x");
		assertEquals(45, Std.int(locallyReturned.posY), "server echo uses matching start block center y");

		course.addLooseHat(20, course.level.maxY + 501, 0, 6, 0xFFFFFF, 0, 4);
		handler.dispatch("maybeReturnHatToStart", ["4"]);
		assertEquals(1, countLooseHats(course), "hat without matching start is removed instead of respawned");

		shell.remove();
		course.remove();
	}

	private static function testMinionEggBlocksSpawnAuthoredEggs():Void {
		var eggBlocks = [for (i in 0...26) '$i;1;30'].join(",");
		var handler = new CommandHandler();
		var course = buildCourse(handler, "race", 'm3`ffffff`0;0;11,$eggBlocks');
		assertEquals(26, course.level.minionEggBlocks().length, "decoded level exposes minion egg block positions");
		assertEquals(0, course.eggRound.count(), "minion eggs wait for gameplay start");
		assertTrue(!course.levelRenderer.blockDisplays.exists("0,30"), "minion egg block is not rendered as a fallback tile");

		finishDrawing(course);
		course.beginRace();
		finishCountdown(course);

		assertEquals(25, course.eggRound.count(), "course spawns at most 25 minion eggs at gameplay start");
		var first = course.eggRound.egg(1);
		assertTrue(first != null, "first minion egg is registered");
		assertEquals(30, Std.int(first.posX), "first minion egg uses Flash x offset from block position");
		assertEquals(60, Std.int(first.posY), "first minion egg uses Flash y offset from block position");
		assertTrue(handler.hasCommand("removeEgg25"), "last spawned minion egg registers remote removal command");
		assertTrue(!handler.hasCommand("removeEgg26"), "minion egg placement enforces Flash's 25 egg cap");

		course.localCharacter.setControllerPosition(150, -100);
		var playerX = course.localCharacter.x;
		var playerY = course.localCharacter.y;
		first.posX = playerX;
		first.posY = playerY;
		first.velX = 0;
		first.velY = 0;
		var attacker = course.eggRound.egg(2);
		attacker.posX = playerX - 50;
		attacker.posY = playerY;
		attacker.velX = 0;
		attacker.velY = 0;
		LobbySocket.resetSent();
		course.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertTrue(first.removing,
			'race minion egg squashes when it touches the local player (egg=${first.x},${first.y}; player=${course.localCharacter.x},${course.localCharacter.y}; removed=${course.localCharacter.removed})');
		assertTrue(LobbySocket.sentCommands.join("|").indexOf("add_effect`") >= 0,
			"race minion egg attacks when the local player enters its attack probe");
		assertTrue(LobbySocket.sentCommands.join("|").indexOf("grab_egg`") == -1,
			"squashing a race minion does not emit Alien Eggs score collection");

		course.remove();
		assertTrue(!handler.hasCommand("removeEgg25"), "course teardown unregisters minion egg removal command");
	}

	private static function testLooseHatPhysicsAndPickup():Void {
		var handler = new CommandHandler();
		var course = buildCourse(handler, "hat", "m3`ffffff`0;0;11,0;1;0");
		course.createLocalCharacter({
			tempId: 4,
			speed: 80,
			accel: 70,
			jump: 60,
			hatColor: 0xFFFFFF,
			headColor: 0xFFFFFF,
			bodyColor: 0xFFFFFF,
			feetColor: 0xFFFFFF,
			hatId: 1,
			headId: 1,
			bodyId: 1,
			feetId: 1,
			hatColor2: -1,
			headColor2: -1,
			bodyColor2: -1,
			feetColor2: -1,
			group: "0"
		});
		assertTrue(handler.hasCommand("setHats4"), "local character registers setHats command for pickup replies");
		finishDrawing(course);

		var falling = course.addLooseHat(15, -45, 0, 5, 0xFFFFFF, -1, 1);
		for (_ in 0...90) {
			falling.step(course.level, 0);
		}
		assertEquals(true, falling.grounded, "loose hat lands on active blocks");
		assertEquals(30, Std.int(falling.posY), "loose hat snaps to the block top");
		assertEquals(30, Std.int(falling.display.y), "loose hat display follows physics position");
		falling.remove();

		var pickup = course.addLooseHat(15, 0, 0, 6, 0x123456, -1, 2);
		LobbySocket.resetSent();
		pickup.step(course.level, 0, 15, 20, false, false, false);
		assertEquals(0, countLooseHats(course), "touching local player removes loose hat");
		assertEquals("get_hat`2", LobbySocket.lastSent(), "touching local player emits get_hat");
		assertTrue(pickup.display.parent == null, "pickup detaches loose hat display");
		handler.dispatch("setHats4", ["6", "1193046", "-1"]);
		assertEquals(6, course.localCharacter.hat1, "server pickup reply equips the collected hat locally");
		assertTrue(course.localCharacter.hasHatFlag(Character.CROWN), "server pickup reply refreshes local hat powers");
		handler.dispatch("setHats4", [""]);
		assertEquals(1, course.localCharacter.hat1, "blank server hat stack restores the empty hat frame locally");
		assertTrue(!course.localCharacter.hasHatFlag(Character.CROWN), "blank server hat stack clears local hat powers");

		var raceCourse = buildCourse(handler, "race", "m3`ffffff`0;0;11,0;1;0");
		raceCourse.createLocalCharacter(localInit(4));
		finishDrawing(raceCourse);
		raceCourse.beginRace();
		finishCountdown(raceCourse);
		var raceHat = raceCourse.addLooseHat(Math.round(raceCourse.localCharacter.x), Math.round(raceCourse.localCharacter.y), 0, 6, 0x123456, -1, 4);
		LobbySocket.resetSent();
		raceCourse.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(0, countLooseHats(raceCourse), "race frame loop removes a loose hat touched by the local player");
		assertTrue(raceHat.display.parent == null, "race frame loop detaches a collected loose hat display");
		assertTrue(LobbySocket.sentCommands.indexOf("get_hat`4") != -1, "race frame loop emits get_hat outside Hat Attack");
		raceCourse.remove();

		var finishedPickup = course.addLooseHat(15, 0, 0, 6, 0x123456, -1, 3);
		LobbySocket.resetSent();
		finishedPickup.step(course.level, 0, 15, 20, false, false, true);
		assertEquals(1, countLooseHats(course), "done-playing local player does not collect loose hat");
		assertEquals("", LobbySocket.lastSent(), "done-playing pickup suppression emits no get_hat");

		course.remove();
		assertTrue(!handler.hasCommand("setHats4"), "course teardown unregisters local setHats command");
	}

	private static function countLooseHats(course:Course):Int {
		var count = 0;
		for (_ in course.looseHats.keys()) {
			count++;
		}
		return count;
	}

	private static function finishDrawing(course:Course):Void {
		while (!course.levelRenderer.isDrawingComplete()) {
			course.levelRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
	}

	private static function finishCountdown(course:Course):Void {
		while (course.countdown != null && course.countdown.parent != null) {
			course.countdown.advance();
		}
	}

	private static function collectAndUseLocalItem(itemId:Int):Course {
		var course = buildCourse(new CommandHandler(), "race", 'm4`ffffff`2;5;11,0;-2;10;$itemId,0;3;0,1;0;0,1;0;0,1;0;0');
		finishDrawing(course);
		course.beginRace();
		finishCountdown(course);
		course.setKey(Keyboard.UP, true);
		for (_ in 0...40) {
			course.onEnterFrame(new Event(Event.ENTER_FRAME));
			if (course.localCharacter.stateSnapshot().itemId == itemId) {
				break;
			}
		}
		course.setKey(Keyboard.UP, false);
		assertEquals(itemId, course.localCharacter.stateSnapshot().itemId, 'local player collects item $itemId');

		LobbySocket.resetSent();
		course.onEnterFrame(new Event(Event.ENTER_FRAME));
		course.setKey(Keyboard.SPACE, true);
		course.onEnterFrame(new Event(Event.ENTER_FRAME));
		course.setKey(Keyboard.SPACE, false);
		return course;
	}

	private static function buildCourse(handler:CommandHandler, gameMode:String = "race", ?dataString:String):Course {
		if (dataString == null) {
			dataString = "m3`ffffff`0;0;11,1;0;8,0;1;0";
		}
		var level = LevelDecoder.decode(dataString);

		var vars:Map<String, String> = new Map();
		vars.set("level_id", "99");
		vars.set("title", "Lifecycle Test");
		vars.set("song", "song1");
		vars.set("gravity", "1");
		vars.set("max_time", "120");
		vars.set("gameMode", gameMode);
		vars.set("items", "all");
		vars.set("data", dataString);

		var data = new ServerLevelData(vars, true);
		return new Course(level, data, LevelConfig.fromServerData(data), null, null, handler);
	}

	private static function localInit(tempId:Int):LocalCharacterInit {
		return {
			tempId: tempId,
			speed: 80, accel: 70, jump: 60,
			hatColor: 0xFFFFFF, headColor: 0xFFFFFF, bodyColor: 0xFFFFFF, feetColor: 0xFFFFFF,
			hatId: 1, headId: 1, bodyId: 1, feetId: 1,
			hatColor2: -1, headColor2: -1, bodyColor2: -1, feetColor2: -1,
			group: "0"
		};
	}

	private static function remoteInit(tempId:Int):RemoteCharacterInit {
		return {
			tempId: tempId,
			userName: "Rival",
			hatColor: 0xFFFFFF, headColor: 0xFFFFFF, bodyColor: 0xFFFFFF, feetColor: 0xFFFFFF,
			hatId: 1, headId: 1, bodyId: 1, feetId: 1,
			hatColor2: -1, headColor2: -1, bodyColor2: -1, feetColor2: -1,
			group: "0"
		};
	}

	private static function assertEquals<T>(expected:T, actual:T, message:String):Void {
		assertions++;
		if (actual != expected) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) {
			throw 'assertion failed: $message';
		}
	}
}

private class TestSharedEffect extends Effect {
	public function new(startX:Float, startY:Float) {
		super(startX, startY);
	}

	public function armRemoval(frames:Int):Void {
		scheduleRemove(frames);
	}

	public function lastScheduledMs():Int {
		return scheduledRemoveMsForTests();
	}

	public function hasRemoveTimer():Bool {
		return hasScheduledRemoveForTests();
	}
}

private class CourseDelegate implements GameCommandDelegate {
	private final course:Course;

	public function new(course:Course) {
		this.course = course;
	}

	public function createRemoteCharacter(init:RemoteCharacterInit):Void course.createRemoteCharacter(init);
	public function createLocalCharacter(init:LocalCharacterInit):Void course.createLocalCharacter(init);
	public function beginRace():Void course.beginRace();
	public function award(args:Array<String>):Void {}
	public function setExpGain(expOld:Int, expNew:Int, expToRank:Int):Void {}
	public function setLuxGain(amount:Int):Void {}
	public function setPrize(prize:Dynamic):Void {}
	public function cancelPrize(message:String):Void {}
	public function winPrize(prize:Dynamic):Void {}
	public function cowboyMode():Void {}
	public function happyHour():Void {}
	public function setEggSeed(seed:Int):Void course.setEggSeed(seed);
	public function addEggs(count:Int):Void course.addEggs(count);
	public function setLife(lives:Int):Void course.setLife(lives);
	public function superBooster(tempId:Int):Void {}
	public function maybeReturnHatToStart(hatId:Int):Void course.maybeReturnHatToStart(hatId);
	public function startHatCountdown():Void {}
	public function cancelHatCountdown():Void {}
	public function areYouHuman():Void {}
	public function forceQuit():Void {}
}
