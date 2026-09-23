package pr2.mobile;

import openfl.events.Event;
import openfl.events.KeyboardEvent;
import pr2.lobby.LobbySession;
import pr2.lobby.LobbyPopups;
import pr2.lobby.Memory;
import pr2.lobby.level.LevelBrowserData;
import pr2.lobby.level.LevelListingState;
import pr2.lobby.level.LevelAccess;
import pr2.lobby.level.RaceEntryFlow;
import pr2.lobby.search.SearchQuery;
import pr2.mobile.MobileAuthControls.AuthInput;
import pr2.net.LevelListClient.LevelListResult;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.util.AsyncRemovalGuard;

/** Landscape browse/detail/race-entry views sharing the original lobby protocol. */
class MobileLevelBrowser extends LobbyView {
	public var onState:Void->Void;
	public var mode(default, null):String = "campaign";
	public var browsing(default, null):Bool = false;
	public var racing(get, never):Bool;
	public var page(default, null):Int = 1;
	private var viewW:Float = 756;
	private var viewH:Float = 284;
	private var cards:Array<MobileLevelCard> = [];
	private var selected:MobileLevelCard;
	private var race:RaceEntryFlow;
	private var raceCard:MobileLevelCard;
	private var guard = new AsyncRemovalGuard();
	private var status:String = "Loading courses…";
	private var failed:Bool = false;
	private var loading:Bool = false;
	private var removed:Bool = false;
	private var list:MobileScrollPane;
	private var detail:MobileScrollPane;
	private var narrowDetail:Bool = false;
	private var query:String;
	private var searchMode:Int;
	private var searchOrder:Int;
	private var searchDirection:Int;
	private var picker:String = "";
	private var highlights:Map<Int, Bool> = [];
	private var lastViewKey:String = "";
	private static final MODES = ["campaign", "best", "best_week", "newest", "favorites"];
	private static final LABELS = ["Campaign", "All Time Best", "Week’s Best", "Newest", "Favorites"];
	private static final SEARCH_MODES = ["user", "title", "id"];
	private static final SEARCH_LABELS = ["Creator", "Level title", "Level ID"];
	private static final ORDERS = ["date", "alphabetical", "rating", "popularity"];
	private static final ORDER_LABELS = ["Date", "Alphabetical", "Rating", "Popularity"];
	private static final DIRECTIONS = ["desc", "asc"];

