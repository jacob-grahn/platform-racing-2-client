package pr2.page;

#if js
import js.Browser;
#end
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Shape;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.utils.Assets;
import pr2.effects.PixelEffect1;
import pr2.runtime.PR2MovieClip;
import StringTools;

/**
	Plays the site intro animations, ported from the Flash `menu.IntroPage`.

	The original picked an intro sequence per host site, then played each
	intro `MovieClip` in turn inside `IntroPageGraphic.introHolder`. Each intro
	dispatches `Event.COMPLETE` from a frame script on its final frame; a stage
	click skips the rest. When the queue drains (or on click) the flow advances
	to the login page.

	Here the intro symbols are driven by `PR2MovieClip`, and the final-frame
	stop/COMPLETE behaviour is reproduced with `setFrameScript` to match the
	original `addFrameScript` calls in the intro graphic classes.
**/
class IntroPage extends Page {
	// Intro identifiers, matching menu.IntroPage.
	static inline var JIGG_INTRO = 1;
	static inline var ARMOR_INTRO = 2;
	static inline var BUBBOX_INTRO = 3;
	static inline var KONG_INTRO = 4;

	// 1-based frame where each intro's frame script stops and signals
	// completion, matching the original addFrameScript calls:
	//   JiggminIntroGraphic: addFrameScript(230, frame231)
	//   KongregateIntroGraphic: addFrameScript(152, frame153)
	static inline var JIGG_COMPLETE_FRAME = 231;
	static inline var KONG_COMPLETE_FRAME = 153;

	// The Jiggmin wordmark is a 300x87 bitmap (the original `JiggminLogo`),
	// bundled with the block assets.
	static inline var JIGGMIN_LOGO_ASSET = "assets/blocks/jiggmin_logo.png";

	private var toPlay:Array<Int> = [];
	private var background:Null<Shape>;
	private var introPageGraphic:Null<PR2MovieClip>;
	private var introHolder:Null<DisplayObjectContainer>;
	private var currentIntro:Null<PR2MovieClip>;
	private var listeningStage:Null<Stage>;

