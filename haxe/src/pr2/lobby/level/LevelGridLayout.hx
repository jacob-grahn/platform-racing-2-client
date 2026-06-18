package pr2.lobby.level;

/** A single grid cell placement: which level index goes where. */
typedef LevelSlotPosition = {
	var index:Int;
	var x:Float;
	var y:Float;
};

/**
	Pure port of the placement loop in Flash `LevelListing.showCourses`.

	Levels fill three columns; each item is 109px wide and 112px tall. Placement
	starts at `startY` (the running sprite height, +20 when non-zero) and stops as
	soon as a row's top would fall past 224px, which is how the Flash code avoids
	rendering a "phantom" row below the intended final row of a page.
**/
class LevelGridLayout {
	public static inline var COLUMN_WIDTH:Float = 109;
	public static inline var ROW_HEIGHT:Float = 112;
	public static inline var COLUMNS:Int = 3;
	public static inline var MAX_TOP:Float = 224;

	private function new() {}

	public static function positions(count:Int, startY:Float = 0):Array<LevelSlotPosition> {
		var result:Array<LevelSlotPosition> = [];
		var levelInRow = 0;
		var levelOnPage = 0;
		for (i in 0...count) {
			var y = startY + levelOnPage * ROW_HEIGHT;
			if (y > MAX_TOP) {
				break;
			}
			result.push({index: i, x: 2 + levelInRow * COLUMN_WIDTH, y: y});
			levelInRow++;
			if (levelInRow >= COLUMNS) {
				levelOnPage++;
				levelInRow = 0;
			}
		}
		return result;
	}
}
