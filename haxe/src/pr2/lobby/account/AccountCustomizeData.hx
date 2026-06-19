package pr2.lobby.account;

/** Parsed payload of the gameserver `setCustomizeInfo` command. */
class AccountCustomizeData {
	public var hatColor:Int;
	public var headColor:Int;
	public var bodyColor:Int;
	public var feetColor:Int;
	public var hat:Int;
	public var head:Int;
	public var body:Int;
	public var feet:Int;
	public var hats:Array<String>;
	public var heads:Array<String>;
	public var bodies:Array<String>;
	public var feetParts:Array<String>;
	public var speed:Int;
	public var acceleration:Int;
	public var jumping:Int;
	public var rank:Int;
	public var rankTokensUsed:Int;
	public var rankTokensAvailable:Int;
	public var hatColor2:Int;
	public var headColor2:Int;
	public var bodyColor2:Int;
	public var feetColor2:Int;
	public var epicHats:Array<String>;
	public var epicHeads:Array<String>;
	public var epicBodies:Array<String>;
	public var epicFeet:Array<String>;
	public var happyHour:Bool;

	private function new() {}

	public static function parse(args:Array<String>):Null<AccountCustomizeData> {
		if (args == null || args.length < 27) {
			return null;
		}
		var d = new AccountCustomizeData();
		d.hatColor = intAt(args, 0);
		d.headColor = intAt(args, 1);
		d.bodyColor = intAt(args, 2);
		d.feetColor = intAt(args, 3);
		d.hat = intAt(args, 4);
		d.head = intAt(args, 5);
		d.body = intAt(args, 6);
		d.feet = intAt(args, 7);
		d.hats = partsAt(args, 8);
		d.heads = partsAt(args, 9);
		d.bodies = partsAt(args, 10);
		d.feetParts = partsAt(args, 11);
		d.speed = intAt(args, 12);
		d.acceleration = intAt(args, 13);
		d.jumping = intAt(args, 14);
		d.rank = intAt(args, 15);
		d.rankTokensUsed = intAt(args, 16);
		d.rankTokensAvailable = intAt(args, 17);
		d.hatColor2 = intAt(args, 18, -1);
		d.headColor2 = intAt(args, 19, -1);
		d.bodyColor2 = intAt(args, 20, -1);
		d.feetColor2 = intAt(args, 21, -1);
		d.epicHats = partsAt(args, 22);
		d.epicHeads = partsAt(args, 23);
		d.epicBodies = partsAt(args, 24);
		d.epicFeet = partsAt(args, 25);
		d.happyHour = intAt(args, 26) != 0;
		return d;
	}

	private static function intAt(args:Array<String>, index:Int, fallback:Int = 0):Int {
		var value = Std.parseInt(args[index]);
		return value == null ? fallback : value;
	}

	private static function partsAt(args:Array<String>, index:Int):Array<String> {
		return args[index] == null || args[index] == "" ? [] : args[index].split(",");
	}
}
