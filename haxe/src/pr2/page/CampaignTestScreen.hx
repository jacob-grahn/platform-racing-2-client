package pr2.page;

#if js
import js.Browser;
#end
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import pr2.Constants;
import pr2.runtime.FontResolver;
import pr2.gameplay.player.LocalPlayerState;
import pr2.gameplay.Course;
import pr2.gameplay.LevelConfig;
import pr2.lobby.chat.ChatText;
import pr2.net.CampaignListClient;
import pr2.net.CampaignListClient.CampaignListResult;
import pr2.net.CampaignLevelInfo;
import pr2.net.LevelDataClient;
import pr2.net.ServerConfig;
import pr2.net.ServerLevelData;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;
import pr2.level.LevelDecoder;
import pr2.level.ObjectCodes;

/**
	Debug harness for exercising real server campaign levels (see TODO.md).
	Fetches a course list (or a server-selected level directly), decodes it, and
	mounts the production `pr2.gameplay.Course` shell, wrapping it with a status
	overlay toggled by the `/debug` chat command.

	The gameplay shell itself now lives in `Course` so the real `GamePage` mounts
	the same code without this harness chrome. Reachable via `?screen=campaign`
	(optional `&page=N`, `&levelId=N`/`&level=N`); `GamePage` supplies a version to
	load a server-selected level directly.

	`&localLevel=<name>` builds a synthetic level entirely client-side (no server
	fetch) and mounts it in the same `Course` path. This replaces the old
	standalone gameplay harness as the way to exercise gameplay offline; see
	`buildLocalLevel` for the supported layouts.
**/
class CampaignTestScreen extends Sprite {
	private static inline var DEFAULT_PAGE:Int = 1;

	private final page:Int;
	private final requestedLevelId:Null<Int>;
	private final directVersion:Null<Int>;
	private final localLevel:Null<String>;
	private final debugItem:Null<Int>;
	private var statusText:TextField;
	private var course:Course;
	private var lastStatusText:String = "";

