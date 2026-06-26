package pr2.gameplay;

import pr2.net.CommandHandler;

class DrawingInfoTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testPlayerDrawingRows();
		testFinishDrawingCommand();
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

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
