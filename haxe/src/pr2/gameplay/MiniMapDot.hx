package pr2.gameplay;

import openfl.display.Sprite;
import pr2.runtime.PR2MovieClip;

/**
	Port of `MiniMapDot.as`. A single player marker on the minimap. The authored
	`MiniMapDot` symbol carries five labelled colour frames (`remote0`-`remote3`
	and `local`); `setTempID` latches one once, exactly as Flash does.

	The hover popup (`infoMouseEvent`/`HoverPopup`) that shows the player name on
	mouse-over needs `Course.course.playerArray`, which the campaign test screen
	does not yet build, so it is deferred until the full `Game`/`Course` shell
	lands (see TODO.md "Port the complete in-game shell").
**/
class MiniMapDot extends Sprite {
	// MiniMapDot.as colour constants (kept for parity reference; the authored
	// symbol frames already carry these fills).
	public static inline var REMOTE0_COLOR:Int = 0x10B6DE;
	public static inline var REMOTE1_COLOR:Int = 0xFF0000;
	public static inline var REMOTE2_COLOR:Int = 0x00FF00;
	public static inline var REMOTE3_COLOR:Int = 0x999999;
	public static inline var LOCAL_COLOR:Int = 0xFFFF00;

	private final clip:PR2MovieClip;
	private var tempID:Int = -1;

	public function new() {
		super();
		// Flash's MiniMapDot constructor calls stop(); gotoAndStop holds frame 1
		// until setTempID picks the colour, and keeps the clip from animating
		// through the colour frames.
		clip = PR2MovieClip.fromLinkage("MiniMapDot");
		clip.gotoAndStop("remote0");
		addChild(clip);
	}

	/** Latches the dot to one colour frame the first time it is assigned. */
	public function setTempID(id:Int, local:Bool = false):Void {
		if (tempID == -1 && id >= 0 && id <= 3) {
			tempID = id;
			clip.gotoAndStop(labelForTempId(tempID, local));
		}
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

	public function remove():Void {
		// MiniMapDot.remove dispatches MOUSE_OUT to dismiss the hover popup; the
		// popup is deferred here, so there is nothing to dismiss yet.
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
