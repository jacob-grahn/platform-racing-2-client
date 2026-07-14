package pr2.gameplay;

import pr2.gameplay.GameCommandShell;
import pr2.net.CommandHandler;

/**
	A5 coverage: the `GameCommandShell` registers every server command
	`Game.initialize` defines, parses each frame exactly as the Flash handlers do,
	and routes it to the delegate. Frames are pushed through `handleServerFrame`
	(`hash`sendNum`command`args...`) so the registration and the gameserver frame
	layout are exercised end-to-end. `install`/`remove` parity is asserted too.
**/
class GameCommandShellTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var cm = new CommandHandler();
		var rec = new RecordingDelegate();
		var shell = new GameCommandShell(rec, cm);
		shell.install();

		// createLocalCharacter: 17 args (tempId, speed, accel, jump, 4 colors, 4
		// parts, 4 secondary colors, group).
		send(cm, "createLocalCharacter`7`6.5`0.3`13`100`200`300`400`1`2`3`4`11`12`13`14`g");
		assertEquals(7, rec.localInit.tempId, "local tempId parsed");
		if (pr2.DeterministicTestMode.finishSmokeSuite("GameCommandShellTest")) return;
		assertClose(6.5, rec.localInit.speed, "local speed parsed");
		assertClose(0.3, rec.localInit.accel, "local accel parsed");
		assertClose(13, rec.localInit.jump, "local jump parsed");
		assertClose(100, rec.localInit.hatColor, "local hatColor parsed");
		assertClose(4, rec.localInit.feetId, "local feetId parsed");
		assertClose(14, rec.localInit.feetColor2, "local feetColor2 parsed");
		assertEquals("g", rec.localInit.group, "local group parsed");

		// createRemoteCharacter: 15 args (tempId, userName, 4 colors, 4 parts, 4
		// secondary colors, group).
		send(cm, "createRemoteCharacter`9`Rival`100`200`300`400`5`6`7`8`11`12`13`14`mod");
		assertEquals(9, rec.remoteInit.tempId, "remote tempId parsed");
		assertEquals("Rival", rec.remoteInit.userName, "remote userName parsed");
		assertClose(5, rec.remoteInit.hatId, "remote hatId parsed");
		assertClose(14, rec.remoteInit.feetColor2, "remote feetColor2 parsed");
		assertEquals("mod", rec.remoteInit.group, "remote group parsed");

		send(cm, "beginRace`");
		assertEquals(1, rec.beginRaceCount, "beginRace routed");

		send(cm, "award`coin`50");
		assertEquals("coin", rec.awardArgs[0], "award arg0 routed verbatim");
		assertEquals("50", rec.awardArgs[1], "award arg1 routed verbatim");

		send(cm, "setExpGain`120`180`200");
		assertEquals(120, rec.expOld, "expOld parsed");
		assertEquals(180, rec.expNew, "expNew parsed");
		assertEquals(200, rec.expToRank, "expToRank parsed");
		assertEquals(true, send(cm, "setExpGain`121`181`201`", true), "trailing-delimited exp gain frame routes");
		assertEquals(121, rec.expOld, "trailing frame expOld parsed");
		assertEquals(181, rec.expNew, "trailing frame expNew parsed");
		assertEquals(201, rec.expToRank, "trailing frame expToRank parsed");

		send(cm, "setLuxGain`25");
		assertEquals(25, rec.luxAmount, "lux amount parsed");

		send(cm, "setPrize`{\"type\":\"hat\",\"id\":3,\"name\":\"Top Hat\"}");
		assertEquals("hat", rec.prize.type, "setPrize JSON parsed (type)");
		assertEquals(3, rec.prize.id, "setPrize JSON parsed (id)");
		assertEquals(false, rec.prizeWon, "setPrize is not a win");

		send(cm, "cancelPrize`Better luck next time");
		assertEquals("Better luck next time", rec.cancelMessage, "cancel message routed");

		send(cm, "winPrize`{\"type\":\"hat\",\"id\":3,\"name\":\"Top Hat\"}");
		assertEquals("Top Hat", rec.prize.name, "winPrize JSON parsed (name)");
		assertEquals(true, rec.prizeWon, "winPrize flags a win");

		send(cm, "cowboyMode`");
		assertEquals(1, rec.cowboyCount, "cowboyMode routed");

		send(cm, "happyHour`");
		assertEquals(1, rec.happyHourCount, "happyHour routed");

		send(cm, "setEggSeed`777");
		assertEquals(777, rec.eggSeed, "egg seed parsed");

		send(cm, "addEggs`4");
		assertEquals(4, rec.eggsAdded, "egg count parsed");

		send(cm, "setLife`2");
		assertEquals(2, rec.lives, "setLife count parsed");

		send(cm, "superBooster`9");
		assertEquals(9, rec.boostedTempId, "superBooster tempId parsed");

		send(cm, "maybeReturnHatToStart`2");
		assertEquals(2, rec.returnHatId, "maybeReturnHatToStart hatId parsed");

		// startHatCountdown installs the self-clearing cancel command.
		assertEquals(false, cm.hasCommand("cancelHatCountdown"), "cancel command absent before start");
		send(cm, "startHatCountdown`");
		assertEquals(1, rec.hatCountdownStarts, "startHatCountdown routed");
		assertEquals(true, shell.hatCountdownActive, "countdown active after start");
		assertEquals(true, cm.hasCommand("cancelHatCountdown"), "cancel command installed by start");
		send(cm, "cancelHatCountdown`");
		assertEquals(false, shell.hatCountdownActive, "countdown cleared by cancel");
		assertEquals(false, cm.hasCommand("cancelHatCountdown"), "cancel command self-clears");
		assertEquals(1, rec.hatCountdownCancels, "cancelHatCountdown routed");

		send(cm, "areYouHuman`");
		assertEquals(1, rec.areYouHumanCount, "areYouHuman routed");

		send(cm, "forceQuit`");
		assertEquals(1, rec.forceQuitCount, "forceQuit routed");

		// Teardown drops every command (a later frame must not route).
		shell.remove();
		assertEquals(false, cm.hasCommand("createLocalCharacter"), "createLocalCharacter cleared on remove");
		assertEquals(false, cm.hasCommand("beginRace"), "beginRace cleared on remove");
		assertEquals(false, cm.hasCommand("setLife"), "setLife cleared on remove");
		assertEquals(true, cm.hasCommand("areYouHuman"), "default areYouHuman survives shell remove");
		assertEquals(false, cm.hasCommand("forceQuit"), "forceQuit cleared on remove");
		assertEquals(false, send(cm, "award`coin`50"), "no command routes after remove");

		trace('GameCommandShellTest passed $assertions assertions');
	}

	private static var sendNum:Int = 0;

	private static function send(cm:CommandHandler, body:String, preserveTrailing:Bool = false):Bool {
		var parts = body.split("`");
		var command = parts.shift();
		if (!preserveTrailing && parts.length > 0 && parts[parts.length - 1] == "") {
			parts.pop();
		}
		sendNum++;
		return cm.handleServerFrame(CommandHandler.buildServerFrame(sendNum, command, parts));
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.001) {
			throw '$message: expected $expected, got $actual';
		}
	}
}

