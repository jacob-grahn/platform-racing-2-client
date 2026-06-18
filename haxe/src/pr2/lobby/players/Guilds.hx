package pr2.lobby.players;

import haxe.Json;
import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import pr2.lobby.LobbyArt;
import pr2.lobby.players.PlayerListSort.SortState;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `social.Guilds`: the top-guilds list shown to guests. Uses the
	"guilds" frame of `PlayersTabListGraphic` (Name / Active / GP headers), loads
	`guilds_top.php`, and defaults to a descending GP-today sort.
**/
class Guilds extends PlayersListHolder {
	private static inline var NAME_MODE:String = "guildName";

	private var graphic:Null<PR2MovieClip>;
	private var nameButton:Null<DisplayObjectContainer>;
	private var activeButton:Null<DisplayObjectContainer>;
	private var gpButton:Null<DisplayObjectContainer>;
	private var sortState:SortState = {mode: "gpToday", order: "desc"};

	override public function initialize():Void {
		graphic = PR2MovieClip.fromLinkage("PlayersTabListGraphic", {maxNestedDepth: 6});
		graphic.gotoAndStop("guilds");
		addChild(graphic);
		var listHolder = Std.downcast(LobbyArt.findByName(graphic, "listHolder"), DisplayObjectContainer);
		if (listHolder != null) {
			attachHolder(listHolder);
		}
		nameButton = Std.downcast(LobbyArt.findByName(graphic, "name_bt"), DisplayObjectContainer);
		activeButton = Std.downcast(LobbyArt.findByName(graphic, "active_bt"), DisplayObjectContainer);
		gpButton = Std.downcast(LobbyArt.findByName(graphic, "gp_bt"), DisplayObjectContainer);
		if (nameButton != null) {
			nameButton.addEventListener(MouseEvent.CLICK, clickName);
		}
		if (activeButton != null) {
			activeButton.addEventListener(MouseEvent.CLICK, clickActive);
		}
		if (gpButton != null) {
			gpButton.addEventListener(MouseEvent.CLICK, clickGP);
		}
		TextLoader.load(ServerConfig.guildsTopUrl(), onData, onError);
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
