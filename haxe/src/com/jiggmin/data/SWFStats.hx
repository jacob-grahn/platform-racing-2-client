package com.jiggmin.data;

import haxe.Timer;
import openfl.display.Sprite;
import pr2.Constants;
import pr2.app.AppStage;

class SWFStats extends Sprite {
	public static inline var TARGET_FRAME_RATE:Int = Constants.FRAME_RATE;

	private var lastReset:Float;
	private var lagArray:Array<Float> = [];
	private var keepCount:Int = 30;
	private var timer:Null<Timer>;
	private var now:Void->Float;
	private var getFrameRate:Void->Float;
	private var setFrameRate:Float->Void;

	public function new(autoStart:Bool = true, ?now:Void->Float, ?getFrameRate:Void->Float, ?setFrameRate:Float->Void) {
		super();
		this.now = now == null ? defaultNow : now;
		this.getFrameRate = getFrameRate == null ? defaultGetFrameRate : getFrameRate;
		this.setFrameRate = setFrameRate == null ? defaultSetFrameRate : setFrameRate;
		lastReset = this.now();
		if (autoStart) {
			start();
		}
	}

	public function start():Void {
		if (timer != null) {
			return;
		}
		timer = new Timer(1000);
		timer.run = resetStats;
	}

	public function remove():Void {
		if (timer != null) {
			timer.stop();
			timer = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	public function resetStats():Void {
		var time = now();
		var diff = time - lastReset;
		lastReset = time;
		lagArray.push(diff);
		if (lagArray.length > keepCount) {
			lagArray.shift();
		}
		var averageLag = averageLagWindow();
		if (averageLag < 900 || getFrameRate() != TARGET_FRAME_RATE) {
			setFrameRate(TARGET_FRAME_RATE);
		}
	}

	public function sampleCountForTests():Int {
		return lagArray.length;
	}

	public function averageLagForTests():Float {
		return averageLagWindow();
	}

	private function averageLagWindow():Float {
		if (lagArray.length < keepCount) {
			return Math.NaN;
		}
		var totalLag:Float = 0;
		for (i in 0...keepCount) {
			totalLag += lagArray[i];
		}
		return totalLag / keepCount;
	}

	private static function defaultNow():Float {
		return Date.now().getTime();
	}

	private static function defaultGetFrameRate():Float {
		return AppStage.stage == null ? TARGET_FRAME_RATE : AppStage.stage.frameRate;
	}

	private static function defaultSetFrameRate(value:Float):Void {
		if (AppStage.stage != null) {
			AppStage.stage.frameRate = value;
		}
	}
}
