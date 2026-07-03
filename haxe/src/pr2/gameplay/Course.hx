package pr2.gameplay;

#if js
import js.Browser;
#end
import haxe.crypto.Md5;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import pr2.Constants;
import pr2.character.Character;
import pr2.character.CharacterState;
import pr2.character.LocalCharacter;
import pr2.character.RemoteCharacter;
import pr2.effects.ZapEffect;
import pr2.gameplay.GameCommandShell.LocalCharacterInit;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.gameplay.SpecialEvent.PlaceArtifactRequest;
import pr2.harness.BlockVisualEvent;
import pr2.harness.BlockVisualEvent.BlockVisualEventKind;
import pr2.harness.LocalPlayerDebugState;
import pr2.harness.LocalPlayerInput;
import pr2.harness.PlayerDisplayPlacement;
import pr2.lobby.account.AlternateControls;
import pr2.lobby.LobbySession;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevel;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevelFixtureAdapter;
import pr2.level.ServerLevelFixtureAdapter.ServerFixtureLevel;
import pr2.level.ServerLevelRenderer;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerLevelData;

/**
	The in-game race shell: a decoded `ServerLevel` rendered with the authored HUD
	mounted at Course's holder->stage offsets, a local player driven by
	`LocalCharacter`, a follow camera, and incremental block drawing.

	Extracted from `CampaignTestScreen` so the real `GamePage` can mount the shell
	directly (without the campaign-list fetch / debug-overlay chrome the harness
	wraps around it). The harness now builds a `Course` too, supplying `onChatLine`
	to intercept `/debug` and `onFrame` to drive its status overlay.

	The character layer is currently a single `LocalCharacter`; the multiplayer
	`RemoteCharacter` hierarchy (Section B) will populate `characterLayer`
	alongside the local player.
**/
class Course extends Sprite {
	// Verified Course holder->stage offsets (holder is centred at +275,+200).
	public static inline var ITEM_X:Float = 2;
	public static inline var ITEM_Y:Float = 2;
	public static inline var MINIMAP_X:Float = 80;
	public static inline var MINIMAP_Y:Float = 2;
	public static inline var SPECTATE_X:Float = 10;
	public static inline var SPECTATE_Y:Float = 230;
	public static inline var DRAWING_X:Float = 2;
	public static inline var DRAWING_Y:Float = 96;
	public static inline var CHAT_X:Float = 4;
	public static inline var CHAT_Y:Float = 249;
	public static inline var MUSIC_X:Float = 204;
	public static inline var MUSIC_Y:Float = 362;
	public static inline var STATS_X:Float = 490;
	public static inline var STATS_Y:Float = 34;
	public static inline var HEARTS_X:Float = 515;
	public static inline var HEARTS_Y:Float = 59;

	private final level:ServerLevel;
	private final data:ServerLevelData;
	private final config:LevelConfig;
	private final onChatLine:Null<String->Bool>;
	private final onFrame:Null<LocalPlayerDebugState->Void>;
	private final commandHandler:Null<CommandHandler>;

	private final input:LocalPlayerInput = new LocalPlayerInput();

	public var levelRenderer(default, null):ServerLevelRenderer;
	public var backCharacterLayer(default, null):Sprite;
	public var characterLayer(default, null):Sprite;
	public var localCharacter(default, null):LocalCharacter;
	public var remoteCharacters(default, null):Map<Int, RemoteCharacter> = new Map();
	public var playerArray(default, null):Array<Character> = [];
	public var playerSpectating(default, null):Null<Character>;
	public var canSpectate(default, null):Bool = false;
	private var serverFixture:ServerFixtureLevel;
	private var player:LocalCharacter;
	private var camera:CameraFollow;
	private var remoteBlockActivation:RemoteBlockActivation;

	public var miniMap(default, null):MiniMap;
	public var spectatePicker(default, null):SpectatePicker;
	public var itemDisplay(default, null):ItemDisplay;
	public var statsDisplay(default, null):StatsDisplay;
	public var hearts(default, null):Hearts;
	public var musicSelection(default, null):MusicSelection;
	public var raceChat(default, null):RaceChat;
	public var drawingInfo(default, null):DrawingInfo;
	public var countdown(default, null):Countdown;
	public var eggRound(default, null):EggRound;
	public var effectBackground(default, null):EffectBackground;
	public var looseHats(default, null):Map<Int, HatEffect> = new Map();
	public var raceStarted(default, null):Bool = false;

	// Invoked once when the local player reaches a finish block. The host page
	// (GamePage) uses it to mark the player done and show the finished page; the
	// network notification itself is emitted here, mirroring Flash Game.finish.
	public var onFinish:Null<LocalPlayerDebugState->Void> = null;
	public var onPlayJumpSound:Null<Float->Float->Void> = null;
	public var onPlayCharacterSound:Null<pr2.character.Character.CharacterSoundRequest->Void> = null;
	public var onStartJetSound:Null<pr2.character.Character.CharacterSoundRequest->Void> = null;
	public var onStopJetSound:Null<Character->Void> = null;
	public var onStatsSelectSyncRequest:Null<Void->Void> = null;
	private var localFinishHandled:Bool = false;

	// Set by GamePage when the player quits (or otherwise leaves the race) so the
	// per-frame race-phase report keeps saying "finished" instead of clobbering
	// the GamePage-set value back to "racing" while the course keeps ticking.
	public var raceEnded:Bool = false;

	private var playerDot:MiniMapDot;
	private var drawingInfoFinished:Bool = false;
	private var displayedItemId:Null<Int>;
	private var displayedItemUses:Null<Int>;
	private var displayedStats:Null<String>;
	private var displayedLives:Null<Int>;
	private var finishDrawingEmitted:Bool = false;
	private var displayedCourseRotation:Int = 0;
	private final displayedMoveBlockPositions:Map<Int, {worldX:Int, worldY:Int}> = new Map();
	private var displayedMoveBlockArrows:Map<String, Bool> = new Map();
	// Tile keys ("x,y") whose block visual was non-default last frame, so they can
	// be reset to alpha/tint 1 once they return to default. See syncBlockVisuals.
	private var activeVisualBlocks:Map<String, Bool> = new Map();
	private var startPositions:Array<{x:Int, y:Int}> = [];
	private var raceSounds:RaceSounds;
	private var localSetHatsCommandName:Null<String>;
	private var reachedObjectives:Map<Int, Bool> = new Map();
	private var minionEggsSpawned:Bool = false;

