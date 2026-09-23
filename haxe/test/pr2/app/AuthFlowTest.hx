package pr2.app;

import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.MouseEvent;
import openfl.net.URLRequest;
import pr2.net.SuperLoader;
import pr2.page.LoginFlow;
import pr2.page.auth.AuthDialog;
import pr2.net.SavedAccounts;
import pr2.net.ServerInfo;
import pr2.net.ServerStatusClient;
import pr2.net.ServerStatusResult;

/** Exercises the real shared flow with each build's actual dialog presentation. */
@:access(pr2.page.LoginFlow)
@:access(pr2.mobile.MobileAuthDialog)
class AuthFlowTest {
	public static function run():Void {
		SavedAccounts.disablePersistenceForTests();
		var transports:Array<AuthTransport> = [];
		var oldTransport = SuperLoader.transportFactory;
		var oldFetch = ServerStatusClient.fetchFactory;
		SuperLoader.transportFactory = function():Dynamic {
			var transport = new AuthTransport(); transports.push(transport); return transport;
		};
		var respond:ServerStatusResult->Void = null;
		ServerStatusClient.fetchFactory = function(success, error):Void respond = success;
		var flow = new LoginFlow();
		flow.openCredentialDialog();
		flow.loadServers();
		check(!flow.activePopup.comboBox("dropdown").enabled, "server picker disabled while loading");
		respond(new ServerStatusResult([new ServerInfo("127.0.0.1", 9160, 1, "Test", "open", 0, 0, false)]));
		check(flow.activePopup.comboBox("dropdown").enabled, "server response enables selection");
		check(flow.activePopup.input("passBox").displayAsPassword, "login masks password");
		#if (pr2_mobile_ui || pr2_ui_preview)
		if (ScreenFactory.isMobile) {
			var mobile:pr2.mobile.MobileAuthDialog = cast flow.activePopup;
			var combo = mobile.comboBox("dropdown");
			for (i in 0...8) combo.addItem({label: 'Server $i', server: new ServerInfo("127.0.0.1", 9160, i + 2, 'Server $i', "open", 0, 0, false)});
			mobile.resizeViewport(667, 375);
			combo.activate();
			check(mobile.picker != null, "mobile choice opens its own picker");
			mobile.pickerControls[mobile.pickerControls.length - 1].activate();
			check(mobile.pickerOffset > 0, "long choice lists paginate");
			mobile.pickerControls[0].activate();
			check(mobile.picker == null && combo.selectedIndex > 0, "picker selection updates shared model and closes");
			mobile.resizeViewport(390, 667);
			check(mobile.child("forgotPass").y > mobile.child("dropdown").y + 46, "narrow form avoids overlapping controls");
		}
		#end
		flow.activePopup.input("nameBox").text = "TestRacer";
		click(flow.activePopup, "forgotPass");
		check(flow.activePopup.kind == "Recover", "forgot-password button routes to recovery");
		check(flow.activePopup.input("nameBox").text == "TestRacer", "recovery preserves racer name");
		flow.activePopup.input("emailBox").text = "racer@example.test";
		flow.activePopup.onSubmit();
		check(flow.activePopup.kind == "Progress", "recovery shows progress");
		flow.activePopup.onClose();
		transports[transports.length - 1].complete('{"success":true,"message":"Sent"}');
		check(flow.activePopup == null, "canceled recovery does not reopen a dialog");

		flow.openCreateAccountDialog("Racer", "one", "two", "racer@example.test");
		var count = transports.length;
		flow.activePopup.onSubmit();
		check(transports.length == count, "mismatched passwords never submit");
		var notice:AuthDialog = cast flow.getChildAt(flow.numChildren - 1);
		check(notice.kind == "Message", "validation opens message presentation");
		notice.onClose();
		check(flow.activePopup.input("nameBox").text == "Racer", "retry restores name");
		check(flow.activePopup.input("passBox1").text == "one", "retry restores form values");
		flow.activePopup.input("passBox2").text = "one";
		flow.activePopup.onSubmit();
		var pending = transports[transports.length - 1];
		flow.activePopup.onClose();
		pending.complete('{"success":true}');
		check(flow.activePopup.kind == "Register", "canceled registration ignores late success");
		flow.activePopup.onSubmit();
		transports[transports.length - 1].complete('{"success":true}');
		check(flow.activePopup.kind == "ServerSelectPopupGraphic", "registration success continues to server selection");
		check(flow.pendingCreatedUserName == "Racer" && flow.pendingCreatedUserPass == "one", "new-account login retains credentials");
		flow.openGuestDialog();
		check(!cast(flow.activePopup.child("user_del_bt"), openfl.display.InteractiveObject).mouseEnabled, "guest cannot remove accounts");
		SavedAccounts.add("Saved", "test-token");
		flow.openLoginDialog();
		click(flow.activePopup, "user_del_bt");
		check(flow.activePopup.kind == "Confirm", "saved-account deletion requires confirmation");
		flow.activePopup.onCancel();
		check(SavedAccounts.getAll().length == 1, "cancel keeps saved account");
		click(flow.activePopup, "user_del_bt");
		flow.activePopup.onConfirm();
		check(SavedAccounts.getAll().length == 0, "confirm removes saved account");
		check(flow.activePopup.kind == "LoginPopupGraphic", "last removal returns to credentials");
		flow.openForgotPasswordDialog("Racer");
		flow.activePopup.onSubmit();
		pending = transports[transports.length - 1];
		flow.remove();
		pending.complete('{"success":true,"message":"Sent"}');
		check(flow.numChildren == 0, "removed flow ignores late recovery result");
		var oldLogin = pr2.net.LoginAuthClient.loginFactory;
		var authResult:pr2.net.LoginAuthClient.LoginAuthResult->Void = null;
		pr2.net.LoginAuthClient.loginFactory = function(name, password, server, remember, loginId, success, error, token):Void authResult = success;
		var entered = 0;
		flow = new LoginFlow(function(name, server):Void entered++);
		var server = new ServerInfo("127.0.0.1", 9160, 1, "Test", "open", 0, 0, false);
		flow.openLoggingInPopup("123", "Racer", "test-password", false, server);
		flow.activePopup.onClose();
		authResult(new pr2.net.LoginAuthClient.LoginAuthResult(true, "", {}));
		check(entered == 0 && flow.loginGate == null, "canceled login ignores late HTTP success");
		flow.openLoggingInPopup("124", "Racer", "test-password", false, server);
		authResult(new pr2.net.LoginAuthClient.LoginAuthResult(true, "", {}));
		check(entered == 0, "HTTP acceptance waits for socket confirmation");
		flow.loginGate.acceptSocket(1, "Racer");
		check(entered == 1, "HTTP and socket confirmation hand off to lobby once");
		flow.remove();
		pr2.net.LoginAuthClient.loginFactory = oldLogin;
		pr2.lobby.LobbySession.clear();
		SuperLoader.transportFactory = oldTransport;
		ServerStatusClient.fetchFactory = oldFetch;
	}
	private static function click(dialog:AuthDialog, name:String):Void dialog.child(name).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	private static function check(value:Bool, message:String):Void if (!value) throw message;
}

private class AuthTransport extends EventDispatcher {
	public var data:Dynamic;
	public var dataFormat:Dynamic;
	public function new() super();
	public function load(request:URLRequest):Void {}
	public function close():Void {}
	public function complete(body:String):Void { data = body; dispatchEvent(new Event(Event.COMPLETE)); }
}
