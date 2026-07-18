package pr2.page;

#if js
import js.Browser;
#end
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.utils.Assets;
import pr2.Constants;
import pr2.effects.PixelEffect1;
import StringTools;

/**
	Plays the site intro animations, ported from the Flash `menu.IntroPage`.

	The original picked an intro sequence per host site, then played each
	intro `MovieClip` in turn inside `IntroPageGraphic.introHolder`. Each intro
	dispatches `Event.COMPLETE` from a frame script on its final frame; a stage
	click skips the rest. When the queue drains (or on click) the flow advances
	to the login page.

	Here the intro symbols are explicit native views, and their final-frame
	stop/COMPLETE behaviour matches the original `addFrameScript` calls in the
	intro graphic classes.
**/
class IntroPage extends Page {
	// Intro identifiers, matching menu.IntroPage.
	static inline var JIGG_INTRO = 1;
	static inline var KONG_INTRO = 4;

	// The Jiggmin wordmark is a 300x87 bitmap (the original `JiggminLogo`),
	// bundled with the block assets.
	static inline var JIGGMIN_LOGO_ASSET = "assets/blocks/jiggmin_logo.png";

	private var toPlay:Array<Int> = [];
	private var background:Null<Sprite>;
	private var introPageGraphic:Null<IntroPageView>;
	private var introHolder:Null<DisplayObjectContainer>;
	private var currentIntro:Null<IntroAnimationView>;
	private var skipHitArea:Null<Sprite>;
	private var listeningStage:Null<Stage>;
	private var ended:Bool = false;
	private var siteMode:String;
	private final initialFrame:Null<Int>;
	private final includePixelEffect:Bool;

