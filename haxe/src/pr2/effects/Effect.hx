package pr2.effects;

import haxe.Timer;
import pr2.display.Removable;
import pr2.gameplay.EffectBackground;

/**
	Shared Flash `effects.Effect` base: starts at world coordinates, mounts on
	the active `EffectBackground`, and owns frame-counted delayed removal.
**/
class Effect extends Removable {
	private var removeTimer:Null<Timer>;
	private var scheduledRemoveMs:Int = 0;

	public function new(startX:Float = 0, startY:Float = 0) {
		super();
		x = startX;
		y = startY;
		if (EffectBackground.instance != null) {
			EffectBackground.instance.addChild(this);
		}
	}

	function scheduleRemove(frames:Int):Void {
		clearRemoveTimer();
		scheduledRemoveMs = Std.int(frames * (1 / 24) * 1000);
		removeTimer = Timer.delay(remove, scheduledRemoveMs);
	}

	public function scheduledRemoveMsForTests():Int {
		return scheduledRemoveMs;
	}

	public function hasScheduledRemoveForTests():Bool {
		return removeTimer != null;
	}

	override public function remove():Void {
		clearRemoveTimer();
		super.remove();
	}

	private function clearRemoveTimer():Void {
		if (removeTimer == null) {
			return;
		}
		removeTimer.stop();
		removeTimer = null;
	}
}
