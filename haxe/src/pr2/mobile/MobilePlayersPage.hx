package pr2.mobile;

import openfl.events.TimerEvent;
import openfl.utils.Timer;
import pr2.lobby.LobbySession;
import pr2.lobby.NumberFormat;
import pr2.lobby.players.DirectoryEntry;
import pr2.lobby.players.DirectorySource;
import pr2.lobby.players.PlayerListSort;
import pr2.page.Page;
import pr2.ui.TabsHolder;

/** Landscape player and guild directories; profiles remain shared popup flows. */
class MobilePlayersPage extends Page {
	private var view = new LobbyView();
	private var pane = new MobileScrollPane();
	private var source:DirectorySource;
	private var entries:Array<DirectoryEntry> = [];
	private var modes:Array<String>;
	private var mode:String = "online";
	private var guildOnly:Bool;
	private var sort:pr2.lobby.players.PlayerListSort.SortState = {mode:"rank", order:"desc"};
	private var loading:Bool = false;
	private var error:String = "";
	private var dirty:Bool = false;
	private var disposedPage:Bool = false;
	private var timer:Timer;
	private var w:Float = 756;
	private var h:Float = 284;
	public function new(guildOnly:Bool = false) { super(); this.guildOnly = guildOnly; }
	override public function initialize():Void {
		addChild(view); addChild(pane);
		modes = guildOnly ? ["guilds"] : DirectorySource.modes(LobbySession.isMember());
		var selected = guildOnly ? 0 : TabsHolder.resolveSelected("playerLists", 0, modes.length);
		timer = new Timer(500); timer.addEventListener(TimerEvent.TIMER, tick); timer.start();
		choose(modes[selected < 0 ? 0 : selected]);
	}
	private function choose(value:String):Void {
		if (disposedPage || modes.indexOf(value) < 0) return;
		mode = value;
		if (!guildOnly) TabsHolder.setLastTab("playerLists", modes.indexOf(mode));
		sort = {mode:mode == "guilds" ? "gpToday" : "rank", order:"desc"};
		refresh();
	}
	private function refresh():Void {
		if (disposedPage) return;
		if (source != null) source.remove();
		entries = []; error = ""; loading = mode != "online"; pane.reset();
		source = new DirectorySource();
		source.start(mode, function(entry) { entries.push(entry); dirty = true; }, function() {
			loading = false; render();
		}, function(message) { loading = false; error = message; render(); });
		render();
	}
	private function tick(?_:TimerEvent):Void { if (dirty) render(); }
	public function setLayout(width:Float, height:Float):Void { w = width; h = height; if (modes != null) render(); }
	private function setSort(key:String):Void {
		sort = PlayerListSort.nextSort(sort, key, mode == "guilds" ? "guildName" : "userName");
		pane.reset(); render();
	}
	private function render():Void {
		if (disposedPage) return;
		dirty = false;
		PlayerListSort.apply(cast entries, sort, mode == "guilds" ? "guildName" : "userName");
		view.clear(); pane.content.clear();
		var guild = mode == "guilds";
		if (guildOnly) view.label("TOP GUILDS", 4, 0, w - 8, 44, 28, true, 0xFFFFFF);
		else {
			var tabW = (w - (modes.length - 1) * 10) / modes.length;
			for (i in 0...modes.length) {
				var value = modes[i];
				view.button(title(value), i * (tabW + 10), 0, tabW, function() choose(value), value == mode);
			}
		}
		view.panel(0, 56, w, h - 56);
		var keys = guild ? ["guildName", "gpToday", "activeMembers"] : ["userName", "rank", "hats"];
		var labels = guild ? ["Name", "GP today", "Active"] : ["Name", "Rank", "Hats"];
		var sortW = (w - 36 - 100 - 24) / 3;
		for (i in 0...3) {
			var key = keys[i]; var label = labels[i] + (sort.mode == key ? sort.order == "asc" ? " ↑" : " ↓" : "");
			view.button(label, 12 + i * (sortW + 8), 68, sortW, function() setSort(key), sort.mode == key);
		}
		view.button("Refresh", w - 112, 68, 100, refresh);
		pane.x = 12; pane.y = 122;
		var v = pane.content; var width = w - 24;
		if (loading || error != "" || entries.length == 0) {
			var text = loading ? "Loading…" : error != "" ? error : mode == "online" ? "No players received yet. Refresh to request the roster again." : guild ? "No guilds to show." : "Your " + mode + " list is empty.";
			v.label(text, 8, 8, width - 16, 68, 18);
			if (error != "") v.button("Try again", 8, 80, 156, refresh, true);
			pane.setSize(width, Math.max(44, h - 134), error != "" ? 136 : 84);
		} else {
			for (i in 0...entries.length) {
				var entry = entries[i]; var y = i * 72;
				// Separate labels keep long names from reducing the touch target or hiding stats.
				v.graphics.lineStyle(1, 0xD5E2E9); v.graphics.moveTo(8, y + 68); v.graphics.lineTo(width - 8, y + 68);
				var color = guild ? 0x18334B : Std.parseInt("0x" + pr2.lobby.chat.HtmlNameMaker.groupColor(entry.group));
				v.singleLine(entry.name, 8, y + 1, width - 116, 30, 22, true, color == null ? 0x18334B : color);
				var details = guild ? NumberFormat.withCommas(entry.gpToday) + " GP today  •  " + entry.activeMembers + " active" : "Rank " + entry.rank + "  •  " + entry.hats + " hats" + (entry.status == "" ? "" : "  •  " + entry.status);
				v.singleLine(details, 8, y + 33, width - 116, 28, 16);
				v.button("View", width - 100, y + 8, 92, function() entry.open(guild));
			}
			pane.setSize(width, Math.max(44, h - 134), entries.length * 72);
		}
	}
	private static function title(value:String):String return value.charAt(0).toUpperCase() + value.substr(1);
	override public function remove():Void {
		if (disposedPage) return;
		disposedPage = true;
		if (source != null) source.remove(); source = null;
		if (timer != null) { timer.stop(); timer.removeEventListener(TimerEvent.TIMER, tick); timer = null; }
		pane.remove(); view.remove(); super.remove();
	}
}
