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
			var instructions = ScreenFactory.instructions();
			check(Type.getClassName(Type.getClass(instructions)) == (mobile ? "pr2.page.MobileInstructionsPage" : "pr2.page.LoginPage"),
				"instructions destination follows the selected UI");
			check(instructions.fullViewport == mobile, "mobile instructions use the landscape viewport");
			check(instructions.isLoginScreen, "instructions remain in the unauthenticated flow");
			instructions.remove();
			var advanced = ScreenFactory.advancedColor(0xAABBCC);
			check(Type.getClassName(Type.getClass(advanced)) == (mobile ? "pr2.mobile.MobileAdvancedColorPopup" : "pr2.lobby.account.ColorPickerPopup"),
				"advanced picker follows the selected UI");
			check(advanced.getColor() == 0xAABBCC, "advanced picker preserves the selected color");
			advanced.remove();
			var notice = ScreenFactory.message("Welcome!<br><b>Read this.</b>");
			if (mobile) {
				var mobileNotice:pr2.mobile.MobileMessagePopup = cast notice;
				check(mobileNotice.messageTextForTests().indexOf("Read this.") >= 0, "mobile notices render server HTML as readable text");
				check(mobileNotice.messageTextForTests().indexOf("<b>") < 0, "mobile notices do not show raw formatting tags");
			}
			notice.remove();
			var server = new ServerInfo("127.0.0.1", 9160, 1, "Test", "open", 0, 0, false);
			var lobby = ScreenFactory.lobby("Racer", server);
			check(Type.getClassName(Type.getClass(lobby)) == (mobile ? "pr2.page.MobileLobbyPage" : "pr2.page.LobbyPage"), "lobby matches selected UI");
			check(LobbySession.server == server && LobbySession.userName == "Racer", "both shells preserve session arguments");
			check(lobby.fullViewport == mobile, "viewport follows page requirements");
			var editor = ScreenFactory.editor();
			check(Type.getClassName(Type.getClass(editor)) == (mobile ? "pr2.mobile.MobileLevelEditorPage" : "pr2.levelEditor.LevelEditor"), "editor matches selected UI");
			check(editor.fullViewport == mobile, "editor viewport matches selected UI");
			if (mobile) {
				editor.initialize();
				var mobileEditor:pr2.levelEditor.LevelEditor = cast editor;
				check(mobileEditor.mobileCanvasBounds != null, "mobile editor clips the canvas to its viewport");
				check(mobileEditor.isPointOverMenu(10, 10), "mobile editor protects header and outside-canvas taps");
				check(mobileEditor.isPointOverMenu(730, 160), "mobile editor protects palette taps");
				var reportEditor:pr2.mobile.MobileLevelEditorPage = cast editor;
				@:privateAccess reportEditor.selectedReport = {level_id: "7", version: "2", title: "Reported course", creator: "Racer", reporter: "Helper", reason: "Review this"};
				for (reportScreen in ["report-detail", "report-ban", "report-custom"]) {
					@:privateAccess reportEditor.screen = reportScreen;
					@:privateAccess reportEditor.render();
					check(@:privateAccess reportEditor.screen == reportScreen, "mobile report screen renders: " + reportScreen);
				}
			}
			editor.remove();
			var testVars = new Map<String, String>();
			var testCourse = ScreenFactory.testCourse(testVars, false, false, "unsaved-draft");
			check(Type.getClassName(Type.getClass(testCourse)) == (mobile ? "pr2.mobile.MobileTestCoursePage" : "pr2.levelEditor.TestCoursePage"), "test run matches selected UI");
			testCourse.remove();
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