	public function new() {
		super();
		query = Memory.getString("searchStr", "");
		searchMode = bounded(Memory.getInt("searchModeIndex", 0), 3);
		searchOrder = bounded(Memory.getInt("searchOrderIndex", 0), 4);
		searchDirection = bounded(Memory.getInt("searchDirIndex", 0), 2);
		var cm = CommandHandler.commandHandler;
		cm.defineCommand("testLevelAccess", function(_) redraw());
		cm.defineCommand("addPageHighlight", function(a) highlight(a, true));
		cm.defineCommand("removePageHighlight", function(a) highlight(a, false));
		showMode(Memory.getString("mobileLobbyPlay", "campaign"));
	}
	private static function bounded(n:Int, length:Int):Int return n < 0 || n >= length ? 0 : n;
	private function get_racing():Bool return race != null;
	public function setLayout(w:Float, h:Float):Void { viewW = Math.max(280, w); viewH = Math.max(210, h); picker = ""; redraw(); }
	public function showMode(value:String):Void {
		if (MODES.indexOf(value) < 0 && value != "search") value = "campaign";
		if (value == "favorites" && !LobbySession.isMember()) value = "campaign";
		mode = value; Memory.set("mobileLobbyPlay", mode);
		page = Std.int(Math.max(1, Math.min(LevelBrowserData.pageCount(mode), LevelBrowserData.initialPage(mode))));
		if (mode == "search" && searchMode == 2) page = 1;
		browsing = mode == "search"; picker = ""; narrowDetail = false; highlights = [];
		request(); stateChanged();
	}
	public function browse():Void { browsing = true; picker = ""; redraw(); stateChanged(); }
	public function back():Void {
		if (race != null) { leaveRace(); return; }
		picker = ""; browsing = false; narrowDetail = false; redraw(); stateChanged();
	}
	public function showSearch(value:String, type:String):Void {
		query = value == null ? "" : value; searchMode = bounded(SEARCH_MODES.indexOf(type), 3); rememberSearch();
		Memory.set("coursePageNumsearch", 1); showMode("search");
	}
	private function rememberSearch():Void {
		Memory.set("searchStr", query); Memory.set("searchModeIndex", searchMode);
		Memory.set("searchOrderIndex", searchOrder); Memory.set("searchDirIndex", searchDirection);
	}
	private function search():Void { rememberSearch(); mode = "search"; Memory.set("mobileLobbyPlay", mode); page = 1; request(); }
	private function pageTo(n:Int):Void {
		var max = mode == "search" && searchMode == 2 ? 1 : LevelBrowserData.pageCount(mode);
		if (loading || n < 1 || n > max) return;
		page = n; request();
	}
	private function request():Void {
		guard.remove(); guard = new AsyncRemovalGuard(); clearEntries();
		Memory.set("coursePageNum" + mode, page); LevelListingState.currentPageNum = page;
		LobbySocket.write("set_right_room`none");
		failed = false; loading = true; status = "Loading courses…"; redraw();
		if (mode == "search") {
			if (SearchQuery.decide(query, SEARCH_MODES[searchMode], page, false) != Send) {
				loading = false; status = "Search by creator, level title, or ID."; redraw(); return;
			}
			guard.watch(LevelBrowserData.searchFactory(SearchQuery.buildPost(query, SEARCH_MODES[searchMode], ORDERS[searchOrder], DIRECTIONS[searchDirection], page), guard.wrap(onResult), guard.wrap(onError)));
		} else if (mode == "favorites") {
			guard.watch(LevelBrowserData.favoritesFactory(LobbySession.userId, page, LobbySession.token, guard.wrap(onResult), guard.wrap(onError)));
		} else {
			var cached:Dynamic = mode == "campaign" ? Memory.get("campaignInfo" + page) : null;
			if (cached != null) onResult(new LevelListResult(cast cached, true));
			else guard.watch(LevelBrowserData.fetchFactory(mode, page, guard.wrap(onResult), guard.wrap(onError)));
		}
	}
	private function onResult(result:LevelListResult):Void {
		if (!result.hashValid) { onError("Invalid list"); return; }
		loading = false;
		if (mode == "campaign") Memory.set("campaignInfo" + page, result.levels);
		for (info in result.levels) {
			var card = new MobileLevelCard(info); cards.push(card);
			card.onChange = function() entryChanged(card);
		}
		selected = cards.length == 0 ? null : cards[0];
		status = cards.length == 0 ? "No courses found." : "";
		redraw(); LobbySocket.write("set_right_room`" + (mode == "favorites" ? "search" : mode));
	}
	private function onError(_:String):Void { loading = false; failed = true; status = "Couldn’t load courses. Try again."; redraw(); }
	private function entryChanged(card:MobileLevelCard):Void {
		if (removed) return;
		if (card.room.localSlot >= 0 && raceCard != card) {
			stopRace(); selected = raceCard = card; browsing = false; picker = "";
			race = new RaceEntryFlow(card.room.play, leaveRace, redraw); stateChanged();
		}
		redraw();
	}
	private function stopRace():Void { if (race != null) race.remove(); race = null; raceCard = null; }
	public function leaveRace():Void {
		var card = raceCard; stopRace();
		if (card != null) card.room.leave(); redraw(); stateChanged();
	}
	private function join():Void {
		if (selected == null || selected.access() != Open) return;
		for (i in 0...4) if (selected.room.slots[i].name == "") { selected.room.join(i); return; }
	}
	private function stateChanged():Void { if (onState != null) onState(); }
	private function highlight(args:Array<String>, value:Bool):Void {
		if (args.length == 0 || mode == "search" || mode == "favorites") return;
		var n = Std.parseInt(args[0]); if (n == null) return; highlights.set(n, value); redraw();
	}
	private function clearEntries():Void {
		stopRace(); for (card in cards) card.remove(); cards = []; selected = null;
	}
	private function resetView():Void {
		if (list != null) list.remove(); list = null;
		if (detail != null) detail.remove(); detail = null;
		clear();
	}
	private function redraw():Void {
		if (removed) return;
		var key = '$mode:$page:$browsing:$racing:$picker:' + (selected == null ? "" : Std.string(selected.info.levelId));
		var scroll = list == null || key != lastViewKey ? 0 : list.content.y;
		var detailScroll = detail == null || key != lastViewKey ? 0 : detail.content.y;
		lastViewKey = key;
		resetView();
		if (picker != "") { renderPicker(); return; }
		if (race != null) renderRace(); else if (browsing) renderBrowse(); else renderPlay();
		if (list != null) list.setOffset(scroll);
		if (detail != null) detail.setOffset(detailScroll);
	}
	private function collectionLabel():String { var n = MODES.indexOf(mode); return n < 0 ? "Search results" : LABELS[n]; }
	private function renderPlay():Void {
		var narrow = viewW < 570;
		var leftW = narrow ? viewW : Math.floor((viewW - 16) * .475);
		if (!narrow || !narrowDetail) {
			panel(0, 0, leftW, viewH);
			button(collectionLabel(), 14, 14, leftW - 152, browse, true);
			button("Browse", leftW - 130, 14, 116, browse);
			renderList(14, 68, leftW - 28, viewH - 130, false);
			paging(14, viewH - 58, leftW - 28);
		}
		if (!narrow || narrowDetail) {
			var x = narrow ? 0 : leftW + 16;
			renderDetails(x, viewW - x, narrow);
		}
	}
	private function renderList(x:Float, y:Float, w:Float, h:Float, openResult:Bool):Void {
		list = new MobileScrollPane(); list.x = x; list.y = y; addChild(list);
		if (cards.length == 0) {
			list.content.label(failed ? "Couldn’t load courses." : status, 8, 0, w - 16, failed ? 30 : 68, 16);
			if (failed) list.content.button("Retry", 8, 34, Math.min(150, w - 16), request, true);
		}
		for (i in 0...cards.length) {
			var card = cards[i]; var info = card.info;
			var b = list.content.button("", 0, i * 88, w, function() {
				selected = card; narrowDetail = true;
				if (openResult) { browsing = false; stateChanged(); }
				redraw();
			}, false, 78);
			b.selected = selected == card; b.name = "level_" + info.levelId;
			list.content.singleLine(info.title, 10, i * 88 + 5, w - 20, 27, 18);
			list.content.singleLine("by " + info.userName, 10, i * 88 + 29, w - 20, 22, 14, false, 0x50687A);
			list.content.label('Rating ${Math.round(info.rating * 10) / 10}   Rank ${info.minLevel}+   ${card.room.count()}/4 racers', 10, i * 88 + 51, w - 20, 24, 13, false, 0x0B519E);
		}
		list.setSize(w, h, cards.length == 0 ? 140 : cards.length * 88);
	}
	private function paging(x:Float, y:Float, w:Float):Void {
		var max = mode == "search" && searchMode == 2 ? 1 : LevelBrowserData.pageCount(mode);
		button("‹", x, y, 44, function() pageTo(page - 1)).enabled = !loading && page > 1;
		button("›", x + w - 44, y, 44, function() pageTo(page + 1)).enabled = !loading && page < max;
		var active = []; for (n in 1...max + 1) if (highlights.exists(n) && highlights[n]) active.push(n);
		var text = 'PAGE $page / $max'; if (active.length > 0) text += "\nRacers: " + active.join(", ");
		var t = label(text, x + 52, y + 3, w - 104, 40, 13);
		var f = t.defaultTextFormat; f.align = "center"; t.setTextFormat(f);
	}
	private function renderDetails(x:Float, w:Float, narrow:Bool):Void {
		panel(x, 0, w, viewH);
		if (selected == null) { label("Pick a course", x + 18, 20, w - 36, 42, 28, true); label("Choose a level to see its rules and join a race.", x + 18, 78, w - 36, 100); return; }
		var card = selected; var info = card.info;
		detail = new MobileScrollPane(); detail.x = x + 16; detail.y = 10; addChild(detail);
		var v = detail.content; var width = w - 32; var offset:Float = narrow ? 52 : 0;
		if (narrow) v.button("‹ Courses", 0, 0, 140, function() { narrowDetail = false; redraw(); });
		var heading = v.label(info.title, 0, offset, width, 72, 28, true);
		heading.height = Math.max(34, heading.textHeight + 4);
		offset += Math.max(0, heading.height - 34);
		v.button("by " + info.userName, 0, offset + 36, width, function() LobbyPopups.showPlayer(info.userName));
		v.label(modeName(info.type) + '   •   Rank ${info.minLevel}+\nRating ${Math.round(info.rating * 10) / 10}   •   ${card.room.count()} / 4 racers', 0, offset + 86, width, 48, 16);
		var gap = 8; var bw = (width - gap * 2) / 3;
		v.button("Rules", 0, offset + 136, bw, function() { picker = "rules"; redraw(); });
		var fav = v.button(LobbySession.isFavorite(info.levelId) ? "Saved" : "Favorite", bw + gap, offset + 136, bw, card.toggleFavorite);
		fav.enabled = LobbySession.isMember() && !card.favoritePending;
		v.button("More", (bw + gap) * 2, offset + 136, bw, function() LobbyPopups.showLevel(Std.string(info.levelId)));
		var state = card.access(); var yy:Float = offset + 188;
		if (state == PassNeeded) {
			v.label(card.message == "" ? "This course needs a password." : card.message, 0, yy, width, 44, 14); yy += 48;
			var input = v.own(new AuthInput(card.passwordDraft)); input.name = "levelPassword"; input.displayAsPassword = true; input.y = yy; input.setSize(width - 110, 46); input.enabled = !card.passPending;
			input.addEventListener(Event.CHANGE, function(_) card.passwordDraft = input.text);
			v.button("Unlock", width - 102, yy, 102, function() { var p = input.text; input.text = ""; card.unlock(p); }, true).enabled = !card.passPending; yy += 56;
		} else {
			var pending = card.room.pendingSlot >= 0;
			var title = state != Open ? LevelAccess.coverText(state) : pending ? "Joining…" : card.room.count() >= 4 ? "Race is full" : "JOIN RACE ›";
			v.button(title, 0, yy, width, join, true, 54).enabled = state == Open && !pending && card.room.count() < 4; yy += 62;
			if (pending) { v.button("Cancel join", 0, yy, width, card.room.leave); yy += 52; }
			if (card.message != "") { v.label(card.message, 0, yy, width, 50, 14); yy += 54; }
		}
		detail.setSize(width, viewH - 16, yy + 4);
	}
	private function renderBrowse():Void {
		var side = viewW < 570 ? 0.0 : Math.max(156, viewW * .30);
		if (side > 0) {
			panel(0, 0, side, viewH);
			detail = new MobileScrollPane(); detail.x = 12; detail.y = 14; addChild(detail);
			var n = LobbySession.isMember() ? 5 : 4;
			for (i in 0...n) { var key = MODES[i]; detail.content.button(LABELS[i], 0, i * 52, side - 24, function() showMode(key)).selected = mode == key; }
			detail.setSize(side - 24, viewH - 24, n * 52);
		}
		var x = side > 0 ? side + 16 : 0; var w = viewW - x; panel(x, 0, w, viewH);
		var yy:Float = 14;
		if (side == 0) { button("Collections", x + 14, yy, w - 28, function() { picker = "collections"; redraw(); }); yy += 54; }
		var input = own(new AuthInput(query)); input.name = "levelSearch"; input.x = x + 14; input.y = yy; input.setSize(w - 134, 46); input.maxChars = 50;
		input.addEventListener(Event.CHANGE, function(_) { query = input.text; rememberSearch(); });
		input.textField.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) { if (e.keyCode == 13) search(); });
		button("Search", x + w - 112, yy, 98, search, true); yy += 54;
		var bw = (w - 44) / 3;
		button(SEARCH_LABELS[searchMode] + " ▾", x + 14, yy, bw, function() { picker = "mode"; redraw(); });
		button(ORDER_LABELS[searchOrder] + " ▾", x + 22 + bw, yy, bw, function() { picker = "order"; redraw(); });
		button(searchDirection == 0 ? "Descending ▾" : "Ascending ▾", x + 30 + bw * 2, yy, bw, function() { picker = "direction"; redraw(); }); yy += 54;
		renderList(x + 14, yy, w - 28, Math.max(60, viewH - yy - 66), true);
		paging(x + 14, viewH - 58, w - 28);
	}
	private function renderPicker():Void {
		panel(0, 0, viewW, viewH);
		button("‹ Back", viewW - 126, 14, 112, function() { picker = ""; redraw(); });
		if (picker == "rules") {
			label("Course rules", 16, 14, viewW - 158, 40, 28, true);
			detail = new MobileScrollPane(); detail.x = 16; detail.y = 70; addChild(detail);
			var info = selected.info;
			var text = modeName(info.type) + '\nMinimum rank: ${info.minLevel}\n' + (info.pass ? "Password protected\n" : "") + (info.badHats.length > 0 ? "Disallowed hat IDs: " + info.badHats.join(", ") + "\n" : "") + '\n${info.note}';
			var field = detail.content.label(text, 0, 0, viewW - 32, 1000, 18);
			detail.setSize(viewW - 32, viewH - 86, field.textHeight + 12); return;
		}
		var title = picker == "mode" ? "Search by" : picker == "order" ? "Sort by" : picker == "direction" ? "Sort direction" : "Collections";
		label(title, 16, 14, viewW - 158, 40, 28, true);
		var labels = picker == "mode" ? SEARCH_LABELS : picker == "order" ? ORDER_LABELS : picker == "direction" ? ["Descending", "Ascending"] : LABELS.slice(0, LobbySession.isMember() ? 5 : 4);
		for (i in 0...labels.length) {
			var index = i; var column = viewW >= 570 ? i % 2 : 0; var row = viewW >= 570 ? Std.int(i / 2) : i;
			var w = viewW >= 570 ? (viewW - 48) / 2 : viewW - 32;
			button(labels[i], 16 + column * (w + 16), 72 + row * 54, w, function() {
				if (picker == "collections") { picker = ""; showMode(MODES[index]); return; }
				if (picker == "mode") searchMode = index; else if (picker == "order") searchOrder = index; else searchDirection = index;
				rememberSearch(); picker = ""; redraw();
			});
		}
	}
	private function renderRace():Void {
		var left = (viewW - 16) * .55; var rightX = left + 16; var right = viewW - rightX;
		panel(0, 0, left, viewH); panel(rightX, 0, right, viewH);
		list = new MobileScrollPane(); list.x = 16; list.y = 12; addChild(list);
		var roster = list.content;
		roster.singleLine(raceCard.info.title, 0, 0, left - 32, 40, 26, true);
		for (i in 0...4) {
			var slot = raceCard.room.slots[i]; var index = i;
			var text = slot.name == "" ? '${i + 1}   Waiting for a racer…' : '${i + 1}   ${slot.name}' + (slot.me ? " (you)" : "") + '   •   Rank ${slot.rank}' + (slot.ready ? "   Ready" : "");
			var b = roster.button(text, 0, 46 + i * 52, left - 32, function() {
				if (slot.name == "") raceCard.room.join(index); else LobbyPopups.showPlayer(slot.name);
			});
			b.selected = slot.me;
			var format = b.labelField.defaultTextFormat; format.font = "Nunito Bold"; format.size = 15; b.labelField.setTextFormat(format);
		}
		list.setSize(left - 32, viewH - 24, 252);
		detail = new MobileScrollPane(); detail.x = rightX + 16; detail.y = 12; addChild(detail);
		var ready = detail.content;
		ready.label('${raceCard.room.count()} / 4 racers', 0, 0, right - 32, 40, 28, true);
		ready.label(race.confirmed ? "Waiting for the server…" : "Get ready to race!", 0, 50, right - 32, 38, 16, false, 0x50687A);
		ready.label(race.countdown == "" ? "--" : race.countdown, 0, 88, right - 32, 62, 46, true, 0x0B519E);
		ready.label(race.confirmed ? "Your Play request was sent." : "Press Play to confirm you’re ready.", 0, 152, right - 32, 40, 15);
		ready.button(race.confirmed ? "Waiting…" : "PLAY!", 0, 198, right - 32, race.play, true, 54).enabled = !race.confirmed;
		detail.setSize(right - 32, viewH - 24, 258);
	}
	private static function modeName(type:String):String return switch (type) { case "d": "Deathmatch"; case "e": "Egg mode"; case "o": "Objective"; case "h": "Hat attack"; default: "Race"; }
	override public function remove():Void {
		removed = true; guard.remove(); clearEntries(); resetView();
		var cm = CommandHandler.commandHandler; cm.defineCommand("testLevelAccess", null); cm.defineCommand("addPageHighlight", null); cm.defineCommand("removePageHighlight", null);
		LobbySocket.write("set_right_room`none"); onState = null; super.remove();
	}
}
