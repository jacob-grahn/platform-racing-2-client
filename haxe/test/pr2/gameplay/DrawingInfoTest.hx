package pr2.gameplay;

import pr2.lobby.LobbySession;
import pr2.net.CommandHandler;

class DrawingInfoTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testPlayerDrawingRows();
		testFinishDrawingCommand();
		testFinishTimesCommandAndRaceRows();
		testObjectiveRowsAndKongStats();
		trace('DrawingInfoTest passed $assertions assertions');
	}

	private static function testPlayerDrawingRows():Void {
		var commands = new CommandHandler();
		var info = new DrawingInfo(commands);
		for (i in 0...4) {
			assertEquals("", info.playerName(i), 'name $i starts empty');
			assertEquals("", info.timeText(i), 'time $i starts empty');
			assertEquals(false, info.isDrawing(i), 'spinner $i starts hidden');
		}

		info.addPlayer("Tester", 2);
		assertEquals("Tester", info.playerName(2), "addPlayer writes name");
		assertEquals(true, info.isDrawing(2), "addPlayer shows drawing spinner");

		info.finishDrawing(2);
		assertEquals(false, info.isDrawing(2), "finishDrawing hides spinner");
		assertEquals("Tester", info.playerName(2), "finishDrawing keeps player name");

		info.clear();
		assertEquals("", info.playerName(2), "clear removes name without finish time");
		assertEquals(false, info.isDrawing(2), "clear keeps spinner hidden");
		info.remove();
	}

	private static function testFinishDrawingCommand():Void {
		var commands = new CommandHandler();
		var info = new DrawingInfo(commands);
		assertEquals(true, commands.hasCommand("finishDrawing"), "constructor registers finishDrawing");
		info.addPlayer("Local", 0);
		assertEquals(true, info.isDrawing(0), "player waits while drawing");
		assertEquals(true, commands.dispatch("finishDrawing", ["0"]), "command dispatches");
		assertEquals(false, info.isDrawing(0), "finishDrawing command hides spinner");
		info.remove();
		assertEquals(false, commands.hasCommand("finishDrawing"), "remove unregisters finishDrawing");
	}

	private static function testFinishTimesCommandAndRaceRows():Void {
		var savedName = LobbySession.userName;
		LobbySession.userName = "Local";
		var frames = 81;
		var commands = new CommandHandler();
		var info = new DrawingInfo(commands, Modes.race, 0, function():Int return frames, function():Float return 27);
		assertEquals(true, commands.hasCommand("finishTimes"), "constructor registers finishTimes");
		info.addPlayer("Drawing", 1);
		assertEquals(true, commands.dispatch("finishTimes", [
			"Local", "65.347", "0", "1",
			"Rival", "forfeit", "0", "0",
			"Sketchy", "0", "1", "1"
		]), "finishTimes command dispatches");
		assertEquals("Local", info.playerName(0), "local row name");
		assertEquals("1:05.35*", info.timeText(0), "local row decimal time gets nerd star");
		assertEquals("Rival", info.playerName(1), "forfeit row name");
		assertEquals("forfeit (gone)", info.timeText(1), "forfeit row shows gone suffix");
		assertEquals("Sketchy", info.playerName(2), "drawing row name");
		assertEquals("", info.timeText(2), "drawing row has no time yet");
		assertEquals(true, info.isDrawing(2), "drawing row shows spinner");
		info.showLocalTimeHoverForTests();
		assertEquals(true, info.hasLocalTimeHoverForTests(), "local time hover opens");
		assertEquals("The time listed here is the time the server reports. This includes lag.\n\nSince you played for 81 frames at 27fps, your no-lag time is 0:03.00.",
			info.localTimeHoverContentForTests(), "hover describes server and no-lag time");
		info.hideLocalTimeHoverForTests();
		assertEquals(false, info.hasLocalTimeHoverForTests(), "local time hover closes");
		info.remove();
		assertEquals(false, commands.hasCommand("finishTimes"), "remove unregisters finishTimes");
		LobbySession.userName = savedName;
	}

	private static function testObjectiveRowsAndKongStats():Void {
		var savedName = LobbySession.userName;
		LobbySession.userName = "Local";
		var submitted:Array<String> = [];
		var info = new DrawingInfo(new CommandHandler(), Modes.obj, 50815, null, null, function(name:String, value:String):Void {
			submitted.push('$name=$value');
		});
		info.finishRace([
			"Local", "77.2,2,5", "0", "1",
			"Rival", "forfeit,1,5", "0", "1"
		]);
		assertEquals("1:17.20 (2/5)*", info.timeText(0), "objective local row formats time and count");
		assertEquals("forfeit (1/5)", info.timeText(1), "objective forfeit keeps objective count");
		assertEquals("Newbieland 2=77.2,2,5", submitted.join("|"), "known campaign course submits Kong stat");
		info.remove();

		var egg = new DrawingInfo(new CommandHandler(), Modes.egg);
		egg.finishRace(["Local", "3", "0", "1"]);
		assertEquals("3", egg.timeText(0), "egg mode keeps raw score without local star");
		egg.remove();
		LobbySession.userName = savedName;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
