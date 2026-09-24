package pr2.page;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.app.AppStage;
import pr2.app.ScreenFactory;
import pr2.mobile.LobbyView;

/** Landscape, in-client control guide for the touch release. */
class MobileInstructionsPage extends Page {
	private final siteMode:String;
	private final canvas = new Sprite();
	private final view = new LobbyView();
	public function new(siteMode:String) {
		super();
		fullViewport = true;
		isLoginScreen = true;
		this.siteMode = siteMode;
	}
	override public function initialize():Void {
		addChild(canvas);
		canvas.addChild(view);
		view.graphics.beginFill(0x10283C); view.graphics.drawRect(0, 0, 844, 390); view.graphics.endFill();
		view.label("HOW TO PLAY", 42, 17, 500, 45, 31, true, 0xFFFFFF);
		view.button("← TITLE", 684, 16, 118, goBack, false, 44);
		card(42, 75, 238, "RACE", "Pick a level from Play. Run through the course and touch a finish block to complete it.");
		card(303, 75, 238, "MOVE + JUMP", "Drag the joystick to move. Tap Jump to leap; hold it for a higher jump. Joystick up can hold an existing jump, but never starts one.");
		card(564, 75, 238, "ITEMS", "Collect an item, then tap its button to use it. The button appears when you have an item.");
		view.label("Tap the center swap icon to put movement and action controls on your preferred sides.", 50, 285, 744, 44, 17, false, 0xD1ED62);
		#if (js && html5)
		view.button("ORIGINAL GUIDE ↗", 562, 323, 240, openOriginalGuide, false, 44);
		#end
		if (AppStage.stage != null) AppStage.stage.addEventListener(Event.RESIZE, layout);
		layout();
	}
	private function card(x:Float, y:Float, width:Float, title:String, body:String):Void {
		view.panel(x, y, width, 190);
		view.label(title, x + 16, y + 13, width - 32, 34, 21, true, 0x0B519E);
		view.label(body, x + 16, y + 52, width - 32, 125, 16, false, 0x18334B);
	}
	private function goBack():Void if (pageHolder != null) pageHolder.changePage(ScreenFactory.login(siteMode));
	private function openOriginalGuide():Void {
		#if (js && html5)
		js.Browser.window.open("/instructions.php", "_blank");
		#end
	}
	private function layout(?_:Event):Void {
		var stage = AppStage.stage;
		var w = stage == null ? 844.0 : stage.stageWidth;
		var h = stage == null ? 390.0 : stage.stageHeight;
		var scale = Math.min(w / 844, h / 390);
		canvas.scaleX = canvas.scaleY = scale;
		canvas.x = (w - 844 * scale) / 2;
		canvas.y = (h - 390 * scale) / 2;
		graphics.clear(); graphics.beginFill(0x10283C); graphics.drawRect(0, 0, w, h); graphics.endFill();
	}
	override public function remove():Void {
		if (AppStage.stage != null) AppStage.stage.removeEventListener(Event.RESIZE, layout);
		view.remove();
		super.remove();
	}
}
