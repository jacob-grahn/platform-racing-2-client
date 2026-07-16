package pr2.gameplay;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import pr2.lobby.dialogs.HoverPopup;

/**
	Port of `MiniMapDot.as`. A single player marker on the minimap. The authored
	`MiniMapDot` symbol carries five labelled colour frames (`remote0`-`remote3`
	and `local`); `setTempID` latches one once, exactly as Flash does.

	The hover popup (`infoMouseEvent`/`HoverPopup`) is enabled only for live Course
	dots that have been assigned player metadata, matching Flash's suppression
	outside an active Game.
**/
class MiniMapDot extends Sprite {
	// MiniMapDot.as colour constants (kept for parity reference; the authored
	// symbol frames already carry these fills).
	public static inline var REMOTE0_COLOR:Int = 0x10B6DE;
	public static inline var REMOTE1_COLOR:Int = 0xFF0000;
	public static inline var REMOTE2_COLOR:Int = 0x00FF00;
	public static inline var REMOTE3_COLOR:Int = 0x999999;
	public static inline var LOCAL_COLOR:Int = 0xFFFF00;

	private var tempID:Int = -1;
	private var selectedColor:Int = REMOTE0_COLOR;
	public var hover(default, null):Null<HoverPopup>;
	private var hoverEnabled:Bool = false;
	private var hoverTitle:String = "";
	private var hoverContent:String = "";

	public function new() {
		super();
		// Flash's constructor stops on frame 1 (`remote0`) until setTempID
		// chooses one of the other labelled colour states.
		drawMarker();
		addEventListener(MouseEvent.MOUSE_OVER, infoMouseEvent);
		addEventListener(MouseEvent.MOUSE_OUT, infoMouseEvent);
	}

	/** Latches the dot to one colour frame the first time it is assigned. */
	public function setTempID(id:Int, local:Bool = false):Void {
		if (tempID == -1 && id >= 0 && id <= 3) {
			tempID = id;
			selectedColor = local ? LOCAL_COLOR : colorForTempId(tempID);
			drawMarker();
		}
	}

	/** Native marker colour, exposed for deterministic parity coverage. */
	public function markerColorForTests():Int {
		return selectedColor;
	}

	/** The authored frame label for a temp id, matching MiniMapDot.setTempID. */
	public static function labelForTempId(id:Int, local:Bool):String {
		return local ? "local" : "remote" + Std.string(id);
	}

	/** The dot colour for a temp id, matching MiniMapDot.getColor. */
	public static function colorForTempId(id:Int):Int {
		return switch (id) {
			case 0: REMOTE0_COLOR;
			case 1: REMOTE1_COLOR;
			case 2: REMOTE2_COLOR;
			case 3: REMOTE3_COLOR;
			default: LOCAL_COLOR;
		}
	}

	public function setHoverInfo(playerNumber:Int, playerName:String, liveGame:Bool = true):Void {
		hoverEnabled = liveGame;
		hoverTitle = "Player " + playerNumber;
		hoverContent = playerName;
	}

	private function infoMouseEvent(event:MouseEvent = null):Void {
		if (!hoverEnabled && event != null) {
			return;
		}
		if (hover != null) {
			hover.remove();
			hover = null;
		}
		if (event == null || event.type == MouseEvent.MOUSE_OUT) {
			return;
		}
		if (event.type == MouseEvent.MOUSE_OVER) {
			hover = new HoverPopup(hoverTitle, hoverContent, this);
		}
	}

	public function remove():Void {
		infoMouseEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		removeEventListener(MouseEvent.MOUSE_OVER, infoMouseEvent);
		removeEventListener(MouseEvent.MOUSE_OUT, infoMouseEvent);
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	/**
		The XFL edges are `(-2,-4) .. (2,0)` in authored pixels. Keeping the
		bottom-centre origin is important because minimap coordinates attach dots
		at a player's exact course position.
	**/
	private function drawMarker():Void {
		graphics.clear();
		graphics.lineStyle(0.05, 0x000000);
		graphics.beginFill(selectedColor);
		graphics.drawRect(-2, -4, 4, 4);
		graphics.endFill();
	}
}
