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
import pr2.net.CampaignListClient;
import pr2.net.CampaignListClient.CampaignListResult;
import pr2.net.CampaignLevelInfo;
import pr2.net.LevelDataClient;
import pr2.net.ServerLevelData;
import pr2.level.ServerLevel;
import pr2.level.ServerLevelDecoder;

/**
	Bit 1 of the server campaign level test harness (see TODO.md). Fetches a real
	campaign course list from the live PR2 server and reports what came back. This
	proves end-to-end connectivity and list parsing before later bits load,
	render, and play the first level.

	Reachable via `?screen=campaign` (optional `&page=N`, default 1).
**/
class CampaignTestScreen extends Sprite {
	private static inline var DEFAULT_PAGE:Int = 1;

	private final page:Int;
	private var statusText:TextField;

	public function new(?page:String) {
		super();
		this.page = parsePage(page);

		drawBackground();
		createStatusText();
		setStatus("phase=fetching", 'Fetching campaign list page ${this.page}...');
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	private static function parsePage(page:Null<String>):Int {
		if (page == null) {
			return DEFAULT_PAGE;
		}
		var parsed = Std.parseInt(StringTools.trim(page));
		return (parsed == null || parsed < 1) ? DEFAULT_PAGE : parsed;
	}

	private function onAddedToStage(event:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		CampaignListClient.fetch(page, onList, onError);
	}

	private function onList(result:CampaignListResult):Void {
		if (result.levels.length == 0) {
			setStatus("phase=empty", 'Campaign list page $page returned no levels.');
			return;
		}

		var first = result.levels[0];
		setStatus('phase=listLoaded;levels=${result.levels.length};firstId=${first.levelId}', [
			'Campaign list page $page',
			'levels=${result.levels.length} listHashValid=${result.hashValid}',
			'first level: ${first.describe()}',
			"",
			'Loading level data for ${first.levelId} v${first.version}...'
		].join("\n"));

		LevelDataClient.fetch(first.levelId, first.version, function(data:ServerLevelData):Void {
			onLevelData(first, data);
		}, onLevelError);
	}

	private function onLevelData(info:CampaignLevelInfo, data:ServerLevelData):Void {
		var lines = [
			'Campaign page $page -> first level loaded',
			'id=${info.levelId} v${info.version} levelHashValid=${data.hashValid}',
			'title: ${data.title}',
			'gravity=${data.gravity} maxTime=${data.maxTime} mode=${data.gameMode}',
			'items (${data.items.length}): ${data.items.join(", ")}'
		];

		var debug = 'phase=levelLoaded;id=${info.levelId};hashValid=${data.hashValid};readMode=${data.readMode()}';
		try {
			var level = ServerLevelDecoder.decode(data.data);
			lines.push('decoded: blocks=${level.blocks.length} bg=0x${StringTools.hex(level.bgColor, 6)}');
			lines.push('starts=${level.startBlocks().length} finishes=${level.finishBlocks().length} bounds=${level.maxX - level.minX}x${level.maxY - level.minY}px');
			lines.push("");
			lines.push("Next: render these blocks + drop the character in (TODO Bit 4+).");
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

	private function createStatusText():Void {
		statusText = new TextField();
		statusText.defaultTextFormat = new TextFormat("_sans", 13, 0xD7E8FF);
		statusText.selectable = false;
		statusText.mouseEnabled = false;
		statusText.multiline = true;
		statusText.wordWrap = true;
		statusText.autoSize = TextFieldAutoSize.NONE;
		statusText.x = 16;
		statusText.y = 16;
		statusText.width = Constants.STAGE_WIDTH - 32;
		statusText.height = Constants.STAGE_HEIGHT - 32;
		addChild(statusText);
	}

	private function setStatus(debugState:String, text:String):Void {
		statusText.text = text;
		#if js
		Browser.document.body.setAttribute("data-pr2-harness", "campaign");
		Browser.document.body.setAttribute("data-pr2-debug-state", debugState);
		#end
	}
}
