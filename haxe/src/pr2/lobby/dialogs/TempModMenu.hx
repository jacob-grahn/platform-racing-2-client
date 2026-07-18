package pr2.lobby.dialogs;

import openfl.display.Sprite;
import pr2.net.LobbySocket;
import pr2.lobby.dialogs.ModerationMenuView.ModerationMenuLayout;

/**
	Port of Flash `dialogs.TempModMenu`: temporary moderators can issue warning
	levels directly and confirm a 30-minute server kick from a player popup.
**/
class TempModMenu extends Sprite {
	private var art:Null<ModerationMenuView>;
	private var target:Popup;
	private var userName:String;

	public function new(name:String, popup:Popup) {
		super();
		userName = name;
		target = popup;
		art = new ModerationMenuView(TempMod, "-- Mod --", [
			{name: "warning1Button", label: "Warning 1", press: function():Void warnUser(1)},
			{name: "warning2Button", label: "Warning 2", press: function():Void warnUser(2)},
			{name: "warning3Button", label: "Warning 3", press: function():Void warnUser(3)},
			{name: "kickButton", label: "30 Minute Kick", press: clickKick}
		]);
		addChild(art);
	}

	private function warnUser(warnLevel:Int):Void {
		LobbySocket.write("warn`" + userName + "`" + warnLevel);
		target.startFadeOut();
	}

	private function clickKick():Void {
		new ConfirmPopup(kickUser,
			"Are you sure you want to kick " + userName + "? They will not be able to re-enter this server for 30 minutes.");
	}

	private function kickUser():Void {
		LobbySocket.write("kick`" + userName);
		target.startFadeOut();
	}

	public function remove():Void {
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
