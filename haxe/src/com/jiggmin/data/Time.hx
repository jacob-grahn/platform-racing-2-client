package com.jiggmin.data;

class Time {
	private var offsetMS:Float = 0;
	private var startMS:Float = 0;
	private var now:Void->Float;

	public function new(?now:Void->Float) {
		this.now = now == null ? Data.getMS : now;
	}

	public function setTime(n:Float):Void {
		offsetMS = n * 1000;
		startMS = now();
	}

	public function getMS():Float {
		return now() - startMS + offsetMS;
	}

	public function getTimestamp():Float {
		return getMS() / 1000;
	}

	public function getDay():Float {
		var ms = getTimestamp();
		return Math.round((ms / 24) / 60) / 60;
	}
}
