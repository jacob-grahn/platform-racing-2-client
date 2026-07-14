package pr2.lobby;

import openfl.events.Event;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.net.URLVariables;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.SuperLoader;

class UploadingPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testStringMapConstructor();
		if (pr2.DeterministicTestMode.finishSmokeSuite("UploadingPopupTest")) return;
		testFlashUrlRequestConstructor();
		testCallbackCanOwnMessages();
		SuperLoader.resetHooks();
		LobbySession.token = "";
		closeAll();
		trace('UploadingPopupTest passed $assertions assertions');
	}

	private static function testCallbackCanOwnMessages():Void {
		var savedPostFactory = UploadingPopup.postFactory;
		var savedShowMessage = SuperLoader.showMessage;
		var messages:Array<String> = [];
		var parsedMessage = "";
		SuperLoader.showMessage = function(message:String):Void messages.push(message);
		UploadingPopup.postFactory = function(url:String, fields:Map<String, String>, onResult:String->Void, onError:String->Void):Void {
			onResult('{"success":true,"message":"Level saved!"}');
		};

		new UploadingPopup("https://example.test/save", new Map<String, String>(), "Saving...", function(result:Dynamic):Void {
			parsedMessage = Std.string(Reflect.field(result, "message"));
		}, null, false);

		assertEquals("Level saved!", parsedMessage, "callback receives server message");
		assertEquals(0, messages.length, "explicit aem false suppresses callback response echo");

		UploadingPopup.postFactory = savedPostFactory;
		SuperLoader.showMessage = savedShowMessage;
		closeAll();
	}

	private static function testStringMapConstructor():Void {
		var savedPostFactory = UploadingPopup.postFactory;
		var captured:{url:String, fields:Map<String, String>} = null;
		var parsed:Dynamic = null;
		UploadingPopup.postFactory = function(url:String, fields:Map<String, String>, onResult:String->Void, onError:String->Void):Void {
			captured = {url: url, fields: fields};
			onResult('{"success":true,"prize":"hat"}');
		};

		var popup = new UploadingPopup("https://example.test/save", ["mode" => "favorite"], "Saving...", function(result:Dynamic):Void {
			parsed = result;
		});

		assertEquals("https://example.test/save", captured.url, "string constructor posts URL");
		assertEquals("favorite", captured.fields.get("mode"), "string constructor posts fields");
		assertEquals("Saving...", LobbyArt.text(popup, "textBox").text, "string constructor display text");
		assertEquals("hat", Std.string(Reflect.field(parsed, "prize")), "string constructor parses JSON response");
		assertEquals('{"success":true,"prize":"hat"}', popup.data, "raw response stored");

		UploadingPopup.postFactory = savedPostFactory;
		closeAll();
	}

	private static function testFlashUrlRequestConstructor():Void {
		var savedRequestFactory = UploadingPopup.requestFactory;
		var savedRand = SuperLoader.nextRand;
		var savedShowMessage = SuperLoader.showMessage;
		var savedToken = LobbySession.token;
		var messages:Array<String> = [];
		var completeEvents = 0;
		var parsedEvents = 0;
		var captured:URLRequest = null;
		var complete:String->Void = null;
		SuperLoader.nextRand = function():Int return 777;
		SuperLoader.showMessage = function(message:String):Void messages.push(message);
		LobbySession.token = "tok";
		UploadingPopup.requestFactory = function(request:URLRequest, onResult:String->Void, onError:String->Void):Void {
			captured = request;
			complete = onResult;
		};

		var vars = new URLVariables();
		Reflect.setField(vars, "guild_id", "42");
		var request = new URLRequest("https://example.test/guild_join.php");
		request.method = URLRequestMethod.POST;
		request.data = vars;
		var popup = new UploadingPopup(request, "url", "Joining...", false);
		popup.addEventListener(Event.COMPLETE, function(_:Event):Void completeEvents++);
		popup.addEventListener(UploadingPopup.PARSED_DATA, function(_:Event):Void parsedEvents++);
		complete("success=1&message=Joined&guild_name=Speed");

		var sentVars:URLVariables = cast captured.data;
		assertEquals("https://example.test/guild_join.php", captured.url, "request constructor preserves URL");
		assertEquals(URLRequestMethod.POST, captured.method, "request constructor preserves method");
		assertEquals("42", Std.string(Reflect.field(sentVars, "guild_id")), "request variables preserve authored fields");
		assertEquals("777", Std.string(Reflect.field(sentVars, "rand")), "request variables add rand");
		assertEquals("tok", Std.string(Reflect.field(sentVars, "token")), "request variables add token");
		assertEquals("Joining...", LobbyArt.text(popup, "textBox").text, "request constructor display text");
		assertEquals("Speed", Std.string(Reflect.field(popup.parsedData, "guild_name")), "URLVariables response parsed");
		assertEquals(0, messages.length, "aem false suppresses success message");
		assertEquals(1, completeEvents, "complete event dispatched");
		assertEquals(1, parsedEvents, "Flash parsedData event dispatched");

		UploadingPopup.requestFactory = savedRequestFactory;
		SuperLoader.nextRand = savedRand;
		SuperLoader.showMessage = savedShowMessage;
		LobbySession.token = savedToken;
		closeAll();
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
