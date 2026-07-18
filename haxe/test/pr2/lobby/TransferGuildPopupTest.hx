package pr2.lobby;

import haxe.Json;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.NativeFormView;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.TransferGuildPopup;
import pr2.net.ServerConfig;
import pr2.ui.controls.GameTextInput;
import pr2.util.TestDisplayUtil as DisplayUtil;

class TransferGuildPopupTest {
	private static inline var ACCOUNT_CHANGE_KEY:String = "KVhFJSVLNigvKkdhV0RaSw==";
	private static inline var ACCOUNT_CHANGE_IV:String = "QEFUZCskMnhhdk8rYlFLKg==";

	private static var assertions:Int = 0;

	public static function main():Void {
		var savedUploadFactory = TransferGuildPopup.uploadFactory;
		ServerConfig.setHost("http://example.test");
		testValidationAndCancel();
		if (pr2.DeterministicTestMode.finishSmokeSuite("TransferGuildPopupTest")) return;
		testEncryptedUploadAndGuildState();
		TransferGuildPopup.uploadFactory = savedUploadFactory;
		ServerConfig.resetHost();
		closeAll();
		trace('TransferGuildPopupTest passed $assertions assertions');
	}

	private static function testValidationAndCancel():Void {
		var uploads = 0;
		TransferGuildPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String,
				onResult:Dynamic->Void):Null<pr2.lobby.dialogs.UploadingPopup> {
			uploads++;
			return null;
		};
		var popup = new TransferGuildPopup();
		var art = formView(popup);
		assertEquals(2, art.panels.length, "transfer-guild keeps the two authored ShadowBG instances");
		assertEquals(-116.0, art.panels[0].y, "transfer form ShadowBG keeps its XFL Y");
		assertEquals(0.92236328125, art.panels[0].scaleY, "transfer form ShadowBG keeps its XFL vertical scale");
		assertEquals(65.7, art.panels[1].y, "transfer description ShadowBG keeps its XFL Y");
		assertEquals(0.26177978515625, art.panels[1].scaleY, "transfer description ShadowBG keeps its XFL vertical scale");
		assertEquals(4.0, input(popup, "emailBox").x, "transfer inputs keep their XFL X");
		assertEquals(-70.75, input(popup, "emailBox").y, "transfer email keeps its XFL Y");
		assertEquals(100, input(popup, "emailBox").maxChars, "transfer email keeps its authored maximum length");
		assertEquals(20, input(popup, "nameBox").maxChars, "new owner keeps its authored maximum length");
		assertEquals(true, input(popup, "passBox").displayAsPassword, "transfer password field keeps masking");
		assertEquals(24.25, art.submitButton.y, "transfer buttons keep their XFL Y");
		input(popup, "emailBox").text = "owner@example.test";
		click(popup, "ok_bt");
		assertEquals(0, uploads, "missing fields do not upload");
		assertEquals("Please fill in all of the fields.", lastMessageText(), "missing-field error copy");
		closeAll();

		popup = new TransferGuildPopup();
		click(popup, "cancel_bt");
		assertEquals(true, popup.fadeOutStarted, "cancel fades the dialog");
		closeAll();
	}

	private static function testEncryptedUploadAndGuildState():Void {
		var uploads:Array<{url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void}> = [];
		TransferGuildPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String,
				onResult:Dynamic->Void):Null<pr2.lobby.dialogs.UploadingPopup> {
			uploads.push({url: url, fields: fields, label: label, onResult: onResult});
			return null;
		};
		LobbySession.begin("CurrentOwner", 1, null, 99, true);
		LobbySession.updateGuildState(44, "Guild Name", true, "emblem.png", false);
		var accountChanges = 0;
		LobbySession.onAccountChange(function():Void accountChanges++);
		var popup = new TransferGuildPopup();
		input(popup, "emailBox").text = "owner@example.test";
		input(popup, "passBox").text = "secret";
		input(popup, "nameBox").text = "NextOwner";
		input(popup, "nameBox").dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, 13));

		assertEquals(1, uploads.length, "enter key submits guild transfer");
		assertEquals(ServerConfig.guildTransferUrl(), uploads[0].url, "guild-transfer endpoint");
		assertEquals("Uploading...", uploads[0].label, "upload label");
		var payload:Dynamic = Json.parse(PR2Encryptor.decryptBase64(uploads[0].fields.get("data"), ACCOUNT_CHANGE_KEY, ACCOUNT_CHANGE_IV));
		assertEquals("owner@example.test", Reflect.field(payload, "email"), "payload includes email");
		assertEquals("CurrentOwner", Reflect.field(payload, "name"), "payload includes logged-in name");
		assertEquals("secret", Reflect.field(payload, "pass"), "payload includes password");
		assertEquals("NextOwner", Reflect.field(payload, "new_owner"), "payload includes new owner");
		assertEquals(true, popup.fadeOutStarted, "submit fades the dialog");

		uploads[0].onResult({success: true});
		assertEquals(44, LobbySession.guildId, "transfer keeps guild id");
		assertEquals("Guild Name", LobbySession.guildName, "transfer keeps guild name");
		assertEquals(false, LobbySession.guildOwner, "transfer clears owner flag");
		assertEquals(1, accountChanges, "transfer dispatches account change");
		closeAll();
	}

	private static function input(popup:TransferGuildPopup, name:String):GameTextInput {
		var value = Std.downcast(DisplayUtil.findByName(popup, name), GameTextInput);
		if (value == null) throw name + " missing";
		return value;
	}

	private static function formView(popup:TransferGuildPopup):NativeFormView {
		for (index in 0...popup.numChildren) {
			var view = Std.downcast(popup.getChildAt(index), NativeFormView);
			if (view != null) return view;
		}
		throw "native transfer-guild form missing";
	}

	private static function click(popup:TransferGuildPopup, name:String):Void {
		var target = DisplayUtil.findByName(popup, name);
		if (target == null) throw name + " missing";
		target.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function lastMessageText():String {
		var open = Popup.getOpen();
		var message = Std.downcast(open[open.length - 1], MessagePopup);
		assertNotNull(message, "validation opens message popup");
		return LobbyArt.text(message, "textBox").text;
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
		LobbySession.clear();
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw message;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
