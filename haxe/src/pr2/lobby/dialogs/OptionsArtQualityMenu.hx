package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import pr2.lobby.account.Settings;
import pr2.runtime.FlCheckBox;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class OptionsArtQualityMenu extends AutoDismissPopup {
	public static var instance:Null<OptionsArtQualityMenu> = null;

	private var art:Null<PR2MovieClip>;

	public function new(target:DisplayObject) {
		if (OptionsArtQualityMenu.instance != null) {
			OptionsArtQualityMenu.instance.remove();
		}
		super();
		OptionsArtQualityMenu.instance = this;
		art = PR2MovieClip.fromLinkage("OptionsArtQualityMenuGraphic", {maxNestedDepth: 4});
		addChild(art);
		var check = losslessCheck();
		if (check != null) {
			check.selected = Settings.getValue(Settings.ART_LOSSLESS_QUALITY, false);
		}
		positionNear(target);
	}

	public function setLosslessForTests(value:Bool):Void {
		var check = losslessCheck();
		if (check != null) {
			check.selected = value;
		}
	}

	public function isLosslessSelectedForTests():Bool {
		var check = losslessCheck();
		return check != null && check.selected;
	}

	override public function remove():Void {
		if (isRemoved()) {
			return;
		}
		if (OptionsArtQualityMenu.instance == this) {
			OptionsArtQualityMenu.instance = null;
		}
		var check = losslessCheck();
		if (check != null) {
			Settings.setValue(Settings.ART_LOSSLESS_QUALITY, check.selected);
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private function losslessCheck():Null<FlCheckBox> {
		return art == null ? null : Std.downcast(DisplayUtil.findByName(art, "lossless_chk"), FlCheckBox);
	}
}
