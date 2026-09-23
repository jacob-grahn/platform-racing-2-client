package pr2.lobby.account;

/** Layout-independent Flash customization rules. */
class CustomizationRules {
	public static function stat(value:Int, available:Int):Int return Std.int(Math.max(0, Math.min(Math.min(100, value), available)));
	public static function budget(data:AccountCustomizeData):Int return Std.int(Math.max(data.happyHour ? 300 : 150 + data.rank, data.speed + data.acceleration + data.jumping));
	public static function epic(ids:Array<String>, id:Int):Bool return ids.indexOf("*") >= 0 || ids.indexOf(Std.string(id)) >= 0;
	public static function keyToSlot(key:Int):Int {
		if (key >= 48 && key <= 57) return key == 48 ? 10 : key - 48;
		if (key >= 96 && key <= 105) return key == 96 ? 10 : key - 96;
		return -1;
	}
}
