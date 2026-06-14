package pr2.level;

enum abstract BlockType(String) from String to String {
	var Basic = "basic";
	var Start = "start";
	var Finish = "finish";

	public static function parse(value:String):BlockType {
		return switch (value) {
			case Basic: Basic;
			case Start: Start;
			case Finish: Finish;
			default: throw 'unknown block type "$value"';
		}
	}

	public inline function isSolid():Bool {
		return switch (this) {
			case Basic | Start | Finish: true;
			default: false;
		}
	}
}
