package pr2.lobby;

/**
	Port of the comma-grouping in Flash `com.jiggmin.data.Data.formatNumber`, used
	by the guild list (GP today) and other lobby figures.
**/
class NumberFormat {
	private function new() {}

	public static function withCommas(value:Int):String {
		var negative = value < 0;
		var digits = Std.string(negative ? -value : value);
		var out = "";
		var count = 0;
		var i = digits.length - 1;
		while (i >= 0) {
			out = digits.charAt(i) + out;
			count++;
			if (count % 3 == 0 && i != 0) {
				out = "," + out;
			}
			i--;
		}
		return negative ? "-" + out : out;
	}
}
