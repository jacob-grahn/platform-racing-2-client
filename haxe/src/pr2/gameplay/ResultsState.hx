package pr2.gameplay;

typedef ResultAward = { final bonus:String; final exp:String; }

/** Shared server result data. Never infer placement, rewards, or a new rank. */
class ResultsState {
	public static var kongStatSubmit:Null<String->Int->Void>;
	public final awards:Array<ResultAward> = [];
	public var hasExperience(default, null):Bool = false;
	public var gained(default, null):Int = 0;
	public final progress = new ExperienceProgress();
	public function new() {}
	public function award(bonus:String, exp:String):Bool {
		if (awards.length >= 5) return false;
		awards.push({bonus: bonus, exp: exp}); return true;
	}
	public function setExpGain(old:Int, next:Int, toRank:Int):Void {
		hasExperience = true; gained = next - old;
		progress.start(old, next, toRank);
		if (kongStatSubmit != null) kongStatSubmit("Exp Gained at Once", gained);
	}
}
