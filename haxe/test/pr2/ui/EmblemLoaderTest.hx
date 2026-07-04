package pr2.ui;

import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IOErrorEvent;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.utils.ByteArray;
import pr2.lobby.LobbySession;
import pr2.net.SuperLoader;

class EmblemLoaderTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testLocalImageFitsUploadsAndAppliesFilename();
		testUploadErrorFinishesWithoutChangingFilename();
		testRemoveCleansUploadAndIgnoresLateCompletion();
		SuperLoader.resetHooks();
		LobbySession.token = "";
		trace('EmblemLoaderTest passed $assertions assertions');
	}

	private static function testLocalImageFitsUploadsAndAppliesFilename():Void {
		var fake = new FakeTransport();
		SuperLoader.transportFactory = function():Dynamic return fake;
		SuperLoader.nextRand = function():Int return 321;
		LobbySession.token = "tok";
		var loader = new EmblemLoader(100, 50, "https://example.test/emblem_upload.php", "https://example.test/emblems/");
		var events:Array<String> = [];
		loader.addEventListener(EmblemLoader.BEGIN_LOADING, function(_:Event):Void events.push("begin"));
		loader.addEventListener(EmblemLoader.FINISH_LOADING, function(_:Event):Void events.push("finish"));

		var source = new BitmapData(200, 50, false, 0xFF0000);
		loader.drawLocalBitmapForTests(source);
		assertEquals(true, loader.isLoading(), "local draw starts upload");
		assertEquals(0xFFFFFF, loader.pixelForTests(50, 5), "fitted image leaves white top padding");
		assertEquals(0xFF0000, loader.pixelForTests(50, 25), "fitted image draws centered source");
		assertEquals(true, fake.loaded.url.indexOf("https://example.test/emblem_upload.php?") == 0, "upload endpoint used");
		assertEquals(true, fake.loaded.url.indexOf("rand=321") != -1, "binary upload gets rand on URL");
		assertEquals(true, fake.loaded.url.indexOf("token=tok") != -1, "binary upload gets token on URL");
		assertEquals(URLRequestMethod.POST, fake.loaded.method, "upload POSTs");
		assertEquals("Content-type", fake.loaded.requestHeaders[0].name, "content type header name");
		assertEquals("application/octet-stream", fake.loaded.requestHeaders[0].value, "content type header value");
		assertEquals(0xFF, byteAt(cast fake.loaded.data, 0), "JPEG starts with SOI high byte");
		assertEquals(0xD8, byteAt(cast fake.loaded.data, 1), "JPEG starts with SOI low byte");

		fake.data = '{"success":true,"filename":"uploaded-emblem.jpg"}';
		fake.emit(new Event(Event.COMPLETE));
		assertEquals(false, loader.isLoading(), "successful upload clears loading");
		assertEquals("uploaded-emblem.jpg", loader.getFileName(), "server filename applied");
		assertEquals("begin,finish", events.join(","), "begin and finish events dispatched");
		loader.remove();
		source.dispose();
	}

	private static function testUploadErrorFinishesWithoutChangingFilename():Void {
		var fake = new FakeTransport();
		var messages:Array<String> = [];
		SuperLoader.transportFactory = function():Dynamic return fake;
		SuperLoader.showMessage = function(message:String):Void messages.push(message);
		var loader = new EmblemLoader(100, 50, "https://example.test/emblem_upload.php", "https://example.test/emblems/");
		loader.setFileNameForTests("before.jpg");
		var finishes = 0;
		loader.addEventListener(EmblemLoader.FINISH_LOADING, function(_:Event):Void finishes++);

		loader.drawLocalBitmapForTests(new BitmapData(50, 50, false, 0x00FF00));
		fake.emit(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "upload failed"));
		assertEquals(false, loader.isLoading(), "failed upload clears loading");
		assertEquals("before.jpg", loader.getFileName(), "failed upload preserves filename");
		assertEquals(1, finishes, "failed upload dispatches finish");
		assertEquals("Error: upload failed", messages[0], "failed upload reports error");
		loader.remove();
	}

	private static function testRemoveCleansUploadAndIgnoresLateCompletion():Void {
		var fake = new FakeTransport();
		SuperLoader.transportFactory = function():Dynamic return fake;
		var loader = new EmblemLoader(100, 50, "https://example.test/emblem_upload.php", "https://example.test/emblems/");
		var finishes = 0;
		loader.addEventListener(EmblemLoader.FINISH_LOADING, function(_:Event):Void finishes++);
		loader.drawLocalBitmapForTests(new BitmapData(50, 50, false, 0x0000FF));
		loader.remove();
		fake.data = '{"success":true,"filename":"late.jpg"}';
		fake.emit(new Event(Event.COMPLETE));
		assertEquals(true, fake.closed, "remove closes active upload transport");
		assertEquals(true, fake.removes >= 5, "remove detaches upload listeners");
		assertEquals(0, finishes, "late upload completion ignored after remove");
	}

	private static function byteAt(bytes:ByteArray, index:Int):Int {
		var oldPosition = bytes.position;
		bytes.position = index;
		var value = bytes.readUnsignedByte();
		bytes.position = oldPosition;
		return value;
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

	override public function removeEventListener(type:String, listener:Dynamic, useCapture:Bool = false):Void {
		removes++;
		super.removeEventListener(type, listener, useCapture);
	}

	public function emit(event:Event):Void {
		dispatchEvent(event);
	}
}
