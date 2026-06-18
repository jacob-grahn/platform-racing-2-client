package pr2.lobby;

import pr2.lobby.LobbyLeft;
import pr2.lobby.LobbyRight;
import pr2.lobby.players.PlayerListSort;
import pr2.lobby.players.PlayerListSort.SortableRow;
import pr2.lobby.search.SearchQuery;
import pr2.lobby.search.SearchQuery.SearchDecision;
import pr2.lobby.level.LevelAccess;
import pr2.lobby.level.LevelAccess.LevelAccessState;
import pr2.lobby.level.LevelGridLayout;
import pr2.lobby.messages.MessagesPaging;
import pr2.net.CampaignLevelInfo;
import pr2.net.ServerConfig;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.ui.CustomScrollBar;
import pr2.ui.PageNavigation;
import pr2.ui.TabLayout;
import pr2.ui.TabsHolder;

/**
	Deterministic coverage for the shared lobby services and tab logic that don't
	need real display art: tab overlap math, remembered tab restoration, the
	socket command recorder, the command dispatcher, and session guest/member
	state.
**/
class LobbyServicesTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testTabLayoutNoCompression();
		testTabLayoutCompression();
		testTabLayoutSingleTab();
		testTabMemory();
		testScrollBarMapping();
		testPageNavigationPositions();
		testPlayerSortStateMachine();
		testPlayerSortOrdering();
		testPaneTabLabels();
		testLevelListParsing();
		testSearchQuery();
		testLevelAccess();
		testLevelGridLayout();
		testLevelInfoParsing();
		testSessionGuestMember();
		testSocketRecording();
		testCommandDispatch();
		testMemoryAndSecureData();
		testMessagesPaging();
		trace('LobbyServicesTest passed $assertions assertions');
	}

	private static function testMessagesPaging():Void {
		// Flash chat.Messages: start = (currentPage - 1) * itemsPerPage, count = itemsPerPage.
		assertEquals(0, MessagesPaging.startIndex(1), "page 1 starts at 0");
		assertEquals(10, MessagesPaging.startIndex(2), "page 2 starts at 10");
		assertEquals(40, MessagesPaging.startIndex(5), "page 5 starts at 40");
		assertEquals(0, MessagesPaging.startIndex(0), "page 0 clamps to first page");
		assertEquals(20, MessagesPaging.startIndex(3, 10), "explicit items-per-page");
		ServerConfig.resetHost();
		assertEquals("https://pr2hub.com/messages_get.php?start=10&count=10", ServerConfig.messagesGetUrl(10, 10), "messages_get url");
	}

	private static function testTabLayoutNoCompression():Void {
		// Row narrower than the pane: tabs stay at their cumulative offsets.
		var xs = TabLayout.positions([40, 50, 30], 200);
		assertEquals(0.0, xs[0], "first tab x");
		assertEquals(40.0, xs[1], "second tab x");
		assertEquals(90.0, xs[2], "third tab x");
	}

	private static function testTabLayoutCompression():Void {
		// total = 120, maxW = 90 -> overflow 30 split across (n-1)=2 => tabW = 15.
		// tab[1] -= 15*1, tab[2] -= 15*2.
		var xs = TabLayout.positions([40, 40, 40], 90);
		assertEquals(0.0, xs[0], "compressed first x");
		assertEquals(25.0, xs[1], "compressed second x");
		assertEquals(50.0, xs[2], "compressed third x");
	}

	private static function testTabLayoutSingleTab():Void {
		// One tab wider than the pane must not divide by zero.
		var xs = TabLayout.positions([300], 100);
		assertEquals(1, xs.length, "single tab count");
		assertEquals(0.0, xs[0], "single tab x");
	}

	private static function testTabMemory():Void {
		TabsHolder.clearMemory();
		// No memory yet: falls back to the supplied default.
		assertEquals(2, TabsHolder.resolveSelected("lobbyLeft", 2, 4), "default selected");
		TabsHolder.setLastTab("lobbyLeft", 1);
		assertEquals(1, TabsHolder.resolveSelected("lobbyLeft", 2, 4), "remembered selected");
		// Remembered index out of range for a smaller tab set falls back.
		assertEquals(0, TabsHolder.resolveSelected("lobbyLeft", 0, 1), "stale memory ignored");
		TabsHolder.clearMemory();
	}

	private static function testScrollBarMapping():Void {
		// Thumb spans [20, 120]; target overflow = 400 - 300 = 100 px.
		// At the top the target sits at its initial y; at the bottom it scrolls up
		// by the full overflow.
		assertEquals(0.0, CustomScrollBar.thumbToTargetY(20, 20, 120, 0, 400, 300), "thumb top -> initial");
		assertEquals(-100.0, CustomScrollBar.thumbToTargetY(120, 20, 120, 0, 400, 300), "thumb bottom -> full scroll");
		assertEquals(-50.0, CustomScrollBar.thumbToTargetY(70, 20, 120, 0, 400, 300), "thumb middle -> half scroll");
		// Out-of-range thumb is clamped; target never scrolls below initial.
		assertEquals(0.0, CustomScrollBar.thumbToTargetY(-50, 20, 120, 0, 400, 300), "above top clamps to initial");
		assertEquals(-100.0, CustomScrollBar.thumbToTargetY(999, 20, 120, 0, 400, 300), "below bottom clamps to full");
	}

	private static function testPageNavigationPositions():Void {
		// Three 40px buttons across a 90px strip overlap exactly like the tab strip.
		var xs = PageNavigation.buttonPositions([40, 40, 40], 90);
		assertEquals(0.0, xs[0], "page button first x");
		assertEquals(25.0, xs[1], "page button second x");
		assertEquals(50.0, xs[2], "page button third x");
		// Fewer/narrower buttons than the strip spread apart (negative startingPos).
		var spread = PageNavigation.buttonPositions([20, 20], 100);
		assertEquals(0.0, spread[0], "spread first x");
		assertEquals(80.0, spread[1], "spread second x");
	}

	private static function testPlayerSortStateMachine():Void {
		// A numeric header sorts descending first; re-clicking it toggles to asc.
		var state = PlayerListSort.nextSort({mode: "rank", order: "desc"}, "rank", "userName");
		assertEquals("rank", state.mode, "re-click keeps mode");
		assertEquals("asc", state.order, "re-click toggles order");
		// Switching to another numeric header resets to descending.
		state = PlayerListSort.nextSort(state, "hats", "userName");
		assertEquals("hats", state.mode, "switch column");
		assertEquals("desc", state.order, "new numeric column is desc");
		// The name header sorts ascending.
		state = PlayerListSort.nextSort(state, "userName", "userName");
		assertEquals("userName", state.mode, "name column");
		assertEquals("asc", state.order, "name column is asc");
		// Re-clicking the name header toggles to descending.
		state = PlayerListSort.nextSort(state, "userName", "userName");
		assertEquals("desc", state.order, "name re-click toggles");
		// Tiebreak columns pair up as in the originals.
		assertEquals("hats", PlayerListSort.tiebreak("rank"), "rank tiebreak");
		assertEquals("activeMembers", PlayerListSort.tiebreak("gpToday"), "gp tiebreak");
	}

	private static function testPlayerSortOrdering():Void {
		// Descending rank, with hats as the tiebreak and name as the final tiebreak.
		var rows:Array<SortableRow> = [
			new TestRow("alice", 5, 2),
			new TestRow("bob", 9, 1),
			new TestRow("carol", 5, 7),
			new TestRow("dave", 5, 2)
		];
		PlayerListSort.apply(rows, {mode: "rank", order: "desc"}, "userName");
		assertEquals("bob", rows[0].sortName(), "highest rank first");
		assertEquals("carol", rows[1].sortName(), "rank tie broken by hats");
		assertEquals("alice", rows[2].sortName(), "remaining tie broken by name");
		assertEquals("dave", rows[3].sortName(), "name order after alice");
		// Ascending name sort.
		PlayerListSort.apply(rows, {mode: "userName", order: "asc"}, "userName");
		assertEquals("alice", rows[0].sortName(), "name asc first");
		assertEquals("dave", rows[3].sortName(), "name asc last");
	}

	private static function testPaneTabLabels():Void {
		// Members see PMs (left) and Favorites (right); guests don't.
		var leftMember = LobbyLeft.tabLabels(2);
		assertEquals(4, leftMember.length, "member left tab count");
		assertEquals("PMs", leftMember[1], "member left has PMs");
		var leftGuest = LobbyLeft.tabLabels(0);
		assertEquals(3, leftGuest.length, "guest left tab count");
		assertEquals("Players", leftGuest[1], "guest left drops PMs");

		var rightMember = LobbyRight.tabLabels(1);
		assertEquals(6, rightMember.length, "member right tab count");
		assertEquals("♥", rightMember[5], "member right has favorites");
		var rightGuest = LobbyRight.tabLabels(0);
		assertEquals(5, rightGuest.length, "guest right tab count");
		assertEquals("Campaign", rightGuest[0], "right defaults to campaign");
	}

	private static function testLevelListParsing():Void {
		// Campaign page formula `((server_id + day) % 6) + 1`, 1..6.
		assertEquals(1, pr2.net.LevelListClient.campaignPage(0, 0), "campaign page base");
		assertEquals(3, pr2.net.LevelListClient.campaignPage(5, 3), "campaign page wraps within 6");
		assertEquals(6, pr2.net.LevelListClient.campaignPage(2, 3), "campaign page upper");
		// Parsing pulls the levels array; an arbitrary body has an invalid hash.
		var body = '{"hash":"zzz","levels":[{"level_id":"7","title":"Alpha","user_name":"Jo"},{"level_id":"8","title":"Beta","user_name":"Al"}]}';
		var result = pr2.net.LevelListClient.parse(body);
		assertEquals(2, result.levels.length, "parsed level count");
		assertEquals(7, result.levels[0].levelId, "first level id");
		assertEquals("Beta", result.levels[1].title, "second level title");
		assertEquals(false, result.hashValid, "arbitrary hash is invalid");
	}

	private static function testSearchQuery():Void {
		// Blank query sends nothing.
		assertEquals(Std.string(SearchDecision.Skip), Std.string(SearchQuery.decide("   ", "user", 1, true)), "blank query skipped");
		// A normal query on any page sends.
		assertEquals(Std.string(SearchDecision.Send), Std.string(SearchQuery.decide("mario", "user", 3, false)), "user query sends");
		// Id search past page 1 snaps to page 1 on first run, then is ignored.
		assertEquals(Std.string(SearchDecision.ResetToFirstPage), Std.string(SearchQuery.decide("1234", "id", 4, true)), "id page>1 first run resets");
		assertEquals(Std.string(SearchDecision.Skip), Std.string(SearchQuery.decide("1234", "id", 4, false)), "id page>1 later skipped");
		assertEquals(Std.string(SearchDecision.Send), Std.string(SearchQuery.decide("1234", "id", 1, false)), "id page 1 sends");
		// POST params carry the inputs.
		var vars = SearchQuery.buildPost("mario", "user", "rating", "desc", 2);
		assertEquals("mario", vars.get("search_str"), "post search_str");
		assertEquals("user", vars.get("mode"), "post mode");
		assertEquals("rating", vars.get("order"), "post order");
		assertEquals("desc", vars.get("dir"), "post dir");
		assertEquals("2", vars.get("page"), "post page");
	}

	private static function testLevelAccess():Void {
		var noHats:Array<Int> = [];
		// Open level, sufficient rank: playable.
		assertEquals("Open", accessName(LevelAccess.evaluate(false, false, 1, false, 5, 3, -1, noHats)), "open level");
		// Password level not yet entered: pass cover (members below mod).
		assertEquals("PassNeeded", accessName(LevelAccess.evaluate(true, false, 1, false, 9, 0, -1, noHats)), "pass needed");
		// Owner bypasses the password.
		assertEquals("Open", accessName(LevelAccess.evaluate(true, false, 1, true, 9, 0, -1, noHats)), "owner bypasses pass");
		// Moderators (group>=2) bypass the password.
		assertEquals("Open", accessName(LevelAccess.evaluate(true, false, 2, false, 9, 0, -1, noHats)), "mod bypasses pass");
		// Rank too low: rank cover with the min rank.
		assertEquals("RankNeeded", accessName(LevelAccess.evaluate(false, false, 1, false, 2, 10, -1, noHats)), "rank gate");
		assertEquals("Rank 10 Needed", LevelAccess.coverText(LevelAccess.evaluate(false, false, 1, false, 2, 10, -1, noHats)), "rank cover text");
		// Disallowed hat applies even to the owner.
		assertEquals("HatNotAllowed", accessName(LevelAccess.evaluate(false, false, 1, true, 5, 0, 7, [7, 9])), "hat gate");
		assertEquals("HatNotAllowed", accessName(LevelAccess.evaluate(false, false, 2, false, 5, 0, 7, [7])), "mod still hat-gated");
	}

	private static function accessName(state:LevelAccessState):String {
		return switch (state) {
			case Open: "Open";
			case PassNeeded: "PassNeeded";
			case RankNeeded(_): "RankNeeded";
			case HatNotAllowed: "HatNotAllowed";
		}
	}

	private static function testLevelGridLayout():Void {
		// Seven levels from y=0 fill three columns then start a second/third row.
		var positions = LevelGridLayout.positions(7, 0);
		assertEquals(7, positions.length, "all seven placed at y=0 start");
		assertEquals(2.0, positions[0].x, "col0 x");
		assertEquals(111.0, positions[1].x, "col1 x");
		assertEquals(220.0, positions[2].x, "col2 x");
		assertEquals(0.0, positions[2].y, "row0 y");
		assertEquals(112.0, positions[3].y, "row1 y");
		assertEquals(224.0, positions[6].y, "row2 y at the limit");
		// A non-zero start height pushes rows past 224 and the phantom row is cut.
		var shifted = LevelGridLayout.positions(9, 20);
		assertEquals(6, shifted.length, "rows past 224 are dropped");
	}

	private static function testLevelInfoParsing():Void {
		var data = {
			level_id: "42",
			version: "3",
			title: "Castle",
			user_name: "Jo",
			user_group: "1,1",
			min_level: "5",
			rating: "4.5",
			play_count: "1200",
			note: "fun",
			pass: "1",
			type: "d",
			bad_hats: "0,1,7,9",
			time: "1600000000"
		};
		var info = CampaignLevelInfo.fromDynamic(data);
		assertEquals(42, info.levelId, "level id");
		assertEquals(true, info.pass, "pass flag");
		assertEquals("d", info.type, "type code");
		assertEquals(2, info.badHats.length, "bad hats keep ids > 1");
		assertEquals(7, info.badHats[0], "first bad hat");
		assertEquals(9, info.badHats[1], "second bad hat");
	}

	private static function testSessionGuestMember():Void {
		LobbySession.clear();
		assertEquals(true, LobbySession.isGuest(), "fresh session is guest");
		assertEquals(false, LobbySession.isMember(), "guest is not member");
		LobbySession.begin("Jiggmin", 3, null, 1, true);
		assertEquals(true, LobbySession.isMember(), "logged-in is member");
		assertEquals("Jiggmin", LobbySession.userName, "user name set");
		assertEquals(true, LobbySession.remember, "remember flag set");
		var fired = 0;
		var listener = function():Void {
			fired++;
		};
		LobbySession.onAccountChange(listener);
		LobbySession.notifyAccountChange();
		assertEquals(1, fired, "account change fired");
		LobbySession.clear();
	}

	private static function testSocketRecording():Void {
		LobbySocket.resetSent();
		LobbySocket.write("set_chat_room`main");
		LobbySocket.write("set_right_room`none");
		assertEquals(2, LobbySocket.sentCommands.length, "two commands recorded");
		assertEquals("set_right_room`none", LobbySocket.lastSent(), "last command");
		LobbySocket.resetSent();
		assertEquals(0, LobbySocket.sentCommands.length, "reset clears recorder");
	}

	private static function testCommandDispatch():Void {
		var handler = new CommandHandler();
		var captured:Array<String> = null;
		handler.defineCommand("setChatRoomList", function(args):Void {
			captured = args;
		});
		// Server layout: hash`num`command`arg1`arg2`
		var handled = handler.handleServerFrame("abc`5`setChatRoomList`main`speed`");
		assertEquals(true, handled, "frame handled");
		assertEquals("main", captured[0], "first arg parsed");
		assertEquals("speed", captured[1], "second arg parsed");
		handler.defineCommand("setChatRoomList", null);
		assertEquals(false, handler.handleServerFrame("abc`6`setChatRoomList`x`"), "cleared command ignored");
	}

	private static function testMemoryAndSecureData():Void {
		Memory.clear();
		assertEquals(7, Memory.getInt("coursePageNum1", 7), "memory default int");
		Memory.set("coursePageNum1", 3);
		assertEquals(3, Memory.getInt("coursePageNum1", 7), "memory stored int");
		SecureData.clear();
		assertEquals(0.0, SecureData.getNumber("userRank"), "secure default");
		SecureData.setNumber("userRank", 5);
		assertEquals(5.0, SecureData.getNumber("userRank"), "secure stored");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}

/** Minimal `SortableRow` for exercising the players/guilds sort comparator. */
private class TestRow implements SortableRow {
	private var name:String;
	private var rank:Int;
	private var hats:Int;

	public function new(name:String, rank:Int, hats:Int) {
		this.name = name;
		this.rank = rank;
		this.hats = hats;
	}

	public function numericField(key:String):Float {
		return key == "rank" ? rank : (key == "hats" ? hats : 0);
	}

	public function sortName():String {
		return name;
	}
}
