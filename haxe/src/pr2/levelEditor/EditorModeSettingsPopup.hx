package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.app.AppStage;
import pr2.gameplay.Modes;
import pr2.lobby.dialogs.AutoDismissController;
import pr2.runtime.FlComboBox;
import pr2.runtime.PR2MovieClip;
import pr2.ui.StageFocus;
import pr2.util.DisplayUtil;

class EditorModeSettingsPopup extends Sprite {
	public final editor:LevelEditor;
	public final art:PR2MovieClip;
	public final dropdown:Null<FlComboBox>;
	private var autoDismiss:Null<AutoDismissController>;
	private var removed:Bool = false;
	private var dropdownOpen:Bool = false;

	public function new(editor:LevelEditor, target:DisplayObject) {
		super();
		this.editor = editor;
		art = PR2MovieClip.fromLinkage("ModeMenuGraphic", {maxNestedDepth: 6});
		addChild(art);
		dropdown = Std.downcast(DisplayUtil.findByName(art, "modeSelect"), FlComboBox);
		if (dropdown != null) {
			var hasRoguelike = false;
			for (i in 0...dropdown.length) {
				if (Std.string(Reflect.field(dropdown.dataProvider.getItemAt(i), "data")) == Modes.roguelike) {
					hasRoguelike = true;
					break;
				}
			}
			if (!hasRoguelike) {
				dropdown.addItem({label: "Roguelike", data: Modes.roguelike});
			}
			selectMode(editor.gameMode);
			dropdown.addEventListener(Event.OPEN, openDropdown);
			dropdown.addEventListener(Event.CHANGE, changeMode);
			dropdown.addEventListener(Event.CLOSE, closeDropdown);
		}
		mountNear(target);
		autoDismiss = new AutoDismissController(this, remove, function() return !dropdownOpen);
	}

	public function selectedMode():String {
		return dropdown == null || dropdown.selectedItem == null ? "" : Std.string(Reflect.field(dropdown.selectedItem, "data"));
	}

	public function setSelectedMode(mode:String):Void {
		selectMode(mode);
		changeMode(null);
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (autoDismiss != null) {
			autoDismiss.remove();
			autoDismiss = null;
		}
		if (dropdown != null) {
			dropdown.removeEventListener(Event.OPEN, openDropdown);
			dropdown.removeEventListener(Event.CHANGE, changeMode);
			dropdown.removeEventListener(Event.CLOSE, closeDropdown);
		}
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.modeSettingsPopupRemoved(this);
		StageFocus.reset();
	}

	private function selectMode(mode:String):Void {
		if (dropdown == null) {
			return;
		}
		var normalized = mode == "eggs" ? "egg" : (mode == null || mode == "" ? "race" : mode);
		for (i in 0...dropdown.length) {
			var item = dropdown.dataProvider.getItemAt(i);
			if (Std.string(Reflect.field(item, "data")) == normalized) {
				dropdown.selectedIndex = i;
				return;
			}
		}
		dropdown.selectedIndex = 0;
	}

	private function changeMode(_:Event):Void {
		if (dropdown != null && dropdown.selectedItem != null) {
			editor.setGameMode(Std.string(Reflect.field(dropdown.selectedItem, "data")));
		}
	}

	private function openDropdown(_:Event):Void {
		dropdownOpen = true;
	}

	private function closeDropdown(event:Event):Void {
		dropdownOpen = false;
		changeMode(event);
	}

	private function mountNear(target:DisplayObject):Void {
		if (AppStage.stage == null) {
			return;
		}
		AppStage.stage.addChild(this);
		var targetBounds = target.getBounds(AppStage.stage);
		var popupBounds = getBounds(this);
		var popupWidth = popupBounds.width <= 0 ? 240 : popupBounds.width;
		var popupHeight = popupBounds.height <= 0 ? 115 : popupBounds.height;
		x = targetBounds.left > popupWidth ? targetBounds.left - popupWidth - 7 : targetBounds.right + 7;
		y = targetBounds.top;
		if (y < 0) {
			y = 0;
		}
		if (y + popupHeight > 400) {
			y = 400 - popupHeight;
		}
		x = Math.round(x);
		y = Math.round(y);
	}

}