	public function new(level:ServerLevel, data:ServerLevelData, config:LevelConfig, ?onChatLine:String->Bool, ?onFrame:LocalPlayerDebugState->Void,
			?commandHandler:CommandHandler) {
		super();
		this.level = level;
		this.data = data;
		this.config = config;
		this.onChatLine = onChatLine;
		this.onFrame = onFrame;
		this.commandHandler = commandHandler;
		build();
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	private function build():Void {
		var startBlocks = level.startBlocks();
		var focus = startBlocks.length == 0 ? null : startBlocks[0];
		levelRenderer = new ServerLevelRenderer(level, focus, ServerLevelRenderer.DEFAULT_FOCUS_X, ServerLevelRenderer.DEFAULT_FOCUS_Y, true);
		addChild(levelRenderer);
		raceSounds = new RaceSounds(levelRenderer.cameraOffset);

		serverFixture = ServerLevelFixtureAdapter.convert(level, data.gravity, Std.string(config.levelId), config.title);
		// The controller swaps the player's coordinates about the fixture origin on
		// each rotate step, so the block layer must turn about that same point.
		levelRenderer.setRotationPivot(serverFixture.originTileX * ServerLevelRenderer.TILE_SIZE, serverFixture.originTileY * ServerLevelRenderer.TILE_SIZE);
		player = new LocalCharacter(serverFixture.fixture);
		player.onPlayJumpSound = playJumpSound;
		player.onPlayCharacterSound = playCharacterSound;
		player.onArtifactHatActivated = onArtifactHatActivated;
		player.onStartJetSound = startJetSound;
		player.onStopJetSound = stopJetSound;
		player.setGameMode(config.gameMode);
		player.setAllowedItems(config.allowedItems);
		player.display.x = player.halfWidth;
		player.display.y = player.charHeight;
		localCharacter = player;
		playerArray[player.tempID] = player;
		remoteBlockActivation = new RemoteBlockActivation(serverFixture, levelRenderer);
		activeCommandHandler().defineCommand("activate", activateCommand);
		buildStartPositions();

		characterLayer = new Sprite();
		characterLayer.addChild(player);
		backCharacterLayer = new Sprite();
		levelRenderer.attachBackCharacterLayer(backCharacterLayer);
		levelRenderer.attachFrontCharacterLayer(characterLayer);

		camera = new CameraFollow(0, 0);
		camera.snapTo(serverFixture.fixturePixelToWorldX(player.x), serverFixture.fixturePixelToWorldY(player.y));

		buildMiniMap();
		buildSpectatePicker();
		buildItemDisplay();
		buildStatsDisplay();
		buildHearts();
		buildMusicSelection();
		buildRaceChat();
		buildDrawingInfo();
		eggRound = new EggRound(commandHandler != null ? commandHandler : CommandHandler.commandHandler, collectEgg, characterLayer, levelRenderer.cameraOffset);
		effectBackground = new EffectBackground(this, commandHandler != null ? commandHandler : CommandHandler.commandHandler);
		updatePlayerDisplay();
	}

	private function activeCommandHandler():CommandHandler {
		return commandHandler != null ? commandHandler : CommandHandler.commandHandler;
	}

	private function buildMiniMap():Void {
		miniMap = new MiniMap();
		for (block in level.blocks) {
			if (block.code >= ObjectCodes.BLOCK_START1 && block.code <= ObjectCodes.BLOCK_START4) {
				continue;
			}
			if (block.code == ObjectCodes.BLOCK_MINION_EGG) {
				continue;
			}
			miniMap.addBlock(block.code, block.x, block.y);
		}
		miniMap.rasterize();
		playerDot = miniMap.getDot();
		playerDot.setTempID(0, true);
		playerDot.setHoverInfo(1, LobbySession.userName == "" ? "Guest" : LobbySession.userName, true);
		miniMap.x = MINIMAP_X;
		miniMap.y = MINIMAP_Y;
		addChild(miniMap);
	}

	private function buildItemDisplay():Void {
		itemDisplay = new ItemDisplay();
		itemDisplay.x = ITEM_X;
		itemDisplay.y = ITEM_Y;
		addChild(itemDisplay);
		displayedItemId = null;
		displayedItemUses = null;
		syncItemDisplay();
	}

	private function buildStatsDisplay():Void {
		statsDisplay = new StatsDisplay();
		statsDisplay.x = STATS_X;
		statsDisplay.y = STATS_Y;
		addChild(statsDisplay);
		displayedStats = null;
		syncStatsDisplay();
	}

	private function buildHearts():Void {
		hearts = new Hearts();
		hearts.x = HEARTS_X;
		hearts.y = HEARTS_Y;
		hearts.visible = false;
		addChild(hearts);
		displayedLives = null;
		syncHearts();
	}

	private function buildMusicSelection():Void {
		musicSelection = new MusicSelection();
		musicSelection.x = MUSIC_X;
		musicSelection.y = MUSIC_Y;
		addChild(musicSelection);
		musicSelection.setSong(data.song);
	}

	private function buildRaceChat():Void {
		raceChat = new RaceChat(handleRaceChatLine);
		raceChat.x = CHAT_X;
		raceChat.y = CHAT_Y;
		addChild(raceChat);
	}

	private function buildDrawingInfo():Void {
		drawingInfo = new DrawingInfo();
		drawingInfo.x = DRAWING_X;
		drawingInfo.y = DRAWING_Y;
		drawingInfo.addPlayer("You", 0);
		drawingInfoFinished = false;
		addChild(drawingInfo);
	}

	private function buildSpectatePicker():Void {
		spectatePicker = new SpectatePicker(this);
		spectatePicker.x = SPECTATE_X;
		spectatePicker.y = SPECTATE_Y;
		addChild(spectatePicker);
		toggleSpectatePossible(false);
	}

	private function buildStartPositions():Void {
		startPositions = [];
		for (block in level.blocks) {
			if (isStartBlock(block)) {
				startPositions.push({x: block.x + 15, y: block.y + 15});
			}
		}
	}

	private function returnHatToStart(hat:HatEffect):Void {
		var info = hat.info();
		hat.remove();
		if (info.id < startPositions.length) {
			var start = startPositions[info.id];
			addLooseHat(start.x, start.y, 0, info.num, info.color, info.color2, info.id);
		}
	}

	private function stepLooseHats():Void {
		if (looseHats == null || localCharacter == null || levelRenderer == null) {
			return;
		}
		for (id in [for (id in looseHats.keys()) id]) {
			var hat = looseHats.get(id);
			if (hat != null) {
				hat.step(level, Math.round(levelRenderer.rotation), localCharacter.x, localCharacter.y, localCharacter.crouching,
					localCharacter.removed, isDonePlaying());
				maybeEmitHatToStart(hat);
			}
		}
	}

	public function isDonePlaying():Bool {
		return localFinishHandled || raceEnded;
	}

	private static function isStartBlock(block:DecodedBlock):Bool {
		return block.code >= ObjectCodes.BLOCK_START1 && block.code <= ObjectCodes.BLOCK_START4;
	}

	/** Lets a wrapper (the debug harness) intercept chat lines before display. **/
	public function handleRaceChatLine(message:String):Bool {
		return onChatLine != null && onChatLine(message);
	}

	public function createLocalCharacter(init:LocalCharacterInit):LocalCharacter {
		if (localCharacter == null) {
			return null;
		}
		unregisterLocalSetHatsCommand();
		localCharacter.tempID = init.tempId;
		localCharacter.groupStr = init.group;
		localCharacter.setHatId(Std.int(init.hatId));
		localCharacter.setHeadId(Std.int(init.headId));
		localCharacter.setBodyId(Std.int(init.bodyId));
		localCharacter.setFeetId(Std.int(init.feetId));
		localCharacter.setColors(Std.int(init.hatColor), Std.int(init.hatColor2), Std.int(init.headColor), Std.int(init.headColor2),
			Std.int(init.bodyColor), Std.int(init.bodyColor2), Std.int(init.feetColor), Std.int(init.feetColor2));
		localCharacter.setStats(init.speed, init.accel, init.jump);
		playerArray[init.tempId] = localCharacter;
		registerLocalSetHatsCommand(init.tempId);
		return localCharacter;
	}

	private function registerLocalSetHatsCommand(tempId:Int):Void {
		if (commandHandler == null) {
			return;
		}
		localSetHatsCommandName = "setHats" + tempId;
		commandHandler.defineCommand(localSetHatsCommandName, setLocalHatsCommand);
	}

	private function unregisterLocalSetHatsCommand():Void {
		if (commandHandler != null && localSetHatsCommandName != null) {
			commandHandler.defineCommand(localSetHatsCommandName, null);
		}
		localSetHatsCommandName = null;
	}

	private function setLocalHatsCommand(args:Array<String>):Void {
		if (localCharacter != null) {
			localCharacter.setHats([for (arg in args) parseIntArg(arg)]);
		}
	}

	private function activateCommand(args:Array<String>):Void {
		if (remoteBlockActivation == null || args.length < 2) {
			return;
		}
		remoteBlockActivation.activateSegment(parseIntArg(args[0]), parseIntArg(args[1]), args.length > 2 ? args[2] : "");
	}

	public function createRemoteCharacter(init:RemoteCharacterInit):RemoteCharacter {
		removeRemoteCharacter(init.tempId);
		var dot = miniMap == null ? null : miniMap.getDot();
		if (dot != null) {
			dot.setHoverInfo(init.tempId + 1, init.userName, true);
		}
		var remote = new RemoteCharacter(init.tempId, dot, init.userName, Std.int(init.hatId), Std.int(init.headId), Std.int(init.bodyId),
			Std.int(init.feetId), init.group, commandHandler);
		remote.setColors(Std.int(init.hatColor), Std.int(init.hatColor2), Std.int(init.headColor), Std.int(init.headColor2),
			Std.int(init.bodyColor), Std.int(init.bodyColor2), Std.int(init.feetColor), Std.int(init.feetColor2));
		if (remoteBlockActivation != null) {
			remote.onBlockTouch = remoteBlockActivation.touch;
		}
		remote.onPlayJumpSound = playRemoteJumpSound;
		remote.onPlayCharacterSound = playCharacterSound;
		remote.onStartJetSound = startJetSound;
		remote.onStopJetSound = stopJetSound;
		remote.onParentChange = function(parentLayer:String):Void {
			moveCharacterToLayer(remote, parentLayer);
		};
		remoteCharacters.set(init.tempId, remote);
		playerArray[init.tempId] = remote;
		if (characterLayer != null) {
			characterLayer.addChild(remote);
		}
		return remote;
	}

	public function getRemoteCharacter(tempId:Int):Null<RemoteCharacter> {
		return remoteCharacters == null ? null : remoteCharacters.get(tempId);
	}

	public function remoteCharacterCount():Int {
		if (remoteCharacters == null) {
			return 0;
		}
		var count = 0;
		for (_ in remoteCharacters.keys()) {
			count++;
		}
		return count;
	}

	public function removeRemoteCharacter(tempId:Int):Void {
		if (remoteCharacters == null) {
			return;
		}
		var remote = remoteCharacters.get(tempId);
		if (remote == null) {
			return;
		}
		remote.remove();
		remoteCharacters.remove(tempId);
		if (playerArray != null && tempId >= 0 && tempId < playerArray.length) {
			playerArray[tempId] = null;
		}
		if (playerSpectating == remote) {
			changeSpectate(-1);
			if (spectatePicker != null) {
				spectatePicker.stopSpectating();
			}
		}
	}

	public function removeAllRemoteCharacters():Void {
		if (remoteCharacters == null) {
			return;
		}
		var ids = [for (id in remoteCharacters.keys()) id];
		for (id in ids) {
			removeRemoteCharacter(id);
		}
	}

	public function beginRace():Void {
		if (countdown != null) {
			countdown.remove();
		}
		toggleSpectatePossible(false);
		raceStarted = false;
		countdown = new Countdown(onCountdownFinish);
		// CountdownGraphic's art is registered on its own origin, so anchor it at
		// the screen center (Course HUD coords are top-left based).
		countdown.x = Constants.STAGE_WIDTH / 2;
		countdown.y = Constants.STAGE_HEIGHT / 2;
		addChild(countdown);
		if (localCharacter != null) {
			var startPos = localCharacter.getPos();
			LobbySocket.write('exact_pos`${Math.round(startPos.x)}`${Math.round(startPos.y)}');
		}
	}

	public function setEggSeed(seed:Int):Void {
		if (eggRound != null) {
			eggRound.initRound(seed);
		}
	}

	public function addEggs(count:Int):Void {
		if (config.gameMode != "egg" || eggRound == null) {
			return;
		}
		eggRound.addEggs(count, level);
	}

	public function setLife(lives:Int):Void {
		if (config.gameMode != "deathmatch") {
			return;
		}
		if (localCharacter != null) {
			localCharacter.setLife(lives);
		}
		if (hearts != null) {
			hearts.visible = true;
			hearts.setHearts(lives);
			displayedLives = hearts.getHeartCount();
		}
	}

	public function addLooseHat(x:Int, y:Int, rot:Int, num:Int, color:Int, color2:Int, id:Int):HatEffect {
		removeLooseHat(id);
		return new HatEffect(this, x, y, rot, num, color, color2, id, characterLayer, commandHandler);
	}

	public function removeLooseHat(id:Int):Bool {
		if (looseHats == null) {
			return false;
		}
		var hat = looseHats.get(id);
		if (hat == null) {
			return false;
		}
		hat.remove();
		return true;
	}

	// True once a loose hat has drifted 500px past the level edge it fell out of
	// (the edge depends on the level's rotation). Both the local return and the
	// remote emit paths trip on the same boundary.
	private function hatPastReturnBoundary(hat:HatEffect):Bool {
		var hatPos = RotationMath.rotatePoint(hat.posX, hat.posY, hat.rot);
		return (hatPos.y > level.maxY + 500 && hat.rot == 0)
			|| (hatPos.y < level.minY - 500 && Math.abs(hat.rot) == 180)
			|| (hatPos.x > level.maxX + 500 && hat.rot == 90)
			|| (hatPos.x < level.minX - 500 && hat.rot == -90);
	}

	public function maybeReturnHatToStart(hatId:Int):Void {
		if (looseHats == null) {
			return;
		}
		var hat = looseHats.get(hatId);
		if (hat == null) {
			return;
		}
		if (hatPastReturnBoundary(hat)) {
			returnHatToStart(hat);
		}
	}

	private function maybeEmitHatToStart(hat:HatEffect):Void {
		if (hat.sentReturnToStart) {
			return;
		}
		if (hatPastReturnBoundary(hat)) {
			hat.returningToStart();
			localCharacter.emitHatToStart(hat.id);
		}
	}

	public function collectEgg(id:Int):Void {
		if (localCharacter != null) {
			localCharacter.emitGrabEgg(id);
		}
	}

	private function playJumpSound(fixtureX:Float, fixtureY:Float):Void {
		var worldX = serverFixture.fixturePixelToWorldX(fixtureX);
		var worldY = serverFixture.fixturePixelToWorldY(fixtureY);
		playWorldJumpSound(worldX, worldY);
	}

	private function playRemoteJumpSound(worldX:Float, worldY:Float):Void {
		playWorldJumpSound(worldX, worldY);
	}

	private function playWorldJumpSound(worldX:Float, worldY:Float):Void {
		if (onPlayJumpSound != null) {
			onPlayJumpSound(worldX, worldY);
			return;
		}
		raceSounds.playWorldJumpSound(worldX, worldY);
	}

	private function playCharacterSound(request:pr2.character.Character.CharacterSoundRequest):Void {
		if (onPlayCharacterSound != null) {
			onPlayCharacterSound(request);
			return;
		}
		raceSounds.playCharacterSound(request);
	}

	private function onArtifactHatActivated():Void {
		if (musicSelection != null) {
			musicSelection.gotArtifact();
		}
		if (localCharacter != null && characterLayer != null) {
			characterLayer.addChild(new ZapEffect(localCharacter, false, false, true));
		}
	}

	private function startJetSound(request:pr2.character.Character.CharacterSoundRequest):Void {
		stopJetSound(request.target);
		if (onStartJetSound != null) {
			raceSounds.markJetSoundActive(request.target);
			onStartJetSound(request);
			return;
		}
		raceSounds.startJetSound(request);
	}

	private function stopJetSound(character:Character):Void {
		if (!raceSounds.hasJetSound(character)) {
			return;
		}
		if (onStopJetSound != null) {
			onStopJetSound(character);
		}
		raceSounds.stopJetSound(character);
	}

	private function stopAllJetSounds():Void {
		for (character in raceSounds.activeJetCharacters()) {
			stopJetSound(character);
		}
	}

	private function playSuperJumpSound():Void {
		raceSounds.playSuperJumpSound();
	}

	public function toggleSpectatePossible(value:Bool):Void {
		if (spectatePicker != null) {
			spectatePicker.toggleVisibility(value);
		}
		if (canSpectate == value) {
			return;
		}
		canSpectate = value;
		playerSpectating = null;
	}

	public function changeSpectate(tempId:Int):Void {
		if (playerSpectating != null && tempId == playerSpectating.tempID) {
			return;
		}
		playerSpectating = tempId >= 0 && playerArray != null && tempId < playerArray.length ? playerArray[tempId] : null;
	}

	public function artifactPlacementAt(stageX:Float, stageY:Float):PlaceArtifactRequest {
		var point = levelRenderer.screenToWorld(stageX - x, stageY - y);
		return {
			levelId: Std.int(config.levelId),
			x: Math.round(point.x),
			y: Math.round(point.y),
			rot: Math.round(levelRenderer.rotation)
		};
	}

	private function onCountdownFinish():Void {
		raceStarted = true;
		spawnMinionEggs();
		if (localCharacter != null) {
			localCharacter.initNetworkEmission();
		}
	}

	private function spawnMinionEggs():Void {
		if (minionEggsSpawned || eggRound == null) {
			return;
		}
		minionEggsSpawned = true;
		var placed = 0;
		for (block in level.blocks) {
			if (block.code != ObjectCodes.BLOCK_MINION_EGG) {
				continue;
			}
			if (placed >= 25) {
				break;
			}
			eggRound.addFixedEgg(block.x + 30, block.y + 30, 0);
			placed++;
		}
	}

	private function onAddedToStage(event:Event):Void {
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		stage.addEventListener(Event.DEACTIVATE, resetInput);
		stage.addEventListener(FocusEvent.FOCUS_OUT, resetInput);
	}

	private function onRemovedFromStage(event:Event):Void {
		if (stage != null) {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.removeEventListener(Event.DEACTIVATE, resetInput);
			stage.removeEventListener(FocusEvent.FOCUS_OUT, resetInput);
		}
	}

	private function onEnterFrame(event:Event):Void {
		if (player == null) {
			return;
		}
		if (levelRenderer != null && !levelRenderer.isDrawingComplete()) {
			pr2.app.DebugSignal.set("race-phase", "loading");
			return;
		}
		reportRacePhase();
		if (!drawingInfoFinished) {
			emitFinishDrawingReady();
			if (drawingInfo != null) {
				drawingInfo.finishDrawing(0);
			}
			drawingInfoFinished = true;
		}

		if (raceStarted) {
			player.step(input.copy());
			player.maybeSquash(playerArray);
			player.tickJellyfishSting(playerArray, Std.random(35) + 1);
		}
		if (raceStarted && eggRound != null) {
			if (config.gameMode == "egg") {
				eggRound.step(level, Math.round(levelRenderer.rotation), localCharacter.x, localCharacter.y, localCharacter.crouching, localCharacter.removed);
			} else {
				eggRound.step(level);
			}
		}
		if (raceStarted && config.gameMode == "hat") {
			stepLooseHats();
		}
		syncBlockVisuals();
		updatePlayerDisplay();
		var state = player.debugState();
		emitLocalItemEffect(state);
		maybeHandleLocalFinish(state);
		syncItemDisplay(state.itemId, state.itemUses);
		if (player.consumeStatsSelectSyncRequest() && onStatsSelectSyncRequest != null) {
			onStatsSelectSyncRequest();
		}
		syncStatsDisplay(state);
		syncHearts(state);
		if (onFrame != null) {
			onFrame(state);
		}
	}

	// Publishes the race lifecycle phase and the live remote-player count to the
	// document body so the OpenFL driver can detect level entry, the countdown,
	// racing, and finish, and assert that two co-joined clients actually see each
	// other (remote-count >= 1). The finished phase is also set by GamePage's quit
	// path, which Course does not observe.
	private function reportRacePhase():Void {
		var phase = if (localFinishHandled || raceEnded) {
			"finished";
		} else if (raceStarted) {
			"racing";
		} else if (countdown != null && countdown.parent != null) {
			"countdown";
		} else {
			"ready";
		}
		pr2.app.DebugSignal.set("race-phase", phase);
		pr2.app.DebugSignal.set("remote-count", Std.string(remoteCharacterCount()));
	}

	// Port of the local side of Game.finish: when the player bumps a finish block
	// the controller latches `finished`; objective mode reports each objective and
	// removes its minimap marker, while every other mode emits finish_race once and
	// lets the host page surface the finished page.
	private function maybeHandleLocalFinish(state:LocalPlayerDebugState):Void {
		if (!state.finished) {
			return;
		}
		var finishId = state.finishBlockId == null ? -1 : state.finishBlockId;
		var finishX = state.finishX == null ? 0 : state.finishX;
		var finishY = state.finishY == null ? 0 : state.finishY;
		if (config.gameMode == "objective") {
			if (state.finishBlockId == null || reachedObjectives.exists(finishId)) {
				return;
			}
			reachedObjectives.set(finishId, true);
			// Objective mode reports the objective and keeps racing; it must not
			// surface the finished page, so onFinish stays unfired here.
			if (miniMap != null) {
				miniMap.removeFinish(finishX, finishY);
			}
			if (localCharacter != null) {
				localCharacter.emitObjectiveReached(finishId, finishX, finishY);
			}
			return;
		}
		if (localFinishHandled) {
			return;
		}
		localFinishHandled = true;
		if (localCharacter != null) {
			localCharacter.emitFinishRace(finishId, finishX, finishY);
			if (config.gameMode != "hat") {
				localCharacter.beginRemove();
			}
		}
		if (onFinish != null) {
			onFinish(state);
		}
	}

	private function emitLocalItemEffect(state:LocalPlayerDebugState):Void {
		if (state.lastItemEffect == null || localCharacter == null) {
			return;
		}
		var parts = state.lastItemEffect.split(":");
		switch (parts[0]) {
			case "slash":
				var worldX = Std.int(serverFixture.fixturePixelToWorldX(state.x));
				var worldY = Std.int(serverFixture.fixturePixelToWorldY(state.y - 25));
				var direction = parts.length > 1 ? parts[1] : "right";
				var payload = 'Slash`$worldX`$worldY`$direction`' + localCharacter.tempID;
				if (eggRound != null) {
					eggRound.mountAttackVisual(payload);
				}
				LobbySocket.write('add_effect`$payload');
			case "mine":
				if (parts.length < 3) {
					return;
				}
				var coords = parts[1].split(",");
				if (coords.length < 2) {
					return;
				}
				var effectX = Std.parseFloat(coords[0]);
				var effectY = Std.parseFloat(coords[1]);
				var rotation = Std.parseFloat(parts[2]);
				if (Math.isNaN(effectX) || Math.isNaN(effectY) || Math.isNaN(rotation)) {
					return;
				}
				var tileWorldX = Std.int(Math.round((effectX - 15) / ServerLevelRenderer.TILE_SIZE)) * ServerLevelRenderer.TILE_SIZE;
				var tileWorldY = Std.int(Math.round((effectY - 15) / ServerLevelRenderer.TILE_SIZE)) * ServerLevelRenderer.TILE_SIZE;
				levelRenderer.showMineAppear(effectX, effectY, tileWorldX, tileWorldY, rotation);
				LobbySocket.write('add_effect`Mine`$effectX`$effectY`$rotation');
			default:
		}
	}

	private function syncItemDisplay(?itemId:Null<Int>, ?itemUses:Null<Int>):Void {
		if (itemDisplay == null) {
			return;
		}
		if (itemId == null && player != null) {
			var state = player.debugState();
			itemId = state.itemId;
			itemUses = state.itemUses;
		}
		if (itemId != displayedItemId) {
			itemDisplay.setItemCode(itemId == null ? 0 : itemId);
			displayedItemId = itemId;
		}
		if (itemUses != displayedItemUses) {
			itemDisplay.setAmmo(itemUses == null ? 0 : itemUses);
			displayedItemUses = itemUses;
		}
	}

	private function syncStatsDisplay(?state:LocalPlayerDebugState):Void {
		if (statsDisplay == null) {
			return;
		}
		if (state == null && player != null) {
			state = player.debugState();
		}
		if (state == null) {
			return;
		}
		var speed = Math.round(state.speedStat);
		var accel = Math.round(state.accelerationStat);
		var jump = Math.round(state.jumpStat);
		var key = '$speed,$accel,$jump';
		if (key != displayedStats) {
			statsDisplay.setStats(speed, accel, jump);
			displayedStats = key;
		}
	}

	private function syncHearts(?state:LocalPlayerDebugState):Void {
		if (hearts == null) {
			return;
		}
		if (state == null && player != null) {
			state = player.debugState();
		}
		if (state == null) {
			return;
		}
		if (config.gameMode != "deathmatch") {
			return;
		}
		if (state.lives != displayedLives) {
			hearts.visible = true;
			hearts.setHearts(state.lives);
			displayedLives = state.lives;
		}
	}

	private function syncBlockVisuals():Void {
		syncMoveBlockArrows();
		syncMoveBlockDisplays();
		// Only blocks with non-default alpha/tint (fading/removed/depleted) need
		// restyling; iterating all blocks here was O(blocks) per frame and dropped
		// large levels to a few fps. Update just the active set, and reset any block
		// that returned to default since last frame.
		var current:Map<String, Bool> = new Map();
		for (key in player.activeVisualBlockKeys()) {
			current.set(key, true);
			var tileX = tileKeyX(key);
			var tileY = tileKeyY(key);
			applyBlockVisual(tileX, tileY, player.blockAlphaAt(tileX, tileY), player.blockColorMultiplierAt(tileX, tileY),
				player.blockIceOverlayAlphaAt(tileX, tileY));
		}
		for (key in activeVisualBlocks.keys()) {
			if (!current.exists(key)) {
				applyBlockVisual(tileKeyX(key), tileKeyY(key), 1, 1, 0);
			}
		}
		activeVisualBlocks = current;
		for (event in player.consumeBlockVisualEvents()) {
			switch (event.kind) {
				case LocalActivate:
					emitLocalBlockActivation(event);
				case ArrowAnimate:
					levelRenderer.animateArrow(worldXOf(event), worldYOf(event));
				case MineExplode:
					levelRenderer.showMineExplosion(worldXOf(event), worldYOf(event));
				case BrickPieces:
					showBlockPieces(event, "BrickPieceGraphic", 10, 10, 25);
				case CrumblePieces:
					showBlockPieces(event, "CrumblePieceGraphic", 5, 5, 15);
				case MinePieces:
					showBlockPieces(event, "MinePieceGraphic", 30, 30, 50);
				case WaterRipple:
					levelRenderer.triggerWaterRipple(worldXOf(event), worldYOf(event));
				case SafetyPoof:
					levelRenderer.showTeleportPop(worldXOf(event), worldYOf(event));
				case BlockBumpSound:
					levelRenderer.animateBlockBump(worldXOf(event), worldYOf(event), event.hitX, event.hitY);
					playBlockBumpSound(event);
				case ItemBlockSound:
					playItemBlockSound();
				case HappyBlockSound:
					playStatBlockSound(event, RaceSounds.BUMP_HAPPY_SOUND);
				case SadBlockSound:
					playStatBlockSound(event, RaceSounds.BUMP_SAD_SOUND);
				case SuperJumpSound:
					playSuperJumpSound();
				case PushBlockMove:
					if (event.toTileX != null && event.toTileY != null) {
						levelRenderer.moveBlockDisplay(
							worldXOf(event),
							worldYOf(event),
							worldTileX(event.toTileX),
							worldTileY(event.toTileY)
						);
					}
			}
		}
	}

	private function syncMoveBlockDisplays():Void {
		if (levelRenderer == null || serverFixture == null || serverFixture.fixture == null) {
			return;
		}
		var fixtureBlocks = serverFixture.fixture.blocks;
		for (i in 0...fixtureBlocks.length) {
			var fixtureBlock = fixtureBlocks[i];
			if (fixtureBlock.type != pr2.level.BlockType.Move || i >= level.blocks.length) {
				continue;
			}
			var currentWorldX = (fixtureBlock.x + serverFixture.originTileX) * ServerLevelFixtureAdapter.TILE_SIZE;
			var currentWorldY = (fixtureBlock.y + serverFixture.originTileY) * ServerLevelFixtureAdapter.TILE_SIZE;
			var displayed = displayedMoveBlockPositions.get(i);
			if (displayed == null) {
				var original = level.blocks[i];
				displayedMoveBlockPositions.set(i, {worldX: original.x, worldY: original.y});
				displayed = displayedMoveBlockPositions.get(i);
			}
			if (displayed.worldX != currentWorldX || displayed.worldY != currentWorldY) {
				levelRenderer.moveBlockDisplay(displayed.worldX, displayed.worldY, currentWorldX, currentWorldY);
				displayedMoveBlockPositions.set(i, {worldX: currentWorldX, worldY: currentWorldY});
			}
		}
	}

	private function syncMoveBlockArrows():Void {
		if (levelRenderer == null || serverFixture == null || player == null) {
			return;
		}
		var current:Map<String, Bool> = new Map();
		var directions = player.activeMoveBlockDirections();
		for (tileKey in directions.keys()) {
			var tileX = tileKeyX(tileKey);
			var tileY = tileKeyY(tileKey);
			var worldX = (tileX + serverFixture.originTileX) * ServerLevelFixtureAdapter.TILE_SIZE;
			var worldY = (tileY + serverFixture.originTileY) * ServerLevelFixtureAdapter.TILE_SIZE;
			var worldKey = '$worldX,$worldY';
			current.set(worldKey, true);
			levelRenderer.showMoveBlockArrow(worldX, worldY, directions.get(tileKey));
		}
		for (worldKey in displayedMoveBlockArrows.keys()) {
			if (!current.exists(worldKey)) {
				levelRenderer.hideMoveBlockArrow(tileKeyX(worldKey), tileKeyY(worldKey));
			}
		}
		displayedMoveBlockArrows = current;
	}

	private function playBlockBumpSound(event:BlockVisualEvent):Void {
		raceSounds.playBlockBumpSound(worldXOf(event), worldYOf(event));
	}

	private function playItemBlockSound():Void {
		raceSounds.playItemBlockSound();
	}

	private function playStatBlockSound(event:BlockVisualEvent, path:String):Void {
		raceSounds.playStatBlockSound(path);
	}

	private function applyBlockVisual(tileX:Int, tileY:Int, alpha:Float, multiplier:Float, iceOverlayAlpha:Float):Void {
		var worldX = (tileX + serverFixture.originTileX) * ServerLevelFixtureAdapter.TILE_SIZE;
		var worldY = (tileY + serverFixture.originTileY) * ServerLevelFixtureAdapter.TILE_SIZE;
		levelRenderer.setBlockAlpha(worldX, worldY, alpha);
		levelRenderer.setBlockColorMultiplier(worldX, worldY, multiplier);
		levelRenderer.setBlockIceOverlayAlpha(worldX, worldY, iceOverlayAlpha);
	}

	private static inline function tileKeyX(key:String):Int {
		return Std.parseInt(key.substring(0, key.indexOf(",")));
	}

	private static inline function tileKeyY(key:String):Int {
		return Std.parseInt(key.substring(key.indexOf(",") + 1));
	}

	private function emitFinishDrawingReady():Void {
		if (finishDrawingEmitted || localCharacter == null) {
			return;
		}
		finishDrawingEmitted = true;
		var cowboyChance = Std.parseInt(config.cowboyChance);
		localCharacter.emitFinishDrawing(
			Md5.encode(data.saveString + Std.int(config.levelId) + data.version + pr2.net.ServerConfig.LEVEL_HASH_SALT),
			config.gameMode,
			finishBlockPositions(),
			level.finishBlocks().length,
			cowboyChance == null ? 5 : cowboyChance,
			config.badHats
		);
	}

	private function finishBlockPositions():String {
		var finishes = level.finishBlocks();
		if (finishes.length > 5) {
			return "all";
		}
		var parts:Array<String> = [];
		for (i in 0...finishes.length) {
			var block = finishes[i];
			parts.push('{"id":${i + 1},"x":${block.x + 15},"y":${block.y + 15}}');
		}
		return "[" + parts.join(",") + "]";
	}

	private inline function worldXOf(event:BlockVisualEvent):Int {
		return (event.tileX + serverFixture.originTileX) * ServerLevelFixtureAdapter.TILE_SIZE;
	}

	private inline function worldYOf(event:BlockVisualEvent):Int {
		return (event.tileY + serverFixture.originTileY) * ServerLevelFixtureAdapter.TILE_SIZE;
	}

	private inline function worldTileX(tileX:Int):Int {
		return (tileX + serverFixture.originTileX) * ServerLevelFixtureAdapter.TILE_SIZE;
	}

	private inline function worldTileY(tileY:Int):Int {
		return (tileY + serverFixture.originTileY) * ServerLevelFixtureAdapter.TILE_SIZE;
	}

	private function emitLocalBlockActivation(event:BlockVisualEvent):Void {
		var segX = event.tileX + serverFixture.originTileX;
		var segY = event.tileY + serverFixture.originTileY;
		var payload = event.activationPayload == null ? "" : event.activationPayload;
		LobbySocket.write('activate`$segX`$segY`$payload');
	}

	private function showBlockPieces(event:BlockVisualEvent, linkage:String, spreadX:Float, spreadY:Float, spreadRot:Float):Void {
		levelRenderer.showBlockPieces(linkage, worldXOf(event), worldYOf(event), event.count, spreadX, spreadY, spreadRot);
	}

	private function updatePlayerDisplay():Void {
		if (player == null || levelRenderer == null || serverFixture == null) {
			return;
		}

		var state = player.debugState();
		// Spin the world to match the controller's rotate-block state: the committed
		// 90-degree step is baked into the block layer while the in-progress tween
		// animates the whole course. The minimap snaps to the committed rotation,
		// mirroring Flash Course.rotate. Applied before the camera offset so culling
		// rebuilds against the new rotation in the same frame.
		levelRenderer.setCourseRotation(state.courseRotation, localCharacter.courseTweenRotation);
		if (miniMap != null) {
			miniMap.rotate(state.courseRotation);
		}
		// Use the controller's authoritative position, not player.x/player.y: the
		// PlayerDisplayPlacement.place() call below overwrites player.x/player.y
		// with the on-screen (feet) coordinate every frame. During the race that
		// is harmless because step()->syncFromController rewrites player.x/y back
		// to the controller position before the next updatePlayerDisplay. During
		// the 3-2-1 countdown, though, step() never runs, so reading player.x/y
		// here would feed the previous frame's screen coordinate back into the
		// camera target and make it scroll away, snapping back only at "Go".
		var worldX = serverFixture.fixturePixelToWorldX(state.x);
		var worldY = serverFixture.fixturePixelToWorldY(state.y);
		if (state.courseRotation != displayedCourseRotation) {
			camera.snapTo(worldX, worldY);
			displayedCourseRotation = state.courseRotation;
		} else {
			camera.follow(worldX, worldY);
		}
		levelRenderer.setCameraOffset(Constants.STAGE_WIDTH / 2 + camera.posX, Constants.STAGE_HEIGHT / 2 + camera.posY);
		if (playerDot != null) {
			playerDot.x = worldX;
			playerDot.y = worldY;
		}
		var screen = levelRenderer.worldToCharacterLayer(worldX, worldY);
		moveCharacterToLayer(player, state.touchedBlockType == "water" ? "backBackground" : "frontBackground");
		PlayerDisplayPlacement.place(player, player.display, screen.x, screen.y, player.facingScaleX);
		player.rotation = localCharacter.characterRotation;
		// Until the countdown finishes the race has not started and the local
		// player is never stepped (Flash keeps it in mode="wait"/state="stand"
		// with its physics ENTER_FRAME not yet attached). Show the idle stand pose
		// instead of the airborne "jump" the motion state derives from the not-yet
		// grounded spawn, so the character sits still on its start block through
		// the 3-2-1 rather than floating mid-jump.
		var clipState = raceStarted ? state.characterState : CharacterState.Stand;
		player.display.setState(clipState.toClipName());
		player.display.advanceOneFrame();
	}

	private function moveCharacterToLayer(character:Character, parentLayer:String):Void {
		var target = parentLayer == "backBackground" ? backCharacterLayer : characterLayer;
		if (target != null && character.parent != target) {
			target.addChild(character);
		}
	}

	private function onKeyDown(event:KeyboardEvent):Void {
		setKey(event.keyCode, true);
	}

	private function onKeyUp(event:KeyboardEvent):Void {
		setKey(event.keyCode, false);
	}

	private function setKey(keyCode:UInt, pressed:Bool):Void {
		if (raceChat != null && raceChat.inputHasFocus()) {
			return;
		}
		if (keyCode == Keyboard.LEFT || AlternateControls.matches("left", keyCode)) input.left = pressed;
		if (keyCode == Keyboard.RIGHT || AlternateControls.matches("right", keyCode)) input.right = pressed;
		if (keyCode == Keyboard.UP || AlternateControls.matches("up", keyCode)) input.jump = pressed;
		if (keyCode == Keyboard.DOWN || AlternateControls.matches("down", keyCode)) input.down = pressed;
		if (keyCode == Keyboard.SPACE || AlternateControls.matches("item", keyCode)) input.item = pressed;
	}

	private function resetInput(_:Event):Void {
		input.clear();
	}

	public function remove():Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		if (stage != null) {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.removeEventListener(Event.DEACTIVATE, resetInput);
			stage.removeEventListener(FocusEvent.FOCUS_OUT, resetInput);
		}
		if (miniMap != null) {
			miniMap.remove();
			miniMap = null;
			playerDot = null;
		}
		if (spectatePicker != null) {
			spectatePicker.remove();
			spectatePicker = null;
		}
		if (itemDisplay != null) {
			itemDisplay.remove();
			itemDisplay = null;
		}
		if (statsDisplay != null) {
			statsDisplay.remove();
			statsDisplay = null;
		}
		if (hearts != null) {
			hearts.remove();
			hearts = null;
		}
		if (musicSelection != null) {
			musicSelection.remove();
			musicSelection = null;
		}
		if (raceChat != null) {
			raceChat.remove();
			raceChat = null;
		}
		if (drawingInfo != null) {
			drawingInfo.remove();
			drawingInfo = null;
		}
		if (countdown != null) {
			countdown.remove();
			countdown = null;
		}
		if (effectBackground != null) {
			effectBackground.remove();
			effectBackground = null;
		}
		if (eggRound != null) {
			eggRound.clear();
			eggRound = null;
		}
		if (looseHats != null) {
			for (id in [for (id in looseHats.keys()) id]) {
				removeLooseHat(id);
			}
			looseHats = null;
		}
		stopAllJetSounds();
		removeAllRemoteCharacters();
		activeCommandHandler().defineCommand("activate", null);
		unregisterLocalSetHatsCommand();
		if (levelRenderer != null) {
			levelRenderer.remove();
			levelRenderer = null;
		}
		localCharacter = null;
		player = null;
		playerSpectating = null;
		playerArray = null;
		canSpectate = false;
		characterLayer = null;
		backCharacterLayer = null;
		remoteBlockActivation = null;
		remoteCharacters = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private static function parseIntArg(value:String):Int {
		var parsed = Std.parseInt(value);
		return parsed == null ? 0 : parsed;
	}
}
