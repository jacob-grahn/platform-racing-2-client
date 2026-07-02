package pr2.ui;

import openfl.events.TextEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.display.Sprite;
import pr2.lobby.LobbyArt;
import pr2.lobby.chat.ChatText;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/** Something `PageNavigation` can drive: page selection callbacks. */
interface Paginated {
	function setPageNum(i:Int):Void;
}

/**
	Port of Flash `ui.PageNavigation`: a strip of numbered page buttons.

	`full` mode draws `<- Last`, `1..count`, `Next ->`; `vertical` mode draws only
	`1..count` stacked; the default horizontal-with-arrows mode draws just the
	prev/next buttons. Buttons compress to fit `maxW` exactly like the lobby tab
	strip. The current page is non-clickable; clicking another calls back into the
	target's `setPageNum`. Level listings also highlight the live-loaded page.
**/
class PageNavigation extends Sprite {
	public var selected:Int;

	private var target:Paginated;
	private var mode:String;
	private var count:Int;
	private var maxW:Float;
	private var navButtons:Array<PR2MovieClip> = [];
	private var linkListeners:Array<TextEvent->Void> = [];

	public function new(target:Paginated, mode:String = "full", selected:Int = 1, count:Int = 9, maxW:Float = 200) {
		super();
		this.target = target;
		this.mode = mode;
		this.selected = selected;
		this.count = count;
		this.maxW = maxW;
		draw();
	}

	/**
		Pure port of `PageNavigation.position`: lay buttons end-to-end then pull each
		button after the first by `startingPos * i`, where `startingPos` distributes
		the difference between the laid-out length and `maxW`. Unlike tab layout this
		is applied unconditionally, so few buttons spread apart and many compress.
	**/
	public static function buttonPositions(sizes:Array<Float>, maxW:Float):Array<Float> {
		var coords:Array<Float> = [];
		var running:Float = 0;
		for (size in sizes) {
			coords.push(running);
			running += size;
		}
		if (coords.length > 1) {
			var startingPos = (running - maxW) / (coords.length - 1);
			for (i in 1...coords.length) {
				coords[i] -= startingPos * i;
			}
		}
		return coords;
	}

	private function draw():Void {
		clear();
		if (mode != "vertical") {
			makeNavButton("<- Last", selected - 1, selected > 1);
		}
		if (mode == "full" || mode == "vertical") {
			var i = 1;
			while (i <= count) {
				makeNavButton(Std.string(i), i, i != selected);
				i++;
			}
		}
		if (mode != "vertical") {
			makeNavButton("Next ->", selected + 1, selected < count);
		}
		position(mode != "vertical" ? "horizontal" : "vertical");
	}

	private function position(direction:String):Void {
		var horizontal = direction == "horizontal";
		var sizes:Array<Float> = [];
		for (button in navButtons) {
			sizes.push(horizontal ? button.width : button.height);
		}
		var coords = buttonPositions(sizes, maxW);
		for (i in 0...navButtons.length) {
			if (horizontal) {
				navButtons[i].x = coords[i];
			} else {
				navButtons[i].y = coords[i];
			}
		}
	}

	private function makeNavButton(title:String, num:Int, clickable:Bool):Void {
		var button = PR2MovieClip.fromLinkage("PageNumberGraphic", {maxNestedDepth: 3});
		var textBox = Std.downcast(DisplayUtil.findByName(button, "textBox"), TextField);
		if (textBox != null) {
			textBox.autoSize = TextFieldAutoSize.LEFT;
			if (clickable) {
				textBox.htmlText = "<a href='event:" + num + "'><font color='#325638'><u>" + ChatText.escapeString(title) + "</u></font></a>";
				var listener = makeLinkListener();
				textBox.addEventListener(TextEvent.LINK, listener);
				linkListeners.push(listener);
			} else {
				textBox.text = title;
				linkListeners.push(null);
			}
		} else {
			linkListeners.push(null);
		}
		addChild(button);
		navButtons.push(button);
	}

	private function makeLinkListener():TextEvent->Void {
		return function(event:TextEvent):Void {
			setPageNum(Std.parseInt(event.text));
		};
	}

	private function clear():Void {
		for (i in 0...navButtons.length) {
			var button = navButtons[i];
			var listener = linkListeners[i];
			if (listener != null) {
				var textBox = Std.downcast(DisplayUtil.findByName(button, "textBox"), TextField);
				if (textBox != null) {
					textBox.removeEventListener(TextEvent.LINK, listener);
				}
			}
			if (button.parent != null) {
				button.parent.removeChild(button);
			}
			button.dispose();
		}
		navButtons = [];
		linkListeners = [];
	}

	public function setPageNum(i:Int):Void {
		selected = i;
		draw();
		target.setPageNum(i);
	}

	public function addPageHighlight(i:Int):Void {
		if ((mode != "vertical" && mode != "full") || i > count || i < 1 || selected == i) {
			return;
		}
		var button = navButtons[buttonIndex(i)];
		var textBox = button == null ? null : Std.downcast(DisplayUtil.findByName(button, "textBox"), TextField);
		if (textBox != null) {
			textBox.htmlText = "<a href='event:" + i + "'><font color='#FFFFFF'><u>" + i + "</u></font></a>";
		}
	}

	public function removePageHighlight(i:Int):Void {
		if ((mode != "vertical" && mode != "full") || i > count || i < 1 || selected == i) {
			return;
		}
		var button = navButtons[buttonIndex(i)];
		var textBox = button == null ? null : Std.downcast(DisplayUtil.findByName(button, "textBox"), TextField);
		if (textBox != null) {
			textBox.htmlText = "<a href='event:" + i + "'><font color='#325638'><u>" + i + "</u></font></a>";
		}
	}

	/**
		Button index used for highlighting, matching Flash's `navButtonArray[i - 1]`.
		This is correct for `vertical` mode (the only mode level listings use, where
		the array is `[1..count]`); the original code's guard also permits `full`,
		where the same index is off by one — preserved here for faithfulness.
	**/
	private function buttonIndex(i:Int):Int {
		return i - 1;
	}

	public function remove():Void {
		clear();
		target = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
