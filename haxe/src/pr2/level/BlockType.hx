package pr2.level;

enum abstract BlockType(String) from String to String {
	var Basic = "basic";
	var Brick = "brick";
	var Start = "start";
	var Finish = "finish";
	var Solid = "solid";
	var Ice = "ice";
	var ArrowDown = "arrow_down";
	var ArrowUp = "arrow_up";
	var ArrowLeft = "arrow_left";
	var ArrowRight = "arrow_right";
	var Mine = "mine";
	var Item = "item";
	var InfiniteItem = "infinite_item";
	var Crumble = "crumble";
	var Vanish = "vanish";
	var Move = "move";
	var Water = "water";
	var RotateRight = "rotate_right";
	var RotateLeft = "rotate_left";
	var Push = "push";
	var Safety = "safety";
	var Teleport = "teleport";
	var CustomStats = "custom_stats";
	var Happy = "happy";
	var Sad = "sad";
	var Heart = "heart";
	var Time = "time";
	/** Runtime-only solid laid by the Snake item; never serialized in level data. */
	var SnakeTrail = "snake_trail";

	public static function parse(value:String):BlockType {
		return switch (value) {
			case Basic: Basic;
			case Brick: Brick;
			case Start: Start;
			case Finish: Finish;
			case Solid: Solid;
			case Ice: Ice;
			case ArrowDown: ArrowDown;
			case ArrowUp: ArrowUp;
			case ArrowLeft: ArrowLeft;
			case ArrowRight: ArrowRight;
			case Mine: Mine;
			case Item: Item;
			case InfiniteItem: InfiniteItem;
			case Crumble: Crumble;
			case Vanish: Vanish;
			case Move: Move;
			case Water: Water;
			case RotateRight: RotateRight;
			case RotateLeft: RotateLeft;
			case Push: Push;
			case Safety: Safety;
			case Teleport: Teleport;
			case CustomStats: CustomStats;
			case Happy: Happy;
			case Sad: Sad;
			case Heart: Heart;
			case Time: Time;
			case SnakeTrail: SnakeTrail;
			default: throw 'unknown block type "$value"';
		}
	}

	public inline function isSolid():Bool {
		return switch (this) {
			case Basic | Brick | Finish | Solid | Ice | ArrowDown | ArrowUp | ArrowLeft | ArrowRight | Mine | Item | InfiniteItem | Crumble | Vanish | Move | RotateRight | RotateLeft | Push | Teleport | CustomStats | Happy | Sad | Heart | Time | SnakeTrail: true;
			case Start | Water | Safety: false;
			default: false;
		}
	}
}
