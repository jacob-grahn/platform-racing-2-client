package pr2.lobby.dialogs;

import openfl.display.Sprite;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.net.LobbySocket;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `dialogs.TempModMenu`: temporary moderators can issue warning
	levels directly and confirm a 30-minute server kick from a player popup.
**/
class TempModMenu extends Sprite {
	private var art:Null<PR2MovieClip>;
	private var target:Popup;
	private var userName:String;
	private var bindings:Array<Null<Binding>> = [];

	public function new(name:String, popup:Popup) {
		super();
		userName = name;
		target = popup;
		art = PR2MovieClip.fromLinkage("TempModMenuGraphic", {maxNestedDepth: 4});
		addChild(art);

		bind("warning1Button", function():Void warnUser(1));
		bind("warning2Button", function():Void warnUser(2));
		bind("warning3Button", function():Void warnUser(3));
		bind("kickButton", clickKick);
	}

	private function bind(name:String, handler:Void->Void):Void {
		bindings.push(LobbyArt.bind(LobbyArt.findByName(art, name), handler));
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
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
