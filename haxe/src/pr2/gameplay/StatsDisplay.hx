package pr2.gameplay;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.display.Removable;
import pr2.lobby.dialogs.HoverPopup;
import pr2.runtime.SvgAsset;

/**
	Port of Flash `gameplay.StatsDisplay`.

	Shows the racing character's speed, acceleration, and jump stats over
	`StatsDisplayGraphic`. Hovering for 250ms opens a `HoverPopup` summarizing the
	three values (`Current Stats`); the popup is torn down on mouse-out and on
	removal, matching Flash dispatching a synthetic `MOUSE_OUT` from `remove`.
**/
class StatsDisplay extends Removable {
	static inline var HOVER_DELAY_MS:Int = 250;
	public static inline final BACKGROUND_ASSET = "assets/svg/effects/stats_display_01.svg";

	private var art:Null<Sprite>;
	private var speedBox:Null<TextField>;
	private var accelBox:Null<TextField>;
	private var jumpBox:Null<TextField>;
	private var pop:Null<HoverPopup>;
	private var hoverTimer:Null<haxe.Timer>;
	public final exactBackground:Shape;

	public function new() {
		super();
		art = new Sprite();
		exactBackground = SvgAsset.create(BACKGROUND_ASSET);
		exactBackground.name = "exactBackground";
		art.addChild(exactBackground);
		speedBox = createStatBox("speedBox", 2.4, 15.5);
		accelBox = createStatBox("accelBox", 20.25, 15.7);
		jumpBox = createStatBox("jumpBox", 38.35, 15.3);
		art.addChild(speedBox);
		art.addChild(accelBox);
		art.addChild(jumpBox);
		addChild(art);
		mouseChildren = false;
		addEventListener(MouseEvent.MOUSE_OVER, onMouse);
		addEventListener(MouseEvent.MOUSE_OUT, onMouse);
		setStats(0, 0, 0);
	}

	private function createStatBox(name:String, x:Float, width:Float):TextField {
		var field = new TextField();
		field.name = name;
		field.x = x;
		field.y = 3.75;
		field.width = width;
		field.height = 9.75;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat("Verdana", 8, 0, false, null, null, null, null,
			TextFormatAlign.CENTER);
		return field;
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

	override public function remove():Void {
		if (isRemoved()) return;
		cancelHoverTimer();
		if (pop != null) {
			pop.remove();
			pop = null;
		}
		removeEventListener(MouseEvent.MOUSE_OVER, onMouse);
		removeEventListener(MouseEvent.MOUSE_OUT, onMouse);
		if (art != null) {
			if (art.parent != null) art.parent.removeChild(art);
			art = null;
		}
		speedBox = null;
		accelBox = null;
		jumpBox = null;
		super.remove();
	}
}
