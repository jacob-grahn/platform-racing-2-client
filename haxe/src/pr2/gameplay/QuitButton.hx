package pr2.gameplay;

import openfl.display.InteractiveObject;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.ui.Keyboard;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `gameplay.QuitButton`.

	Mouse release quits immediately. A focused-button Space key release asks for
	confirmation while the player is still racing, but quits immediately after
	the player is already done. The authored glow timeline is exposed through the
	same start/stop calls used by `Game.finish`.
**/
class QuitButton extends openfl.display.Sprite {
	private var art:Null<PR2MovieClip>;
	private var button:Null<InteractiveObject>;
	private var quit:Null<Void->Void>;
	private var isDonePlaying:Null<Void->Bool>;

	public function new(quit:Void->Void, isDonePlaying:Void->Bool) {
		super();
		this.quit = quit;
		this.isDonePlaying = isDonePlaying;

		art = PR2MovieClip.fromLinkage("QuitButtonGraphic", {maxNestedDepth: 5});
		addChild(art);
		button = Std.downcast(LobbyArt.findByName(art, "quit_bt"), InteractiveObject);
		if (button != null) {
			button.addEventListener(MouseEvent.MOUSE_UP, invokeMouseQuit);
			button.addEventListener(KeyboardEvent.KEY_UP, invokeKeyboardQuit);
		}
		stopGlow();
	}

	public function startGlow():Void {
		var glow = glowClip();
		if (glow != null) {
			glow.gotoAndPlay("on");
		}
	}

	public function stopGlow():Void {
		var glow = glowClip();
		if (glow != null) {
			glow.gotoAndStop("off");
		}
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

	private function glowClip():Null<PR2MovieClip> {
		return art == null ? null : Std.downcast(LobbyArt.findByName(art, "glow"), PR2MovieClip);
	}

	public function remove():Void {
		if (button != null) {
			button.removeEventListener(MouseEvent.MOUSE_UP, invokeMouseQuit);
			button.removeEventListener(KeyboardEvent.KEY_UP, invokeKeyboardQuit);
			button = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		quit = null;
		isDonePlaying = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
