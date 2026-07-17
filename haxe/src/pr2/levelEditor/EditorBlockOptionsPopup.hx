package pr2.levelEditor;

import openfl.display.Sprite;
import openfl.geom.Rectangle;
import pr2.app.AppStage;
import pr2.lobby.dialogs.AutoDismissController;

class EditorBlockOptionsPopup extends Sprite {
	public final editor:LevelEditor;
	public final block:EditorBlockObject;
	public final art:EditorBlockOptionsView;
	private var autoDismiss:Null<AutoDismissController>;
	private var removed:Bool = false;

	public function new(editor:LevelEditor, block:EditorBlockObject, linkage:String) {
		super();
		this.editor = editor;
		this.block = block;
		art = new EditorBlockOptionsView(linkage);
		addChild(art);
		mountNearBlock();
		autoDismiss = new AutoDismissController(this, remove);
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
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.blockOptionsPopupRemoved(this);
	}

	private function mountNearBlock():Void {
		var host:Null<Sprite> = editor.overlayLayer;
		if (AppStage.stage != null) {
			AppStage.stage.addChild(this);
			var blockBounds = block.getBounds(AppStage.stage);
			placeBeside(blockBounds);
			return;
		}
		if (host != null) {
			host.addChild(this);
			var blockBounds = block.getBounds(host);
			placeBeside(blockBounds);
		}
	}

	private function placeBeside(blockBounds:Rectangle):Void {
		var popupBounds = getBounds(this);
		var popupWidth = popupBounds.width <= 0 ? 236 : popupBounds.width;
		var popupHeight = popupBounds.height <= 0 ? 120 : popupBounds.height;
		x = blockBounds.left > popupWidth ? blockBounds.left - popupWidth - 7 : blockBounds.right + 7;
		y = blockBounds.top;
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
