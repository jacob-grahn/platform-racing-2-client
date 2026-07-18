package pr2.gameplay;

import haxe.Json;
import openfl.display.InteractiveObject;
import openfl.display.Shape;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.filters.GlowFilter;
import openfl.ui.Keyboard;
import openfl.utils.Assets;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.ui.controls.GameButton;
import pr2.runtime.SvgAsset;

/**
	Port of Flash `gameplay.QuitButton`.

	Mouse release quits immediately. A focused-button Space key release asks for
	confirmation while the player is still racing, but quits immediately after
	the player is already done. The authored glow timeline is exposed through the
	same start/stop calls used by `Game.finish`.
**/
class QuitButton extends openfl.display.Sprite {
	public static inline final BACKGROUND_ASSET = "assets/svg/effects/quit_background_01.svg";
	public static inline final GLOW_ASSET = "assets/svg/effects/quit_glow_01.svg";
	public static inline final GLOW_DATA_ASSET = "assets/ui/quit-glow.json";
	private static var parsedGlowData:Dynamic;
	private var art:Null<openfl.display.Sprite>;
	private var button:Null<GameButton>;
	private var glow:Null<Shape>;
	private var glowFrame:Int = 2;
	public var glowActive(default, null):Bool = false;
	private var quit:Null<Void->Void>;
	private var isDonePlaying:Null<Void->Bool>;

	public function new(quit:Void->Void, isDonePlaying:Void->Bool) {
		super();
		this.quit = quit;
		this.isDonePlaying = isDonePlaying;

		art = new openfl.display.Sprite();
		addChild(art);
		var background = SvgAsset.create(BACKGROUND_ASSET);
		art.addChild(background);
		glow = SvgAsset.create(GLOW_ASSET);
		glow.name = "glow";
		glow.x = 153;
		glow.y = 169;
		art.addChild(glow);
		button = new GameButton("Quit");
		button.name = "quit_bt";
		button.x = 153;
		button.y = 169;
		button.setSize(54, 22);
		art.addChild(button);
		if (button != null) {
			button.addEventListener(MouseEvent.MOUSE_UP, invokeMouseQuit);
			button.addEventListener(KeyboardEvent.KEY_UP, invokeKeyboardQuit);
		}
		stopGlow();
	}

	public function startGlow():Void {
		if (glow == null || glowActive) return;
		glowActive = true;
		glowFrame = glowData().labels.on;
		glow.addEventListener(Event.ENTER_FRAME, animateGlow);
		applyGlowFrame();
	}

	public function stopGlow():Void {
		glowActive = false;
		if (glow != null) {
			glow.removeEventListener(Event.ENTER_FRAME, animateGlow);
			glowFrame = glowData().labels.off;
			applyGlowFrame();
		}
	}

	private function animateGlow(_:Null<Event>):Void {
		glowFrame++;
		var data = glowData();
		if (glowFrame >= data.endFrameScript.frame) glowFrame = Reflect.field(data.labels, data.endFrameScript.target);
		applyGlowFrame();
	}

	private function applyGlowFrame():Void {
		if (glow == null) return;
		var frame:Dynamic = glowData().frames[glowFrame - 1];
		glow.visible = frame.visible;
		if (!glow.visible) {
			glow.filters = [];
			return;
		}
		if (frame.glow == null) {
			glow.filters = [];
			return;
		}
		var filter:Dynamic = frame.glow;
		glow.filters = [new GlowFilter(filter.color, filter.alpha, filter.blurX, filter.blurY, filter.strength, filter.quality)];
	}

	private static function glowData():Dynamic {
		if (parsedGlowData != null) return parsedGlowData;
		var content = Assets.getText(GLOW_DATA_ASSET);
		#if sys
		if (content == null) content = sys.io.File.getContent("art/ui/quit-glow.json");
		#end
		if (content == null) throw 'Missing authored Quit glow data $GLOW_DATA_ASSET';
		parsedGlowData = Json.parse(content);
		return parsedGlowData;
	}

	public function glowFrameForTests():Int return glowFrame;
	public function advanceGlowForTests():Void animateGlow(null);
	public function glowVisibleForTests():Bool return glow != null && glow.visible;
	public function glowBlurForTests():Float {
		if (glow == null || glow.filters.length == 0) return 0;
		return Std.downcast(glow.filters[0], GlowFilter).blurX;
	}
	public function glowStrengthForTests():Float {
		if (glow == null || glow.filters.length == 0) return 0;
		return Std.downcast(glow.filters[0], GlowFilter).strength;
	}

	private function invokeMouseQuit(_:MouseEvent):Void {
		doQuit();
	}

	private function invokeKeyboardQuit(event:KeyboardEvent):Void {
		if (event.keyCode != Keyboard.SPACE) {
			return;
		}
		if (isDonePlaying != null && !isDonePlaying()) {
			new ConfirmPopup(doQuit, "Do you really want to quit the game?");
		} else {
			doQuit();
		}
	}

	private function doQuit():Void {
		if (quit != null) {
			quit();
		}
	}

	public function remove():Void {
		stopGlow();
		if (button != null) {
			button.removeEventListener(MouseEvent.MOUSE_UP, invokeMouseQuit);
			button.removeEventListener(KeyboardEvent.KEY_UP, invokeKeyboardQuit);
			button.dispose();
			button = null;
		}
		if (art != null) {
			if (art.parent != null) art.parent.removeChild(art);
			art = null;
		}
		glow = null;
		quit = null;
		isDonePlaying = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
