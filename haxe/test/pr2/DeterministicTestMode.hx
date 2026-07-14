package pr2;

/** Runtime switch used to keep the default deterministic run broad and fast. */
class DeterministicTestMode {
	private static var cachedSmoke:Null<Bool>;
	private static var cachedGroups:Null<Array<String>>;
	private static var selectedSuites:Int = 0;

	public static function isSmoke():Bool {
		if (cachedSmoke == null) {
			cachedSmoke = Sys.getEnv("PR2_TEST_MODE") == "smoke";
		}
		return cachedSmoke;
	}

	public static function finishSmokeSuite(name:String):Bool {
		if (!isSmoke()) return false;
		trace('$name passed its smoke test');
		return true;
	}

	public static function runSuite(name:String, tags:Array<String>, callback:Void->Void):Void {
		var requested = groups();
		if (requested.length > 0) {
			var matches = false;
			for (tag in tags) {
				if (requested.indexOf(tag) >= 0) {
					matches = true;
					break;
				}
			}
			if (!matches) return;
		}
		selectedSuites++;
		callback();
	}

	public static function hasGroupSelection():Bool {
		return groups().length > 0;
	}

	public static function selectionSummary():String {
		return groups().join(", ") + ': $selectedSuites suites';
	}

	private static function groups():Array<String> {
		if (cachedGroups == null) {
			var raw = Sys.getEnv("PR2_TEST_GROUPS");
			cachedGroups = raw == null || raw == "" ? [] : raw.split(",");
		}
		return cachedGroups;
	}
}
