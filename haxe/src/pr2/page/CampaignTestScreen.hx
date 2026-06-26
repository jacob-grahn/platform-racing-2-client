package pr2.page;

#if js
import js.Browser;
#end
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import pr2.lobby.account.AlternateControls;
import pr2.Constants;
import pr2.runtime.FontResolver;
import pr2.character.CharacterDisplay;
import pr2.character.CharacterRenderMode;
import pr2.harness.LocalPlayerController;
import pr2.harness.LocalPlayerInput;
import pr2.harness.PlayerDisplayPlacement;
import pr2.harness.BlockVisualEvent;
import pr2.harness.BlockVisualEvent.BlockVisualEventKind;
import pr2.gameplay.CameraFollow;
import pr2.gameplay.DrawingInfo;
import pr2.gameplay.ItemDisplay;
import pr2.gameplay.MiniMap;
import pr2.gameplay.MiniMapDot;
import pr2.gameplay.MusicSelection;
import pr2.gameplay.RaceChat;
import pr2.lobby.chat.ChatText;
import pr2.net.CampaignListClient;
import pr2.net.CampaignListClient.CampaignListResult;
import pr2.net.CampaignLevelInfo;
import pr2.net.LevelDataClient;
import pr2.net.ServerConfig;
import pr2.net.ServerLevelData;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevel;
import pr2.level.ServerLevelDecoder;
import pr2.level.ServerLevelFixtureAdapter;
import pr2.level.ServerLevelFixtureAdapter.ServerFixtureLevel;
import pr2.level.ServerLevelRenderer;

/**
	Bit 1 of the server campaign level test harness (see TODO.md). Fetches a real
	campaign course list from the live PR2 server and reports what came back. This
	proves end-to-end connectivity and list parsing before loading, rendering,
	and playing either the first listed level or a requested level on that page.

	Reachable via `?screen=campaign` (optional `&page=N`, default 1, and
	`&levelId=N` or `&level=N` to load a specific level from that page). GamePage
	also supplies a version to bypass the list and load a server-selected level
	directly without navigating away from the live session.
**/
class CampaignTestScreen extends Sprite {
	private static inline var DEFAULT_PAGE:Int = 1;

	private final page:Int;
	private final requestedLevelId:Null<Int>;
	private final directVersion:Null<Int>;
	private final input:LocalPlayerInput = new LocalPlayerInput();
	private var statusText:TextField;
	private var levelRenderer:ServerLevelRenderer;
	private var serverFixture:ServerFixtureLevel;
	private var player:LocalPlayerController;
	private var playerDisplay:Sprite;
	private var characterDisplay:CharacterDisplay;
	private var camera:CameraFollow;
	private var miniMap:MiniMap;
	private var playerDot:MiniMapDot;
	private var itemDisplay:ItemDisplay;
	private var musicSelection:MusicSelection;
	private var raceChat:RaceChat;
	private var drawingInfo:DrawingInfo;
	private var drawingInfoFinished:Bool = false;
	private var displayedItemId:Null<Int>;
	private var displayedItemUses:Null<Int>;
	private var lastStatusText:String = "";

