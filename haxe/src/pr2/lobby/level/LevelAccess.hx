package pr2.lobby.level;

/** Outcome of the Flash `LevelItem.testAccess` cover logic. */
enum LevelAccessState {
	/** Playable: no access cover shown. */
	Open;
	/** Password required: the pass cover with text box / button is shown. */
	PassNeeded;
	/** Rank too low: cover reads "Rank N Needed". */
	RankNeeded(minRank:Int);
	/** Wearing a disallowed hat: cover reads "Hat Not Allowed". */
	HatNotAllowed;
}

/**
	Pure port of the access checks in Flash `level_browser.LevelItem.testAccess`,
	separated from the display object so the parity-critical gating is unit-testable.

	The original evaluates, in order: password (unless owner / group >= 2 / already
	entered), then minimum rank, then disallowed hats. Owners and moderators
	(`group >= 2`) bypass password and rank but, like everyone, are still subject
	to the hat restriction (the Flash code checks hats after the early returns).
**/
class LevelAccess {
	private function new() {}

	public static function evaluate(
		pass:Bool,
		passOK:Bool,
		group:Int,
		byMe:Bool,
		myRank:Int,
		minRank:Int,
		currentHat:Int,
		badHats:Array<Int>
	):LevelAccessState {
		// Password gate (skipped for the owner, moderators, or once entered).
		if (pass && !passOK && group < 2 && !byMe) {
			return PassNeeded;
		}
		// Rank gate (skipped for the owner and moderators).
		var rank = myRank < 0 ? 0 : myRank;
		if (group < 2 && !byMe && rank < minRank) {
			return RankNeeded(minRank);
		}
		// Hat gate applies to everyone.
		if (badHats != null && badHats.length > 0 && badHats.indexOf(currentHat) != -1) {
			return HatNotAllowed;
		}
		return Open;
	}

	/** The text the Flash access cover displays for a gated state ("" when open). */
	public static function coverText(state:LevelAccessState):String {
		return switch (state) {
			case Open: "";
			case PassNeeded: "Pass Needed";
			case RankNeeded(minRank): 'Rank $minRank Needed';
			case HatNotAllowed: "Hat Not Allowed";
		}
	}
}
