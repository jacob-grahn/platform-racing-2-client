package pr2.lobby.players;

import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import pr2.lobby.players.PlayerListSort.SortState;
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
	public static var fetchFactory(get, set):GuildsFetchFactory;
	private static function get_fetchFactory():GuildsFetchFactory return DirectorySource.guildFetch;
	private static function set_fetchFactory(value:GuildsFetchFactory):GuildsFetchFactory return DirectorySource.guildFetch = value;

	private var graphic:Null<PlayersTabListView>;
	private var nameButton:Null<DisplayObjectContainer>;
	private var activeButton:Null<DisplayObjectContainer>;
	private var gpButton:Null<DisplayObjectContainer>;
	private var sortState:SortState = {mode: "gpToday", order: "desc"};
	private var source:DirectorySource;

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
		source = new DirectorySource();
		source.start("guilds", function(entry) addListing(new GuildEntry(entry.name, entry.guildId, entry.activeMembers, entry.gpToday)), function() {
			applySort(sortState, NAME_MODE); hideLoadingGraphic();
		}, function(_) hideLoadingGraphic());
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

	override public function remove():Void {
		if (source != null) source.remove(); source = null;
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
