package pr2.gameplay;

import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.dialogs.Popup;
import pr2.ui.RatingSelect;
import pr2.util.DisplayUtil;

/**
	Port of Flash `gameplay.FinishedPage`: the end-of-race popup with the level
	rating control, the experience-gain bar, and up to five award/exp bonus
	lines.

	Flash builds this from the live `Game` (reading `pendingAwards`, `expOld`,
	`expNew`, `expToRank`, and `getCourseID`). The in-game `Game`/`Course` shell
	is not ported yet, so this takes the level id directly and exposes the same
	`award` / `setExpGain` entry points the `Game` called; the caller supplies an
	`onReturn` for the "Return to Lobby" button (Flash wrote `set_game_room`none`
	and changed the page to the lobby there).
**/
class FinishedPage extends Popup {
	public static var kongStatSubmit:Null<String->Int->Void> = null;

	private var art:Null<FinishedPageView>;
	private var stars:Null<RatingSelect>;
	private var expGain:Null<ExpGain>;
	private var onReturn:Null<Void->Void>;
	private var onClose:Null<FinishedPage->Void>;
	private var curAwardLine:Int = 1;

	private var returnBinding:Null<Binding>;
	private var closeBinding:Null<Binding>;

	public function new(courseID:Int, ?onReturn:Void->Void, ?onClose:FinishedPage->Void) {
		super();
		this.onReturn = onReturn;
		this.onClose = onClose;

		art = new FinishedPageView();
		returnBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "return_bt"), clickReturn);
		closeBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "close_bt"), function():Void startFadeOut());
		addChild(art);

		stars = new RatingSelect(courseID);
		stars.x = 6;
		stars.y = 87;
		addChild(stars);

		expGain = new ExpGain();
		expGain.x = 0;
		expGain.y = 47;
		addChild(expGain);
	}

	/** Add a bonus/exp award line, matching `FinishedPage.award`. */
	public function award(bonus:String, exp:String):Void {
		if (art == null || curAwardLine > 5) {
			return;
		}
		var bonusField = LobbyArt.directText(art, "bonus" + curAwardLine);
		if (bonusField != null) {
			bonusField.text = bonus;
		}
		var expField = LobbyArt.directText(art, "exp" + curAwardLine);
		if (expField != null) {
			expField.text = exp;
		}
		curAwardLine++;
	}

	/** Fill the total and animate the exp bar, matching `FinishedPage.setExpGain`. */
	public function setExpGain(expOld:Int, expNew:Int, expToRank:Int):Void {
		if (art != null) {
			var total = LobbyArt.directText(art, "expTotal");
			if (total != null) {
				total.text = "+ " + (expNew - expOld);
			}
		}
		if (expGain != null) {
			expGain.start(expOld, expNew, expToRank);
		}
		if (kongStatSubmit != null) {
			kongStatSubmit("Exp Gained at Once", expNew - expOld);
		}
	}

	private function clickReturn():Void {
		if (onReturn != null) {
			onReturn();
		}
		startFadeOut();
	}

	override public function remove():Void {
		var close = onClose;
		onClose = null;
		if (close != null) {
			close(this);
		}
		LobbyArt.unbind(returnBinding);
		LobbyArt.unbind(closeBinding);
		if (expGain != null) {
			expGain.remove();
			expGain = null;
		}
		if (stars != null) {
			stars.remove();
			stars = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
