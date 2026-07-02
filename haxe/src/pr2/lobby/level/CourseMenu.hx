package pr2.lobby.level;

import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.app.AppStage;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.InfoPopup;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.runtime.PR2MovieClip;
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

	The Flash `AutoDismissPopup` base is folded in here (the stage MOUSE_DOWN
	hit-test). `flash.utils.setInterval/setTimeout` map to `haxe.Timer`.
**/
class CourseMenu extends InfoPopup {
	public static var instance:Null<CourseMenu> = null;

	private var art:Null<PR2MovieClip>;
	private var slot:Null<Slot>;
	private var textBox:Null<TextField>;
	private var playButton:Null<openfl.display.DisplayObject>;
	private var cancelButton:Null<openfl.display.DisplayObject>;
	private var playBinding:Null<LobbyArt.Binding>;
	private var cancelBinding:Null<LobbyArt.Binding>;

	private var confirmed:Bool = false;
	private var timer:Int = 0;
	private var secondInterval:Null<haxe.Timer>;
	private var waitTimeout:Null<haxe.Timer>;
	private var initTimeout:Null<haxe.Timer>;

	public function new(s:Slot) {
		super();
		if (CourseMenu.instance != null) {
			CourseMenu.instance.staticCloseMenu();
		}
		CourseMenu.instance = this;

		this.slot = s;
		art = PR2MovieClip.fromLinkage("CourseMenuGraphic", {maxNestedDepth: 6});
		addChild(art);

		// CourseMenuGraphic's countdown field was exported without an instance name;
		// recover it as the single top-level dynamic text on the clip.
		var fields = LobbyArt.directTextFields(art);
		textBox = fields.length > 0 ? fields[0] : null;

		playButton = DisplayUtil.findByName(art, "play_bt");
		cancelButton = DisplayUtil.findByName(art, "cancel_bt");
		playBinding = LobbyArt.bind(playButton, clickPlay);
		cancelBinding = LobbyArt.bind(cancelButton, closeMenu);

		var cm = CommandHandler.commandHandler;
		cm.defineCommand("forceTime", forceTime);
		cm.defineCommand("closeCourseMenu", remoteRemove);
		waitTimeout = haxe.Timer.delay(closeMenu, 30000);

		positionNear(s);

		// AutoDismissPopup: arm the click-outside dismiss after layout settles.
		initTimeout = haxe.Timer.delay(initAutoDismiss, 25);
	}

	public function forceTime(a:Array<String>):Void {
		var timeRemaining = a.length > 0 ? Std.parseInt(a[0]) : null;
		if (timeRemaining == null) {
			timeRemaining = 0;
		}
		stopInterval();
		stopWait();
		if (timeRemaining < 0) {
			if (textBox != null) {
				textBox.text = "--";
			}
			waitTimeout = haxe.Timer.delay(closeMenu, 30000);
		} else {
			timer = initialTimer(timeRemaining);
			secondInterval = new haxe.Timer(1000);
			secondInterval.run = decrementTimer;
			decrementTimer();
		}
	}

	/**
		Internal countdown seed for a server `forceTime` of `timeRemaining`
		seconds: the original sets `(15 - timeRemaining) + 1` and immediately ticks
		once, so the first value shown is `15 - timeRemaining`. Pure for testing.
	**/
	public static inline function initialTimer(timeRemaining:Int):Int {
		return (15 - timeRemaining) + 1;
	}

	private function decrementTimer():Void {
		timer--;
		if (timer < 0) {
			timer = 0;
			stopInterval();
			LobbySocket.write("force_start`");
		}
		if (textBox != null) {
			textBox.text = Std.string(timer);
		}
	}

	private function clickPlay():Void {
		confirmed = true;
		stopWait();
		if (slot != null) {
			slot.sendConfirmSlot();
		}
	}

	public function remoteRemove(_:Array<String>):Void {
		remove();
	}

	private function closeMenu():Void {
		confirmed = false;
		remove();
		if (AppStage.stage != null) {
			AppStage.stage.focus = AppStage.stage;
		}
	}

	public function staticCloseMenu():Void {
		closeMenu();
	}

	// ---- auto-dismiss (folded-in AutoDismissPopup) -----------------------

	private function initAutoDismiss():Void {
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
		}
	}

	private function downHandler(e:MouseEvent):Void {
		if (!hitTestPoint(e.stageX, e.stageY, true)) {
			remove();
		}
	}

	override public function remove():Void {
		if (slot == null) {
			// Already removed; avoid re-running teardown (and re-clearing the slot).
			return;
		}
		if (CourseMenu.instance == this) {
			CourseMenu.instance = null;
		}
		var cm = CommandHandler.commandHandler;
		cm.defineCommand("forceTime", null);
		cm.defineCommand("closeCourseMenu", null);
		LobbyArt.unbind(playBinding);
		LobbyArt.unbind(cancelBinding);
		playBinding = null;
		cancelBinding = null;
		stopInterval();
		stopWait();
		if (initTimeout != null) {
			initTimeout.stop();
			initTimeout = null;
		}
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, downHandler);
		}
		var s = slot;
		slot = null;
		s.sendClearSlot();
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private inline function stopInterval():Void {
		if (secondInterval != null) {
			secondInterval.stop();
			secondInterval = null;
		}
	}

	private inline function stopWait():Void {
		if (waitTimeout != null) {
			waitTimeout.stop();
			waitTimeout = null;
		}
	}
}
