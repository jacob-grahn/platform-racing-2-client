package pr2.gameplay;

#if js
import js.Browser;
#end
import haxe.crypto.Md5;
import StringTools;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.StageQuality;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import pr2.Constants;
import pr2.character.Character;
import pr2.character.CharacterState;
import pr2.character.LocalCharacter;
import pr2.character.RemoteCharacter;
import pr2.effects.ZapEffect;
import pr2.effects.Slash;
import pr2.effects.StingEffect;
import pr2.effects.BlockPiece;
import pr2.effects.FollowFadeEffect;
import pr2.gameplay.GameCommandShell.LocalCharacterInit;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.gameplay.SpecialEvent.PlaceArtifactRequest;
import pr2.gameplay.player.BlockVisualEvent;
import pr2.gameplay.player.BlockVisualEvent.BlockVisualEventKind;
import pr2.gameplay.player.LocalPlayerState;
import pr2.gameplay.player.LocalPlayerInput;
import pr2.gameplay.player.PlayerDisplayPlacement;
import pr2.gameplay.presentation.CharacterPresentationLayer;
import pr2.gameplay.presentation.CameraPresentationPose;
import pr2.gameplay.presentation.PresentationPose;
import pr2.lobby.account.AlternateControls;
import pr2.lobby.chat.ChatText;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.level.ObjectCodes;
import pr2.level.LevelRenderer;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerLevelData;
import pr2.runtime.FontResolver;
import pr2.runtime.FrameClock;

