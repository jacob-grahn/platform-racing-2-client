package pr2.mobile;

import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import pr2.app.AppStage;
import pr2.lobby.dialogs.Popup;

/** Unscaled landscape modal shell shared by profile and compose flows. */
class MobilePanelPopup extends Popup {
	private var shell:LobbyView;
	private var rotationHint:LobbyView;
	private var content:Sprite;
	private var title:String;
	private var shellAlpha:Float;
	private var w:Float = 844;
	private var h:Float = 390;
	public function new(title:String, shellAlpha:Float = 0.97) {
		super(false); this.title = title; this.shellAlpha = shellAlpha;
		shell = new LobbyView(); content = new Sprite(); rotationHint = new LobbyView();
		addChild(shell); addChild(content); addChild(rotationHint);
		if (AppStage.stage != null) AppStage.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown, false, 2000);
		layoutForSize(AppStage.stage == null ? w : AppStage.stage.stageWidth, AppStage.stage == null ? h : AppStage.stage.stageHeight);
	}
	override public function layoutForSize(width:Float, height:Float):Void {
		w = width; h = height; x = y = 0; scaleX = scaleY = 1;
		if (shell == null) return;
		shell.clear(); shell.graphics.beginFill(0x081A2B, shellAlpha); shell.graphics.drawRect(0,0,w,h); shell.graphics.endFill();
		shell.singleLine(title, 24, 16, w - 176, 40, 28, true, 0xFFFFFF);
		shell.button("Close", w - 132, 12, 108, startFadeOut);
		content.x = 24; content.y = 68; resizeContent(Math.max(280, w - 48), Math.max(120, h - 84));
		rotationHint.clear(); rotationHint.visible = h > w;
		if (rotationHint.visible) {
			rotationHint.graphics.beginFill(0x0B519E); rotationHint.graphics.drawRect(0,0,w,h); rotationHint.graphics.endFill();
			rotationHint.label("Turn your device sideways", 24, h/2 - 60, w-48,120,28,true,0xFFFFFF);
		}
	}
	private function resizeContent(width:Float, height:Float):Void {}
	private function keyDown(e:KeyboardEvent):Void {
		if (e.keyCode == 27 && isTopmostForTests() && !e.isDefaultPrevented()) { e.preventDefault(); e.stopImmediatePropagation(); startFadeOut(); }
	}
	override public function remove():Void {
		if (isRemoved()) return;
		if (AppStage.stage != null) AppStage.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		if (shell != null) shell.remove(); if (rotationHint != null) rotationHint.remove();
		super.remove();
	}
}
