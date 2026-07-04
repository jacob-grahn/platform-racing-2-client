package pr2.lobby.dialogs;

import openfl.display.Sprite;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.net.LobbySocket;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class AdminMenu extends Sprite {
	private var art:Null<PR2MovieClip>;
	private var target:Popup;
	private var userName:String;
	private var mode:Null<String>;
	private var bindings:Array<Null<Binding>> = [];

	public function new(name:String, popup:Popup) {
		super();
		userName = name;
		target = popup;
		art = PR2MovieClip.fromLinkage("AdminMenuGraphic", {maxNestedDepth: 4});
		addChild(art);

		bind("tempMod_bt", clickTemp);
		bind("trialMod_bt", clickTrial);
		bind("permaMod_bt", clickPerma);
		bind("demote_bt", clickDemote);
	}

	private function bind(name:String, handler:Void->Void):Void {
		bindings.push(LobbyArt.bind(DisplayUtil.findByName(art, name), handler));
	}

	private function clickTemp():Void {
		mode = "temporary";
		new ConfirmPopup(promoteModerator,
			"Are you sure you want to promote " + userName + " to a temporary moderator? They will be a moderator on this server until they log off. They will be able to administer 30 minute server kicks.");
	}

	private function clickTrial():Void {
		mode = "trial";
		new ConfirmPopup(promoteModerator,
			"Are you sure you want to promote " + userName + " to a trial moderator? They will only be able to ban for up to a day.");
	}

	private function clickPerma():Void {
		mode = "permanent";
		new ConfirmPopup(promoteModerator,
			"Are you sure you want to promote " + userName + " to a permanent moderator? They will be able to ban for up to a year, see IP addresses, unpublish levels, edit guilds, and use the PR2 Hub moderation tools.");
	}

	private function clickDemote():Void {
		mode = null;
		new ConfirmPopup(demoteModerator, "Are you sure you want to demote " + userName + "?");
	}

	private function promoteModerator():Void {
		LobbySocket.write("promote_to_moderator`" + userName + "`" + mode);
		target.startFadeOut();
	}

	private function demoteModerator():Void {
		LobbySocket.write("demote_moderator`" + userName);
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
