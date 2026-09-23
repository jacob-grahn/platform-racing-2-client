package pr2.gameplay;

/** The session can deliver results without knowing their presentation. */
interface RaceResults {
	function award(bonus:String, exp:String):Void;
	function setExpGain(expOld:Int, expNew:Int, expToRank:Int):Void;
	function remove():Void;
}