	public function new(?page:String, ?levelId:String, ?version:Int) {
		super();
		this.page = parsePage(page);
		this.requestedLevelId = parseRequestedLevelId(levelId);
		this.directVersion = version;

		drawBackground();
		createStatusText();
		setStatus(
			"phase=fetching",
			directVersion != null
				? 'Loading level ${requestedLevelId} v${directVersion}...'
				: requestedLevelId == null
				? 'Fetching campaign list page ${this.page}...'
				: 'Fetching campaign list page ${this.page} for level ${requestedLevelId}...'
		);
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	public static function parsePage(page:Null<String>):Int {
		if (page == null) {
			return DEFAULT_PAGE;
		}
		var parsed = Std.parseInt(StringTools.trim(page));
		return (parsed == null || parsed < 1) ? DEFAULT_PAGE : parsed;
	}

	public static function parseRequestedLevelId(levelId:Null<String>):Null<Int> {
		if (levelId == null) {
			return null;
		}
		var parsed = Std.parseInt(StringTools.trim(levelId));
		return (parsed == null || parsed < 1) ? null : parsed;
	}

	public static function selectLevel(levels:Array<CampaignLevelInfo>, requestedLevelId:Null<Int>):Null<CampaignLevelInfo> {
		if (levels.length == 0) {
			return null;
		}
		if (requestedLevelId != null) {
			for (level in levels) {
				if (level.levelId == requestedLevelId) {
					return level;
				}
			}
		}
		return levels[0];
	}

	private function onAddedToStage(event:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		#if html5
		if (!ServerConfig.hasProxyHost()) {
			setStatus(
				"phase=proxyRequired",
				'Campaign fetch requires a same-origin API proxy on HTML5.\nUse ?apiHost=/api with tools/dev_proxy.py or configure an equivalent deploy proxy.'
			);
			return;
		}
		#end
		if (directVersion != null && requestedLevelId != null) {
			LevelDataClient.fetch(requestedLevelId, directVersion, function(data:ServerLevelData):Void {
				onDirectLevelData(requestedLevelId, directVersion, data);
			}, onLevelError);
		} else {
			CampaignListClient.fetch(page, onList, onError);
		}
	}

	private function onDirectLevelData(levelId:Int, version:Int, data:ServerLevelData):Void {
		var info = new CampaignLevelInfo(levelId, version, data.title, "", 0, 0, 0);
		onLevelData(info, data);
	}

	public function remove():Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		if (stage != null) {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		}
		if (miniMap != null) {
			miniMap.remove();
			miniMap = null;
			playerDot = null;
		}
		if (itemDisplay != null) {
			itemDisplay.remove();
			itemDisplay = null;
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
		if (levelRenderer != null) {
			levelRenderer.remove();
			levelRenderer = null;
		}
		if (parent != null) parent.removeChild(this);
	}

	private function onList(result:CampaignListResult):Void {
		if (result.levels.length == 0) {
			setStatus("phase=empty", 'Campaign list page $page returned no levels.');
			return;
		}

		var selected = selectLevel(result.levels, requestedLevelId);
		var requestedStatus = requestedLevelId == null
			? "default first level"
			: (selected.levelId == requestedLevelId ? 'matched requested level ${requestedLevelId}' : 'requested level ${requestedLevelId} not found; using first level');
		setStatus('phase=listLoaded;levels=${result.levels.length};selectedId=${selected.levelId}', [
			'Campaign list page $page',
			'levels=${result.levels.length} listHashValid=${result.hashValid}',
			requestedStatus,
			'selected level: ${selected.describe()}',
			"",
			'Loading level data for ${selected.levelId} v${selected.version}...'
		].join("\n"));

		LevelDataClient.fetch(selected.levelId, selected.version, function(data:ServerLevelData):Void {
			onLevelData(selected, data);
		}, onLevelError);
	}

	private function onLevelData(info:CampaignLevelInfo, data:ServerLevelData):Void {
		var lines = [
			'Campaign page $page -> selected level loaded',
			'id=${info.levelId} v${info.version} levelHashValid=${data.hashValid}',
			'title: ${data.title}',
			'gravity=${data.gravity} maxTime=${data.maxTime} mode=${data.gameMode}',
			'items (${data.items.length}): ${data.items.join(", ")}'
		];

		var debug = 'phase=levelLoaded;id=${info.levelId};hashValid=${data.hashValid};readMode=${data.readMode()}';
		try {
			var level = ServerLevelDecoder.decode(data.data);
			renderDecodedLevel(level, data);
			lines.push('decoded: blocks=${level.blocks.length} bg=0x${StringTools.hex(level.bgColor, 6)}');
			lines.push('starts=${level.startBlocks().length} finishes=${level.finishBlocks().length} bounds=${level.maxX - level.minX}x${level.maxY - level.minY}px');
			debug += ';blocks=${level.blocks.length};starts=${level.startBlocks().length}';
		} catch (error:Dynamic) {
			lines.push('decode failed: ${Std.string(error)}');
			debug += ';decodeError';
		}

		setStatus(debug, lines.join("\n"));
	}

	private function onError(message:String):Void {
		setStatus("phase=error", 'Campaign list fetch failed:\n$message');
	}

	private function onLevelError(message:String):Void {
		setStatus("phase=levelError", 'Level data fetch failed:\n$message');
	}

	private function drawBackground():Void {
		var background = new Shape();
		background.graphics.beginFill(Constants.BACKGROUND_COLOR);
		background.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		background.graphics.endFill();
		addChild(background);
	}

	private function renderDecodedLevel(level:ServerLevel, data:ServerLevelData):Void {
		if (levelRenderer != null) {
			levelRenderer.remove();
		}

		var startBlocks = level.startBlocks();
		var focus = startBlocks.length == 0 ? null : startBlocks[0];
		var renderer = new ServerLevelRenderer(level, focus, ServerLevelRenderer.DEFAULT_FOCUS_X, ServerLevelRenderer.DEFAULT_FOCUS_Y, true);
		levelRenderer = renderer;
		addChildAt(levelRenderer, 1);

		serverFixture = ServerLevelFixtureAdapter.convert(level, data.gravity, Std.string(data.levelId), data.title);
		player = new LocalPlayerController(serverFixture.fixture);
		playerDisplay = new Sprite();
		characterDisplay = new CharacterDisplay(
			{hat: 1, head: 1, body: 1, feet: 1},
			{primary: 0x005CB8, secondary: 0xFFF200},
			CharacterRenderMode.Layered
		);
		characterDisplay.x = LocalPlayerController.STANDING_WIDTH / 2;
		characterDisplay.y = LocalPlayerController.STANDING_HEIGHT;
		characterDisplay.scaleX = 0.9;
		characterDisplay.scaleY = 0.9;
		playerDisplay.addChild(characterDisplay);
		levelRenderer.addChild(playerDisplay);
		// Center the camera on the player from the first frame. Easing in from an
		// off-center start would briefly leave the player low and to the side
		// because this screen has no countdown to hide the drift (see
		// CameraFollow.snapTo).
		camera = new CameraFollow(0, 0);
		camera.snapTo(serverFixture.fixturePixelToWorldX(player.x), serverFixture.fixturePixelToWorldY(player.y));
		buildMiniMap(level);
		buildItemDisplay();
		buildMusicSelection(data.song);
		buildRaceChat();
		buildDrawingInfo();
		updatePlayerDisplay();
	}

	/**
		Builds the minimap from the decoded level, mirroring Map.attachObject:
		start blocks and minion eggs are excluded from the silhouette, finish
		blocks add a finish box, everything else is filled in. The local player
		gets a yellow dot. Positioned at stage (80, 2) to match Course's minimap
		holder offset (-195, -198) against the centred game holder.
	**/
	private function buildMiniMap(level:ServerLevel):Void {
		if (miniMap != null) {
			miniMap.remove();
			miniMap = null;
			playerDot = null;
		}

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
		miniMap.x = 80;
		miniMap.y = 2;
		addChild(miniMap);
	}

	/** Positions the authored item display at Course's stage-space (2, 2). */
	private function buildItemDisplay():Void {
		if (itemDisplay != null) {
			itemDisplay.remove();
		}
		itemDisplay = new ItemDisplay();
		itemDisplay.x = 2;
		itemDisplay.y = 2;
		addChild(itemDisplay);
		displayedItemId = null;
		displayedItemUses = null;
		syncItemDisplay();
	}

	/** Positions the authored race music selector at Course's stage-space (204, 362). */
	private function buildMusicSelection(songId:String):Void {
		if (musicSelection != null) musicSelection.remove();
		musicSelection = new MusicSelection();
		musicSelection.x = 204;
		musicSelection.y = 362;
		addChild(musicSelection);
		musicSelection.setSong(songId);
	}

	/** Positions the authored race chat at Course's stage-space (4, 249). */
	private function buildRaceChat():Void {
		if (raceChat != null) raceChat.remove();
		raceChat = new RaceChat(handleRaceChatLine);
		raceChat.x = 4;
		raceChat.y = 249;
		addChild(raceChat);
	}

	/** Positions the authored drawing status at Course's stage-space (2, 96). */
	private function buildDrawingInfo():Void {
		if (drawingInfo != null) drawingInfo.remove();
		drawingInfo = new DrawingInfo();
		drawingInfo.x = 2;
		drawingInfo.y = 96;
		drawingInfo.addPlayer("You", 0);
		drawingInfoFinished = false;
		addChild(drawingInfo);
	}

	private function createStatusText():Void {
		statusText = new TextField();
		statusText.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 12, 0xFFFFFF);
		statusText.selectable = false;
		statusText.mouseEnabled = false;
		statusText.multiline = true;
		statusText.wordWrap = true;
		statusText.autoSize = TextFieldAutoSize.NONE;
		statusText.x = 16;
		statusText.y = 16;
		statusText.width = Constants.STAGE_WIDTH - 32;
		statusText.height = 112;
		statusText.background = true;
		statusText.backgroundColor = 0x000000;
		statusText.alpha = 0.82;
		statusText.visible = false;
		addChild(statusText);
	}