/**
	The in-game race shell: a decoded `Level` rendered with the authored HUD
	mounted at Course's holder->stage offsets, a local player driven by
	`LocalCharacter`, a follow camera, and incremental block drawing.

	Extracted from `CampaignTestScreen` so the real `GamePage` can mount the shell
	directly (without the campaign-list fetch / debug-overlay chrome the harness
	wraps around it). The harness now builds a `Course` too, supplying `onChatLine`
	to intercept `/debug` and `onFrame` to drive its status overlay.

	Local and remote characters share the front/back character layers, while the
	roster controller owns their command registration and lifecycle.
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
	public static inline var TIMER_X:Float = 490;
	public static inline var TIMER_Y:Float = 2;
	public static inline var STATS_X:Float = 490;
	public static inline var STATS_Y:Float = 34;
	public static inline var HEARTS_X:Float = 515;
	public static inline var HEARTS_Y:Float = 59;

	private final level:Level;
	private final data:ServerLevelData;
	private final config:LevelConfig;
	private final onChatLine:Null<String->Bool>;
	private final onFrame:Null<LocalPlayerState->Void>;
	private final commandHandler:CommandHandler;
	private var suppliedMusicSelection:Null<MusicSelection>;

	private final input:LocalPlayerInput = new LocalPlayerInput();

	public var levelRenderer(default, null):LevelRenderer;
	public var backCharacterLayer(default, null):Sprite;
	public var characterLayer(default, null):Sprite;
	public var localCharacter(default, null):LocalCharacter;
	public var remoteCharacters(default, null):Map<Int, RemoteCharacter> = new Map();
	public var playerArray(default, null):Array<Character> = [];
	public var playerSpectating(default, null):Null<Character>;
	public var canSpectate(default, null):Bool = false;
	private var blockController:BlockController;
	private var player:LocalCharacter;
	private var camera:CameraFollow;
	private var snakeManager:SnakeManager;
	private var remoteBlockActivation:RemoteBlockActivation;
	private final localPresentationPose:PresentationPose = new PresentationPose();
	private final cameraPresentationPose:CameraPresentationPose = new CameraPresentationPose();
	private var localPresentationBeforeCourseRotation:Int = 0;
	private var localPresentationDeltaX:Float = 0;
	private var localPresentationDeltaY:Float = 0;
	private var localPresentationDiscontinuityPending:Bool = true;

	public var miniMap(default, null):MiniMap;
	public var spectatePicker(default, null):SpectatePicker;
	public var itemDisplay(default, null):ItemDisplay;
	public var statsDisplay(default, null):StatsDisplay;
	public var timer(default, null):CourseTimer;
	public var hearts(default, null):Hearts;
	public var roguelikeProgressText(default, null):TextField;
	public var musicSelection(default, null):MusicSelection;
	public var raceChat(default, null):RaceChat;
	public var drawingInfo(default, null):DrawingInfo;
	public var countdown(default, null):Countdown;
	public var eggRound(default, null):EggRound;
	public var effectBackground(default, null):EffectBackground;
	public var looseHats(default, null):Map<Int, HatEffect> = new Map();
	private final looseHatPresentationOwners:Array<HatEffect> = [];
	public var raceStarted(default, null):Bool = false;
	public var framesPlaying(default, null):Int = 0;
	/** Suppresses live-server finish submission for local/editor-hosted courses. */
	public var offlineMode:Bool = false;
	public var debugLastCrumbleForce(default, null):String = "";
	public var debugCrumbleActivations(default, null):Int = 0;
	public var debugCrumblePiecesSpawned(default, null):Int = 0;

	// Invoked once when the local player reaches a finish block. The host page
	// (GamePage) uses it to mark the player done and show the finished page; the
	// network notification itself is emitted here, mirroring Flash Game.finish.
	public var onFinish:Null<LocalPlayerState->Void> = null;
	public var onOutOfTime:Null<Void->Void> = null;
	public var onPlayJumpSound:Null<Float->Float->Void> = null;
	public var onPlayCharacterSound:Null<pr2.character.Character.CharacterSoundRequest->Void> = null;
	public var onStartJetSound:Null<pr2.character.Character.CharacterSoundRequest->Void> = null;
	public var onStopJetSound:Null<Character->Void> = null;
	public var onStatsSelectSyncRequest:Null<Void->Void> = null;
	public var onCollectEgg:Null<Int->Bool> = null;
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
	private final displayedMoveBlockPositions:Map<LevelBlock, {worldX:Int, worldY:Int, originalWorldX:Int, originalWorldY:Int}> = new Map();
	private var displayedMoveBlockArrows:Map<String, Bool> = new Map();
	// Tile keys ("x,y") whose block visual was non-default last frame, so they can
	// be reset to alpha/tint 1 once they return to default. See syncBlockVisuals.
	private var activeVisualBlocks:Map<String, Bool> = new Map();
	private var startPositions:Array<{x:Int, y:Int}> = [];
	private var raceSounds:RaceSounds;
	private var localCommandNames:Array<String> = [];
	private var reachedObjectives:Map<Int, Bool> = new Map();
	private var minionEggsSpawned:Bool = false;
	private var frameCounterActive:Bool = false;
	private var physicsTraceFrame:Int = 0;
	private var rotationTweenActive:Bool = false;
	private var currentStageQuality:StageQuality = StageQuality.HIGH;
	private var keyScrollActive:Bool = false;
	private var scrollLeft:Bool = false;
	private var scrollRight:Bool = false;
	private var scrollUp:Bool = false;
	private var scrollDown:Bool = false;
	private var scrollShift:Bool = false;
	private var scrollVelX:Float = 0;
	private var scrollVelY:Float = 0;
	private final particleEffects:CourseParticleEffects;
	private final roster:CourseRosterController;
	private final blockVisuals:CourseBlockVisualController;

	public function new(level:Level, data:ServerLevelData, config:LevelConfig, ?onChatLine:String->Bool, ?onFrame:LocalPlayerState->Void,
			?commandHandler:CommandHandler, ?musicSelection:MusicSelection) {
		super();
		this.level = level;
		this.data = data;
		this.config = config;
		this.onChatLine = onChatLine;
		this.onFrame = onFrame;
		this.commandHandler = commandHandler != null ? commandHandler : CommandHandler.commandHandler;
		suppliedMusicSelection = musicSelection;
		roster = new CourseRosterController(this);
		blockVisuals = new CourseBlockVisualController(this);
		particleEffects = new CourseParticleEffects(function() {
			return levelRenderer == null ? null : levelRenderer.worldEffectLayer();
		});
		build();
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	public function allowedItemsForTests():Array<Int> {
		return config.allowedItems.copy();
	}

	public function debugStageQualityForTests():StageQuality {
		return currentStageQuality;
	}

	public function debugKeyScrollActive():Bool {
		return keyScrollActive;
	}

	private function build():Void {
		level.configureRuntime(Std.string(config.levelId), config.title, data.gravity);
		var startBlocks = level.startBlocks();
		var focus = startBlocks.length == 0 ? null : startBlocks[0];
		levelRenderer = new LevelRenderer(level, focus, LevelRenderer.DEFAULT_FOCUS_X, LevelRenderer.DEFAULT_FOCUS_Y, true);
		addChild(levelRenderer);
		// Spatial audio uses the authoritative 30 Hz offset. Presentation-only
		// camera extrapolation remains visual and cannot feed back into sound.
		raceSounds = new RaceSounds(levelRenderer.cameraOffset);

		blockController = new BlockController(level);
		blockController.onBlockRemoved = removeRuntimeBlock;
		blockController.onBlockAdded = addRuntimeBlock;
		player = new LocalCharacter(level, 1, 1, 1, 1, blockController);
		snakeManager = new SnakeManager(level, levelRenderer, player.controller);
		player.onPlayJumpSound = playJumpSound;
		player.onPlayCharacterSound = playCharacterSound;
		player.onArtifactVisualActivated = onArtifactVisualActivated;
		player.onArtifactHatActivated = onArtifactHatActivated;
		player.onStartJetSound = startJetSound;
		player.onStopJetSound = stopJetSound;
		particleEffects.install(player);
		player.setGameMode(config.gameMode);
		player.setHatsAllowed(config.gameMode != Modes.roguelike);
		player.setAllowedItems(config.allowedItems);
		player.setCourseTime(maxCourseTimeSeconds());
		localCharacter = player;
		player.controller.onCourseRotationCommitted = player.commitNetworkCourseRotation;
		player.controller.onRotationTweenFrame = player.setNetworkRotation;
		playerArray[player.tempID] = player;
		remoteBlockActivation = new RemoteBlockActivation(level, levelRenderer);
		activeCommandHandler().defineCommand("activate", activateCommand);
		buildStartPositions();
		positionLocalAtStartCenter();

		characterLayer = new Sprite();
		characterLayer.addChild(player);
		backCharacterLayer = new Sprite();
		levelRenderer.attachBackCharacterLayer(backCharacterLayer);
		levelRenderer.attachFrontCharacterLayer(characterLayer);

		camera = new CameraFollow(0, 0);
		camera.snapTo(player.x, player.y);

		buildMiniMap();
		buildSpectatePicker();
		buildItemDisplay();
		buildTimer();
		buildStatsDisplay();
		buildHearts();
		buildMusicSelection();
		buildRaceChat();
		buildDrawingInfo();
		effectBackground = new EffectBackground(this, commandHandler);
		levelRenderer.attachEffectLayer(effectBackground);
		eggRound = new EggRound(commandHandler, collectEgg, effectBackground,
			levelRenderer.cameraOffset, null, null, function(shooterId:Int):Void {
				if (localCharacter != null && shooterId != localCharacter.tempID && !localCharacter.isFrozen()) {
					localCharacter.freeze();
				}
			}, function(block:LevelBlock):Void {
				if (localCharacter == null || block.code == ObjectCodes.BLOCK_ICE) {
					return;
				}
				localCharacter.freezeBlock(block.x, block.y);
			}, null, function(shooterId:Int, impulseX:Float, impulseY:Float):Void {
				if (localCharacter != null && shooterId != localCharacter.tempID && !localCharacter.removed) {
					localCharacter.receiveHit(impulseX, impulseY);
				}
			}, function(shooterId:Int, block:LevelBlock, damageForce:Float, senderRotation:Int):Void {
				handleLaserBlockHit(shooterId, block, damageForce, senderRotation);
			}, function():Int {
				return localCharacter == null ? -0x3fffffff : localCharacter.tempID;
			}, function(payload:String):Void {
				if (effectBackground != null) {
					effectBackground.addEffect(payload.split("`"));
				}
			});
		updatePlayerDisplay();
	}

	private function handleLaserBlockHit(shooterId:Int, block:LevelBlock, damageForce:Float, senderRotation:Int):Void {
		if (localCharacter != null && shooterId == -1) {
			// Egg attacks are locally authoritative and retain the full block
			// damage path, including destructible-block activation.
			localCharacter.controller.damageBlockFromEffect(block, damageForce);
			return;
		}
		if (!isRemoteLaserShooter(shooterId, localCharacter == null ? null : localCharacter.tempID)) {
			// The local ItemController already applies this collision. Ignore the
			// echoed visual projectile so it cannot bump or activate the block twice.
			return;
		}
		animateEffectBlockBump(block, damageForce, senderRotation);
	}

	private static function isRemoteLaserShooter(shooterId:Int, localPlayerId:Null<Int>):Bool {
		return localPlayerId == null || shooterId != localPlayerId;
	}

	private function animateEffectBlockBump(block:LevelBlock, damageForce:Float, impulseRotation:Int):Void {
		if (levelRenderer == null) {
			return;
		}
		var clampedForce = Math.max(-20, Math.min(20, damageForce));
		var visualImpulse = RotationMath.rotatePoint(clampedForce, 0, impulseRotation);
		levelRenderer.animateBlockBump(block.worldX, block.worldY, visualImpulse.x, visualImpulse.y);
	}

	private function activeCommandHandler():CommandHandler {
		return commandHandler;
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
			miniMap.addBlock(block.code, block.worldX, block.worldY);
		}
		miniMap.rasterize();
		playerDot = miniMap.getDot();
		playerDot.setTempID(0, true);
		playerDot.setHoverInfo(1, LobbySession.userName == "" ? "Guest" : LobbySession.userName, true);
		miniMap.x = MINIMAP_X;
		miniMap.y = MINIMAP_Y;
		addChild(miniMap);
	}

	private function rebuildMiniMap():Void {
		var index = -1;
		if (miniMap != null) {
			if (miniMap.parent == this) {
				index = getChildIndex(miniMap);
			}
			miniMap.remove();
			miniMap = null;
			playerDot = null;
		}
		buildMiniMap();
		if (index >= 0 && miniMap != null && miniMap.parent == this) {
			setChildIndex(miniMap, Std.int(Math.min(index, numChildren - 1)));
		}
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

	private function buildTimer():Void {
		timer = new CourseTimer({onOutOfTime: outOfTimeHandler});
		timer.x = TIMER_X;
		timer.y = TIMER_Y;
		timer.mouseEnabled = false;
		timer.mouseChildren = false;
		timer.setTime(maxCourseTimeSeconds());
		addChild(timer);
	}

	private function buildHearts():Void {
		hearts = new Hearts();
		hearts.x = HEARTS_X;
		hearts.y = HEARTS_Y;
		hearts.visible = false;
		addChild(hearts);
		if (config.gameMode == Modes.roguelike) {
			roguelikeProgressText = new TextField();
			roguelikeProgressText.defaultTextFormat = new TextFormat(FontResolver.resolve("Verdana"), 10, 0x000000);
			roguelikeProgressText.x = HEARTS_X - 67;
			roguelikeProgressText.y = HEARTS_Y;
			roguelikeProgressText.width = 63;
			roguelikeProgressText.height = 18;
			roguelikeProgressText.selectable = false;
			roguelikeProgressText.mouseEnabled = false;
			addChild(roguelikeProgressText);
		}
		displayedLives = null;
		syncHearts();
	}

	private function buildMusicSelection():Void {
		var shouldSetSong = suppliedMusicSelection == null;
		if (suppliedMusicSelection != null) {
			musicSelection = suppliedMusicSelection;
			suppliedMusicSelection = null;
		} else {
			musicSelection = new MusicSelection();
		}
		musicSelection.x = MUSIC_X;
		musicSelection.y = MUSIC_Y;
		addChild(musicSelection);
		if (shouldSetSong) {
			musicSelection.setSong(data.song);
		}
	}

	/**
		Transfers the level music UI/player to a replacement test-course shell.
		Flash's TestCourse.restart() keeps its Course and GameSound instances, so
		the song continues instead of opening another stream.
	**/
	public function releaseMusicSelection():Null<MusicSelection> {
		var released = musicSelection;
		musicSelection = null;
		if (released != null && released.parent != null) {
			released.parent.removeChild(released);
		}
		return released;
	}

	private function buildRaceChat():Void {
		raceChat = new RaceChat(handleRaceChatLine);
		raceChat.x = CHAT_X;
		raceChat.y = CHAT_Y;
		addChild(raceChat);
	}

	public function removeRaceChat():Void {
		if (raceChat == null) {
			return;
		}
		raceChat.remove();
		raceChat = null;
	}

	private function buildDrawingInfo():Void {
		drawingInfo = new DrawingInfo(null, config.gameMode, Std.int(config.levelId), function():Int return framesPlaying);
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
				startPositions.push({x: block.worldX + 15, y: block.worldY + 15});
			}
		}
	}

	private function positionLocalAtStartCenter():Void {
		if (localCharacter == null || startPositions.length == 0) {
			return;
		}
		var startIndex = LobbySession.tournamentMode ? 0 : localCharacter.tempID;
		if (startIndex < 0 || startIndex >= startPositions.length) {
			startIndex = 0;
		}
		var start = startPositions[startIndex];
		localCharacter.resetControllerForRaceStart(start.x, start.y);
	}

	private function maxCourseTimeSeconds():Int {
		var parsed = Std.parseFloat(config.maxTime);
		return Math.isNaN(parsed) ? 0 : Std.int(parsed);
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
				hat.step(level, levelRenderer.courseRotationDegrees, localCharacter.x, localCharacter.y, localCharacter.crouching,
					localCharacter.removed, isDonePlaying());
				if (config.gameMode == "hat") {
					maybeEmitHatToStart(hat);
				}
			}
		}
	}

	private function renderLooseHatPresentationFrame():Void {
		for (index in 0...looseHatPresentationOwners.length) {
			looseHatPresentationOwners[index].renderPresentationFrame();
		}
	}

	public function isDonePlaying():Bool {
		return localFinishHandled || raceEnded;
	}

	public function gameMode():String {
		return config.gameMode;
	}

	private static function isStartBlock(block:LevelBlock):Bool {
		return block.code >= ObjectCodes.BLOCK_START1 && block.code <= ObjectCodes.BLOCK_START4;
	}

	/** Lets a wrapper (the debug harness) intercept chat lines before display. **/
	public function handleRaceChatLine(message:String):Bool {
		if (ChatText.trimWhitespace(message).toLowerCase() == "/level" && config.levelId > 0) {
			new LevelInfoPopup(Std.int(config.levelId));
			return true;
		}
		return onChatLine != null && onChatLine(message);
	}

	public function createLocalCharacter(init:LocalCharacterInit):LocalCharacter {
		var character = roster.createLocalCharacter(init);
		invalidateLocalPresentationPose();
		return character;
	}
	public function createRemoteCharacter(init:RemoteCharacterInit):RemoteCharacter return roster.createRemoteCharacter(init);
	public function getRemoteCharacter(tempId:Int):Null<RemoteCharacter> return roster.getRemoteCharacter(tempId);
	public function remoteCharacterCount():Int return roster.remoteCharacterCount();
	public function removeRemoteCharacter(tempId:Int):Void roster.removeRemoteCharacter(tempId);
	public function removeAllRemoteCharacters():Void roster.removeAllRemoteCharacters();

	private function activateCommand(args:Array<String>):Void roster.activateCommand(args);
	private function unregisterLocalCommands():Void roster.unregisterLocalCommands();

	public function beginRace():Void {
		if (countdown != null) {
			countdown.remove();
		}
		if (drawingInfo != null) {
			drawingInfo.clear();
		}
		framesPlaying = 0;
		frameCounterActive = true;
		if (timer != null) {
			timer.init();
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

	public function teleportLocalToStage(stageX:Float, stageY:Float):Bool {
		if (localCharacter == null || levelRenderer == null) {
			return false;
		}
		var local = globalToLocal(new Point(stageX, stageY));
		var world = levelRenderer.screenToWorld(local.x, local.y);
		var state = localCharacter.stateSnapshot();
		levelRenderer.showTeleportPop(state.x, state.y);
		invalidateLocalPresentationPose();
		localCharacter.setControllerPosition(world.x, world.y);
		levelRenderer.showTeleportPop(world.x, world.y);
		updatePlayerDisplay();
		return true;
	}

	private function removeRuntimeBlock(block:LevelBlock, removedIndex:Int):Void {
		if (levelRenderer != null) {
			levelRenderer.removeRuntimeBlockDisplay(block, removedIndex);
		}
	}

	private function addRuntimeBlock(block:LevelBlock):Void {
		if (levelRenderer != null) {
			levelRenderer.ensureRuntimeBlockDisplay(block);
		}
	}

	public function placeRuntimeMine(worldX:Int, worldY:Int):Bool {
		if (blockController == null) {
			return false;
		}
		return blockController.addBlock(new LevelBlock(
			Std.int(Math.floor(worldX / level.tileSize)),
			Std.int(Math.floor(worldY / level.tileSize)),
			pr2.level.BlockType.Mine
		));
	}

	public function setLife(lives:Int):Void {
		if (config.gameMode != "deathmatch" && config.gameMode != Modes.roguelike) {
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

	public function outOfTimeHandler():Void {
		frameCounterActive = false;
		if (onOutOfTime != null) {
			onOutOfTime();
		}
	}

	public function addLooseHat(x:Int, y:Int, rot:Int, num:Int, color:Int, color2:Int, id:Int):HatEffect {
		removeLooseHat(id);
		var hat = new HatEffect(this, x, y, rot, num, color, color2, id, effectBackground, commandHandler);
		looseHatPresentationOwners.push(hat);
		return hat;
	}

	public function unregisterLooseHatPresentationOwner(hat:HatEffect):Void {
		var index = looseHatPresentationOwners.indexOf(hat);
		if (index >= 0) looseHatPresentationOwners.splice(index, 1);
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
		var hatPos = CoordinateFrames.canonicalFromGravityValues(hat.posX, hat.posY, hat.rot);
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
		if (config.gameMode != "egg") {
			return;
		}
		if (onCollectEgg != null && onCollectEgg(id)) {
			return;
		}
		if (localCharacter != null) {
			localCharacter.emitGrabEgg(id);
		}
	}

	private function playJumpSound(worldX:Float, worldY:Float):Void {
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
	}

	private function onArtifactVisualActivated():Void {
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

	@:allow(pr2.gameplay.CharacterLifecycleTest)
	private function activeParticleEmitterCount():Int {
		return particleEffects.activeEmitterCount();
	}

	@:allow(pr2.gameplay.CharacterLifecycleTest)
	private function activeDjinnEmitterCount():Int {
		return particleEffects.activeDjinnEmitterCount();
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
		var previousRemote = Std.downcast(playerSpectating, RemoteCharacter);
		if (previousRemote != null) previousRemote.requestPresentationSnap();
		canSpectate = value;
		playerSpectating = null;
		markLocalPresentationDiscontinuity();
		toggleKeyScroll(value);
	}

	public function changeSpectate(tempId:Int):Void {
		if (playerSpectating != null && tempId == playerSpectating.tempID) {
			return;
		}
		var previousRemote = Std.downcast(playerSpectating, RemoteCharacter);
		if (previousRemote != null) previousRemote.requestPresentationSnap();
		playerSpectating = tempId >= 0 && playerArray != null && tempId < playerArray.length ? playerArray[tempId] : null;
		markLocalPresentationDiscontinuity();
		toggleKeyScroll(canSpectate && playerSpectating == null);
	}

	public function artifactPlacementAt(stageX:Float, stageY:Float):PlaceArtifactRequest {
		var point = levelRenderer.screenToWorld(stageX - x, stageY - y);
		return {
			levelId: Std.int(config.levelId),
			x: Math.round(point.x),
			y: Math.round(point.y),
			rot: levelRenderer.courseRotationDegrees
		};
	}

	private function onCountdownFinish():Void {
		raceStarted = true;
		blockController.startGameplay();
		physicsTraceFrame = 0;
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
			eggRound.addFixedEgg(block.worldX + 30, block.worldY + 30, 0);
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
		if (!FrameClock.shouldRunSimulationFrame()) {
			if (FrameClock.shouldRenderIntermediatePresentationFrame()) {
				renderLocalPresentationFrame();
				renderRemotePresentationFrames();
				renderFollowFadePresentationFrames();
				if (snakeManager != null) snakeManager.renderPresentationFrame();
				if (eggRound != null) eggRound.renderPresentationFrame();
				renderLooseHatPresentationFrame();
				renderCameraPresentationFrame();
				renderCourseRotationPresentationFrame();
			}
			return;
		}
		if (frameCounterActive) {
			framesPlaying++;
		}
		if (player == null) {
			return;
		}
		beginLocalPresentationPoseCapture(player.stateSnapshot());
		if (levelRenderer != null && !levelRenderer.isDrawingComplete()) {
			toggleKeyScroll(true);
			finishLocalPresentationPoseCapture(player.stateSnapshot(), false);
			updatePlayerDisplay();
			pr2.app.DebugSignal.set("race-phase", "loading");
			return;
		}
		if (!localFinishHandled && !raceEnded) {
			toggleKeyScroll(false);
		}
		reportRacePhase();
		if (!drawingInfoFinished) {
			emitFinishDrawingReady();
			if (drawingInfo != null) {
				drawingInfo.finishDrawing(0);
			}
			drawingInfoFinished = true;
		}

		var localPhysicsStepped = false;
		if (raceStarted && !localFinishHandled) {
			if (physicsTraceRuntimeEnabled() && physicsTraceFrame < physicsTraceFrameLimit()) {
				player.controller.beginDetailedTraceFrame(physicsTraceFrame);
			} else {
				player.controller.stopDetailedTrace();
			}
			var playerInput = input.copy();
			var beforeStep = player.stateSnapshot();
			if ((snakeManager != null && snakeManager.localActive()) || (input.item && beforeStep.itemId == Items.SNAKE)) {
				playerInput.left = false;
				playerInput.right = false;
				playerInput.jump = false;
				playerInput.down = false;
			}
			player.step(playerInput);
			localPhysicsStepped = true;
			player.maybeSquash(playerArray);
			player.tickJellyfishSting(playerArray, Std.random(35) + 1);
			physicsTraceFrame++;
		} else {
			player.controller.stopDetailedTrace();
		}
		var state = player.stateSnapshot();
		if (raceStarted && !localFinishHandled && state.lastItemEffect == "snake_start" && snakeManager != null) {
			snakeManager.startLocal(localCharacter.tempID, state.x, state.y, localCharacter.facingScaleX);
		}
		if (snakeManager != null) {
			snakeManager.step();
		}
		if (raceStarted && eggRound != null) {
			eggRound.step(level, levelRenderer.courseRotationDegrees, localCharacter.x, localCharacter.y, localCharacter.crouching,
				localCharacter.removed, config.gameMode == "egg");
		}
		if (raceStarted) {
			stepLooseHats();
		}
		syncBlockVisuals();
		state = player.stateSnapshot();
		if (raceStarted && !localFinishHandled) {
			player.x = state.x;
			player.y = state.y;
			localCharacter.emitNetworkUpdate(state.touchedBlockType == "water" ? "backBackground" : "frontBackground");
		}
		finishLocalPresentationPoseCapture(state, localPhysicsStepped && !state.finished);
		updatePlayerDisplay();
		emitLocalItemEffect(state);
		maybeHandleLocalFinish(state);
		// TestCourse's finish callback synchronously removes this Course and mounts
		// its replacement. Do not continue the old frame after that teardown.
		if (player == null) {
			return;
		}
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

	private function beginLocalPresentationPoseCapture(state:LocalPlayerState):Void {
		localCharacter.clearPresentationWorldOffset();
		localPresentationBeforeCourseRotation = state.courseRotation;
		localPresentationPose.beginSimulationTick(
			state.x,
			state.y,
			localCharacter.characterRotation,
			localCharacter.facingScaleX,
			presentationLayerFor(state)
		);
	}

	private function finishLocalPresentationPoseCapture(state:LocalPlayerState, predictMovement:Bool = true):Void {
		var layer = presentationLayerFor(state);
		// Local x/y prediction is anchored at this authoritative post-step pose
		// and uses half of the predicted next authoritative displacement.
		// Contacts and teleports therefore do not carry the completed movement
		// delta forward, and block impulses cannot predict into active surfaces.
		if (predictMovement) {
			localPresentationDeltaX = localCharacter.controller.presentationDeltaX();
			localPresentationDeltaY = localCharacter.controller.presentationDeltaY();
		} else {
			localPresentationDeltaX = 0;
			localPresentationDeltaY = 0;
		}
		// Rotation still uses pose-delta extrapolation, so keep its lifecycle,
		// layer, and committed-course-rotation guard independent of x/y.
		var discontinuous = localPresentationDiscontinuityPending
			|| state.courseRotation != localPresentationBeforeCourseRotation
			|| layer != localPresentationPose.previousLayer;
		localPresentationPose.finishSimulationTick(
			state.x,
			state.y,
			localCharacter.characterRotation,
			localCharacter.facingScaleX,
			layer,
			discontinuous
		);
		localPresentationDiscontinuityPending = false;
	}

	private static inline function presentationLayerFor(state:LocalPlayerState):CharacterPresentationLayer {
		return state.touchedBlockType == "water" ? CharacterPresentationLayer.Back : CharacterPresentationLayer.Front;
	}

	private function renderLocalPresentationFrame():Void {
		if (player == null || !localPresentationPose.hasSamples) {
			return;
		}
		// Reuse the exact CharacterView pose selected on the last simulation tick.
		// Presentation frames transform that bitmap/vector tree only: they never
		// select a clip, advance its timeline, or synthesize body-art frames.
		var rotationFactor = localPresentationPose.discontinuity ? 0.0 : 0.5;
		applyLocalPresentationPose(
			localPresentationPose.currentX + localPresentationDeltaX * 0.5,
			localPresentationPose.currentY + localPresentationDeltaY * 0.5,
			localPresentationPose.extrapolatedRotation(rotationFactor),
			localPresentationPose.currentFacing
		);
	}

	private function markLocalPresentationDiscontinuity():Void {
		localPresentationDiscontinuityPending = true;
		localPresentationPose.markDiscontinuity();
		var spectatedRemote = Std.downcast(playerSpectating, RemoteCharacter);
		if (spectatedRemote != null) spectatedRemote.requestPresentationSnap();
		snapPresentationTransformsToAuthoritative();
	}

	private function invalidateLocalPresentationPose():Void {
		localPresentationDiscontinuityPending = true;
		localPresentationDeltaX = 0;
		localPresentationDeltaY = 0;
		localPresentationPose.clear();
		snapPresentationTransformsToAuthoritative();
	}

	private function snapPresentationTransformsToAuthoritative():Void {
		if (player != null) {
			if (localPresentationPose.hasSamples) {
				applyLocalPresentationPose(
					localPresentationPose.currentX,
					localPresentationPose.currentY,
					localPresentationPose.currentRotation,
					localPresentationPose.currentFacing
				);
			} else {
				player.display.x = 0;
				player.display.y = 0;
				player.display.rotation = 0;
				player.display.scaleX = PlayerDisplayPlacement.CHARACTER_SCALE * player.facingScaleX;
				player.display.scaleY = PlayerDisplayPlacement.CHARACTER_SCALE;
				player.clearPresentationWorldOffset();
			}
		}
		if (levelRenderer != null) {
			if (cameraPresentationPose.hasSamples) {
				cameraPresentationPose.present(cameraPresentationPose.currentX, cameraPresentationPose.currentY);
				levelRenderer.setPresentationCameraOffset(
					Constants.STAGE_WIDTH / 2 + cameraPresentationPose.currentX,
					Constants.STAGE_HEIGHT / 2 + cameraPresentationPose.currentY
				);
			}
			levelRenderer.setPresentationCourseTweenRotation(levelRenderer.courseTweenRotation());
		}
	}

	private function applyLocalPresentationPose(x:Float, y:Float, rotation:Float, facing:Int):Void {
		var worldOffsetX = x - localPresentationPose.currentX;
		var worldOffsetY = y - localPresentationPose.currentY;
		var radians = -localPresentationPose.currentRotation * Math.PI / 180;
		var cos = Math.cos(radians);
		var sin = Math.sin(radians);
		player.display.x = worldOffsetX * cos - worldOffsetY * sin;
		player.display.y = worldOffsetX * sin + worldOffsetY * cos;
		player.display.rotation = rotation - localPresentationPose.currentRotation;
		player.display.scaleX = PlayerDisplayPlacement.CHARACTER_SCALE * facing;
		player.display.scaleY = PlayerDisplayPlacement.CHARACTER_SCALE;
		player.setPresentationWorldOffset(worldOffsetX, worldOffsetY);
	}

	private function renderRemotePresentationFrames():Void {
		if (playerArray == null) return;
		for (index in 0...playerArray.length) {
			var character = Std.downcast(playerArray[index], RemoteCharacter);
			if (character != null) character.renderPresentationFrame();
		}
	}

	private function renderFollowFadePresentationFrames():Void {
		if (characterLayer == null) return;
		for (index in 0...characterLayer.numChildren) {
			var effect = Std.downcast(characterLayer.getChildAt(index), FollowFadeEffect);
			if (effect != null) effect.renderPresentationFrame();
		}
	}

	private function renderCameraPresentationFrame():Void {
		if (levelRenderer == null || !cameraPresentationPose.hasSamples) {
			return;
		}
		var factor = localPresentationPose.hasSamples && !localPresentationPose.discontinuity ? 0.5 : 0.0;
		cameraPresentationPose.present(
			cameraPresentationPose.extrapolatedX(factor),
			cameraPresentationPose.extrapolatedY(factor)
		);
		levelRenderer.setPresentationCameraOffset(
			Constants.STAGE_WIDTH / 2 + cameraPresentationPose.presentedX,
			Constants.STAGE_HEIGHT / 2 + cameraPresentationPose.presentedY
		);
	}

	private function renderCourseRotationPresentationFrame():Void {
		if (levelRenderer == null || !localPresentationPose.hasSamples) {
			return;
		}
		var factor = localPresentationPose.discontinuity ? 0.0 : 0.5;
		levelRenderer.setPresentationCourseTweenRotation(
			-localPresentationPose.extrapolatedRotation(factor)
		);
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

	private function physicsTraceRuntimeEnabled():Bool {
		#if js
		var queryValue = physicsTraceQueryValue();
		if (queryValue != null) {
			return isEnabledFlag(queryValue);
		}
		var windowValue = untyped Browser.window.__PR2_PHYSICS_TRACE;
		if (windowValue != null) {
			return isEnabledFlag(Std.string(windowValue));
		}
		try {
			var storage = Browser.window.localStorage;
			if (storage != null) {
				for (key in ["pr2PhysicsTrace", "PR2_PHYSICS_TRACE", "physicsTrace"]) {
					var value = storage.getItem(key);
					if (value != null) {
						return isEnabledFlag(value);
					}
				}
			}
		} catch (error:Dynamic) {}
		#end
		return false;
	}

	private function physicsTraceFrameLimit():Int {
		#if js
		var value = runtimeValue("physicsTraceFrames", ["pr2PhysicsTraceFrames", "PR2_PHYSICS_TRACE_FRAMES", "physicsTraceFrames"]);
		if (value != null) {
			var parsed = Std.parseInt(value);
			if (parsed != null && parsed > 0) {
				return parsed;
			}
		}
		#end
		return 2500;
	}

	private static function isEnabledFlag(value:String):Bool {
		var normalized = value == null ? "" : value.toLowerCase();
		return normalized == "1" || normalized == "true" || normalized == "yes" || normalized == "on";
	}

	#if js
	private static function physicsTraceQueryValue():Null<String> {
		for (name in ["physicsTrace", "pr2PhysicsTrace", "tracePhysics"]) {
			var value = queryValue(name);
			if (value != null) {
				return value;
			}
		}
		return null;
	}

	private static function runtimeValue(queryName:String, storageNames:Array<String>):Null<String> {
		var value = queryValue(queryName);
		if (value != null) {
			return value;
		}
		try {
			var storage = Browser.window.localStorage;
			if (storage != null) {
				for (name in storageNames) {
					value = storage.getItem(name);
					if (value != null) {
						return value;
					}
				}
			}
		} catch (error:Dynamic) {}
		return null;
	}

	private static function queryValue(name:String):Null<String> {
		var query = Browser.window.location.search;
		if (query == null || query.length <= 1) {
			return null;
		}
		for (part in query.substr(1).split("&")) {
			var pieces = part.split("=");
			var key = StringTools.urlDecode(pieces[0]);
			if (key == name) {
				return pieces.length > 1 ? StringTools.urlDecode(pieces[1]) : "1";
			}
		}
		return null;
	}
	#end

	// Port of the local side of Game.finish: when the player bumps a finish block
	// the controller latches `finished`; objective mode reports each objective and
	// removes its minimap marker, while every other mode emits finish_race once and
	// lets the host page surface the finished page.
	private function maybeHandleLocalFinish(state:LocalPlayerState):Void {
		if (!state.finished) {
			return;
		}
		markLocalPresentationDiscontinuity();
		var finishId = state.finishBlockId == null ? -1 : state.finishBlockId;
		// Preserve the -1/0/0 sentinel for finishes without a block
		// (deathmatch/time-out).
		var finishX = state.finishBlockId == null || state.finishX == null
			? 0
			: Std.int(state.finishX);
		var finishY = state.finishBlockId == null || state.finishY == null
			? 0
			: Std.int(state.finishY);
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
			raceSounds.playVictorySound();
			return;
		}
		if (offlineMode) {
			if (localFinishHandled) {
				return;
			}
			localFinishHandled = true;
			raceSounds.playVictorySound();
			if (onFinish != null) {
				onFinish(state);
			}
			return;
		}
		if (localFinishHandled) {
			return;
		}
		localFinishHandled = true;
		raceSounds.playVictorySound();
		frameCounterActive = false;
		toggleKeyScroll(true);
		// Flash freezes the HUD clock when a normal race finishes. Hat mode keeps
		// running until its separate finish flow resolves.
		if (config.gameMode != "hat" && timer != null) {
			timer.pause();
		}
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

	private function emitLocalItemEffect(state:LocalPlayerState):Void {
		if (state.lastItemEffect == null || localCharacter == null) {
			return;
		}
		var parts = state.lastItemEffect.split(":");
		switch (parts[0]) {
			case "laser":
				localCharacter.playItemUseAnimation("Laser");
				var direction = parts.length > 1 ? parts[1] : "right";
				var offset = direction == "left" ? -20 : 20;
				var worldX = Std.int(state.x + offset);
				var worldY = Std.int(state.y - 25);
				var rotation = levelRenderer == null ? 0 : levelRenderer.courseRotationDegrees;
				if (effectBackground != null) {
					effectBackground.addEffect(["Laser", Std.string(worldX), Std.string(worldY), direction, Std.string(rotation),
						Std.string(localCharacter.tempID)]);
				}
				LobbySocket.write('add_effect`Laser`$worldX`$worldY`$direction`$rotation`' + localCharacter.tempID);
			case "slash":
				localCharacter.playItemUseAnimation("Sword");
				var weaponPosition = localCharacter.getWeaponEffectPosition();
				var worldX = Std.int(weaponPosition.x);
				var worldY = Std.int(weaponPosition.y);
				var direction = parts.length > 1 ? parts[1] : "right";
				var payload = 'Slash`$worldX`$worldY`$direction`' + localCharacter.tempID;
				mountSlashEffect(worldX, worldY, direction, localCharacter.tempID,
					levelRenderer == null ? 0 : levelRenderer.courseRotationDegrees);
				LobbySocket.write('add_effect`$payload');
			case "ice_wave":
				var direction = parts.length > 1 ? parts[1] : "right";
				var offset = direction == "left" ? -20 : 20;
				var angle = direction == "left" ? 180 : 0;
				var worldX = Std.int(state.x + offset);
				var worldY = Std.int(state.y - 25);
				var rotation = levelRenderer == null ? 0 : levelRenderer.courseRotationDegrees;
				if (effectBackground != null) {
					effectBackground.addEffect(["IceWave", Std.string(worldX), Std.string(worldY), Std.string(angle), Std.string(rotation),
						Std.string(localCharacter.tempID)]);
				}
				LobbySocket.write('add_effect`IceWave`$worldX`$worldY`$angle`$rotation`' + localCharacter.tempID);
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
				var canonicalCenter = CoordinateFrames.canonicalFromMinePacket(
					new CoordinateFrames.EffectPacketPoint(Std.int(effectX), Std.int(effectY)),
					Std.int(rotation)
				);
				var tileWorldX = Std.int(Math.round((canonicalCenter.x - 15) / LevelRenderer.TILE_SIZE)) * LevelRenderer.TILE_SIZE;
				var tileWorldY = Std.int(Math.round((canonicalCenter.y - 15) / LevelRenderer.TILE_SIZE)) * LevelRenderer.TILE_SIZE;
				var receiverRotation = levelRenderer.courseRotationDegrees;
				var displayCenter = CoordinateFrames.displayFromCanonical(canonicalCenter, receiverRotation);
				levelRenderer.showMineAppear(displayCenter.x, displayCenter.y, tileWorldX, tileWorldY, receiverRotation, true,
					function():Void placeRuntimeMine(tileWorldX, tileWorldY));
				LobbySocket.write('add_effect`Mine`$effectX`$effectY`$rotation');
			case "teleport":
				if (parts.length < 3) {
					return;
				}
				emitLocalTeleportItemPop(parts[1]);
				emitLocalTeleportItemPop(parts[2]);
			case "zap`":
				if (characterLayer != null) {
					characterLayer.addChild(new ZapEffect(localCharacter, true, true, true));
				}
				LobbySocket.write("zap`");
			default:
		}
	}

	private function emitLocalTeleportItemPop(coordsText:String):Void {
		var coords = coordsText.split(",");
		if (coords.length < 2 || levelRenderer == null) {
			return;
		}
		var worldX = Std.parseFloat(coords[0]);
		var worldY = Std.parseFloat(coords[1]);
		if (Math.isNaN(worldX) || Math.isNaN(worldY)) {
			return;
		}
		levelRenderer.showTeleportPop(Std.int(worldX), Std.int(worldY));
		LobbySocket.write('add_effect`Teleport`$worldX`$worldY');
	}

	public function mountSlashEffect(worldX:Int, worldY:Int, direction:String, shooterID:Int, ?senderRotation:Int):Slash {
		var receiverRotation = levelRenderer == null ? 0 : levelRenderer.courseRotationDegrees;
		if (senderRotation == null) {
			var remote = getRemoteCharacter(shooterID);
			senderRotation = remote == null ? receiverRotation : -remote.remoteRotation;
		}
		var effect = new Slash(worldX, worldY, direction, shooterID, {
			level: level,
			courseRotation: receiverRotation,
			senderRotation: senderRotation,
			player: localCharacter == null ? null : {
				tempId: localCharacter.tempID,
				x: localCharacter.stateSnapshot().x,
				y: localCharacter.stateSnapshot().y,
				removed: localCharacter.removed,
				hit: function(impulseX:Float, impulseY:Float):Void localCharacter.receiveHit(impulseX, impulseY)
			},
			onBlockDamage: function(block, reach):Void {
				if (localCharacter != null) {
					localCharacter.controller.damageBlockFromEffect(block, reach, senderRotation);
				} else {
					animateEffectBlockBump(block, reach, senderRotation);
				}
			},
			playSound: playSlashSound
		});
		return effect;
	}

	public function applySnakeNetwork(args:Array<String>):Void {
		if (snakeManager != null) {
			snakeManager.applyNetwork(args);
		}
	}

	private function playSlashSound(worldX:Float, worldY:Float):Void {
		if (levelRenderer == null || !openfl.utils.Assets.exists(Slash.SOUND_PATH)) {
			return;
		}
		var offset = levelRenderer.cameraOffset();
		pr2.audio.SoundEffects.playGameSound(openfl.utils.Assets.getSound(Slash.SOUND_PATH), worldX, worldY, offset.x, offset.y);
	}

	private function syncItemDisplay(?itemId:Null<Int>, ?itemUses:Null<Int>):Void {
		if (itemDisplay == null) {
			return;
		}
		if (itemId == null && player != null) {
			var state = player.stateSnapshot();
			itemId = state.itemId;
			itemUses = state.itemUses;
		}
		if (itemId != displayedItemId) {
			itemDisplay.setItemCode(itemId == null ? 0 : itemId);
			displayedItemId = itemId;
			// ItemDisplay.setItem resets its dots to one. Flash then has the new
			// item's constructor reapply its use count, even when the prior item had
			// the same count, so invalidate the cached HUD value here.
			displayedItemUses = null;
		}
		if (itemUses != displayedItemUses) {
			itemDisplay.setAmmo(itemUses == null ? 0 : itemUses);
			displayedItemUses = itemUses;
		}
	}

	private function syncStatsDisplay(?state:LocalPlayerState):Void {
		if (statsDisplay == null) {
			return;
		}
		if (state == null && player != null) {
			state = player.stateSnapshot();
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

	private function syncHearts(?state:LocalPlayerState):Void {
		if (hearts == null) {
			return;
		}
		if (state == null && player != null) {
			state = player.stateSnapshot();
		}
		if (state == null) {
			return;
		}
		if (config.gameMode != "deathmatch" && config.gameMode != Modes.roguelike) {
			return;
		}
		if (state.lives != displayedLives) {
			hearts.visible = true;
			hearts.setHearts(state.lives);
			displayedLives = state.lives;
		}
		if (roguelikeProgressText != null) {
			roguelikeProgressText.text = 'Finish: ${state.roguelikeFinishHits}/${pr2.gameplay.player.LocalPlayerController.ROGUELIKE_REQUIRED_FINISH_HITS}';
		}
	}

	private function syncBlockVisuals():Void blockVisuals.syncBlockVisuals();
	private function syncMoveBlockDisplays():Void blockVisuals.syncMoveBlockDisplays();
	private function emitFinishDrawingReady():Void blockVisuals.emitFinishDrawingReady();
	private function emitLocalBlockActivation(event:BlockVisualEvent):Void blockVisuals.emitLocalBlockActivation(event);
	private function emitLocalTeleportPop(event:BlockVisualEvent):Void blockVisuals.emitLocalTeleportPop(event);
	public function debugActiveBlockPieces():Int return blockVisuals.debugActiveBlockPieces();
	private function recordCrumbleActivation(tileX:Int, tileY:Int, payload:String):Void
		blockVisuals.recordCrumbleActivation(tileX, tileY, payload);

	private function publishMultiplayerDiagnostics():Void {
		#if js
		if (Browser.location.search.indexOf("multiplayerDebug=1") < 0 || Browser.document.body == null) {
			return;
		}
		Browser.document.body.setAttribute("data-pr2-crumble-force", debugLastCrumbleForce);
		Browser.document.body.setAttribute("data-pr2-crumble-activations", Std.string(debugCrumbleActivations));
		Browser.document.body.setAttribute("data-pr2-crumble-pieces-spawned", Std.string(debugCrumblePiecesSpawned));
		Browser.document.body.setAttribute("data-pr2-active-block-pieces", Std.string(debugActiveBlockPieces()));
		#end
	}

	private function updatePlayerDisplay():Void {
		if (player == null || levelRenderer == null) {
			return;
		}

		var state = player.stateSnapshot();
		syncRotationLifecycle(localCharacter.courseTweenRotation);
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
		// with the world-space display coordinate every frame. During the race that
		// is harmless because step()->syncFromController rewrites player.x/y back
		// to the controller position before the next updatePlayerDisplay. During
		// the 3-2-1 countdown, though, step() never runs, so reading player.x/y
		// here would feed the previous frame's screen coordinate back into the
		// camera target and make it scroll away, snapping back only at "Go".
		var worldX = state.x;
		var worldY = state.y;
		var cameraTarget = cameraTargetWorld(worldX, worldY);
		cameraPresentationPose.beginAuthoritativeUpdate(camera.posX, camera.posY);
		if (keyScrollActive) {
			applyKeyScroll();
		} else {
			if (state.courseRotation != displayedCourseRotation) {
				camera.snapTo(cameraTarget.x, cameraTarget.y);
				displayedCourseRotation = state.courseRotation;
			} else {
				camera.follow(cameraTarget.x, cameraTarget.y);
			}
		}
		cameraPresentationPose.finishAuthoritativeUpdate(camera.posX, camera.posY);
		levelRenderer.setCameraOffset(
			Constants.STAGE_WIDTH / 2 + cameraPresentationPose.presentedX,
			Constants.STAGE_HEIGHT / 2 + cameraPresentationPose.presentedY
		);
		if (playerDot != null) {
			playerDot.x = worldX;
			playerDot.y = worldY;
		}
		moveCharacterToLayer(player, state.touchedBlockType == "water" ? "backBackground" : "frontBackground");
		PlayerDisplayPlacement.place(player, player.display, worldX, worldY, player.facingScaleX, localCharacter.characterRotation);
		// Until the countdown finishes the race has not started and the local
		// player is never stepped (Flash keeps it in mode="wait"/state="stand"
		// with its physics ENTER_FRAME not yet attached). Show the idle stand pose
		// instead of the airborne "jump" the motion state derives from the not-yet
		// grounded spawn, so the character sits still on its start block through
		// the 3-2-1 rather than floating mid-jump.
		var clipState = raceStarted ? state.characterState : CharacterState.Stand;
		var clipName = clipState.toClipName();
		if (!player.display.isState(clipName)) {
			player.display.setState(clipName);
		}
		player.display.advanceOneFrame();
	}

	private function cameraTargetWorld(localWorldX:Float, localWorldY:Float):Point {
		if (snakeManager != null) {
			var snakeHead = snakeManager.localHeadWorld();
			if (snakeHead != null) {
				return snakeHead;
			}
		}
		if (playerSpectating == null || playerSpectating == localCharacter) {
			return new Point(localWorldX, localWorldY);
		}
		var pos = playerSpectating.getPos();
		return new Point(pos.x, pos.y);
	}

	private function syncRotationLifecycle(tweenRotation:Int):Void {
		var active = tweenRotation != 0;
		if (active == rotationTweenActive) {
			return;
		}
		rotationTweenActive = active;
		if (levelRenderer != null) {
			levelRenderer.setArtCaching(!active);
		}
		setStageQuality(active ? StageQuality.LOW : StageQuality.HIGH);
	}

	private function setStageQuality(value:StageQuality):Void {
		currentStageQuality = value;
		if (stage != null) {
			stage.quality = value;
		}
	}

	private function toggleKeyScroll(active:Bool):Void {
		if (keyScrollActive == active) {
			return;
		}
		markLocalPresentationDiscontinuity();
		keyScrollActive = active;
		if (!active) {
			scrollVelX = 0;
			scrollVelY = 0;
		}
	}

	private function applyKeyScroll():Void {
		var accel = scrollShift ? 20 : 10;
		if (scrollDown) {
			scrollVelY -= accel;
		}
		if (scrollUp) {
			scrollVelY += accel;
		}
		if (scrollLeft) {
			scrollVelX += accel;
		}
		if (scrollRight) {
			scrollVelX -= accel;
		}
		scrollVelX *= 0.6;
		scrollVelY *= 0.6;
		camera.scroll(scrollVelX, scrollVelY);
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
		if (keyCode == Keyboard.SHIFT) {
			scrollShift = pressed;
		}
		var left = keyCode == Keyboard.LEFT || AlternateControls.matches("left", keyCode);
		var right = keyCode == Keyboard.RIGHT || AlternateControls.matches("right", keyCode);
		var up = keyCode == Keyboard.UP || AlternateControls.matches("up", keyCode);
		var down = keyCode == Keyboard.DOWN || AlternateControls.matches("down", keyCode);
		if (pressed && snakeManager != null && (snakeManager.localActive() || input.item)) {
			if (left) snakeManager.setLocalDirection(-1, 0);
			if (right) snakeManager.setLocalDirection(1, 0);
			if (up) snakeManager.setLocalDirection(0, -1);
			if (down) snakeManager.setLocalDirection(0, 1);
		}
		if (left) scrollLeft = pressed;
		if (right) scrollRight = pressed;
		if (up) scrollUp = pressed;
		if (down) scrollDown = pressed;
		if (!keyScrollActive) {
			if (left) input.left = pressed;
			if (right) input.right = pressed;
			if (up) input.jump = pressed;
			if (down) input.down = pressed;
		}
		if (keyCode == Keyboard.SPACE || AlternateControls.matches("item", keyCode)) input.item = pressed;
	}


	private function resetInput(_:Event):Void {
		input.clear();
		scrollLeft = false;
		scrollRight = false;
		scrollUp = false;
		scrollDown = false;
		scrollShift = false;
		scrollVelX = 0;
		scrollVelY = 0;
	}

	public function remove():Void {
		FrameClock.resetCurrentPresentationPhase();
		invalidateLocalPresentationPose();
		cameraPresentationPose.clear();
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
		if (roguelikeProgressText != null) {
			if (roguelikeProgressText.parent != null) {
				roguelikeProgressText.parent.removeChild(roguelikeProgressText);
			}
			roguelikeProgressText = null;
		}
		if (musicSelection != null) {
			musicSelection.remove();
			musicSelection = null;
		}
		removeRaceChat();
		if (timer != null) {
			timer.remove();
			timer = null;
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
		looseHatPresentationOwners.resize(0);
		stopAllJetSounds();
		particleEffects.clearAll();
		removeAllRemoteCharacters();
		if (snakeManager != null) {
			snakeManager.clear();
			snakeManager = null;
		}
		activeCommandHandler().defineCommand("activate", null);
		unregisterLocalCommands();
		if (localCharacter != null) {
			localCharacter.remove();
		}
		if (levelRenderer != null) {
			levelRenderer.remove();
			levelRenderer = null;
		}
		localCharacter = null;
		player = null;
		playerSpectating = null;
		playerArray = null;
		onCollectEgg = null;
		onStatsSelectSyncRequest = null;
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
