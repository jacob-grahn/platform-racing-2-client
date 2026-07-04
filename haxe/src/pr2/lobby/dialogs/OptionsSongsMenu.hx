package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import pr2.lobby.account.Settings;
import pr2.runtime.FlCheckBox;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class OptionsSongsMenu extends AutoDismissPopup {
	public static var instance:Null<OptionsSongsMenu> = null;

	private var art:Null<PR2MovieClip>;

	public function new(target:DisplayObject) {
		if (OptionsSongsMenu.instance != null) {
			OptionsSongsMenu.instance.remove();
		}
		super();
		OptionsSongsMenu.instance = this;
		art = PR2MovieClip.fromLinkage("OptionsSongsMenuGraphic", {maxNestedDepth: 4});
		addChild(art);
		var disabled = Settings.disabledSongs();
		for (i in 1...22) {
			if (i == 9 || i == 16) {
				continue;
			}
			var check = songCheck(i);
			if (check != null) {
				check.selected = disabled.indexOf(Std.string(i)) < 0;
			}
		}
		positionNear(target);
		y -= 45;
	}

	public function setSongSelectedForTests(songId:Int, selected:Bool):Void {
		var check = songCheck(songId);
		if (check != null) {
			check.selected = selected;
		}
	}

	public function isSongSelectedForTests(songId:Int):Bool {
		var check = songCheck(songId);
		return check != null && check.selected;
	}

	override public function remove():Void {
		if (isRemoved()) {
			return;
		}
		if (OptionsSongsMenu.instance == this) {
			OptionsSongsMenu.instance = null;
		}
		var disabled:Array<Int> = [];
		for (i in 1...22) {
			if (i == 9 || i == 16) {
				continue;
			}
			var check = songCheck(i);
			if (check != null && !check.selected) {
				disabled.push(i);
			}
		}
		Settings.setValue(Settings.DISABLED_SONGS, disabled);
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private function songCheck(songId:Int):Null<FlCheckBox> {
		return art == null ? null : Std.downcast(DisplayUtil.findByName(art, "song" + songId), FlCheckBox);
	}
}