	/**
		@param siteMode which host the client thinks it is, picking the intro
			sequence (defaults to the kongregate Jiggmin+Kongregate sequence).
		@param only optional single intro name ("jiggmin", "kongregate",
			"armor", "bubblebox") to play just one intro; used for testing.
	**/
	public function new(?siteMode:String, ?only:String) {
		super();

		// The original Jiggmin intro played over a full-screen black backdrop
		// (Symbol 26). Reproduce it here so the window background never shows
		// through behind the intro graphics or the assembling logo blocks.
		background = new Shape();
		addChild(background);

		introPageGraphic = PR2MovieClip.fromLinkage("IntroPageGraphic");
		addChild(introPageGraphic);
		introHolder = Std.downcast(introPageGraphic.getChildByTimelineName("introHolder"), DisplayObjectContainer);

		var single = only == null ? null : introTypeFromName(only);
		if (single != null) {
			toPlay = [single];
		} else {
			var mode = siteMode == null ? "kongregate" : siteMode;
			toPlay = switch (mode) {
				case "inXile": [JIGG_INTRO];
				case "bubbleBox": [JIGG_INTRO, BUBBOX_INTRO];
				case "armorGames": [JIGG_INTRO, ARMOR_INTRO];
				default: [JIGG_INTRO, KONG_INTRO]; // kongregate
			};
		}

		// Intros advance via ENTER_FRAME, so they can only start once we are on
		// the stage. The stage click-to-skip listener also needs the stage.
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	private function onAddedToStage(event:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		listeningStage = stage;
		drawBackground();
		stage.addEventListener(MouseEvent.CLICK, onClick);
		playNextIntro();
	}

	private function drawBackground():Void {
		if (background == null || stage == null) {
			return;
		}
		background.graphics.clear();
		background.graphics.beginFill(0x000000);
		background.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		background.graphics.endFill();
	}

	private function onClick(event:MouseEvent):Void {
		endIntro();
	}

	private function playNextIntro():Void {
		clearCurrentIntro();

		if (toPlay.length <= 0) {
			endIntro();
			return;
		}

		var type = toPlay.shift();
		var intro:Null<PR2MovieClip> = null;
		var completeFrame = 0;

		switch (type) {
			case JIGG_INTRO:
				intro = PR2MovieClip.fromLinkage("JiggminIntroGraphic");
				completeFrame = JIGG_COMPLETE_FRAME;
				injectJiggminLogo(intro);
			case KONG_INTRO:
				intro = PR2MovieClip.fromLinkage("KongregateIntroGraphic");
				completeFrame = KONG_COMPLETE_FRAME;
			case ARMOR_INTRO:
				intro = PR2MovieClip.fromLinkage("ArmorIntroGraphic");
			case BUBBOX_INTRO:
				intro = PR2MovieClip.fromLinkage("BubbleBoxIntroGraphic");
		}

		if (intro == null) {
			endIntro();
			return;
		}

		currentIntro = intro;
		reportState("intro-" + introName(type));

		// Reproduce the original final-frame frame script: stop and dispatch
		// COMPLETE. Where we do not know the exact stop frame, fall back to the
		// symbol's last frame.
		var stopFrame = completeFrame > 0 ? completeFrame : intro.totalFrames;
		if (stopFrame > intro.totalFrames) {
			stopFrame = intro.totalFrames;
		}
		intro.setFrameScript(stopFrame - 1, function() {
			intro.stop();
			intro.dispatchEvent(new Event(Event.COMPLETE));
		});
		intro.addEventListener(Event.COMPLETE, onComplete);

		if (introHolder != null) {
			introHolder.addChild(intro);
		} else {
			addChild(intro);
		}
	}

	/**
		The Jiggmin intro leaves an empty `logo_mc` slot inside its `logo` clip;
		the original injected a `JiggminLogo` bitmap wrapped in a `PixelEffect1`
		pixel dissolve. We reproduce that here: the logo bitmap is sliced into
		floating blocks that fly in and assemble the wordmark over the intro.
		Best-effort: never throws if the slot or asset is missing.
	**/
	private function injectJiggminLogo(intro:PR2MovieClip):Void {
		if (!Assets.exists(JIGGMIN_LOGO_ASSET)) {
			return;
		}

		var logo = Std.downcast(intro.getChildByTimelineName("logo"), PR2MovieClip);
		if (logo == null) {
			return;
		}

		var logoMc = Std.downcast(logo.getChildByTimelineName("logo_mc"), DisplayObjectContainer);
		var container:Null<DisplayObjectContainer> = logoMc != null ? logoMc : logo;
		if (container == null) {
			return;
		}

		var bitmapData = Assets.getBitmapData(JIGGMIN_LOGO_ASSET);
		if (bitmapData == null) {
			return;
		}
		// Mirror `new PixelEffect1(new JiggminLogo(300, 87))`: the effect owns a
		// copy of the logo pixels, so clone rather than handing it the shared
		// cached asset bitmap (SegPixel mutates and disposes its source).
		container.addChild(new PixelEffect1(bitmapData.clone()));
	}

	private function clearCurrentIntro():Void {
		if (currentIntro == null) {
			return;
		}

		currentIntro.stop();
		currentIntro.removeEventListener(Event.COMPLETE, onComplete);
		if (currentIntro.parent != null) {
			currentIntro.parent.removeChild(currentIntro);
		}
		currentIntro.dispose();
		currentIntro = null;
	}

	private function onComplete(event:Event):Void {
		playNextIntro();
	}

	private function endIntro():Void {
		clearCurrentIntro();
		reportState("login");
		if (pageHolder != null) {
			pageHolder.changePage(new LoginPage());
		}
	}

	private static function introTypeFromName(name:String):Null<Int> {
		return switch (StringTools.trim(name).toLowerCase()) {
			case "jiggmin" | "jigg": JIGG_INTRO;
			case "kongregate" | "kong": KONG_INTRO;
			case "armor" | "armorgames": ARMOR_INTRO;
			case "bubblebox" | "bubbox": BUBBOX_INTRO;
			default: null;
		}
	}

	private static function introName(type:Int):String {
		return switch (type) {
			case JIGG_INTRO: "jiggmin";
			case KONG_INTRO: "kongregate";
			case ARMOR_INTRO: "armor";
			case BUBBOX_INTRO: "bubblebox";
			default: "unknown";
		}
	}

	/**
		Publishes the current intro flow state to the DOM so automated harness
		runs can observe the sequence, mirroring the gameplay harness's
		`data-pr2-debug-state` hook.
	**/
	private function reportState(state:String):Void {
		#if js
		Browser.document.body.setAttribute("data-pr2-intro-state", state);
		#end
	}

	override public function remove():Void {
		if (listeningStage != null) {
			listeningStage.removeEventListener(MouseEvent.CLICK, onClick);
			listeningStage = null;
		}
		clearCurrentIntro();
		introHolder = null;
		introPageGraphic = null;
		background = null;
		super.remove();
	}
}
