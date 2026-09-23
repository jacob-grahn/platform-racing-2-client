package pr2.app;

import pr2.lobby.LobbySession;
import pr2.lobby.players.DirectorySource;
import pr2.mobile.MobilePlayersPage;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.ui.TabsHolder;

@:access(pr2.mobile.MobilePlayersPage)
class MobilePlayersTest {
	static var replies:Array<String->Void> = [];
	static var failures:Array<String->Void> = [];
	static var urls:Array<String> = [];
	static var cancelled:Int = 0;
	static function fetch(url:String, data:String->Void, error:String->Void):pr2.util.AsyncRemovalGuard.AsyncRemovable {
		urls.push(url); replies.push(data); failures.push(error); return {remove:function() cancelled++};
	}
	public static function main():Void {
		var oldUsers = DirectorySource.userFetch; var oldGuilds = DirectorySource.guildFetch;
		DirectorySource.userFetch = fetch; DirectorySource.guildFetch = fetch;
		LobbySession.clear(); TabsHolder.clearMemory(); LobbySocket.resetSent();
		var page = new MobilePlayersPage(); page.initialize();
		check(page.modes.join(",") == "online,guilds", "guest destinations follow Flash");
		check(LobbySocket.lastSent() == "get_online_list`", "requests real socket roster");
		CommandHandler.commandHandler.dispatch("addUser", ["Zed", "1", "20", "3"]);
		CommandHandler.commandHandler.dispatch("addUser", ["Amy", "2,0", "20", "4"]);
		CommandHandler.commandHandler.dispatch("addUser", ["Guest", "0", "0", "1"]);
		CommandHandler.commandHandler.dispatch("addUser", ["Amy", "2", "99", "9"]);
		page.tick();
		check(page.entries.length == 3 && page.entries[0].name == "Amy", "deduplicated roster uses hats as rank tiebreak");
		page.setSort("rank"); check(page.entries[0].name == "Guest", "numeric direction toggles");
		page.setSort("userName"); check(page.entries[0].name == "Amy", "name ascending");
		page.setSort("userName"); check(page.entries[0].name == "Zed", "name descending");
		page.choose("friends"); check(page.mode == "online", "guest cannot enter member list");
		page.choose("guilds"); check(page.loading && urls[0].indexOf("guilds_top.php") >= 0, "guilds loading endpoint");
		CommandHandler.commandHandler.dispatch("addUser", ["Late", "1", "1", "1"]);
		check(page.entries.length == 0, "switch releases roster command");
		replies[0]('{"guilds":[{"guild_name":"Small","guild_id":7,"active_count":2,"gp_today":12},{"guild_name":"Big","guild_id":8,"active_count":4,"gp_today":900}]}');
		check(!page.loading && page.entries[0].guildId == 8, "guild parsing and default GP sort");
		page.setSort("activeMembers"); check(page.entries[0].name == "Big", "active member sort");
		page.setLayout(635, 269); checkLayout(page);
		page.remove(); page.remove();
		check(cancelled == 1, "guild loader removed once");
		var remembered = new MobilePlayersPage(); remembered.initialize(); check(remembered.mode == "guilds", "tab remembered on return"); remembered.remove();
		LobbySession.group = 1; TabsHolder.clearMemory();
		page = new MobilePlayersPage(); page.initialize();
		check(page.modes.join(",") == "online,friends,following,ignored", "member destinations follow Flash");
		page.choose("friends"); var pending = replies.length - 1;
		check(urls[pending].indexOf("mode=friends") >= 0, "relationship endpoint mode");
		page.choose("following"); replies[pending]('{"users":[{"name":"Stale","group":1,"rank":20,"hats":2}]}');
		check(page.entries.length == 0 && page.loading, "late response cannot cross list navigation");
		pending = replies.length - 1; failures[pending]("offline");
		check(page.error != "" && !page.loading, "transport failure offers retry");
		page.refresh(); pending = replies.length - 1; replies[pending]("bad json");
		check(page.error != "", "malformed JSON is not presented as an empty list");
		page.refresh(); pending = replies.length - 1; replies[pending]('{"users":[]}');
		check(page.error == "" && page.entries.length == 0 && !page.loading, "empty successful list");
		page.choose("ignored"); pending = replies.length - 1;
		var payload = '{"users":[{"name":"Friend","group":"1","rank":"42","hats":6,"status":"Derron"},{"name":"Friend","group":1,"rank":9,"hats":1}]}';
		replies[pending](payload); check(page.entries.length == 1 && page.entries[0].status == "Derron", "relationship status and duplicates preserved");
		page.setLayout(635,269); checkLayout(page);
		var classic = new pr2.lobby.players.PlayersUserListLoader("ignored"); classic.initialize(); replies[replies.length - 1](payload);
		check((@:privateAccess classic.listingSortNamesForTests()).join(",") == "Friend", "classic uses same parser and deduplication"); classic.remove();
		page.refresh(); pending = replies.length - 1; page.remove(); replies[pending](payload);
		check(page.entries.length == 0, "removed view ignores late replies");
		var first = new DirectorySource(); first.start("online", function(_) {}, function() {}, function(_) {});
		var received = 0; var second = new DirectorySource(); second.start("online", function(_) received++, function() {}, function(_) {});
		first.remove(); CommandHandler.commandHandler.dispatch("addUser", ["New", "1", "1", "1"]);
		check(received == 1, "old teardown does not unregister new command owner"); second.remove();
		DirectorySource.userFetch = oldUsers; DirectorySource.guildFetch = oldGuilds; LobbySession.clear(); TabsHolder.clearMemory();
		trace("MobilePlayersTest passed"); Sys.exit(0);
	}
	static function checkLayout(page:MobilePlayersPage):Void {
		for (control in page.view.controls) check(control.controlHeight >= 44 && control.x >= 0 && control.x + control.controlWidth <= 635, "compact header targets fit");
		for (control in page.pane.content.controls) check(control.controlHeight >= 44 && control.x + control.controlWidth <= page.pane.scrollRect.width, "compact row targets fit");
	}
	static function check(value:Bool, message:String):Void { if (!value) throw message; }
}
