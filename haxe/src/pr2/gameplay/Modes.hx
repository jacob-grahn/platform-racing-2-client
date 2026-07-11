package pr2.gameplay;

/** Port of Flash `gameplay.Modes`. **/
class Modes {
	public static inline var egg:String = "egg";
	public static inline var dm:String = "deathmatch";
	public static inline var race:String = "race";
	public static inline var obj:String = "objective";
	public static inline var hat:String = "hat";
	public static inline var roguelike:String = "roguelike";

	public static function getFullName(str:String):String {
		if (str == "e" || str == "eggs" || str == egg) {
			return "Alien Eggs";
		} else if (str == "d" || str == "dm" || str == dm) {
			return "Deathmatch";
		} else if (str == "o" || str == "obj" || str == obj) {
			return "Objective";
		} else if (str == "h" || str == hat) {
			return "Hat Attack";
		} else if (str == "l" || str == "rl" || str == roguelike) {
			return "Roguelike";
		}
		return "Race";
	}
}
