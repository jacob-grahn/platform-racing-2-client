package pr2.net;

class ServerConfigTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testDefaultsToProductionHost();
		testProxyHostBuildsSameOriginUrls();
		testLocalOverrideUsesExplicitEnvValue();
		testBlankHostDoesNotReplaceCurrentHost();
		trace('ServerConfigTest passed $assertions assertions');
	}

	private static function testDefaultsToProductionHost():Void {
		ServerConfig.resetHost();
		assertEquals(ServerConfig.DEFAULT_HOST, ServerConfig.getHost(), "default host");
		assertEquals(false, ServerConfig.hasProxyHost(), "default is not proxy");
		assertEquals("https://pr2hub.com/files/lists/campaign/1", ServerConfig.listUrl("campaign", 1), "default campaign list url");
		assertEquals("https://pr2hub.com/levels/50815.txt?version=7", ServerConfig.levelDataUrl(50815, 7), "default level data url");
	}

	private static function testProxyHostBuildsSameOriginUrls():Void {
		ServerConfig.resetHost();
		ServerConfig.setHost(" /api ");
		assertEquals("/api", ServerConfig.getHost(), "trimmed proxy host");
		assertEquals(true, ServerConfig.hasProxyHost(), "proxy detected");
		assertEquals("/api/files/lists/campaign/2", ServerConfig.listUrl("campaign", 2), "proxy campaign list url");
		assertEquals("/api/levels/50815.txt?version=7", ServerConfig.levelDataUrl(50815, 7), "proxy level data url");
	}

	private static function testLocalOverrideUsesExplicitEnvValue():Void {
		ServerConfig.resetHost();
		ServerConfig.applyLocalOverrides(" http://localhost:8080/api ");
		assertEquals("http://localhost:8080/api", ServerConfig.getHost(), "local env host");
		assertEquals("http://localhost:8080/api/login.php", ServerConfig.loginUrl(), "local env login url");
	}

	private static function testBlankHostDoesNotReplaceCurrentHost():Void {
		ServerConfig.resetHost();
		ServerConfig.setHost("/api");
		ServerConfig.setHost(" ");
		assertEquals("/api", ServerConfig.getHost(), "blank host ignored");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