	public function isDebugTextVisible():Bool {
		return statusText != null && statusText.visible;
	}

	public static function isDebugChatCommand(message:String):Bool {
		return ChatText.trimWhitespace(message == null ? "" : message).toLowerCase() == "/debug";
	}

	public function handleRaceChatLine(message:String):Bool {
		if (!isDebugChatCommand(message)) {
			return false;
		}
		if (statusText != null) {
			statusText.visible = !statusText.visible;
		}
		return true;
	}

	private function setStatus(debugState:String, text:String):Void {
		lastStatusText = text;
		statusText.text = text;
		#if js
		Browser.document.body.setAttribute("data-pr2-harness", "campaign");
		Browser.document.body.setAttribute("data-pr2-debug-state", debugState);
		#end
	}

	private function onEnterFrame(event:Event):Void {
		if (player == null) {
			return;
		}
		if (levelRenderer != null && !levelRenderer.isBlockDrawingComplete()) {
			#if js
			Browser.document.body.setAttribute("data-pr2-debug-state", 'phase=drawing;blocks=${levelRenderer.drawnBlockCount()}');
			#end
			return;
		}
		if (!drawingInfoFinished) {
			if (drawingInfo != null) {
				drawingInfo.finishDrawing(0);
			}
			drawingInfoFinished = true;
		}

		player.step(input.copy());
		syncBlockVisuals();
		updatePlayerDisplay();
		var state = player.debugState();
		syncItemDisplay(state.itemId, state.itemUses);
		statusText.text = lastStatusText + '\nplayer ${state.serialize()}';
		#if js
		Browser.document.body.setAttribute("data-pr2-debug-state", 'phase=playable;${state.serialize()}');
		#end
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

	private function syncBlockVisuals():Void {
		for (block in serverFixture.fixture.blocks) {
			var worldX = (block.x + serverFixture.originTileX) * ServerLevelFixtureAdapter.TILE_SIZE;
			var worldY = (block.y + serverFixture.originTileY) * ServerLevelFixtureAdapter.TILE_SIZE;
			levelRenderer.setBlockAlpha(worldX, worldY, player.blockAlphaAt(block.x, block.y));
			levelRenderer.setBlockColorMultiplier(worldX, worldY, player.blockColorMultiplierAt(block.x, block.y));
		}
		for (event in player.consumeBlockVisualEvents()) {
			switch (event.kind) {
				case ArrowAnimate:
					var worldX = (event.tileX + serverFixture.originTileX) * ServerLevelFixtureAdapter.TILE_SIZE;
					var worldY = (event.tileY + serverFixture.originTileY) * ServerLevelFixtureAdapter.TILE_SIZE;
					levelRenderer.animateArrow(worldX, worldY);
				case MineExplode:
					var worldX = (event.tileX + serverFixture.originTileX) * ServerLevelFixtureAdapter.TILE_SIZE;
					var worldY = (event.tileY + serverFixture.originTileY) * ServerLevelFixtureAdapter.TILE_SIZE;
					levelRenderer.showMineExplosion(worldX, worldY);
				case BrickPieces:
					showBlockPieces(event, "BrickPieceGraphic", 10, 10, 25);
				case CrumblePieces:
					showBlockPieces(event, "CrumblePieceGraphic", 5, 5, 15);
				case MinePieces:
					showBlockPieces(event, "MinePieceGraphic", 30, 30, 50);
			}
		}
	}

	private function showBlockPieces(event:BlockVisualEvent, linkage:String, spreadX:Float, spreadY:Float, spreadRot:Float):Void {
		var worldX = (event.tileX + serverFixture.originTileX) * ServerLevelFixtureAdapter.TILE_SIZE;
		var worldY = (event.tileY + serverFixture.originTileY) * ServerLevelFixtureAdapter.TILE_SIZE;
		levelRenderer.showBlockPieces(linkage, worldX, worldY, event.count, spreadX, spreadY, spreadRot);
	}

	private function updatePlayerDisplay():Void {
		if (player == null || levelRenderer == null || serverFixture == null || playerDisplay == null || characterDisplay == null) {
			return;
		}

		var state = player.debugState();
		var worldX = serverFixture.fixturePixelToWorldX(player.x);
		var worldY = serverFixture.fixturePixelToWorldY(player.y);
		camera.follow(worldX, worldY);
		levelRenderer.setCameraOffset(Constants.STAGE_WIDTH / 2 + camera.posX, Constants.STAGE_HEIGHT / 2 + camera.posY);
		if (playerDot != null) {
			playerDot.x = worldX;
			playerDot.y = worldY;
		}
		var screen = levelRenderer.worldToScreen(worldX, worldY);
		PlayerDisplayPlacement.place(playerDisplay, characterDisplay, screen.x, screen.y, player.crouching, player.facingScaleX);
		characterDisplay.setState(state.characterState.toClipName());
		characterDisplay.advanceOneFrame();
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
}
