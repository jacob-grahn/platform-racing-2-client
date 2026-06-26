package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.geom.ColorTransform;

/**
	Port of Flash `com.jiggmin.data.EpicFlash`.

	Cycles a random color transform across a set of display objects on a fixed
	interval, used to make "epic" prize upgrades shimmer. `start`/`stop` toggle
	the interval; `setDelay` re-arms it while active.
**/
class EpicFlash {
	private var items:Array<DisplayObject> = [];
	private var timer:Null<haxe.Timer>;
	private var intervalDelay:Int;
	private var active:Bool = false;

	public function new(delay:Int = 500) {
		intervalDelay = delay;
	}

	public function start():Void {
		stopTimer();
		timer = new haxe.Timer(intervalDelay);
		timer.run = colorTick;
		active = true;
	}

	public function stop():Void {
		stopTimer();
		active = false;
	}

	public function setDelay(delay:Int):Void {
		intervalDelay = delay;
		if (active) {
			start();
		}
	}

	public function isEmpty():Bool {
		return items.length <= 0;
	}

	public function addItem(item:DisplayObject):Void {
		if (item != null) {
			items.push(item);
		}
	}

	public function colorTick():Void {
		var ct = new ColorTransform();
		ct.color = Math.round(Math.random() * 0xFFFFFF);
		for (item in items) {
			item.transform.colorTransform = ct;
		}
	}

	private function stopTimer():Void {
		if (timer != null) {
			timer.stop();
			timer = null;
		}
	}

	public function remove():Void {
		stopTimer();
		active = false;
		items = [];
	}
}
