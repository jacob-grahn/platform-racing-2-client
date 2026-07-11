package pr2.levelEditor;

import pr2.lobby.dialogs.Popup;
import pr2.runtime.PR2MovieClip;

class LevelEditorConnectingPopup extends Popup {
	public var art(default, null):Null<PR2MovieClip>;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("ConnectingPopupGraphic", {maxNestedDepth: 4});
		addChild(art);
	}

	override public function remove():Void {
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
