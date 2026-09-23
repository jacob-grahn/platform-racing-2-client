package pr2.lobby.players;

typedef PlayersUserListFetchResource = pr2.util.AsyncRemovalGuard.AsyncRemovable;
typedef PlayersUserListFetchFactory = pr2.lobby.players.DirectorySource.DirectoryFetch;

/** Classic relationship lists share transport, parsing, and cancellation with mobile. */
class PlayersUserListLoader extends PlayersTabList {
	public static var fetchFactory(get, set):PlayersUserListFetchFactory;
	private static function get_fetchFactory():PlayersUserListFetchFactory return DirectorySource.userFetch;
	private static function set_fetchFactory(value:PlayersUserListFetchFactory):PlayersUserListFetchFactory return DirectorySource.userFetch = value;
	private var mode:String;
	private var source:DirectorySource;
	public function new(mode:String) { super(); this.mode = mode; }
	override public function initialize():Void {
		super.initialize(); source = new DirectorySource();
		source.start(mode, function(entry) addUserEntry(entry.name, entry.group, entry.rank, entry.hats, entry.status), hideLoadingGraphic, function(_) hideLoadingGraphic());
	}
	override public function remove():Void {
		if (source != null) source.remove(); source = null;
		super.remove();
	}
}
