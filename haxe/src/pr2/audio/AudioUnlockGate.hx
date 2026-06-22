package pr2.audio;

/** Target-independent one-shot state used by the browser audio unlock adapter. */
class AudioUnlockGate {
	public var unlocked(default, null):Bool = false;

	public function new() {}

	public function attempt(resume:() -> Bool):Bool {
		if (unlocked) {
			return true;
		}
		unlocked = resume();
		return unlocked;
	}
}
