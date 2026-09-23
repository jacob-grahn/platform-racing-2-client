package pr2.lobby.level;

import openfl.text.TextField;
import pr2.app.AppStage;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.AutoDismissPopup;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.util.DisplayUtil;

/**
	Port of Flash `level_browser.CourseMenu` (an `AutoDismissPopup`).

	Shown beside a join `Slot` when the local player fills it: renders
	`CourseMenuGraphic` with its Play / Cancel buttons and a countdown text box,
	and registers the gameserver `forceTime` / `closeCourseMenu` commands. Play
	confirms the slot; only the server's later `startGame` command enters the
	level. Cancel clears it. The server drives `forceTime` to
	run a 15-second countdown that issues `force_start` at zero, or `-1` to show a
	`--` wait with a 30-second fallback dismiss. Clicking outside the popup, like
	the original auto-dismiss, removes it.

	`flash.utils.setInterval/setTimeout` map to `haxe.Timer`.
**/
class CourseMenu extends AutoDismissPopup {
	public static var instance:Null<CourseMenu> = null;

	private var art:Null<CourseMenuView>;
	private var slot:Null<Slot>;
	private var textBox:Null<TextField>;
	private var playButton:Null<openfl.display.DisplayObject>;
	private var cancelButton:Null<openfl.display.DisplayObject>;
	private var playBinding:Null<LobbyArt.Binding>;
	private var cancelBinding:Null<LobbyArt.Binding>;

	private var flow:RaceEntryFlow;
	private var confirmed(get, never):Bool;
	private function get_confirmed():Bool return flow.confirmed;

	public function new(s:Slot) {
		super();
		if (CourseMenu.instance != null) {
			CourseMenu.instance.staticCloseMenu();
		}
		CourseMenu.instance = this;

		this.slot = s;
		art = new CourseMenuView();
		addChild(art);

		// CourseMenuGraphic's countdown field was exported without an instance name;
		// recover it as the single top-level dynamic text on the clip.
		textBox = art.countdown;

		playButton = DisplayUtil.directChildByName(art, "play_bt");
		cancelButton = DisplayUtil.directChildByName(art, "cancel_bt");
		playBinding = LobbyArt.bind(playButton, clickPlay);
		cancelBinding = LobbyArt.bind(cancelButton, closeMenu);

		flow = new RaceEntryFlow(function() { if (slot != null) slot.sendConfirmSlot(); }, closeMenu,
			function() { if (textBox != null) textBox.text = flow.countdown; });

		positionNear(s);
	}

	public function forceTime(a:Array<String>):Void flow.forceTime(a);
	public static inline function initialTimer(timeRemaining:Int):Int return RaceEntryFlow.initialTimer(timeRemaining);
	private function decrementTimer():Void flow.tick();
	private function clickPlay():Void flow.play();

	public function remoteRemove(_:Array<String>):Void {
		remove();
	}

	private function closeMenu():Void {
		remove();
	}

	public function staticCloseMenu():Void {
		closeMenu();
	}

	override public function remove():Void {
		if (slot == null) {
			// Already removed; avoid re-running teardown (and re-clearing the slot).
			return;
		}
		if (CourseMenu.instance == this) {
			CourseMenu.instance = null;
		}
		flow.remove();
		LobbyArt.unbind(playBinding);
		LobbyArt.unbind(cancelBinding);
		playBinding = null;
		cancelBinding = null;
		var s = slot;
		slot = null;
		s.sendClearSlot();
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

}
