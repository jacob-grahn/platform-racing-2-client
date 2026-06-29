package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.runtime.PR2MovieClip;

/**
	Authored shell for Flash `dialogs.LevelInfoPopup`.

	The full data load/report/rating/moderation flow is still porting work; this
	class owns the modal lifecycle used by level links so the route is no longer a
	record-only marker.
**/
class LevelInfoPopup extends Popup {
	public static var instance:Null<LevelInfoPopup>;

	public final levelId:Int;

	private var art:Null<PR2MovieClip>;
	private var closeBinding:Null<Binding>;

	public function new(id:Int) {
		if (LevelInfoPopup.instance != null) {
			LevelInfoPopup.instance.startFadeOut();
		}
		super();
		LevelInfoPopup.instance = this;
		levelId = id;

		art = PR2MovieClip.fromLinkage("LevelInfoPopupGraphic", {maxNestedDepth: 8});
		var levelInfo:Null<DisplayObject> = LobbyArt.findByName(art, "levelInfo");
		if (levelInfo != null) {
			levelInfo.visible = false;
		}
		addChild(art);
		closeBinding = LobbyArt.bind(LobbyArt.findByName(art, "close_bt"), startFadeOut);
	}

	override public function remove():Void {
		if (LevelInfoPopup.instance == this) {
			LevelInfoPopup.instance = null;
		}
		LobbyArt.unbind(closeBinding);
		closeBinding = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
