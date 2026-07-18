package pr2.lobby;

import openfl.geom.Rectangle;
import pr2.lobby.LobbySpecialButton.LobbySpecialButtonKind;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Exact two production frames of XFL `UI/Pages/Lobby/LobbyBottom`. */
class LobbyBottomButtonsView extends NativeView {
	private static inline var CLASSIC_BUTTON_WIDTH:Float = 100;
	public final logoutButton:GameButton;
	public final levelEditorButton:GameButton;
	public final moreGamesButton:LobbySpecialButton;
	public final optionsButton:GameButton;
	public final vaultButton:LobbySpecialButton;
	public final creditsButton:GameButton;
	public var member(default, null):Bool;

	public function new(member:Bool) {
		super();
		scrollRect = new Rectangle(0, 0, 550, 400);
		creditsButton = classic("creditsButton", "Credits");
		moreGamesButton = special("moreGamesButton", Kong);
		optionsButton = classic("optionsButton", "Options");
		levelEditorButton = classic("levelEditorButton", "Level Editor");
		logoutButton = classic("logoutButton", "Logout");
		vaultButton = special("vaultButton", Vault);
		setMemberVariant(member);
	}

	public function setMemberVariant(member:Bool):Void {
		this.member = member;
		if (member) {
			// XFL label `kongregateSite`, frame 21.
			place(creditsButton, 246.9, 435, CLASSIC_BUTTON_WIDTH * 0.581741333007812, 22);
			place(moreGamesButton, 363.45, 430, CLASSIC_BUTTON_WIDTH * 0.960159301757812, 22 * 1.272705078125);
			place(optionsButton, 423, 369, CLASSIC_BUTTON_WIDTH * 0.580245971679688, 22);
			place(levelEditorButton, 285, 369, CLASSIC_BUTTON_WIDTH * 0.739898681640625, 22);
			place(logoutButton, 363, 369, CLASSIC_BUTTON_WIDTH * 0.559982299804688, 22);
			place(vaultButton, 206, 366, CLASSIC_BUTTON_WIDTH * 0.740097045898438, 22 * 1.272705078125);
		} else {
			// XFL label `sponsoredSite`, frame 11.
			place(creditsButton, 207, 369, CLASSIC_BUTTON_WIDTH * 0.581741333007812, 22);
			place(moreGamesButton, 334.15, 421, CLASSIC_BUTTON_WIDTH * 0.960159301757812, 22 * 1.272705078125);
			place(optionsButton, 423, 369, CLASSIC_BUTTON_WIDTH * 0.581741333007812, 22);
			place(levelEditorButton, 272, 369, CLASSIC_BUTTON_WIDTH * 0.814407348632812, 22);
			place(logoutButton, 361, 369, CLASSIC_BUTTON_WIDTH * 0.546981811523438, 22);
			place(vaultButton, 255, 421, CLASSIC_BUTTON_WIDTH * 0.740097045898438, 22 * 1.272705078125);
		}
	}

	private function classic(name:String, label:String):GameButton {
		var button = ownControl(new GameButton(label));
		button.name = name;
		addChild(button);
		return button;
	}

	private function special(name:String, kind:LobbySpecialButtonKind):LobbySpecialButton {
		var button = ownControl(new LobbySpecialButton(kind));
		button.name = name;
		addChild(button);
		return button;
	}

	private static function place(button:GameButton, x:Float, y:Float, width:Float, height:Float):Void {
		button.x = x;
		button.y = y;
		button.setSize(width, height);
	}
}
