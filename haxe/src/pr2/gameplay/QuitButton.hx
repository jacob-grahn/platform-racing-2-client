package pr2.gameplay;

import openfl.display.InteractiveObject;
import openfl.display.Shape;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.filters.GlowFilter;
import openfl.ui.Keyboard;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.ui.controls.GameButton;

/**
	Port of Flash `gameplay.QuitButton`.

	Mouse release quits immediately. A focused-button Space key release asks for
	confirmation while the player is still racing, but quits immediately after
	the player is already done. The authored glow timeline is exposed through the
	same start/stop calls used by `Game.finish`.
**/
class QuitButton extends openfl.display.Sprite {
	private var art:Null<openfl.display.Sprite>;
	private var button:Null<GameButton>;
	private var glow:Null<Shape>;
	private var glowFrame:Int = 0;
	public var glowActive(default, null):Bool = false;
	private var quit:Null<Void->Void>;
	private var isDonePlaying:Null<Void->Bool>;

	public function new(quit:Void->Void, isDonePlaying:Void->Bool) {
		super();
		this.quit = quit;
		this.isDonePlaying = isDonePlaying;

		art = new openfl.display.Sprite();
		addChild(art);
		var background = new Shape();
		background.graphics.beginFill(0xD8D8D8, 0.9);
		background.graphics.drawRoundRect(146, 162, 66, 35, 8, 8);
		background.graphics.endFill();
		art.addChild(background);
		glow = new Shape();
		glow.name = "glow";
		glow.graphics.beginFill(0xFFFF66, 0.75);
		glow.graphics.drawRoundRect(149, 165, 60, 29, 7, 7);
		glow.graphics.endFill();
		glow.filters = [new GlowFilter(0xFFFF33, 0.9, 12, 12, 2)];
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
		glowFrame = 0;
		glow.addEventListener(Event.ENTER_FRAME, animateGlow);
		animateGlow(null);
	}

	public function stopGlow():Void {
		glowActive = false;
		if (glow != null) {
			glow.removeEventListener(Event.ENTER_FRAME, animateGlow);
			glow.alpha = 0;
		}
	}

	private function animateGlow(_:Null<Event>):Void {
		glowFrame++;
		if (glow != null) glow.alpha = 0.45 + 0.4 * Math.sin(glowFrame * Math.PI / 15);
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
