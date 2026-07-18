package pr2.lobby.players;

import haxe.Json;
import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import pr2.lobby.LobbyArt;
import pr2.lobby.players.PlayerListSort.SortState;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.DisplayUtil;

typedef GuildsFetchResource = {
	function remove():Void;
}

typedef GuildsFetchFactory = String->(String->Void)->(String->Void)->GuildsFetchResource;

/**
	Port of Flash `social.Guilds`: the top-guilds list shown to guests. Uses the
	"guilds" frame of `PlayersTabListGraphic` (Name / Active / GP headers), loads
	`guilds_top.php`, and defaults to a descending GP-today sort.
**/
class Guilds extends PlayersListHolder {
	private static inline var NAME_MODE:String = "guildName";
	public static var fetchFactory:GuildsFetchFactory = defaultFetch;

	private var graphic:Null<PlayersTabListView>;
	private var nameButton:Null<DisplayObjectContainer>;
	private var activeButton:Null<DisplayObjectContainer>;
	private var gpButton:Null<DisplayObjectContainer>;
	private var sortState:SortState = {mode: "gpToday", order: "desc"};
	private var asyncGuard:AsyncRemovalGuard = new AsyncRemovalGuard();

	override public function initialize():Void {
		graphic = new PlayersTabListView(true);
		addChild(graphic);
		var listHolder = Std.downcast(DisplayUtil.directChildByName(graphic, "listHolder"), DisplayObjectContainer);
		if (listHolder != null) {
			attachHolder(listHolder);
		}
		nameButton = Std.downcast(DisplayUtil.directChildByName(graphic, "name_bt"), DisplayObjectContainer);
		activeButton = Std.downcast(DisplayUtil.directChildByName(graphic, "active_bt"), DisplayObjectContainer);
		gpButton = Std.downcast(DisplayUtil.directChildByName(graphic, "gp_bt"), DisplayObjectContainer);
		if (nameButton != null) {
			nameButton.addEventListener(MouseEvent.CLICK, clickName);
		}
		if (activeButton != null) {
			activeButton.addEventListener(MouseEvent.CLICK, clickActive);
		}
		if (gpButton != null) {
			gpButton.addEventListener(MouseEvent.CLICK, clickGP);
		}
		asyncGuard.watch(fetchFactory(ServerConfig.guildsTopUrl(), asyncGuard.wrap(onData), asyncGuard.wrap(onError)));
	}

	private static function defaultFetch(url:String, onData:String->Void, onError:String->Void):GuildsFetchResource {
		return TextLoader.load(url, onData, onError);
	}

	private function onData(body:String):Void {
		try {
			var parsed:Dynamic = Json.parse(body);
			var guilds:Array<Dynamic> = parsed.guilds;
			if (guilds != null) {
				for (guild in guilds) {
					addListing(new GuildEntry(Std.string(guild.guild_name), intOf(guild.guild_id), intOf(guild.active_count), intOf(guild.gp_today)));
				}
			}
		} catch (error:Dynamic) {}
		applySort(sortState, NAME_MODE);
		hideLoadingGraphic();
	}

	private function onError(message:String):Void {
		hideLoadingGraphic();
	}

	private function clickName(_:MouseEvent):Void {
		setSort("guildName");
	}

	private function clickActive(_:MouseEvent):Void {
		setSort("activeMembers");
	}

	private function clickGP(_:MouseEvent):Void {
		setSort("gpToday");
	}

	private function setSort(newMode:String):Void {
		sortState = PlayerListSort.nextSort(sortState, newMode, NAME_MODE);
		applySort(sortState, NAME_MODE);
	}

	private static function intOf(value:Dynamic):Int {
		if (value == null) {
			return 0;
		}
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			return Std.int(value);
		}
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? 0 : parsed;
	}

	override public function remove():Void {
		asyncGuard.remove();
		if (nameButton != null) {
			nameButton.removeEventListener(MouseEvent.CLICK, clickName);
		}
		if (activeButton != null) {
			activeButton.removeEventListener(MouseEvent.CLICK, clickActive);
		}
		if (gpButton != null) {
			gpButton.removeEventListener(MouseEvent.CLICK, clickGP);
		}
		if (graphic != null) {
			graphic.dispose();
			graphic = null;
		}
		super.remove();
	}
}
