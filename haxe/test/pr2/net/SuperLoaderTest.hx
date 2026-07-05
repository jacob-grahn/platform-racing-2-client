package pr2.net;

import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.net.URLVariables;
import pr2.lobby.LobbySession;

class SuperLoaderTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testPrepareFields();
		testAppendQueryFields();
		testDecodeJsonMessagesAndErrors();
		testDecodeUrlVariables();
		testFormatIoError();
		testEventedJsonLoad();
		testPostDecorationAndRawData();
		testErrorEventAndCancellationCleanup();
		SuperLoader.resetHooks();
		LobbySession.token = "";
		trace('SuperLoaderTest passed $assertions assertions');
	}

	private static function testPrepareFields():Void {
		SuperLoader.nextRand = function():Int return 12345;
		LobbySession.token = "session-token";
		var fields = SuperLoader.prepareFields(["mode" => "save"]);
		assertEquals("save", fields.get("mode"), "original field preserved");
		assertEquals("12345", fields.get("rand"), "rand appended");
		assertEquals("session-token", fields.get("token"), "session token appended");

		var explicit = SuperLoader.prepareFields(["token" => "saved-login-token", "rand" => "77"]);
		assertEquals("saved-login-token", explicit.get("token"), "explicit token is not overwritten");
		assertEquals("77", explicit.get("rand"), "explicit rand is not overwritten");
	}

	private static function testAppendQueryFields():Void {
		SuperLoader.nextRand = function():Int return 222;
		LobbySession.token = "tok";
		var url = SuperLoader.appendQueryFields("https://example.com/api?mode=x");
		assertEquals(true, url.indexOf("mode=x&") != -1, "existing query gets ampersand");
		assertEquals(true, url.indexOf("rand=222") != -1, "query rand appended");
		assertEquals(true, url.indexOf("token=tok") != -1, "query token appended");
	}

	private static function testDecodeJsonMessagesAndErrors():Void {
		var messages:Array<String> = [];
		SuperLoader.showMessage = function(message:String):Void messages.push(message);
		var ok = SuperLoader.decodeJson("json", '{"success":true,"message":"Saved"}');
		assertEquals(true, ok.success, "success JSON accepted");
		assertEquals("Saved", messages[0], "server message auto-shown");

		var failed = SuperLoader.decodeJson("json", '{"success":false,"error":"Nope"}');
		assertEquals(false, failed.success, "success false rejected");
		assertEquals("Nope", failed.message, "error text returned");
		assertEquals("Error: Nope", messages[1], "server error auto-shown");

		var invalid = SuperLoader.decodeJson("json", "not json");
		assertEquals(false, invalid.success, "invalid JSON rejected");
		assertEquals(true, invalid.message.indexOf("invalid response from json") == 0, "invalid JSON reports source");
	}

	private static function testDecodeUrlVariables():Void {
		var result = SuperLoader.decodeUrlVariables("vars", "success=1&message=OK&level_id=42", false);
		assertEquals(true, result.success, "URLVariables success accepted");
		assertEquals("42", Std.string(Reflect.field(result.data, "level_id")), "URLVariables parsed field");
		assertEquals("OK", result.message, "URLVariables message returned");
	}

	private static function testFormatIoError():Void {
		assertEquals("Error #2048: policy problem (HTTP 403)", SuperLoader.formatIoError("url", 403, "Error #2048: policy problem"),
			"Flash-style error number is preserved");
		assertEquals("Error: timeout", SuperLoader.formatIoError("url", 0, "timeout"), "plain IO error gets Error prefix");
	}

	private static function testEventedJsonLoad():Void {
		var fake = new FakeTransport();
		SuperLoader.transportFactory = function():Dynamic return fake;
		SuperLoader.nextRand = function():Int return 999;
		LobbySession.token = "event-token";
		var loader = new SuperLoader(true, SuperLoader.j, false);
		var events:Array<String> = [];
		loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(_:Event):Void events.push("status"));
		loader.addEventListener(ProgressEvent.PROGRESS, function(_:Event):Void events.push("progress"));
		loader.addEventListener(Event.COMPLETE, function(_:Event):Void events.push("complete"));
		loader.addEventListener(SuperLoader.d, function(_:Event):Void events.push("parsed"));
		loader.addEventListener(SuperLoader.e, function(_:Event):Void events.push("error"));

		loader.load(new URLRequest("https://example.test/data?mode=list"));
		assertEquals(true, fake.loaded.url.indexOf("mode=list&") != -1, "query separator preserved");
		assertEquals(true, fake.loaded.url.indexOf("rand=999") != -1, "query rand added");
		assertEquals(true, fake.loaded.url.indexOf("token=event-token") != -1, "query token added");

		fake.emit(new HTTPStatusEvent(HTTPStatusEvent.HTTP_STATUS, false, false, 200));
		fake.emit(new ProgressEvent(ProgressEvent.PROGRESS, false, false, 4, 10));
		fake.data = '{"success":true,"value":7}';
		fake.emit(new Event(Event.COMPLETE));

		assertEquals("status,progress,complete,parsed", events.join(","), "status/progress/complete/parsed order");
		assertEquals(200, loader.httpStatus, "HTTP status exposed");
		assertEquals('{"success":true,"value":7}', loader.data, "raw data exposed");
		assertEquals("7", Std.string(Reflect.field(loader.parsedData, "value")), "JSON parsedData exposed");
		assertEquals(true, fake.removes >= 5, "transport listeners removed after completion");
	}

	private static function testPostDecorationAndRawData():Void {
		var fake = new FakeTransport();
		SuperLoader.transportFactory = function():Dynamic return fake;
		SuperLoader.nextRand = function():Int return 123;
		LobbySession.token = "post-token";
		var loader = new SuperLoader(true, SuperLoader.raw, false);
		var completes = 0;
		loader.addEventListener(Event.COMPLETE, function(_:Event):Void completes++);
		var vars = new URLVariables();
		Reflect.setField(vars, "mode", "save");
		var request = new URLRequest("https://example.test/post");
		request.method = URLRequestMethod.POST;
		request.data = vars;

		loader.load(request);
		var sentVars:URLVariables = cast fake.loaded.data;
		assertEquals("save", Std.string(Reflect.field(sentVars, "mode")), "POST field preserved");
		assertEquals("123", Std.string(Reflect.field(sentVars, "rand")), "POST rand added");
		assertEquals("post-token", Std.string(Reflect.field(sentVars, "token")), "POST token added");

		fake.data = "plain text";
		fake.emit(new Event(Event.COMPLETE));
		assertEquals(1, completes, "raw complete dispatched");
		assertEquals("plain text", loader.data, "raw loader data exposed");
		assertEquals("plain text", Std.string(loader.parsedData), "raw parsedData mirrors data");
	}

	private static function testErrorEventAndCancellationCleanup():Void {
		var fake = new FakeTransport();
		var messages:Array<String> = [];
		SuperLoader.transportFactory = function():Dynamic return fake;
		SuperLoader.showMessage = function(message:String):Void messages.push(message);
		var loader = new SuperLoader(true, SuperLoader.j, false);
		var errors = 0;
		var ioErrors = 0;
		loader.addEventListener(IOErrorEvent.IO_ERROR, function(_:Event):Void ioErrors++);
		loader.addEventListener(SuperLoader.e, function(_:Event):Void errors++);
		loader.load(new URLRequest("https://example.test/error"));
		fake.emit(new HTTPStatusEvent(HTTPStatusEvent.HTTP_STATUS, false, false, 503));
		fake.emit(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "timeout"));
		assertEquals(1, ioErrors, "underlying IO error is forwarded");
		assertEquals(1, errors, "anyError dispatched");
		assertEquals("Error: timeout (HTTP 503)", loader.errorMessage, "error message exposed");
		assertEquals(0, messages.length, "autoEchoMessage=false suppresses IO error display");

		fake = new FakeTransport();
		SuperLoader.transportFactory = function():Dynamic return fake;
		loader = new SuperLoader(true, SuperLoader.j, false);
		var parsedEvents = 0;
		var completeEvents = 0;
		loader.addEventListener(Event.COMPLETE, function(_:Event):Void completeEvents++);
		loader.addEventListener(SuperLoader.d, function(_:Event):Void parsedEvents++);
		loader.load(new URLRequest("https://example.test/cancel"));
		loader.cancel();
		fake.data = '{"success":true}';
		fake.emit(new Event(Event.COMPLETE));
		assertEquals(true, fake.closed, "cancel closes transport");
		assertEquals(0, completeEvents, "late complete ignored after cancel");
		assertEquals(0, parsedEvents, "late parsedData ignored after cancel");
		assertEquals(true, fake.removes >= 5, "cancel removes transport listeners");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}

private class FakeTransport extends EventDispatcher {
	public var data:Dynamic = null;
	public var dataFormat:Dynamic = null;
	public var loaded:URLRequest = null;
	public var closed:Bool = false;
	public var adds:Int = 0;
	public var removes:Int = 0;

	public function new() {
		super();
	}

	public function load(request:URLRequest):Void {
		loaded = request;
	}

	public function close():Void {
		closed = true;
	}

	override public function addEventListener(type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0,
			useWeakReference:Bool = false):Void {
		adds++;
		super.addEventListener(type, listener, useCapture, priority, useWeakReference);
	}

	override public function removeEventListener(type:String, listener:Dynamic, useCapture:Bool = false):Void {
		removes++;
		super.removeEventListener(type, listener, useCapture);
	}

	public function emit(event:Event):Void {
		dispatchEvent(event);
	}
}
