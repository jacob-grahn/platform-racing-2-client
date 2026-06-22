package pr2.page;

import pr2.audio.AudioManager;

/** Real in-session level page entered only after the server sends `startGame`. */
class GamePage extends Page {
	public final levelId:Int;
	public final version:Int;
	private var level:Null<CampaignTestScreen>;

	public function new(levelId:Int, version:Int) {
		super();
		this.levelId = levelId;
		this.version = version;
	}

	override public function initialize():Void {
		AudioManager.leaveMenu();
		level = new CampaignTestScreen(null, Std.string(levelId), version);
		addChild(level);
	}

	override public function remove():Void {
		if (level != null) {
			level.remove();
			level = null;
		}
		super.remove();
	}
}
