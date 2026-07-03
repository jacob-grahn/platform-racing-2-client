package pr2.lobby.account;

/**
	Port of Flash `com.jiggmin.ColorPicker.ColorChoices`: builds the 22x12 swatch
	grid shown by the colour picker. Column 0 is the recent-colour strip, column 2
	a set of suggested greys/primaries, and the bulk is a 6-step RGB cube laid out
	in the same column/row order as the original.
**/
class ColorChoices {
	public static final COLS:Int = 22;
	public static final ROWS:Int = 12;

	private function new() {}

	public static function populate(recentColors:Array<Int>):Array<Array<Int>> {
		var colors = makeColorArray(COLS, ROWS);

		var blockRow = 0;
		var blockCol = 0;
		var red = 0;
		while (red <= 0xFF) {
			var blue = 0;
			var numB = 0;
			while (blue <= 0xFF) {
				var green = 0;
				var numG = 0;
				while (green <= 0xFF) {
					var color = (red << 16) | (green << 8) | blue;
					var row = (blockRow * 6) + numG + 4;
					var col = (blockCol * 6) + numB;
					colors[row][col] = color;
					green += 51;
					numG++;
				}
				blue += 51;
				numB++;
			}
			red += 51;
			if (++blockRow > 2) {
				blockRow = 0;
				blockCol++;
			}
		}

		for (i in 0...ROWS) {
			colors[0][i] = i < recentColors.length ? recentColors[i] : 0xFFFFFF;
		}

		var suggested = [0x000000, 0x333333, 0x666666, 0x999999, 0xCCCCCC, 0xFFFFFF, 0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00, 0x00FFFF, 0xFF00FF];
		for (i in 0...suggested.length) {
			colors[2][i] = suggested[i];
		}
		return colors;
	}

	private static function makeColorArray(cols:Int, rows:Int):Array<Array<Int>> {
		var grid:Array<Array<Int>> = [];
		for (_ in 0...cols) {
			var row:Array<Int> = [];
			for (_ in 0...rows) {
				row.push(0);
			}
			grid.push(row);
		}
		return grid;
	}
}
