package pr2.levelEditor;

import openfl.display.DisplayObject;
import pr2.level.BlockType;

/** Coordinates mutually exclusive editor settings and block-option popups. */
@:access(pr2.levelEditor.LevelEditor)
class LevelEditorPopupController {
	private final owner:LevelEditor;

	public function new(owner:LevelEditor) {
		this.owner = owner;
	}

	public function openBlockOptions(block:EditorBlockObject):Void {
		owner.lastBlockOptionsRequest = block;
		closeBlockOptionsPopup();
		if (block.type == BlockType.Happy || block.type == BlockType.Sad) {
			owner.activeBlockOptionsPopup = new EditorStatBlockOptionsPopup(owner, block);
		} else if (block.type == BlockType.Item || block.type == BlockType.InfiniteItem) {
			owner.activeBlockOptionsPopup = new EditorItemBlockOptionsPopup(owner, block);
		} else if (block.type == BlockType.Teleport) {
			owner.activeBlockOptionsPopup = new EditorTeleportBlockOptionsPopup(owner, block);
		} else if (block.type == BlockType.CustomStats) {
			owner.activeBlockOptionsPopup = new EditorCustomStatsBlockOptionsPopup(owner, block);
		}
	}

	public function closeBlockOptionsPopup():Void {
		if (owner.activeBlockOptionsPopup != null) {
			var popup = owner.activeBlockOptionsPopup;
			owner.activeBlockOptionsPopup = null;
			popup.remove();
		}
	}

	public function blockOptionsPopupRemoved(popup:EditorBlockOptionsPopup):Void {
		if (owner.activeBlockOptionsPopup == popup) {
			owner.activeBlockOptionsPopup = null;
		}
	}

	public function openItemSettingsMenu(target:DisplayObject):Void {
		closeHatsSettingsPopup();
		closeMusicSettingsPopup();
		closeModeSettingsPopup();
		closeValueSettingsPopup();
		closeItemSettingsPopup();
		owner.activeItemSettingsPopup = new EditorItemSettingsPopup(owner, target);
	}

	public function closeItemSettingsPopup():Void {
		if (owner.activeItemSettingsPopup != null) {
			var popup = owner.activeItemSettingsPopup;
			owner.activeItemSettingsPopup = null;
			popup.remove();
		}
	}

	public function itemSettingsPopupRemoved(popup:EditorItemSettingsPopup):Void {
		if (owner.activeItemSettingsPopup == popup) {
			owner.activeItemSettingsPopup = null;
		}
	}

	public function openHatsSettingsMenu(target:DisplayObject):Void {
		closeItemSettingsPopup();
		closeMusicSettingsPopup();
		closeModeSettingsPopup();
		closeValueSettingsPopup();
		closeHatsSettingsPopup();
		owner.activeHatsSettingsPopup = new EditorHatsSettingsPopup(owner, target);
	}

	public function closeHatsSettingsPopup():Void {
		if (owner.activeHatsSettingsPopup != null) {
			var popup = owner.activeHatsSettingsPopup;
			owner.activeHatsSettingsPopup = null;
			popup.remove();
		}
	}

	public function hatsSettingsPopupRemoved(popup:EditorHatsSettingsPopup):Void {
		if (owner.activeHatsSettingsPopup == popup) {
			owner.activeHatsSettingsPopup = null;
		}
	}

	public function openMusicSettingsMenu(target:DisplayObject):Void {
		closeItemSettingsPopup();
		closeHatsSettingsPopup();
		closeModeSettingsPopup();
		closeValueSettingsPopup();
		closeMusicSettingsPopup();
		owner.activeMusicSettingsPopup = new EditorMusicSettingsPopup(owner, target);
	}

	public function closeMusicSettingsPopup():Void {
		if (owner.activeMusicSettingsPopup != null) {
			var popup = owner.activeMusicSettingsPopup;
			owner.activeMusicSettingsPopup = null;
			popup.remove();
		}
	}

	public function musicSettingsPopupRemoved(popup:EditorMusicSettingsPopup):Void {
		if (owner.activeMusicSettingsPopup == popup) {
			owner.activeMusicSettingsPopup = null;
		}
	}

	public function openModeSettingsMenu(target:DisplayObject):Void {
		closeItemSettingsPopup();
		closeHatsSettingsPopup();
		closeMusicSettingsPopup();
		closeValueSettingsPopup();
		closeModeSettingsPopup();
		owner.activeModeSettingsPopup = new EditorModeSettingsPopup(owner, target);
	}

	public function closeModeSettingsPopup():Void {
		if (owner.activeModeSettingsPopup != null) {
			var popup = owner.activeModeSettingsPopup;
			owner.activeModeSettingsPopup = null;
			popup.remove();
		}
	}

	public function modeSettingsPopupRemoved(popup:EditorModeSettingsPopup):Void {
		if (owner.activeModeSettingsPopup == popup) {
			owner.activeModeSettingsPopup = null;
		}
	}

	public function openValueSettingsMenu(settingId:String, target:DisplayObject):Void {
		closeItemSettingsPopup();
		closeHatsSettingsPopup();
		closeMusicSettingsPopup();
		closeModeSettingsPopup();
		closeValueSettingsPopup();
		owner.activeValueSettingsPopup = new EditorValueSettingsPopup(owner, target, settingId);
	}

	public function closeValueSettingsPopup():Void {
		if (owner.activeValueSettingsPopup != null) {
			var popup = owner.activeValueSettingsPopup;
			owner.activeValueSettingsPopup = null;
			popup.remove();
		}
	}

	public function valueSettingsPopupRemoved(popup:EditorValueSettingsPopup):Void {
		if (owner.activeValueSettingsPopup == popup) {
			owner.activeValueSettingsPopup = null;
		}
	}

	public function openBrushSizeMenu(target:EditorBrushSizePickerButton):Void {
		closeBrushSizeMenu();
		owner.activeBrushSizeMenu = new EditorBrushSizePickerMenu(owner, target);
		owner.addChild(owner.activeBrushSizeMenu);
	}

	public function closeBrushSizeMenu():Void {
		if (owner.activeBrushSizeMenu != null) {
			var menu = owner.activeBrushSizeMenu;
			owner.activeBrushSizeMenu = null;
			menu.remove();
		}
	}

	public function brushSizeMenuRemoved(menu:EditorBrushSizePickerMenu):Void {
		if (owner.activeBrushSizeMenu == menu) {
			owner.activeBrushSizeMenu = null;
		}
	}

}
