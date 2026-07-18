package pr2.app;

import pr2.page.LoginPage;

class ScreenTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCampaignHarnessRequiresDebugFlag();
		testCharacterPartCacheVisualRoute();
		if (pr2.DeterministicTestMode.finishSmokeSuite("ScreenTest")) return;
		testSiteModeMatchesFlashDomainRules();
		testLoginPageAssetMatchesSiteMode();
		trace('ScreenTest passed $assertions assertions');
	}

	private static function testCharacterPartCacheVisualRoute():Void {
		assertEquals(Screen.CharacterPartCache, Screen.fromQuery("?screen=character_part_cache"), "character part-cache visual test route");
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

	private static function testSiteModeMatchesFlashDomainRules():Void {
		assertStringEquals("kongregate", SiteMode.fromUrl("file:///tmp/pr2.swf"), "local defaults to kongregate");
		assertStringEquals("inXile", SiteMode.fromUrl("https://sparkworkz.com/pr2.swf"), "sparkworkz host");
		assertStringEquals("inXile", SiteMode.fromUrl("https://inxile-entertainment.com/pr2.swf"), "inxile host");
		assertStringEquals("pr2hub.com", SiteMode.domainFromUrl("https://www.pr2hub.com/client/pr2.swf"), "domain strips www");
	}

	private static function testLoginPageAssetMatchesSiteMode():Void {
		assertLoginPageArt("assets/svg/login/login_page_no_logo.svg", 868, 846, SiteMode.KONGREGATE, "kongregate uses unbranded login art");
		assertLoginPageArt("assets/svg/login/login_page_no_logo.svg", 868, 846, SiteMode.INXILE, "inxile uses unbranded login art");
	}

	private static function assertStringEquals(expected:String, actual:String, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertLoginPageArt(expectedPath:String, expectedTrimX:Int, expectedTrimY:Int, siteMode:String, message:String):Void {
		var art = @:privateAccess LoginPage.loginPageArtFor(siteMode);
		assertStringEquals(expectedPath, art.assetPath, message);
		assertIntEquals(expectedTrimX, art.trimX, '$message trim x');
		assertIntEquals(expectedTrimY, art.trimY, '$message trim y');
	}

	private static function assertIntEquals(expected:Int, actual:Int, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
