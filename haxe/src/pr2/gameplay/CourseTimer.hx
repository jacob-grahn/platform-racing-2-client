package pr2.gameplay;

import com.jiggmin.data.Data;
import haxe.Timer;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.text.TextField;
import pr2.display.Removable;
import pr2.net.LobbySocket;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

typedef CourseTimerOptions = {
	@:optional var now:Void->Float;
	@:optional var onOutOfTime:Void->Void;
}

/** Flash `gameplay.CourseTimer`: HUD clock anchored to server milliseconds. */
class CourseTimer extends Removable {
	private var graphic:PR2MovieClip;
	private var holder:DisplayObjectContainer;
	private var timeBox:TextField;
	private var time:Int = 120;
	private var startTime:Float = 0;
	private var tickTimer:Timer;
	private var racing:Bool = false;
	private var paused:Bool = true;
	private final now:Void->Float;
	private final onOutOfTime:Null<Void->Void>;

	public function new(?options:CourseTimerOptions) {
		super();
		now = options != null && options.now != null ? options.now : LobbySocket.getMS;
		onOutOfTime = options != null ? options.onOutOfTime : null;
		graphic = PR2MovieClip.fromLinkage("TimerGraphic");
		addChild(graphic);
		holder = Std.downcast(DisplayUtil.findByName(graphic, "holder"), DisplayObjectContainer);
		timeBox = Std.downcast(DisplayUtil.findByName(graphic, "timeBox"), TextField);
		if (timeBox != null) {
			timeBox.text = "";
		}
	}

	public function setTime(t:Float):Void {
		clearTickTimer();
		time = Std.int(t);
		racing = t <= 0;
	}

	public function getMS():Float {
		return time;
	}

	public function addTime(secs:Float):Void {
		if (racing) {
			startTime -= secs * 1000;
			display(getElapsedSecs());
		} else {
			time += Std.int(secs);
			display(getTimeLeft());
		}
		if (paused) {
			resume();
		}
	}

	public function init():Void {
		startTime = now();
		resume();
	}

	public function pause():Void {
		paused = true;
		clearTickTimer();
	}

	public function resume():Void {
		paused = false;
		clearTickTimer();
		tickTimer = new Timer(1000);
		tickTimer.run = tick;
		tick();
	}

	public function tickForTests():Void {
		tick();
	}

	public function debugText():String {
		return timeBox == null ? "" : timeBox.text;
	}

	public function debugTextColor():Int {
		return timeBox == null ? -1 : timeBox.textColor;
	}

	public function debugHolderScale():Float {
		return holder == null ? 1 : holder.scaleX;
	}

	public function debugPaused():Bool {
		return paused;
	}

	public function debugRacing():Bool {
		return racing;
	}

	override public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, go);
		clearTickTimer();
		super.remove();
	}

	private function getElapsedSecs():Float {
		return (now() - startTime) / 1000;
	}

	private function getTimeLeft():Float {
		return Math.round(time - getElapsedSecs());
	}

	private function tick():Void {
		if (racing) {
			display(getElapsedSecs());
			return;
		}
		var timeLeft = Math.round(getTimeLeft());
		display(timeLeft);
		if (timeLeft <= 0) {
			if (onOutOfTime != null) {
				onOutOfTime();
			}
			pause();
		}
	}

	private function display(t:Float):Void {
		var timeLeft = Math.round(t);
		if (timeLeft < 0) {
			timeLeft = 0;
		}
		if (timeBox != null) {
			timeBox.text = Data.formatTime(timeLeft);
			if (!racing) {
				timeBox.textColor = timeLeft < 30 ? 0xFF0000 : 0;
			}
		}
		if (!racing && timeLeft < 10) {
			pulseLowTime();
		}
	}

	private function pulseLowTime():Void {
		removeEventListener(Event.ENTER_FRAME, go);
		addEventListener(Event.ENTER_FRAME, go);
		if (holder != null) {
			holder.scaleX = holder.scaleY = 3;
		}
	}

	private function go(event:Event):Void {
		if (holder == null) {
			removeEventListener(Event.ENTER_FRAME, go);
			return;
		}
		holder.scaleX = holder.scaleY = holder.scaleX * 0.9;
		if (holder.scaleX <= 1) {
			holder.scaleX = holder.scaleY = 1;
			removeEventListener(Event.ENTER_FRAME, go);
		}
	}

	private function clearTickTimer():Void {
		if (tickTimer != null) {
			tickTimer.stop();
			tickTimer = null;
		}
	}
}
