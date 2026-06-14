package pr2.harness;

#if js
import js.Browser;
#end
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.utils.Assets;
import pr2.Constants;
import pr2.level.FixtureLevel;
import pr2.level.LevelFixtureParser;

class GameplayHarness extends Sprite {
	private static inline var FIXTURE_PATH:String = "assets/fixtures/flat-level.json";

	private final level:FixtureLevel;
	private var frameCounter:Int = 0;
	private var statusText:TextField;

	public function new(?level:FixtureLevel) {
		super();
		this.level = level == null ? loadDefaultFixture() : level;

		drawStageBackground();
		addChild(new FixtureLevelRenderer(this.level));
		drawPlayerStartMarker();
		createHud();
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		exportDebugState();
	}

	private static function loadDefaultFixture():FixtureLevel {
		return LevelFixtureParser.parse(Assets.getText(FIXTURE_PATH));
	}

	private function drawStageBackground():Void {
		var background = new Shape();
		background.graphics.beginFill(Constants.BACKGROUND_COLOR);
		background.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		background.graphics.endFill();
		addChild(background);
	}

	private function drawPlayerStartMarker():Void {
		var marker = new Shape();
		var tileSize = level.tileSize;
		marker.graphics.beginFill(0xFFFFFF, 0.9);
		marker.graphics.drawCircle(tileSize / 2, tileSize / 2, tileSize * 0.28);
		marker.graphics.endFill();
		marker.graphics.lineStyle(2, 0x243B7A, 0.9);
		marker.graphics.drawCircle(tileSize / 2, tileSize / 2, tileSize * 0.28);
		marker.x = level.playerStart.x * tileSize;
		marker.y = level.playerStart.y * tileSize;
		addChild(marker);
	}

	private function createHud():Void {
		statusText = new TextField();
		statusText.defaultTextFormat = new TextFormat("_sans", 12, 0xFFFFFF);
		statusText.selectable = false;
		statusText.mouseEnabled = false;
		statusText.multiline = true;
		statusText.wordWrap = true;
		statusText.autoSize = TextFieldAutoSize.NONE;
		statusText.x = 10;
		statusText.y = 8;
		statusText.width = 340;
		statusText.height = 92;
		addChild(statusText);
		updateStatusText();
	}

	private function onEnterFrame(event:Event):Void {
		frameCounter++;
		updateStatusText();
		exportDebugState();
	}

	private function updateStatusText():Void {
		statusText.text = "Platform Racing 2 local gameplay harness\n"
			+ 'fixture=${level.id} ${level.widthTiles}x${level.heightTiles} tile=${level.tileSize}\n'
			+ 'frame=$frameCounter fixedDt=${Constants.FIXED_TIMESTEP_SECONDS}\n'
			+ 'start=${level.playerStart.x},${level.playerStart.y} finish=${level.finish.x},${level.finish.y}\n'
			+ 'blocks=${level.blocks.length}';
	}

	private function exportDebugState():Void {
		var state = 'fixture=${level.id};frame=$frameCounter;start=${level.playerStart.x},${level.playerStart.y};finish=${level.finish.x},${level.finish.y};blocks=${level.blocks.length}';
		#if js
		Browser.document.body.setAttribute("data-pr2-harness", "gameplay");
		Browser.document.body.setAttribute("data-pr2-debug-state", state);
		#end
	}
}
