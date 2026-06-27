package pr2.app;

class ScreenTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCampaignHarnessRequiresDebugFlag();
		trace('ScreenTest passed $assertions assertions');
	}

	private static function testCampaignHarnessRequiresDebugFlag():Void {
		assertEquals(Screen.Intro, Screen.fromQuery("?screen=campaign"), "campaign harness is not a default route");
		assertEquals(Screen.Campaign, Screen.fromQuery("?screen=campaign&debug=1"), "numeric debug flag enables campaign harness");
		assertEquals(Screen.Campaign, Screen.fromQuery("?screen=campaign&debug=campaign"), "named debug flag enables campaign harness");
		assertEquals(Screen.Intro, Screen.fromQuery("?screen=campaign&debug=0"), "false debug flag keeps campaign harness disabled");
	}

	private static function assertEquals(expected:Screen, actual:Screen, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
