package pr2.harness;

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
import openfl.utils.Assets;
import pr2.runtime.FontResolver;
import pr2.Constants;
import pr2.character.CharacterDisplay;
import pr2.character.CharacterRenderMode;
import pr2.level.FixtureLevel;
import pr2.level.LevelFixtureParser;

class GameplayHarness extends Sprite {
	private static inline var FIXTURE_PATH:String = "assets/fixtures/flat-level.json";

	private final level:FixtureLevel;
	private final options:GameplayHarnessOptions;
	private final player:LocalPlayerController;
	private final input:LocalPlayerInput = new LocalPlayerInput();
	private var frameCounter:Int = 0;
	private var statusText:TextField;
	private var playerDisplay:Sprite;
	private var characterDisplay:CharacterDisplay;

	public function new(?level:FixtureLevel, ?options:GameplayHarnessOptions) {
		super();
		this.level = level == null ? loadDefaultFixture() : level;
		this.options = options == null ? loadDefaultOptions() : options;
		player = new LocalPlayerController(this.level);

		drawStageBackground();
		addChild(new FixtureLevelRenderer(this.level));
		createPlayerDisplay();
		createHud();
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		exportDebugState();
	}

	private static function loadDefaultFixture():FixtureLevel {
		return LevelFixtureParser.parse(Assets.getText(FIXTURE_PATH));
	}

	private static function loadDefaultOptions():GameplayHarnessOptions {
		#if js
		return GameplayHarnessOptions.parseQuery(Browser.location.search);
		#else
		return GameplayHarnessOptions.defaults();
		#end
	}

	private function drawStageBackground():Void {
		var background = new Shape();
		background.graphics.beginFill(Constants.BACKGROUND_COLOR);
		background.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		background.graphics.endFill();
		addChild(background);
	}

	private function createPlayerDisplay():Void {
		playerDisplay = new Sprite();

		characterDisplay = new CharacterDisplay(
			options.partIds,
			{primary: options.primaryColor, secondary: options.secondaryColor},
			options.renderMode
		);
		characterDisplay.x = LocalPlayerController.STANDING_WIDTH / 2;
		characterDisplay.y = LocalPlayerController.STANDING_HEIGHT;
		characterDisplay.scaleX = 0.9;
		characterDisplay.scaleY = 0.9;
		playerDisplay.addChild(characterDisplay);

		addChild(playerDisplay);
		updatePlayerDisplay();
	}

	private function createHud():Void {
		statusText = new TextField();
		statusText.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 12, 0xFFFFFF);
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
		player.step(input.copy());
		updatePlayerDisplay();
		updateStatusText();
		exportDebugState();
	}

	private function updateStatusText():Void {
		var playerState = player.debugState();
		statusText.text = "Platform Racing 2 local gameplay harness\n"
			+ 'fixture=${level.id} ${level.widthTiles}x${level.heightTiles} tile=${level.tileSize}\n'
			+ 'frame=$frameCounter fixedDt=${Constants.FIXED_TIMESTEP_SECONDS}\n'
			+ 'player ${playerState.serialize()}\n'
			+ 'finish=${level.finish.x},${level.finish.y} blocks=${level.blocks.length}\n'
			+ 'outfit=${options.serialize()}\n'
			+ 'characterRender=${characterDisplay.renderMode.toLabel()}';
	}

	private function exportDebugState():Void {
		var state = 'fixture=${level.id};frame=$frameCounter;${player.debugState().serialize()};finish=${level.finish.x},${level.finish.y};blocks=${level.blocks.length};${options.serialize()};characterRender=${characterDisplay.renderMode.toLabel()}';
		#if js
		Browser.document.body.setAttribute("data-pr2-harness", "gameplay");
		Browser.document.body.setAttribute("data-pr2-debug-state", state);
		#end
	}

	private function updatePlayerDisplay():Void {
		var height = player.crouching ? LocalPlayerController.CROUCHING_HEIGHT : LocalPlayerController.STANDING_HEIGHT;
		playerDisplay.x = player.x - LocalPlayerController.STANDING_WIDTH / 2;
		playerDisplay.y = player.y - height;
		playerDisplay.scaleY = height / LocalPlayerController.STANDING_HEIGHT;
		characterDisplay.scaleX = 0.9 * player.facingScaleX;
		characterDisplay.setState(player.debugState().characterState.toClipName());
		characterDisplay.advanceOneFrame();
	}

	private function onAddedToStage(event:Event):Void {
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		#if js
		Reflect.setField(Browser.window, "__pr2HarnessSetKeyCode", function(keyCode:Int, pressed:Bool):Void {
			setKey(cast keyCode, pressed);
		});
		#end
	}

	private function onKeyDown(event:KeyboardEvent):Void {
		setKey(event.keyCode, true);
	}

	private function onKeyUp(event:KeyboardEvent):Void {
		setKey(event.keyCode, false);
	}

	private function setKey(keyCode:UInt, pressed:Bool):Void {
		if (keyCode == Keyboard.LEFT || AlternateControls.matches("left", keyCode)) input.left = pressed;
		if (keyCode == Keyboard.RIGHT || AlternateControls.matches("right", keyCode)) input.right = pressed;
		if (keyCode == Keyboard.UP || AlternateControls.matches("up", keyCode)) input.jump = pressed;
		if (keyCode == Keyboard.DOWN || AlternateControls.matches("down", keyCode)) input.down = pressed;
		if (keyCode == Keyboard.SPACE || AlternateControls.matches("item", keyCode)) input.item = pressed;
		if (keyCode == Keyboard.C && pressed) toggleCharacterRenderMode();
	}

	private function toggleCharacterRenderMode():Void {
		characterDisplay.setRenderMode(characterDisplay.renderMode == CharacterRenderMode.Composite
			? CharacterRenderMode.Layered
			: CharacterRenderMode.Composite);
		updateStatusText();
		exportDebugState();
	}
}
