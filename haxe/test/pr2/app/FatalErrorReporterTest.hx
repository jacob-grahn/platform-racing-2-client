package pr2.app;

class FatalErrorReporterTest {
	private static var assertions = 0;

	public static function main():Void {
		testFormatEscapesMessageAndDebugLog();
		if (pr2.DeterministicTestMode.finishSmokeSuite("FatalErrorReporterTest")) return;
		testReportPassesEscapedMessageToPopupFactory();
		trace('FatalErrorReporterTest passed $assertions assertions');
	}

	private static function testFormatEscapesMessageAndDebugLog():Void {
		FatalErrorReporter.debugLog = "";
		FatalErrorReporter.log("phase <boot> & ready");
		var message = FatalErrorReporter.format("boom <bad> & broken");
		assertContains(message, "boom &lt;bad&gt; &amp; broken", "error text escaped");
		assertContains(message, "Debug log:\nphase &lt;boot&gt; &amp; ready", "debug log escaped and appended");
		FatalErrorReporter.debugLog = "";
	}

	private static function testReportPassesEscapedMessageToPopupFactory():Void {
		FatalErrorReporter.debugLog = "";
		var captured = "";
		FatalErrorReporter.report("fatal <popup>", function(message:String):Void {
			captured = message;
		});
		assertContains(captured, "fatal &lt;popup&gt;", "report sends escaped message to popup");
	}

	private static function assertContains(value:String, needle:String, message:String):Void {
		assertions++;
		if (value.indexOf(needle) < 0) {
			throw '$message: expected $value to contain $needle';
		}
	}
}
