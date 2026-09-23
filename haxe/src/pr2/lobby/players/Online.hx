package pr2.lobby.players;

/** Classic roster presentation backed by the shared directory transport. */
class Online extends PlayersTabList {
	private var source:DirectorySource;
	override public function initialize():Void {
		super.initialize();
		source = new DirectorySource();
		source.start("online", function(entry) addUserEntry(entry.name, entry.group, entry.rank, entry.hats), hideLoadingGraphic, function(_) hideLoadingGraphic());
	}
	override public function remove():Void {
		if (source != null) source.remove(); source = null;
		super.remove();
	}
}
