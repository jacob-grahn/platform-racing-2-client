package pr2.gameplay;

/**
	Port of the static item-code/name table from Flash `items.Items`.

	Only the code <-> name lookups that `GamePage`/`LevelConfig` need to resolve a
	level's allowed-items list are ported here; the per-item gameplay `Item`
	subclasses (`getFromCode`) belong with the character/item port (Section B).
**/
class Items {
	public static inline var LASER_GUN:Int = 1;
	public static inline var MINE:Int = 2;
	public static inline var LIGHTNING:Int = 3;
	public static inline var TELEPORT:Int = 4;
	public static inline var SUPER_JUMP:Int = 5;
	public static inline var JET_PACK:Int = 6;
	public static inline var SPEED_BURST:Int = 7;
	public static inline var SWORD:Int = 8;
	public static inline var ICE_WAVE:Int = 9;

	/** Every valid item code, in Flash order. **/
	public static function getAllCodes():Array<Int> {
		return [LASER_GUN, MINE, LIGHTNING, TELEPORT, SUPER_JUMP, JET_PACK, SPEED_BURST, SWORD, ICE_WAVE];
	}

	public static function getNameFromCode(code:Int):String {
		return switch (code) {
			case LASER_GUN: "Laser";
			case MINE: "Mine";
			case LIGHTNING: "Lightning";
			case TELEPORT: "Teleport";
			case SUPER_JUMP: "Super Jump";
			case JET_PACK: "Jet Pack";
			case SPEED_BURST: "Speed Burst";
			case SWORD: "Sword";
			case ICE_WAVE: "Ice Wave";
			default: "None";
		};
	}

	/** Mirrors `Items.getCodeFromName`; unknown names (and "None") map to 0. **/
	public static function getCodeFromName(name:String):Int {
		return switch (name) {
			case "Laser" | "Laser Gun": LASER_GUN;
			case "Mine": MINE;
			case "Lightning": LIGHTNING;
			case "Teleport": TELEPORT;
			case "Super Jump": SUPER_JUMP;
			case "Jet Pack": JET_PACK;
			case "Speed Burst": SPEED_BURST;
			case "Sword": SWORD;
			case "Ice Wave": ICE_WAVE;
			default: 0;
		};
	}
}
