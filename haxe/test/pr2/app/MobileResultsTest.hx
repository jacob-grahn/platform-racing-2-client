package pr2.app;

import pr2.gameplay.LevelRating;
import pr2.mobile.MobileResultsPage;
import pr2.net.LobbySocket;
import pr2.page.GamePage;
import pr2.page.PageHolder;

@:access(pr2.mobile.MobileResultsPage)
@:access(pr2.mobile.MobileGameHud)
@:access(pr2.page.GamePage)
class MobileResultsTest {
	public static function main():Void {
		var calls = 0, cancelled = 0;
		var success:String->Void = null, failure:String->Void = null;
		var original = LevelRating.transport;
		LevelRating.transport = function(url, fields, ok, fail) {
			check(url == pr2.net.ServerConfig.submitRatingUrl(), "shared rating endpoint");
			check(fields.get("level_id") == "12345" && fields.get("rating") == "4", "confirmed rating payload");
			calls++; success = ok; failure = fail;
			return {remove: function() cancelled++};
		};
		LobbySocket.resetSent();
		var holder = new PageHolder(); var game = new GamePage(12345, 7); holder.changePage(game);
		check(ScreenFactory.resultAssets(12345) == null, "mobile skips classic asset warmup");
		game.award(["First Place", "+50"]);
		check(game.finishedPage == null, "awards buffer until completion");
		game.setExpGain(10, 60, 100);
		var page = Std.downcast(game.finishedPage, MobileResultsPage);
		check(page != null && page.state.awards.length == 1 && page.state.gained == 50, "server completion opens mobile results with buffered award");
		check(LobbySocket.lastSent() == "", "server completion never quits the race");
		var hud = Std.downcast(game.hud, pr2.mobile.MobileGameHud);
		check(hud.resultsOpen, "results owns gameplay input");
		game.award(["Speed Bonus", "+20"]); game.setExpGain(10, 80, 100);
		check(page.state.awards.length == 2 && page.state.gained == 70, "late updates refresh the open results");
		for (_ in 0...46) page.state.progress.tick();
		check(page.state.progress.current == 80 && !page.state.progress.active, "shared XP interpolation reaches target");
		page.confirmRating(); check(page.confirmation == null && calls == 0, "rating requires a selection");
		page.selection = 4; page.confirmRating(); check(page.confirmation != null && calls == 0, "selection opens confirmation without posting");
		page.confirmation.onCancel(); check(page.confirmation == null && calls == 0, "cancel never submits");
		page.confirmRating(); page.confirmation.onConfirm();
		check(page.rating.pending && calls == 1, "confirmation submits once");
		page.rating.submit(4); check(calls == 1, "pending request cannot duplicate");
		failure("Please log in to rate."); check(page.rating.failed && !page.rating.pending, "server errors allow retry");
		check(page.details.content.y < 0, "rating feedback is automatically revealed");
		page.confirmRating(); page.confirmation.onConfirm(); success("Thanks!");
		check(page.rating.submitted == 4 && page.rating.message == "Thanks!" && !page.rating.failed, "retry succeeds");
		page.layoutForSize(390, 844); check(page.state.awards.length == 2 && page.selection == 4 && page.view.controls.length == 0, "portrait hint retains results and selection");
		page.layoutForSize(667, 375); check(page.details.visible && page.view.controls.length == 2, "landscape restores scrollable results and fixed actions");
		var submit = page.details.content.getChildByName("Submit rating");
		check(submit != null && submit.y + submit.height <= page.details.scrollRect.height, "submit action fits compact landscape without scrolling");
		page.confirmRating(); page.confirmation.onConfirm();
		var previous = page.rating.message;
		page.startFadeOut(); success("late completion");
		check(cancelled == 3 && page.rating.message == previous, "closing cancels owned requests and ignores late completion");
		page.remove(); page.remove();
		check(game.finishedPage == null && !hud.resultsOpen, "dismiss releases results ownership exactly once");
		game.quitGame(); page = Std.downcast(game.finishedPage, MobileResultsPage);
		check(LobbySocket.lastSent() == "" && page.state.awards.length == 2 && page.state.gained == 70, "reopen preserves data without quitting again");
		LobbySocket.simulateOpenForTests(); page.returnToLobby();
		check(LobbySocket.sentCommands.indexOf("set_game_room`none") >= 0, "return clears server room");
		check(Std.isOfType(holder.getCurrentPage(), pr2.page.MobileLobbyPage), "return uses mobile lobby");
		holder.getCurrentPage().remove();
		game = new GamePage(12345, 7); game.onCourseOutOfTime();
		page = Std.downcast(game.finishedPage, MobileResultsPage);
		check(page.outcome == "Time's up!" && !page.state.hasExperience, "timeout has truthful outcome without invented rewards");
		game.remove();
		var invalid = new LevelRating(12345); invalid.submit(0); invalid.submit(6); check(calls == 3, "invalid ratings never submit"); invalid.remove();
		LevelRating.transport = original;
		pr2.lobby.LobbySession.clear();
		trace("MobileResultsTest passed");
		Sys.exit(0);
	}
	private static function check(value:Bool, message:String):Void { if (!value) throw message; }
}
