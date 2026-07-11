package pr2.levelEditor;

import pr2.lobby.dialogs.Popup;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class ChooseLevelsModePopup extends Popup {
	public final art:PR2MovieClip;
	private var bindings:Array<Binding> = [];

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("ChooseLevelsModePopupGraphic", {maxNestedDepth: 5});
		addChild(art);
		bind("reports_bt", clickReports);
		bind("mine_bt", clickMine);
		bind("cancel_bt", function():Void startFadeOut());
	}

	private function clickReports():Void {
		new GetReportedLevelsPopup();
		startFadeOut();
	}

	private function clickMine():Void {
		new GetLevelsPopup();
		startFadeOut();
	}

	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.findByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	override public function remove():Void {
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		art.dispose();
		super.remove();
	}
}
