package pr2.audio;

class AudioUnlockGateTest {
	public static function main():Void {
		var gate = new AudioUnlockGate();
		var attempts = 0;
		assert(!gate.attempt(function() {
			attempts++;
			return false;
		}), "a rejected resume remains locked");
		if (pr2.DeterministicTestMode.finishSmokeSuite("AudioUnlockGateTest")) return;
		assert(gate.attempt(function() {
			attempts++;
			return true;
		}), "a successful resume unlocks audio");
		assert(gate.attempt(function() {
			attempts++;
			return false;
		}), "an unlocked gate remains unlocked");
		assert(attempts == 2, "the resume callback stops after success");
		trace("AudioUnlockGateTest passed 4 assertions");
	}

	private static function assert(condition:Bool, message:String):Void {
		if (!condition) {
			throw message;
		}
	}
}
