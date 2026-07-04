package pr2.gameplay;

import pr2.gameplay.items.IceWave;
import pr2.gameplay.items.Item;
import pr2.gameplay.items.JetPack;
import pr2.gameplay.items.LaserGun;
import pr2.gameplay.items.Lightning;
import pr2.gameplay.items.Mine;
import pr2.gameplay.items.SpeedBurst;
import pr2.gameplay.items.SuperJump;
import pr2.gameplay.items.Sword;
import pr2.gameplay.items.Teleport;

/**
	Port of the static item-code/name table from Flash `items.Items`.
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

	public static function getFromCode(code:Int):Null<Item> {
		return switch (code) {
			case LASER_GUN: new LaserGun();
			case MINE: new Mine();
			case LIGHTNING: new Lightning();
			case TELEPORT: new Teleport();
			case SUPER_JUMP: new SuperJump();
			case JET_PACK: new JetPack();
			case SPEED_BURST: new SpeedBurst();
			case SWORD: new Sword();
			case ICE_WAVE: new IceWave();
			default: null;
		};
	}

	public static function getCodeFromItem(item:Null<Item>):Int {
		return item == null ? 0 : item.code;
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
