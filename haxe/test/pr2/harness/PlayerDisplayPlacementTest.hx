package pr2.harness;

import openfl.display.Sprite;

class PlayerDisplayPlacementTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCrouchDoesNotSquashCharacterDisplay();
		trace('PlayerDisplayPlacementTest passed $assertions assertions');
	}

	private static function testCrouchDoesNotSquashCharacterDisplay():Void {
		var playerDisplay = new Sprite();
		var characterDisplay = new Sprite();
		characterDisplay.scaleX = PlayerDisplayPlacement.CHARACTER_SCALE;
		characterDisplay.scaleY = PlayerDisplayPlacement.CHARACTER_SCALE;
		playerDisplay.addChild(characterDisplay);

		PlayerDisplayPlacement.place(playerDisplay, characterDisplay, 75, 300, true, -1);

		assertClose(65, playerDisplay.x, "container x stays aligned to the standing hitbox width");
		assertClose(270, playerDisplay.y, "crouch placement uses the shorter collision height");
		assertClose(1, playerDisplay.scaleY, "crouch does not visually squash the character container");
		assertClose(-0.9, characterDisplay.scaleX, "facing still flips the authored character scale");
		assertClose(0.9, characterDisplay.scaleY, "crouch keeps the authored character scale");
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.0001) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
