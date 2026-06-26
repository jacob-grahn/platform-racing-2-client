package pr2.gameplay;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.HoverPopup;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `gameplay.StatsDisplay`.

	Shows the racing character's speed, acceleration, and jump stats over
	`StatsDisplayGraphic`. Hovering for 250ms opens a `HoverPopup` summarizing the
	three values (`Current Stats`); the popup is torn down on mouse-out and on
	removal, matching Flash dispatching a synthetic `MOUSE_OUT` from `remove`.
**/
class StatsDisplay extends Sprite {
	static inline var HOVER_DELAY_MS:Int = 250;

	private var art:Null<PR2MovieClip>;
	private var speedBox:Null<TextField>;
	private var accelBox:Null<TextField>;
	private var jumpBox:Null<TextField>;
	private var pop:Null<HoverPopup>;
	private var hoverTimer:Null<haxe.Timer>;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("StatsDisplayGraphic", {maxNestedDepth: 3});
		addChild(art);
		speedBox = LobbyArt.text(art, "speedBox");
		accelBox = LobbyArt.text(art, "accelBox");
		jumpBox = LobbyArt.text(art, "jumpBox");
		mouseChildren = false;
		addEventListener(MouseEvent.MOUSE_OVER, onMouse);
		addEventListener(MouseEvent.MOUSE_OUT, onMouse);
		setStats(0, 0, 0);
	}

	public function setStats(speed:Int, accel:Int, jump:Int):Void {
		if (speedBox != null) {
			speedBox.text = Std.string(speed);
		}
		if (accelBox != null) {
			accelBox.text = Std.string(accel);
		}
		if (jumpBox != null) {
			jumpBox.text = Std.string(jump);
		}
	}

	public function onMouse(e:MouseEvent):Void {
		if (e.type == MouseEvent.MOUSE_OUT) {
			cancelHoverTimer();
			if (pop != null) {
				pop.remove();
				pop = null;
			}
		} else {
			cancelHoverTimer();
			hoverTimer = haxe.Timer.delay(showHover, HOVER_DELAY_MS);
		}
	}

	/** The `HoverPopup` content string, exactly as Flash assembled it. */
	public function hoverContent():String {
		return "Speed: " + statText(speedBox)
			+ "\nAcceleration: " + statText(accelBox)
			+ "\nJumping: " + statText(jumpBox);
	}

	public function statText(field:Null<TextField>):String {
		return field == null ? "" : field.text;
	}

	private function showHover():Void {
		cancelHoverTimer();
		pop = new HoverPopup("Current Stats", hoverContent(), this);
	}

	private function cancelHoverTimer():Void {
		if (hoverTimer != null) {
			hoverTimer.stop();
			hoverTimer = null;
		}
	}

	public function remove():Void {
		cancelHoverTimer();
		if (pop != null) {
			pop.remove();
			pop = null;
		}
		removeEventListener(MouseEvent.MOUSE_OVER, onMouse);
		removeEventListener(MouseEvent.MOUSE_OUT, onMouse);
		if (art != null) {
			art.dispose();
			art = null;
		}
		speedBox = null;
		accelBox = null;
		jumpBox = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