	public function new(?page:String, ?levelId:String, ?version:Int, ?localLevel:String, ?debugItem:Int) {
		super();
		this.page = parsePage(page);
		this.requestedLevelId = parseRequestedLevelId(levelId);
		this.directVersion = version;
		this.localLevel = localLevel;
		this.debugItem = debugItem;

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
		addEventListener(Event.ENTER_FRAME, onHarnessFrame);
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
		if (localLevel != null) {
			buildLocalLevel();
			return;
		}
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

	// Builds a synthetic level entirely client-side (no server fetch) so gameplay
	// can be exercised and screenshotted in the real `Course`/`LevelRenderer`
	// path without a server. This is the replacement for the old standalone
	// gameplay harness: pick a layout with `?screen=campaign&debug=1&localLevel=<name>`.
	// Supported names: `rotate` (default), `flat`, `arrow`, and `safety`.
	private function buildLocalLevel():Void {
		var name = localLevel == null ? "rotate" : localLevel.toLowerCase();
		var blocks:Array<LevelBlock> = [];
		function add(code:Int, col:Int, row:Int):Void {
			blocks.push(LevelBlock.fromWorldPixels(code, col * 30, row * 30));
		}

		var title;
		switch (name) {
			case "flat":
				// A wide open floor with a start block: a minimal physics sandbox,
				// matching what the old harness's flat-level fixture provided.
				title = "Local Flat Test";
				for (col in 6...34) {
					add(ObjectCodes.BLOCK_BRICK, col, 20);
				}
				add(ObjectCodes.BLOCK_START1, 20, 19);

			case "safety":
				// Safety-net sandbox: leave a floor gap under the net so the standing
				// tile remains in the previous column. A net directly over the current
				// floor tile is intentionally ignored by Flash's SafetyBlock exception.
				title = "Local Safety Test";
				for (col in 6...34) {
					if (col != 24) {
						add(ObjectCodes.BLOCK_BRICK, col, 20);
					}
				}
				add(ObjectCodes.BLOCK_SAFETY, 24, 19);
				add(ObjectCodes.BLOCK_SAFETY, 24, 18);
				add(ObjectCodes.BLOCK_START1, 16, 19);

			case "arrow":
				// Arrow-block sandbox: a brick floor with an up arrow embedded in it and
				// the player spawning on the floor a few tiles to the left. Walk right
				// onto the up arrow to bounce off it (each bounce is a single touch
				// followed by ~1s airborne), which is the condition that exposes arrow
				// and guards the historical disappearing-arrow-overlay regression.
				title = "Local Arrow Test";
				for (col in 6...34) {
					add(col == 20 ? ObjectCodes.BLOCK_ARROW_UP : ObjectCodes.BLOCK_BRICK, col, 20);
				}
				add(ObjectCodes.BLOCK_START1, 16, 19);

			default:
				// Rotate layout: a floor + walls + ceiling box (so missing blocks are
				// obvious), a start block to spawn on, and a rotate block directly
				// above the head to bump when the player jumps.
				title = "Local Rotate Test";
				for (col in 14...27) {
					add(ObjectCodes.BLOCK_BRICK, col, 20);
				}
				for (col in 14...27) {
					add(ObjectCodes.BLOCK_BASIC2, col, 11);
				}
				for (row in 12...20) {
					add(ObjectCodes.BLOCK_BASIC1, 14, row);
					add(ObjectCodes.BLOCK_BASIC1, 26, row);
				}
				add(ObjectCodes.BLOCK_START1, 20, 19);
				add(ObjectCodes.BLOCK_ROTATE_RIGHT, 20, 16);
		}

		var level = Level.fromDecoded(0x6688AA, blocks);
		var vars = new Map<String, String>();
		vars.set("title", title);
		vars.set("gravity", "1");
		vars.set("max_time", "120");
		vars.set("gameMode", "race");
		var data = new ServerLevelData(vars, true);
		mountCourse(level, data);
		if (debugItem != null && debugItem > 0) {
			course.localCharacter.grantItemForDebug(debugItem);
		}
		// The real flow calls beginRace from GamePage once the character exists; the
		// local harness has no GamePage, so start the countdown/race here so physics
		// actually runs offline.
		course.beginRace();
		setStatus("phase=localLevel", 'Local test level "$name" mounted (blocks=${blocks.length}).');
	}

	private function onDirectLevelData(levelId:Int, version:Int, data:ServerLevelData):Void {
		var info = new CampaignLevelInfo(levelId, version, data.title, "", 0, 0, 0);
		onLevelData(info, data);
	}

	public function remove():Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		removeEventListener(Event.ENTER_FRAME, onHarnessFrame);
		if (course != null) {
			course.remove();
			course = null;
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
			var level = LevelDecoder.decode(data.data);
			mountCourse(level, data);
			lines.push('decoded: blocks=${level.blocks.length} bg=0x${StringTools.hex(level.bgColor, 6)}');
			lines.push('starts=${level.startBlocks().length} finishes=${level.finishBlocks().length} bounds=${level.maxX - level.minX}x${level.maxY - level.minY}px');
			debug += ';blocks=${level.blocks.length};starts=${level.startBlocks().length}';
		} catch (error:Dynamic) {
			lines.push('decode failed: ${Std.string(error)}');
			debug += ';decodeError';
		}

		setStatus(debug, lines.join("\n"));
	}

	private function mountCourse(level:Level, data:ServerLevelData):Void {
		if (course != null) {
			course.remove();
		}
		var config = LevelConfig.fromServerData(data);
		course = new Course(level, data, config, handleRaceChatLine, onCourseFrame);
		// Keep the course above the background but below the status overlay.
		addChildAt(course, 1);
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

	public static function isRaceChatFixtureCommand(message:String):Bool {
		return ChatText.trimWhitespace(message == null ? "" : message).toLowerCase() == "/chatfixture";
	}

	public function handleRaceChatLine(message:String):Bool {
		if (isRaceChatFixtureCommand(message)) {
			if (course != null && course.raceChat != null) {
				for (i in 0...8) {
					course.raceChat.receiveChatMessage(i == 7 ? "ClickablePlayer" : 'Player$i', i == 7 ? "1,0" : "0", 'fixture line $i');
				}
			}
			return true;
		}
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

	/** Slim per-frame loop: only reports the harness debug phase; the Course owns
		the actual gameplay/render/HUD update. */
	private function onHarnessFrame(event:Event):Void {
		if (course == null || course.levelRenderer == null) {
			return;
		}
		if (!course.levelRenderer.isDrawingComplete()) {
			#if js
			Browser.document.body.setAttribute("data-pr2-debug-state",
				'phase=drawing;blocks=${course.levelRenderer.drawnBlockCount()};art=${course.levelRenderer.drawnArtItemCount()}'
					+ course.levelRenderer.artProfileDebugState());
			#end
		}
	}

	/** Invoked by the Course each playable frame with the local player's state. */
	private function onCourseFrame(state:LocalPlayerState):Void {
		statusText.text = lastStatusText + '\nplayer ${state.serialize()}';
		#if js
		Browser.document.body.setAttribute("data-pr2-debug-state", 'phase=playable;${state.serialize()}');
		#end
	}
}
