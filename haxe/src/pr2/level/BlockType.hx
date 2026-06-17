package pr2.level;

enum abstract BlockType(String) from String to String {
	var Basic = "basic";
	var Start = "start";
	var Finish = "finish";
	var Solid = "solid";
	var Ice = "ice";
	var ArrowDown = "arrow_down";
	var ArrowUp = "arrow_up";
	var ArrowLeft = "arrow_left";
	var ArrowRight = "arrow_right";
	var Mine = "mine";
	var Crumble = "crumble";
	var Vanish = "vanish";
	var Water = "water";
	var Safety = "safety";

	public static function parse(value:String):BlockType {
		return switch (value) {
			case Basic: Basic;
			case Start: Start;
			case Finish: Finish;
			case Solid: Solid;
			case Ice: Ice;
			case ArrowDown: ArrowDown;
			case ArrowUp: ArrowUp;
			case ArrowLeft: ArrowLeft;
			case ArrowRight: ArrowRight;
			case Mine: Mine;
			case Crumble: Crumble;
			case Vanish: Vanish;
			case Water: Water;
			case Safety: Safety;
			default: throw 'unknown block type "$value"';
		}
	}

	public inline function isSolid():Bool {
		return switch (this) {
			case Basic | Start | Finish | Solid | Ice | ArrowDown | ArrowUp | ArrowLeft | ArrowRight | Mine | Crumble | Vanish: true;
			case Water | Safety: false;
			default: false;
		}
	}
}
