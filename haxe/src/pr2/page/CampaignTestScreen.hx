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
import pr2.harness.LocalPlayerDebugState;
import pr2.gameplay.Course;
import pr2.gameplay.LevelConfig;
import pr2.lobby.chat.ChatText;
import pr2.net.CampaignListClient;
import pr2.net.CampaignListClient.CampaignListResult;
import pr2.net.CampaignLevelInfo;
import pr2.net.LevelDataClient;
import pr2.net.ServerConfig;
import pr2.net.ServerLevelData;
import pr2.level.ServerLevel;
import pr2.level.ServerLevelDecoder;

/**
	Debug harness for exercising real server campaign levels (see TODO.md).
	Fetches a course list (or a server-selected level directly), decodes it, and
	mounts the production `pr2.gameplay.Course` shell, wrapping it with a status
	overlay toggled by the `/debug` chat command.

	The gameplay shell itself now lives in `Course` so the real `GamePage` mounts
	the same code without this harness chrome. Reachable via `?screen=campaign`
	(optional `&page=N`, `&levelId=N`/`&level=N`); `GamePage` supplies a version to
	load a server-selected level directly.
**/
class CampaignTestScreen extends Sprite {
	private static inline var DEFAULT_PAGE:Int = 1;

	private final page:Int;
	private final requestedLevelId:Null<Int>;
	private final directVersion:Null<Int>;
	private var statusText:TextField;
	private var course:Course;
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
			var level = ServerLevelDecoder.decode(data.data);
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

	private function mountCourse(level:ServerLevel, data:ServerLevelData):Void {
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

	/** Slim per-frame loop: only reports the harness debug phase; the Course owns
		the actual gameplay/render/HUD update. */
	private function onHarnessFrame(event:Event):Void {
		if (course == null || course.levelRenderer == null) {
			return;
		}
		if (!course.levelRenderer.isBlockDrawingComplete()) {
			#if js
			Browser.document.body.setAttribute("data-pr2-debug-state", 'phase=drawing;blocks=${course.levelRenderer.drawnBlockCount()}');
			#end
		}
	}

	/** Invoked by the Course each playable frame with the local player's state. */
	private function onCourseFrame(state:LocalPlayerDebugState):Void {
		statusText.text = lastStatusText + '\nplayer ${state.serialize()}';
		#if js
		Browser.document.body.setAttribute("data-pr2-debug-state", 'phase=playable;${state.serialize()}');
		#end
	}
}
