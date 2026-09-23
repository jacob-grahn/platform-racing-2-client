package pr2.mobile;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import pr2.app.AppStage;

/** Mouse/touch-generated pointer drag, wheel scrolling, and bounded content. */
class MobileScrollPane extends Sprite {
	public final content:LobbyView = new LobbyView();
	private var viewH:Float = 1;
	private var contentH:Float = 0;
	private var startY:Float;
	private var originY:Float;
	private var dragging:Bool = false;
	private var moved:Bool = false;
	public function new() {
		super(); addChild(content);
		addEventListener(MouseEvent.MOUSE_WHEEL, wheel);
		addEventListener(MouseEvent.MOUSE_DOWN, down);
		addEventListener(MouseEvent.CLICK, click, true, 1000);
	}
	public function setSize(w:Float, h:Float, total:Float):Void {
		viewH = Math.max(1, h); contentH = total;
		scrollRect = new Rectangle(0, 0, w, viewH);
		graphics.clear(); graphics.beginFill(0xF3F8FA, .01); graphics.drawRect(0, 0, w, viewH); graphics.endFill(); clamp();
	}
	public function reset():Void content.y = 0;
	public function setOffset(value:Float):Void { content.y = value; clamp(); }
	private function clamp():Void content.y = Math.max(Math.min(0, viewH - contentH), Math.min(0, content.y));
	private function wheel(e:MouseEvent):Void { content.y += e.delta * 28; clamp(); e.stopPropagation(); }
	private function down(e:MouseEvent):Void {
		// Text selection and scrolling inside editable fields belong to the input.
		var target:openfl.display.DisplayObject = Std.downcast(e.target, openfl.display.DisplayObject);
		while (target != null && target != this) {
			if (Std.isOfType(target, pr2.ui.controls.GameTextInput)) { moved = false; return; }
			var textField=Std.downcast(target,openfl.text.TextField);
			if(textField!=null&&textField.type==openfl.text.TextFieldType.INPUT){moved=false;return;}
			target = target.parent;
		}
		moved = false; dragging = true; startY = e.stageY; originY = content.y;
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(MouseEvent.MOUSE_MOVE, move);
			AppStage.stage.addEventListener(MouseEvent.MOUSE_UP, up);
		}
	}
	private function move(e:MouseEvent):Void {
		if (!dragging) return;
		if (Math.abs(e.stageY - startY) > 8) moved = true;
		if (moved) { content.y = originY + e.stageY - startY; clamp(); }
	}
	private function up(_:MouseEvent):Void { dragging = false; unbind(); }
	private function click(e:MouseEvent):Void { if (moved) { e.stopImmediatePropagation(); moved = false; } }
	private function unbind():Void {
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_MOVE, move); AppStage.stage.removeEventListener(MouseEvent.MOUSE_UP, up);
		}
	}
	public function remove():Void {
		unbind(); content.remove();
		removeEventListener(MouseEvent.MOUSE_WHEEL, wheel); removeEventListener(MouseEvent.MOUSE_DOWN, down); removeEventListener(MouseEvent.CLICK, click, true);
		if (parent != null) parent.removeChild(this);
	}
}
