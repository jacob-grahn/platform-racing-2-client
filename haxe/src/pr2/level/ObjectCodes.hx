package pr2.level;

/**
	Block object codes, ported from `flash/com/jiggmin/data/Objects.as`. Saved
	block codes are 0-based (offset by -100); a loaded code `< 100` is the saved
	form and gets +100 to become one of these constants (see `resolveBlockCode`).
**/
final class ObjectCodes {
	public static inline var STAMP_TREE:Int = 0;
	public static inline var STAMP_TREE2:Int = 1;
	public static inline var STAMP_TREE3:Int = 2;
	public static inline var STAMP_PETRIFIED_TREE:Int = 3;
	public static inline var STAMP_CACTUS:Int = 4;
	public static inline var STAMP_ROCK:Int = 5;
	public static inline var STAMP_ROCK2:Int = 6;
	public static inline var STAMP_SPIRE:Int = 7;
	public static inline var STAMP_SPIRE2:Int = 8;
	public static inline var STAMP_BUILDING1:Int = 9;

	public static inline var BLOCK_BASIC1:Int = 100;
	public static inline var BLOCK_BASIC2:Int = 101;
	public static inline var BLOCK_BASIC3:Int = 102;
	public static inline var BLOCK_BASIC4:Int = 103;
	public static inline var BLOCK_BRICK:Int = 104;
	public static inline var BLOCK_ARROW_DOWN:Int = 105;
	public static inline var BLOCK_ARROW_UP:Int = 106;
	public static inline var BLOCK_ARROW_LEFT:Int = 107;
	public static inline var BLOCK_ARROW_RIGHT:Int = 108;
	public static inline var BLOCK_MINE:Int = 109;
	public static inline var BLOCK_ITEM:Int = 110;
	public static inline var BLOCK_START1:Int = 111;
	public static inline var BLOCK_START2:Int = 112;
	public static inline var BLOCK_START3:Int = 113;
	public static inline var BLOCK_START4:Int = 114;
	public static inline var BLOCK_ICE:Int = 115;
	public static inline var BLOCK_FINISH:Int = 116;
	public static inline var BLOCK_CRUMBLE:Int = 117;
	public static inline var BLOCK_VANISH:Int = 118;
	public static inline var BLOCK_MOVE:Int = 119;
	public static inline var BLOCK_WATER:Int = 120;
	public static inline var BLOCK_ROTATE_RIGHT:Int = 121;
	public static inline var BLOCK_ROTATE_LEFT:Int = 122;
	public static inline var BLOCK_PUSH:Int = 123;
	public static inline var BLOCK_SAFETY:Int = 124;
	public static inline var BLOCK_ITEM_INF:Int = 125;
	public static inline var BLOCK_HAPPY:Int = 126;
	public static inline var BLOCK_SAD:Int = 127;
	public static inline var BLOCK_HEART:Int = 128;
	public static inline var BLOCK_TIME:Int = 129;
	public static inline var BLOCK_MINION_EGG:Int = 130;
	public static inline var BLOCK_CUSTOM_STATS:Int = 131;
	public static inline var BLOCK_TELEPORT:Int = 132;

	public static inline var BG1Code:Int = 201;
	public static inline var BG2Code:Int = 202;
	public static inline var BG3Code:Int = 203;
	public static inline var BG4Code:Int = 204;
	public static inline var BG5Code:Int = 205;
	public static inline var BG6Code:Int = 206;
	public static inline var BG7Code:Int = 207;

	public static inline var TextCode:Int = 300;

	private function new() {}

	/** Mirrors `BlockBackground.attachObject`: saved codes < 100 are +100. **/
	public static inline function resolveBlockCode(saved:Int):Int {
		return saved < 100 ? saved + 100 : saved;
	}
}
