package pr2.levelEditor;

import openfl.events.Event;
import pr2.lobby.account.ColorPicker;
import pr2.page.EditorBlockOptions;

class EditorTeleportBlockOptionsPopup extends EditorBlockOptionsPopup {
	private var picker:ColorPicker;

	public function new(editor:LevelEditor, block:EditorBlockObject) {
		super(editor, block, "TeleportBlockOptionsGraphic");
		picker = new ColorPicker();
		picker.name = "colorPicker";
		picker.width = 30;
		picker.height = 30;
		picker.x -= 15;
		picker.y += 30;
		picker.setColor(EditorBlockOptions.teleportColor(block.options));
		picker.addEventListener(Event.CHANGE, commitColor);
		addChild(picker);
	}

	public function setTeleportColor(color:Int):Void {
		picker.setColor(color);
	}

	override public function remove():Void {
		commitColor();
		picker.removeEventListener(Event.CHANGE, commitColor);
		picker.remove();
		super.remove();
	}

	private function commitColor(?_):Void {
		block.setOptions(EditorBlockOptions.applyTeleportColor(picker.getColor()));
	}
}
