package pr2.app;

import pr2.mobile.MobileLevelBrowser;
import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.lobby.SecureData;
import pr2.lobby.level.LevelBrowserData;
import pr2.lobby.level.LevelLaunch;
import pr2.lobby.level.LevelActions;
import pr2.net.CampaignLevelInfo;
import pr2.net.CommandHandler;
import pr2.net.LevelListClient.LevelListResult;
import pr2.net.LobbySocket;

/** Actual mobile UI lifecycle driven through the same callbacks/socket dispatcher as production. */
@:access(pr2.mobile.MobileLevelBrowser)
class MobileLobbyFlowTest {
	public static function run():Void {
		var oldFetch = LevelBrowserData.fetchFactory; var oldSearch = LevelBrowserData.searchFactory;
		var oldFavorites = LevelBrowserData.favoritesFactory; var oldPass = LevelActions.passPostFactory;
		Memory.clear(); LobbySession.group = 0; LobbySession.userName = "TestRacer"; SecureData.setNumber("userRank", 20);
		var pending:Array<LevelListResult->Void> = []; var removals = 0;
		LevelBrowserData.fetchFactory = function(mode, page, done, error) { pending.push(done); return {remove:function() removals++}; };
		var searchParams:Map<String,String> = null;
		LevelBrowserData.searchFactory = function(params, done, error) { searchParams = params; pending.push(done); return {remove:function() removals++}; };
		var favoriteUser = -1;
		LevelBrowserData.favoritesFactory = function(id, page, token, done, error) { favoriteUser = id; pending.push(done); return {remove:function() removals++}; };
		var browser = new MobileLevelBrowser();
		check(browser.loading, "list begins loading");
		browser.showMode("newest");
		pending[0](new LevelListResult([level(1)], true));
		check(browser.cards.length == 0 && removals > 0, "late response from abandoned collection is ignored");
		pending[1](new LevelListResult([level(42), level(43)], true));
		check(browser.cards.length == 2 && !browser.loading, "real result callback renders selectable levels");
		browser.setLayout(635, 269);
		check(browser.selected.info.levelId == 42, "resize preserves selection and room");
		browser.pageTo(10); check(browser.page == 1, "listing cannot page beyond the original nine pages");
		browser.showSearch("42", "id");
		check(searchParams["mode"] == "id" && searchParams["page"] == "1", "level lookup sets ID mode and first page");
		var count = pending.length; browser.pageTo(2); check(pending.length == count, "ID lookup has no next page");
		browser.searchMode = 0; browser.searchOrder = 3; browser.searchDirection = 1; browser.query = "Creator"; browser.search();
		check(searchParams["mode"] == "user" && searchParams["order"] == "popularity" && searchParams["dir"] == "asc", "search sends chosen mode, sort and direction");
		pending[pending.length - 1](new LevelListResult([level(42)], false));
		check(browser.failed && browser.cards.length == 0, "bad list hash yields retry state, no playable courses");
		browser.request(); pending[pending.length - 1](new LevelListResult([level(42)], true)); browser.back();
		LobbySocket.resetSent(); browser.join();
		check(LobbySocket.lastSent() == "fill_slot`42_1`0`1", "join uses the real version, slot and listing page");
		check(!browser.racing, "join waits for server slot acknowledgement");
		var cm = CommandHandler.commandHandler;
		cm.dispatch("fillSlot42_1", ["0", "TestRacer", "20", "me"]);
		check(browser.racing && browser.raceCard.room.localSlot == 0, "server acknowledgement opens race entry");
		cm.dispatch("fillSlot42_1", ["1", "Other", "12", ""]);
		check(browser.raceCard.room.count() == 2, "live participant fills update the roster");
		cm.dispatch("confirmSlot42_1", ["1"]); check(browser.raceCard.room.slots[1].ready, "roster readiness is server driven");
		var launches = 0; var oldLaunch = LevelLaunch.handler; LevelLaunch.handler = function(id, version) launches++;
		browser.race.play(); check(launches == 0 && LobbySocket.lastSent() == "confirm_slot`", "Play sends confirmation without launching locally");
		cm.dispatch("forceTime", ["15"]); check(browser.race.countdown == "0", "shared countdown matches classic first tick");
		browser.race.tick(); check(LobbySocket.lastSent() == "force_start`", "timer expiry requests server start");
		browser.leaveRace(); check(!browser.racing && LobbySocket.lastSent() == "clear_slot`", "Leave releases the real slot");
		cm.dispatch("fillSlot42_1", ["0", "TestRacer", "20", "me"]);
		check(!browser.racing, "late slot acknowledgement cannot undo cancellation");
		cm.dispatch("startGame", ["42"]); check(launches == 0, "late game start after leaving cannot launch");
		browser.join(); cm.dispatch("fillSlot42_1", ["0", "TestRacer", "20", "me"]);
		cm.dispatch("clearSlot42_1", ["0"]);
		cm.dispatch("startGame", ["42"]); check(launches == 1, "selected course starts only on server command");
		browser.leaveRace(); LevelLaunch.handler = oldLaunch;
		browser.showMode("favorites"); check(browser.mode == "campaign" && favoriteUser == -1, "guests cannot request favorites");
		LobbySession.group = 1; LobbySession.userId = 12; browser.showMode("favorites"); check(favoriteUser == 12, "member favorites use authenticated endpoint");
		pending[pending.length - 1](new LevelListResult([new CampaignLevelInfo(99, 1, "Locked", "Author", 0, 5, 0, "1", "", true)], true));
		var card = browser.cards[0];
		var respond:String->Void = null; var passFields:Map<String,String> = null;
		LevelActions.passPostFactory = function(url, fields, done, error) { passFields = fields; respond = done; return {remove:function() {}}; };
		card.unlock("test-password");
		check(card.passPending && passFields["hash"] != "test-password", "password uses shared salted hash and pending state");
		respond('{"success":false}'); check(!card.passPending && card.message.indexOf("Incorrect") >= 0, "bad password can be retried");
		card.unlock("retry");
		var encrypted = pr2.crypto.PR2Encryptor.encryptBase64('{"level_id":99,"access":1}', pr2.net.ServerConfig.LEVEL_PASS_KEY, pr2.net.ServerConfig.LEVEL_PASS_IV);
		respond(haxe.Json.stringify({success:true, result:encrypted}));
		check(card.access() == Open && !card.passPending, "valid encrypted response unlocks the selected course");
		var transport = new LobbyTestTransport(); var oldTransport = pr2.net.SuperLoader.transportFactory;
		pr2.net.SuperLoader.transportFactory = function() return transport;
		card.toggleFavorite(); check(card.favoritePending, "favorite request enters pending state");
		transport.complete('{"success":true,"mode":"add"}');
		check(LobbySession.isFavorite(99) && !card.favoritePending, "favorite changes only after successful response");
		card.toggleFavorite(); transport.complete('{"success":false,"error":"Denied"}');
		check(LobbySession.isFavorite(99) && !card.favoritePending, "failed removal keeps the favorite and permits retry");
		card.toggleFavorite(); browser.remove(); transport.complete('{"success":true,"mode":"remove"}');
		check(LobbySession.isFavorite(99), "late favorite response cannot mutate a removed flow");
		pr2.net.SuperLoader.transportFactory = oldTransport;
		check(!cm.hasCommand("fillSlot99_1") && !cm.hasCommand("forceTime"), "teardown removes room and countdown handlers");
		LevelBrowserData.fetchFactory = oldFetch; LevelBrowserData.searchFactory = oldSearch; LevelBrowserData.favoritesFactory = oldFavorites; LevelActions.passPostFactory = oldPass;
		Memory.clear(); LobbySession.clear();
		trace("MobileLobbyFlowTest passed");
	}
	private static function level(id:Int):CampaignLevelInfo return new CampaignLevelInfo(id, 1, 'Course $id', "Author", 0, 4.5, 100);
	private static function check(value:Bool, message:String):Void if (!value) throw message;
}

private class LobbyTestTransport extends openfl.events.EventDispatcher {
	public var data:Dynamic;
	public var dataFormat:Dynamic;
	public function new() super();
	public function load(request:openfl.net.URLRequest):Void {}
	public function close():Void {}
	public function complete(body:String):Void { data = body; dispatchEvent(new openfl.events.Event(openfl.events.Event.COMPLETE)); }
}