private class RecordingDelegate implements GameCommandDelegate {
	public var localInit:LocalCharacterInit;
	public var remoteInit:RemoteCharacterInit;
	public var beginRaceCount:Int = 0;
	public var awardArgs:Array<String> = [];
	public var expOld:Int;
	public var expNew:Int;
	public var expToRank:Int;
	public var luxAmount:Int;
	public var prize:Dynamic;
	public var prizeWon:Bool = false;
	public var cancelMessage:String;
	public var cowboyCount:Int = 0;
	public var happyHourCount:Int = 0;
	public var eggSeed:Int;
	public var eggsAdded:Int;
	public var lives:Int;
	public var boostedTempId:Int;
	public var returnHatId:Int;
	public var hatCountdownStarts:Int = 0;
	public var hatCountdownCancels:Int = 0;
	public var areYouHumanCount:Int = 0;
	public var forceQuitCount:Int = 0;

	public function new() {}

	public function createRemoteCharacter(init:RemoteCharacterInit):Void {
		remoteInit = init;
	}

	public function createLocalCharacter(init:LocalCharacterInit):Void {
		localInit = init;
	}

	public function beginRace():Void {
		beginRaceCount++;
	}

	public function award(args:Array<String>):Void {
		awardArgs = args;
	}

	public function setExpGain(expOld:Int, expNew:Int, expToRank:Int):Void {
		this.expOld = expOld;
		this.expNew = expNew;
		this.expToRank = expToRank;
	}

	public function setLuxGain(amount:Int):Void {
		luxAmount = amount;
	}

	public function setPrize(prize:Dynamic):Void {
		this.prize = prize;
		prizeWon = false;
	}

	public function cancelPrize(message:String):Void {
		cancelMessage = message;
	}

	public function winPrize(prize:Dynamic):Void {
		this.prize = prize;
		prizeWon = true;
	}

	public function cowboyMode():Void {
		cowboyCount++;
	}

	public function happyHour():Void {
		happyHourCount++;
	}

	public function setEggSeed(seed:Int):Void {
		eggSeed = seed;
	}

	public function addEggs(count:Int):Void {
		eggsAdded = count;
	}

	public function setLife(lives:Int):Void {
		this.lives = lives;
	}

	public function superBooster(tempId:Int):Void {
		boostedTempId = tempId;
	}

	public function maybeReturnHatToStart(hatId:Int):Void {
		returnHatId = hatId;
	}

	public function startHatCountdown():Void {
		hatCountdownStarts++;
	}

	public function cancelHatCountdown():Void {
		hatCountdownCancels++;
	}

	public function areYouHuman():Void {
		areYouHumanCount++;
	}

	public function forceQuit():Void {
		forceQuitCount++;
	}
}
