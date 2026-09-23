package pr2.gameplay;

import openfl.display.DisplayObject;
import pr2.ui.RatingSelect;

/**
	Reusable pieces of the finished-race popup.

	GamePage creates these incrementally while the level loading screen is still
	visible. FinishedPage then adopts the same already-rendered instances instead
	of constructing a second, cold copy at the finish line.
**/
class FinishedPageAssets implements ResultsAssets {
	public var art(default, null):Null<FinishedPageView>;
	public var stars(default, null):Null<RatingSelect>;
	public var expGain(default, null):Null<ExpGain>;

	private final courseID:Int;

	public function new(courseID:Int) {
		this.courseID = courseID;
	}

	public function prepareShell():DisplayObject {
		if (art == null) art = new FinishedPageView();
		return art;
	}

	public function prepareRating():DisplayObject {
		if (stars == null) stars = new RatingSelect(courseID);
		return stars;
	}

	public function prepareExpGain():DisplayObject {
		if (expGain == null) expGain = new ExpGain();
		return expGain;
	}

	public function prepareAll():Void {
		prepareShell();
		prepareRating();
		prepareExpGain();
	}

	public function dispose():Void {
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (stars != null) {
			stars.remove();
			stars = null;
		}
		if (expGain != null) {
			expGain.remove();
			expGain = null;
		}
	}
}
