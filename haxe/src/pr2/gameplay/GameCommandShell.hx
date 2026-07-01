package pr2.gameplay;

import haxe.Json;
import pr2.net.CommandHandler;

/** Parsed args for `createRemoteCharacter` (see `Game.createRemoteCharacter`). */
typedef RemoteCharacterInit = {
	tempId:Int,
	userName:String,
	hatColor:Float, headColor:Float, bodyColor:Float, feetColor:Float,
	hatId:Float, headId:Float, bodyId:Float, feetId:Float,
	hatColor2:Float, headColor2:Float, bodyColor2:Float, feetColor2:Float,
	group:String
}

/** Parsed args for `createLocalCharacter` (see `Game.createLocalCharacter`). */
typedef LocalCharacterInit = {
	tempId:Int,
	speed:Float, accel:Float, jump:Float,
	hatColor:Float, headColor:Float, bodyColor:Float, feetColor:Float,
	hatId:Float, headId:Float, bodyId:Float, feetId:Float,
	hatColor2:Float, headColor2:Float, bodyColor2:Float, feetColor2:Float,
	group:String
}

/**
	Side-effecting half of the `Game` command shell. `GameCommandShell` owns the
	parse-and-register half (faithful to `Game.as`); the live `Game`/`Course`
	shell implements this to apply the effects (spawn characters, show popups,
	mutate race state). Splitting it keeps the parsing/routing transcript-testable
	without dragging in the not-yet-ported display objects and the multiplayer
	`Character` hierarchy (filled in by Section B).
**/
interface GameCommandDelegate {
	function createRemoteCharacter(init:RemoteCharacterInit):Void;
	function createLocalCharacter(init:LocalCharacterInit):Void;
	function beginRace():Void;
	function award(args:Array<String>):Void;
	function setExpGain(expOld:Int, expNew:Int, expToRank:Int):Void;
	function setLuxGain(amount:Int):Void;
	function setPrize(prize:Dynamic):Void;
	function cancelPrize(message:String):Void;
	function winPrize(prize:Dynamic):Void;
	function cowboyMode():Void;
	function happyHour():Void;
	function setEggSeed(seed:Int):Void;
	function addEggs(count:Int):Void;
	function superBooster(tempId:Int):Void;
	function maybeReturnHatToStart(hatId:Int):Void;
	function startHatCountdown():Void;
	function cancelHatCountdown():Void;
	function areYouHuman():Void;
	function forceQuit():Void;
}

/**
	Registration + argument-parsing port of the server-command table in
	`gameplay.Game.initialize` / `Game.remove`. Each command is parsed exactly as
	the Flash handlers do (`int(...)`, `Number(...)`, `JSON.parse(...)`) and routed
	to a `GameCommandDelegate`.

	The character-creation commands carry the full part/color/group payload that
	Section B's `LocalCharacter`/`RemoteCharacter` need, so the parse lives here
	and B5 just consumes the typed init records. `startHatCountdown` also installs
	the self-clearing `cancelHatCountdown` command, mirroring the original.
**/
class GameCommandShell {
	private final delegate:GameCommandDelegate;
	private final cm:CommandHandler;
	public var hatCountdownActive(default, null):Bool = false;

	public function new(delegate:GameCommandDelegate, ?commandHandler:CommandHandler) {
		this.delegate = delegate;
		this.cm = commandHandler != null ? commandHandler : CommandHandler.commandHandler;
	}

	/** Register every server command `Game.initialize` defines. */
	public function install():Void {
		cm.defineCommand("createRemoteCharacter", onCreateRemoteCharacter);
		cm.defineCommand("createLocalCharacter", onCreateLocalCharacter);
		cm.defineCommand("beginRace", onBeginRace);
		cm.defineCommand("award", onAward);
		cm.defineCommand("setExpGain", onSetExpGain);
		cm.defineCommand("setLuxGain", onSetLuxGain);
		cm.defineCommand("setPrize", onSetPrize);
		cm.defineCommand("cancelPrize", onCancelPrize);
		cm.defineCommand("winPrize", onWinPrize);
		cm.defineCommand("cowboyMode", onCowboyMode);
		cm.defineCommand("happyHour", onHappyHour);
		cm.defineCommand("setEggSeed", onSetEggSeed);
		cm.defineCommand("addEggs", onAddEggs);
		cm.defineCommand("superBooster", onSuperBooster);
		cm.defineCommand("maybeReturnHatToStart", onMaybeReturnHatToStart);
		cm.defineCommand("startHatCountdown", onStartHatCountdown);
		cm.defineCommand("areYouHuman", onAreYouHuman);
		cm.defineCommand("forceQuit", onForceQuit);
	}

