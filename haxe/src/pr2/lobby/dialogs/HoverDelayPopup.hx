package pr2.lobby.dialogs;

import haxe.Timer;
import openfl.display.Sprite;
import openfl.events.MouseEvent;

/** Flash `HoverDelayPopup`: delayed tooltip wrapper with cancel-on-out/down. */
class HoverDelayPopup extends Sprite {
	public final title:String;
	public final content:String;
	public final delayMs:Int;
	public var hover(default, null):Null<HoverPopup>;

	private var delayTimer:Null<Timer>;

	public function new(title:String = "", content:String = "", delayMs:Int = 500) {
		super();
		this.title = title;
		this.content = content;
		this.delayMs = delayMs;
		addEventListener(MouseEvent.MOUSE_OVER, overHandler);
		addEventListener(MouseEvent.MOUSE_OUT, outHandler);
		addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
	}

	private function overHandler(_:MouseEvent):Void {
		clearDelay();
		hidePopupIfShown();
		delayTimer = Timer.delay(showPopup, delayMs);
	}

	private function outHandler(_:MouseEvent):Void {
		clearDelay();
		hidePopupIfShown();
	}

	private function downHandler(_:MouseEvent):Void {
		clearDelay();
		hidePopupIfShown();
	}

	private function showPopup():Void {
		delayTimer = null;
		hidePopupIfShown();
		hover = new HoverPopup(title, content, this);
	}

	private function hidePopupIfShown():Void {
		if (hover != null) {
			hover.remove();
			hover = null;
		}
	}

	private function clearDelay():Void {
		if (delayTimer != null) {
			delayTimer.stop();
			delayTimer = null;
		}
	}

	public function remove():Void {
		clearDelay();
		removeEventListener(MouseEvent.MOUSE_OVER, overHandler);
		removeEventListener(MouseEvent.MOUSE_OUT, outHandler);
		removeEventListener(MouseEvent.MOUSE_DOWN, downHandler);
		hidePopupIfShown();
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
