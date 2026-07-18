package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import pr2.app.AppStage;
import pr2.gameplay.Items;
import pr2.lobby.dialogs.AutoDismissController;
import pr2.lobby.dialogs.ChecklistMenuView;
import pr2.ui.controls.GameCheckBox;
import pr2.util.DisplayUtil;

class EditorItemSettingsPopup extends Sprite {
	public final editor:LevelEditor;
	public final art:ChecklistMenuView;
	private final checks:Map<Int, GameCheckBox> = new Map();
	private var autoDismiss:Null<AutoDismissController>;
	private var removed:Bool = false;

	public function new(editor:LevelEditor, target:DisplayObject) {
		super();
		this.editor = editor;
		art = new ChecklistMenuView("items");
		addChild(art);
		for (itemId in Items.getAllCodes()) {
			var check:Null<GameCheckBox> = Std.downcast(DisplayUtil.directChildByName(art, "check" + itemId), GameCheckBox);
			if (check != null) {
				check.selected = editor.allowedItems.indexOf(itemId) >= 0;
				checks.set(itemId, check);
			}
		}
		mountNear(target);
		autoDismiss = new AutoDismissController(this, remove);
	}

	public function isItemSelected(itemId:Int):Bool {
		var check = checks.get(itemId);
		return check != null && check.selected;
	}

	public function setItemSelected(itemId:Int, selected:Bool):Void {
		var check = checks.get(itemId);
		if (check != null) {
			check.selected = selected;
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
		var selected:Array<Int> = [];
		for (itemId in Items.getAllCodes()) {
			var check = checks.get(itemId);
			if (check != null && check.selected) {
				selected.push(itemId);
			}
		}
		editor.setAllowedItems(selected);
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.itemSettingsPopupRemoved(this);
	}

	private function mountNear(target:DisplayObject):Void {
		if (AppStage.stage == null) {
			return;
		}
		AppStage.stage.addChild(this);
		var targetBounds = target.getBounds(AppStage.stage);
		var popupBounds = getBounds(this);
		var stageWidth = AppStage.stage.stageWidth > 0 ? AppStage.stage.stageWidth : 550;
		var stageHeight = AppStage.stage.stageHeight > 0 ? AppStage.stage.stageHeight : 400;
		var position = positionNear(targetBounds, popupBounds, stageWidth, stageHeight);
		x = position.x;
		y = position.y;
	}

	public static function positionNear(targetBounds:Rectangle, popupBounds:Rectangle, stageWidth:Float, stageHeight:Float):Point {
		var popupWidth = popupBounds.width <= 0 ? 180 : popupBounds.width;
		var fitsLeft = targetBounds.left - popupWidth - 7 >= 0;
		var x = fitsLeft ? targetBounds.left - popupBounds.right - 7 : targetBounds.right - popupBounds.left + 7;
		var y = targetBounds.top - popupBounds.top;
		if (x + popupBounds.left < 0) x = -popupBounds.left;
		if (x + popupBounds.right > stageWidth) x = stageWidth - popupBounds.right;
		if (y + popupBounds.top < 0) y = -popupBounds.top;
		if (y + popupBounds.bottom > stageHeight) y = stageHeight - popupBounds.bottom;
		x = Math.round(x);
		y = Math.round(y);
		if (x + popupBounds.left < 0) x = Math.ceil(-popupBounds.left);
		if (x + popupBounds.right > stageWidth) x = Math.floor(stageWidth - popupBounds.right);
		if (y + popupBounds.top < 0) y = Math.ceil(-popupBounds.top);
		if (y + popupBounds.bottom > stageHeight) y = Math.floor(stageHeight - popupBounds.bottom);
		return new Point(x, y);
	}

}