	/**
		@param siteMode which host the client thinks it is, picking the intro
			sequence (defaults to the kongregate Jiggmin+Kongregate sequence).
		@param only optional single intro name ("jiggmin" or "kongregate")
			to play just one intro; used for testing.
	**/
	public function new(?siteMode:String, ?only:String, ?initialFrame:Int, includePixelEffect:Bool = true) {
		super();
		this.siteMode = siteMode == null ? "kongregate" : siteMode;
		this.initialFrame = initialFrame;
		this.includePixelEffect = includePixelEffect;

		// The original Jiggmin intro played over a full-screen black backdrop
		// (Symbol 26). Reproduce it here so the window background never shows
		// through behind the intro graphics or the assembling logo blocks.
		background = new Sprite();
		addChild(background);

		introPageGraphic = new IntroPageView();
		addChild(introPageGraphic);
		introHolder = introPageGraphic.introHolder;

		// Flash's `menu.IntroPage` listened for `MouseEvent.CLICK` on
		// `Main.stage`, so a click *anywhere* skipped straight to the login page.
		// OpenFL's HTML5 backend does not reliably dispatch a stage-level CLICK
		// for clicks that land on plain (non-button) art or empty backdrop, so a
		// stage listener alone only fired for the few interactive symbols (the
		// global mute button, the logo) — which is exactly the "clicks only
		// register on the mute button or middle logo" bug. We keep the stage
		// listener (so those interactive symbols still skip, as in Flash) and add
		// the fix for plain-area clicks using the same approach the rest of the
		// client uses for full-region clicks (`LoginPage.createHitArea`): a
		// transparent, full-stage Sprite kept on top of the intro art with its
		// own CLICK listener. Added after `introPageGraphic` so it stays topmost;
		// intros mount inside `introHolder`, which never reorders this page's
		// direct children. (`Main.muteButton` is layered above this page by
		// `Main.addGlobalChrome`, so its click still reaches the stage handler.)
		skipHitArea = new Sprite();
		skipHitArea.name = "skipHitArea";
		skipHitArea.graphics.beginFill(0xFFFFFF, 0);
		skipHitArea.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		skipHitArea.graphics.endFill();
		skipHitArea.addEventListener(MouseEvent.CLICK, onClick);
		addChild(skipHitArea);

		var single = only == null ? null : introTypeFromName(only);
		if (single != null) {
			toPlay = [single];
		} else {
			var mode = this.siteMode;
			toPlay = switch (mode) {
				case "inXile": [JIGG_INTRO];
				default: [JIGG_INTRO, KONG_INTRO]; // kongregate
			};
		}

		// Intros advance via ENTER_FRAME, so they can only start once we are on
		// the stage.
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	private function onAddedToStage(event:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		listeningStage = stage;
		stage.addEventListener(MouseEvent.CLICK, onClick);
		drawBackground();
		playNextIntro();
	}

	private function drawBackground():Void {
		if (background == null || stage == null) {
			return;
		}
		// Size from the fixed Flash stage (550x400), matching every other
		// full-stage backdrop in the client, rather than `stage.stageWidth`/
		// `stageHeight`. This guarantees the backdrop covers the whole stage, so
		// it both hides the window background and gives empty-area clicks a
		// surface to land on so they reach the skip handler.
		background.graphics.clear();
		background.graphics.beginFill(0x000000);
		background.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
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
		var intro:Null<IntroAnimationView> = null;

		switch (type) {
		case JIGG_INTRO:
			intro = new IntroAnimationView("jiggmin");
			if (includePixelEffect) injectJiggminLogo(intro);
			case KONG_INTRO:
				intro = new IntroAnimationView("kongregate");
		}

		if (intro == null) {
			endIntro();
			return;
		}

		currentIntro = intro;
		reportState("intro-" + introName(type));

		intro.addEventListener(Event.COMPLETE, onComplete);

		if (introHolder != null) {
			introHolder.addChild(intro);
		} else {
			addChild(intro);
		}
		if (initialFrame != null) intro.timeline.gotoAndStop(initialFrame);
		#if js
		untyped Browser.window.__pr2SeekIntroForTests = function(frame:Int):Void {
			if (currentIntro != null) currentIntro.timeline.gotoAndStop(frame);
		};
		#end
	}

	/**
		The Jiggmin intro leaves an empty `logo_mc` slot inside its `logo` clip;
		the original injected a `JiggminLogo` bitmap wrapped in a `PixelEffect1`
		pixel dissolve. We reproduce that here: the logo bitmap is sliced into
		floating blocks that fly in and assemble the wordmark over the intro.
		Best-effort: never throws if the slot or asset is missing.
	**/
	private function injectJiggminLogo(intro:IntroAnimationView):Void {
		if (!Assets.exists(JIGGMIN_LOGO_ASSET)) {
			return;
		}

		var bitmapData = Assets.getBitmapData(JIGGMIN_LOGO_ASSET);
		if (bitmapData == null) {
			return;
		}
		// Mirror `new PixelEffect1(new JiggminLogo(300, 87))`: the effect owns a
		// copy of the logo pixels, so clone rather than handing it the shared
		// cached asset bitmap (SegPixel mutates and disposes its source).
		var effect = new PixelEffect1(bitmapData.clone());
		intro.logoHolder.addChild(effect);
	}

	private function clearCurrentIntro():Void {
		if (currentIntro == null) {
			return;
		}

		currentIntro.stop();
		currentIntro.removeEventListener(Event.COMPLETE, onComplete);
		currentIntro.dispose();
		currentIntro = null;
		#if js
		untyped Browser.window.__pr2SeekIntroForTests = null;
		#end
	}

	private function onComplete(event:Event):Void {
		playNextIntro();
	}

	private function endIntro():Void {
		// A click can race the queue draining (or fire more than once); only the
		// first request advances so we never stack two LoginPage transitions.
		if (ended) {
			return;
		}
		ended = true;
		clearCurrentIntro();
		reportState("login");
		if (pageHolder != null) {
			pageHolder.changePage(new LoginPage(siteMode));
		}
	}

	private static function introTypeFromName(name:String):Null<Int> {
		return switch (StringTools.trim(name).toLowerCase()) {
			case "jiggmin" | "jigg": JIGG_INTRO;
			case "kongregate" | "kong": KONG_INTRO;
			default: null;
		}
	}

	private static function introName(type:Int):String {
		return switch (type) {
			case JIGG_INTRO: "jiggmin";
			case KONG_INTRO: "kongregate";
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
		if (skipHitArea != null) {
			skipHitArea.removeEventListener(MouseEvent.CLICK, onClick);
			skipHitArea = null;
		}
		if (listeningStage != null) {
			listeningStage.removeEventListener(MouseEvent.CLICK, onClick);
			listeningStage = null;
		}
		clearCurrentIntro();
		introHolder = null;
		if (introPageGraphic != null) {
			introPageGraphic.dispose();
		}
		introPageGraphic = null;
		background = null;
		super.remove();
	}
}
