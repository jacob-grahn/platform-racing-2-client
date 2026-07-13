package pr2.effects;

import pr2.display.Removable;
import pr2.gameplay.EffectBackground;
import openfl.events.Event;

/**
	Shared Flash `effects.Effect` base: starts at world coordinates, mounts on
	the active `EffectBackground`, and owns frame-counted delayed removal.
**/
class Effect extends Removable {
	private var removeFramesRemaining:Int = 0;
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
		removeFramesRemaining = frames;
		addEventListener(Event.ENTER_FRAME, onRemoveFrame);
	}

	private function onRemoveFrame(_:Event):Void {
		removeFramesRemaining--;
		if (removeFramesRemaining <= 0) {
			remove();
		}
	}

	public function scheduledRemoveMsForTests():Int {
		return scheduledRemoveMs;
	}

	public function hasScheduledRemoveForTests():Bool {
		return removeFramesRemaining > 0;
	}

	override public function remove():Void {
		clearRemoveTimer();
		super.remove();
	}

	private function clearRemoveTimer():Void {
		removeEventListener(Event.ENTER_FRAME, onRemoveFrame);
		removeFramesRemaining = 0;
	}
}
