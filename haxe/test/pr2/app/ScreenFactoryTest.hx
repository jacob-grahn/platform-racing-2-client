package pr2.app;

import pr2.page.Page;
import pr2.net.ServerInfo;
import pr2.lobby.LobbySession;

class ScreenFactoryTest {
	public static function main():Void {
		for (requested in ["classic", "mobile"]) {
			ScreenFactory.configure("?ui=" + requested, "inxile");
			var mobile = #if pr2_mobile_ui true #elseif pr2_ui_preview requested == "mobile" #else false #end;
			check(mobile == ScreenFactory.isMobile, "release selection must ignore query overrides");
			AuthFlowTest.run();
			var login = ScreenFactory.login();
			check(Type.getClassName(Type.getClass(login)) == (mobile ? "pr2.page.MobileLoginPage" : "pr2.page.LoginPage"), "title matches selected UI");
			check(login.isLoginScreen, "disconnect recovery recognizes either title");
			check(Reflect.field(login, "siteMode") == "inxile", "site mode survives logout/recovery");
			login.remove();
			var server = new ServerInfo("127.0.0.1", 9160, 1, "Test", "open", 0, 0, false);
			var lobby = ScreenFactory.lobby("Racer", server);
			check(Type.getClassName(Type.getClass(lobby)) == (mobile ? "pr2.page.MobileLobbyPage" : "pr2.page.LobbyPage"), "lobby matches selected UI");
			check(LobbySession.server == server && LobbySession.userName == "Racer", "both shells preserve session arguments");
			check(lobby.fullViewport == mobile, "viewport follows page requirements");
			var closed = 0;
			var results = ScreenFactory.results(123, function() {}, function(_) closed++, 45, null, "Test level", "Race complete");
			check(Type.getClassName(Type.getClass(results)) == (mobile ? "pr2.mobile.MobileResultsPage" : "pr2.gameplay.FinishedPage"), "results match selected UI");
			results.remove(); check(closed == 1, "result dismissal notifies its owner");
			var racer = ScreenFactory.racer();
			check(Type.getClassName(Type.getClass(racer)) == (mobile ? "pr2.mobile.MobileRacerPage" : "pr2.lobby.tabs.AccountTab"), "racer matches selected UI");
			racer.remove();
			var messages = ScreenFactory.messages();
			check(Type.getClassName(Type.getClass(messages)) == (mobile ? "pr2.mobile.MobileMessagesPage" : "pr2.lobby.tabs.MessagesTab"), "messages match selected UI");
			messages.remove();
			for (guest in [false,true]) {
				var profile = ScreenFactory.profile("Test",guest,false);
				check(Type.getClassName(Type.getClass(profile)) == (mobile ? "pr2.mobile.MobileProfilePopup" : guest ? "pr2.lobby.dialogs.PlayerGuestPopup" : "pr2.lobby.dialogs.PlayerPopup"), "profile matches selected UI");
				profile.remove();
			}
			var compose = ScreenFactory.composeMessage("Test");
			check(Type.getClassName(Type.getClass(compose)) == (mobile ? "pr2.mobile.MobileComposePopup" : "pr2.lobby.dialogs.SendMessagePopup"), "composer matches selected UI");
			compose.remove();
			for (guilds in [false, true]) {
				var players = ScreenFactory.players(guilds);
				check(Type.getClassName(Type.getClass(players)) == (mobile ? "pr2.mobile.MobilePlayersPage" : guilds ? "pr2.lobby.players.Guilds" : "pr2.lobby.tabs.PlayersTab"), "directory matches selected UI");
				players.remove();
			}
		}
		ScreenFactory.configure(null);
		#if (pr2_mobile_ui || pr2_ui_preview)
		MobileLobbyFlowTest.run();
		#end
		LobbySession.clear();
		trace("ScreenFactoryTest passed");
	}
	private static function check(value:Bool, message:String):Void {
		if (!value) throw message;
	}
}
