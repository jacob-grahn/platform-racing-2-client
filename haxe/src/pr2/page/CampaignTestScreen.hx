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
import pr2.Constants;
import pr2.runtime.FontResolver;
import pr2.character.CharacterDisplay;
import pr2.character.CharacterRenderMode;
import pr2.harness.LocalPlayerController;
import pr2.harness.LocalPlayerInput;
import pr2.net.CampaignListClient;
import pr2.net.CampaignListClient.CampaignListResult;
import pr2.net.CampaignLevelInfo;
import pr2.net.LevelDataClient;
import pr2.net.ServerConfig;
import pr2.net.ServerLevelData;
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
	`&levelId=N` or `&level=N` to load a specific level from that page).
**/
class CampaignTestScreen extends Sprite {
	private static inline var DEFAULT_PAGE:Int = 1;

	private final page:Int;
	private final requestedLevelId:Null<Int>;
	private final input:LocalPlayerInput = new LocalPlayerInput();
	private var statusText:TextField;
	private var levelRenderer:ServerLevelRenderer;
	private var serverFixture:ServerFixtureLevel;
	private var player:LocalPlayerController;
	private var playerDisplay:Sprite;
	private var characterDisplay:CharacterDisplay;
	private var lastStatusText:String = "";

	public function new(?page:String, ?levelId:String) {
		super();
		this.page = parsePage(page);
		this.requestedLevelId = parseRequestedLevelId(levelId);

		drawBackground();
		createStatusText();
		setStatus(
			"phase=fetching",
			requestedLevelId == null
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
		CampaignListClient.fetch(page, onList, onError);
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
		if (levelRenderer != null && levelRenderer.parent != null) {
			removeChild(levelRenderer);
		}

		var startBlocks = level.startBlocks();
		var focus = startBlocks.length == 0 ? null : startBlocks[0];
		var renderer = new ServerLevelRenderer(level, focus);
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
		updatePlayerDisplay();
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
		addChild(statusText);
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

		player.step(input.copy());
		updatePlayerDisplay();
		var state = player.debugState();
		statusText.text = lastStatusText + '\nplayer ${state.serialize()}';
		#if js
		Browser.document.body.setAttribute("data-pr2-debug-state", 'phase=playable;${state.serialize()}');
		#end
	}

	private function updatePlayerDisplay():Void {
		if (player == null || levelRenderer == null || serverFixture == null || playerDisplay == null || characterDisplay == null) {
			return;
		}

		var state = player.debugState();
		var height = player.crouching ? LocalPlayerController.CROUCHING_HEIGHT : LocalPlayerController.STANDING_HEIGHT;
		var worldX = serverFixture.fixturePixelToWorldX(player.x);
		var worldY = serverFixture.fixturePixelToWorldY(player.y);
		var screen = levelRenderer.worldToScreen(worldX, worldY);
		playerDisplay.x = screen.x - LocalPlayerController.STANDING_WIDTH / 2;
		playerDisplay.y = screen.y - height;
		playerDisplay.scaleY = height / LocalPlayerController.STANDING_HEIGHT;
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
		switch (keyCode) {
			case Keyboard.LEFT | Keyboard.A:
				input.left = pressed;
			case Keyboard.RIGHT | Keyboard.D:
				input.right = pressed;
			case Keyboard.UP | Keyboard.W | Keyboard.SPACE:
				input.jump = pressed;
			case Keyboard.DOWN | Keyboard.S:
				input.down = pressed;
			default:
		}
	}
}
