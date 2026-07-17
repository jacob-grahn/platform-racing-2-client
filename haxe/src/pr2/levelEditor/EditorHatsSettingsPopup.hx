package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.app.AppStage;
import pr2.lobby.dialogs.AutoDismissController;
import pr2.lobby.dialogs.HoverPopup;
import pr2.lobby.dialogs.ChecklistMenuView;
import pr2.ui.controls.GameCheckBox;
import pr2.util.DisplayUtil;

class EditorHatsSettingsPopup extends Sprite {
	public final editor:LevelEditor;
	public final art:ChecklistMenuView;
	private static inline final LOWEST_HAT_ID:Int = 2;
	private static inline final HIGHEST_HAT_ID:Int = 16;
	private final checks:Map<Int, GameCheckBox> = new Map();
	private var autoDismiss:Null<AutoDismissController>;
	private var removed:Bool = false;
	private var cowboyHover:Null<HoverPopup>;
	private var artifactHover:Null<HoverPopup>;

	public function new(editor:LevelEditor, target:DisplayObject) {
		super();
		this.editor = editor;
		art = new ChecklistMenuView("hats");
		addChild(art);
		for (hatId in LOWEST_HAT_ID...HIGHEST_HAT_ID + 1) {
			var check = Std.downcast(DisplayUtil.findByName(art, "hat" + hatId), GameCheckBox);
			if (check != null) {
				check.selected = editor.badHats.indexOf(hatId) < 0;
				checks.set(hatId, check);
			}
		}
		var artifact = checks.get(14);
		if (artifact != null && editor.gameMode == "hat") {
			artifact.selected = false;
		}
		bindHover(5);
		bindHover(14);
		mountNear(target);
		autoDismiss = new AutoDismissController(this, remove);
	}

	public function isHatAllowed(hatId:Int):Bool {
		var check = checks.get(hatId);
		return check != null && check.selected;
	}

	public function setHatAllowed(hatId:Int, allowed:Bool):Void {
		var check = checks.get(hatId);
		if (check != null) {
			check.selected = allowed;
		}
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
		removeHover();
		for (hatId in [5, 14]) {
			var check = checks.get(hatId);
			if (check != null) {
				check.removeEventListener(MouseEvent.MOUSE_OVER, maybeAddHover);
				check.removeEventListener(Event.CHANGE, maybeAddHover);
				check.removeEventListener(MouseEvent.MOUSE_OUT, removeHover);
			}
		}
		var banned:Array<Int> = [];
		for (hatId in LOWEST_HAT_ID...HIGHEST_HAT_ID + 1) {
			var check = checks.get(hatId);
			if (check != null && !check.selected) {
				banned.push(hatId);
			}
		}
		editor.setBadHats(banned.join(","));
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.hatsSettingsPopupRemoved(this);
	}

	private function bindHover(hatId:Int):Void {
		var check = checks.get(hatId);
		if (check == null) {
			return;
		}
		check.addEventListener(MouseEvent.MOUSE_OVER, maybeAddHover);
		check.addEventListener(Event.CHANGE, maybeAddHover);
		check.addEventListener(MouseEvent.MOUSE_OUT, removeHover);
	}

	private function maybeAddHover(event:Event):Void {
		var target = Std.downcast(event.currentTarget, GameCheckBox);
		if (target == null) {
			return;
		}
		if (target == checks.get(5)) {
			if (cowboyHover == null && Std.parseInt(editor.cowboyChance) > 0 && !target.selected) {
				cowboyHover = new HoverPopup("Cowboy Mode",
					"Disabling the cowboy hat here won't override your setting for chance of cowboy mode.", target);
			} else {
				removeHover();
			}
		} else if (target == checks.get(14) && editor.gameMode == "hat") {
			removeHover();
			if (event.type != MouseEvent.MOUSE_OUT) {
				artifactHover = new HoverPopup("Artifact in Hat Attack",
					"This setting won't have any effect since the artifact hat cannot be used in hat attack mode.", target);
			}
		}
	}

	private function removeHover(?_):Void {
		if (cowboyHover != null) {
			cowboyHover.remove();
			cowboyHover = null;
		}
		if (artifactHover != null) {
			artifactHover.remove();
			artifactHover = null;
		}
	}

	private function mountNear(target:DisplayObject):Void {
		if (AppStage.stage == null) {
			return;
		}
		AppStage.stage.addChild(this);
		var targetBounds = target.getBounds(AppStage.stage);
		var popupBounds = getBounds(this);
		var popupWidth = popupBounds.width <= 0 ? 290 : popupBounds.width;
		var popupHeight = popupBounds.height <= 0 ? 210 : popupBounds.height;
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