	/** Unregister every command (mirrors `Game.remove`, incl. cancelHatCountdown). */
	public function remove():Void {
		cm.defineCommand("createRemoteCharacter", null);
		cm.defineCommand("createLocalCharacter", null);
		cm.defineCommand("beginRace", null);
		cm.defineCommand("award", null);
		cm.defineCommand("setExpGain", null);
		cm.defineCommand("setLuxGain", null);
		cm.defineCommand("setPrize", null);
		cm.defineCommand("cancelPrize", null);
		cm.defineCommand("winPrize", null);
		cm.defineCommand("cowboyMode", null);
		cm.defineCommand("happyHour", null);
		cm.defineCommand("setEggSeed", null);
		cm.defineCommand("addEggs", null);
		cm.defineCommand("superBooster", null);
		cm.defineCommand("maybeReturnHatToStart", null);
		cm.defineCommand("startHatCountdown", null);
		cm.defineCommand("areYouHuman", null);
		cm.defineCommand("forceQuit", null);
		cancelHatCountdown();
	}

	// ---- handlers --------------------------------------------------------

	private function onCreateRemoteCharacter(a:Array<String>):Void {
		delegate.createRemoteCharacter({
			tempId: toInt(a[0]),
			userName: arg(a, 1),
			hatColor: toFloat(a[2]), headColor: toFloat(a[3]), bodyColor: toFloat(a[4]), feetColor: toFloat(a[5]),
			hatId: toFloat(a[6]), headId: toFloat(a[7]), bodyId: toFloat(a[8]), feetId: toFloat(a[9]),
			hatColor2: toFloat(a[10]), headColor2: toFloat(a[11]), bodyColor2: toFloat(a[12]), feetColor2: toFloat(a[13]),
			group: arg(a, 14)
		});
	}

	private function onCreateLocalCharacter(a:Array<String>):Void {
		delegate.createLocalCharacter({
			tempId: toInt(a[0]),
			speed: toFloat(a[1]), accel: toFloat(a[2]), jump: toFloat(a[3]),
			hatColor: toFloat(a[4]), headColor: toFloat(a[5]), bodyColor: toFloat(a[6]), feetColor: toFloat(a[7]),
			hatId: toFloat(a[8]), headId: toFloat(a[9]), bodyId: toFloat(a[10]), feetId: toFloat(a[11]),
			hatColor2: toFloat(a[12]), headColor2: toFloat(a[13]), bodyColor2: toFloat(a[14]), feetColor2: toFloat(a[15]),
			group: arg(a, 16)
		});
	}

	private function onBeginRace(_:Array<String>):Void {
		delegate.beginRace();
	}

	private function onAward(a:Array<String>):Void {
		delegate.award(a);
	}

	private function onSetExpGain(a:Array<String>):Void {
		delegate.setExpGain(toInt(a[0]), toInt(a[1]), toInt(a[2]));
	}

	private function onSetLuxGain(a:Array<String>):Void {
		delegate.setLuxGain(toInt(a[0]));
	}

	private function onSetPrize(a:Array<String>):Void {
		delegate.setPrize(Json.parse(arg(a, 0)));
	}

	private function onCancelPrize(a:Array<String>):Void {
		delegate.cancelPrize(arg(a, 0));
	}

	private function onWinPrize(a:Array<String>):Void {
		delegate.winPrize(Json.parse(arg(a, 0)));
	}

	private function onCowboyMode(_:Array<String>):Void {
		delegate.cowboyMode();
	}

	private function onHappyHour(_:Array<String>):Void {
		delegate.happyHour();
	}

	private function onSetEggSeed(a:Array<String>):Void {
		delegate.setEggSeed(toInt(a[0]));
	}

	private function onAddEggs(a:Array<String>):Void {
		delegate.addEggs(toInt(a[0]));
	}

	private function onSuperBooster(a:Array<String>):Void {
		delegate.superBooster(toInt(a[0]));
	}

	private function onMaybeReturnHatToStart(a:Array<String>):Void {
		delegate.maybeReturnHatToStart(toInt(a[0]));
	}

	private function onStartHatCountdown(_:Array<String>):Void {
		// The original installs the self-clearing cancel command alongside the
		// 1s `check_hat_countdown` interval; the interval/emission belongs to the
		// live shell, so here we only track the active flag + the cancel command.
		cm.defineCommand("cancelHatCountdown", onCancelHatCountdown);
		hatCountdownActive = true;
		delegate.startHatCountdown();
	}

	private function onCancelHatCountdown(_:Array<String>):Void {
		cancelHatCountdown();
		delegate.cancelHatCountdown();
	}

	private function cancelHatCountdown():Void {
		cm.defineCommand("cancelHatCountdown", null);
		hatCountdownActive = false;
	}

	private function onForceQuit(_:Array<String>):Void {
		delegate.forceQuit();
	}

	private function onAreYouHuman(_:Array<String>):Void {
		delegate.areYouHuman();
	}

	// ---- arg helpers -----------------------------------------------------

	private static inline function arg(a:Array<String>, i:Int):String {
		return a != null && i < a.length && a[i] != null ? a[i] : "";
	}

	/** AS3 `int(x)`: parse, falling back to 0 on null/non-numeric. */
	private static inline function toInt(value:String):Int {
		var n = value == null ? null : Std.parseInt(value);
		return n == null ? 0 : n;
	}

	/** AS3 `Number(x)`: parse, falling back to 0 on null/NaN. */
	private static inline function toFloat(value:String):Float {
		var n = value == null ? Math.NaN : Std.parseFloat(value);
		return Math.isNaN(n) ? 0 : n;
	}
}
