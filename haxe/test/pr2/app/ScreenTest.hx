package pr2.app;

import pr2.page.LoginPage;

class ScreenTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCampaignHarnessRequiresDebugFlag();
		testSiteModeMatchesFlashDomainRules();
		testLoginPageAssetMatchesSiteMode();
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

	private static function testSiteModeMatchesFlashDomainRules():Void {
		assertStringEquals("kongregate", SiteMode.fromUrl("file:///tmp/pr2.swf"), "local defaults to kongregate");
		assertStringEquals("bubbleBox", SiteMode.fromUrl("https://www.bubblebox.com/game.swf"), "bubblebox host");
		assertStringEquals("bubbleBox", SiteMode.fromUrl("https://2games.com/pr2.swf"), "2games host");
		assertStringEquals("armorGames", SiteMode.fromUrl("https://armorgames.com/pr2.swf"), "armor games host");
		assertStringEquals("inXile", SiteMode.fromUrl("https://sparkworkz.com/pr2.swf"), "sparkworkz host");
		assertStringEquals("inXile", SiteMode.fromUrl("https://inxile-entertainment.com/pr2.swf"), "inxile host");
		assertStringEquals("pr2hub.com", SiteMode.domainFromUrl("https://www.pr2hub.com/client/pr2.swf"), "domain strips www");
	}

	private static function testLoginPageAssetMatchesSiteMode():Void {
		assertLoginPageArt("assets/login/login_page_no_logo@4x.png", 868, 846, SiteMode.KONGREGATE, "kongregate uses unbranded login art");
		assertLoginPageArt("assets/login/login_page_no_logo@4x.png", 868, 846, SiteMode.BUBBLE_BOX, "bubblebox uses unbranded login art");
		assertLoginPageArt("assets/login/login_page_no_logo@4x.png", 868, 846, SiteMode.ARMOR_GAMES, "armorgames uses unbranded login art");
		assertLoginPageArt("assets/login/login_page_no_logo@4x.png", 868, 846, SiteMode.INXILE, "inxile uses unbranded login art");
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
