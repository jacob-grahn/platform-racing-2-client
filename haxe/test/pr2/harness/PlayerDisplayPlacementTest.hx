package pr2.harness;

import openfl.display.Sprite;
import openfl.geom.Point;

class PlayerDisplayPlacementTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCrouchDoesNotSquashCharacterDisplay();
		testRotationUsesFeetPivot();
		trace('PlayerDisplayPlacementTest passed $assertions assertions');
	}

	private static function testCrouchDoesNotSquashCharacterDisplay():Void {
		var playerDisplay = new Sprite();
		var characterDisplay = new Sprite();
		characterDisplay.scaleX = PlayerDisplayPlacement.CHARACTER_SCALE;
		characterDisplay.scaleY = PlayerDisplayPlacement.CHARACTER_SCALE;
		playerDisplay.addChild(characterDisplay);

		PlayerDisplayPlacement.place(playerDisplay, characterDisplay, 75, 300, -1);

		assertClose(65, playerDisplay.x, "container x stays aligned to the standing hitbox width");
		assertClose(245, playerDisplay.y, "placement always anchors the feet-aligned display origin at the standing height");
		assertClose(1, playerDisplay.scaleY, "crouch does not visually squash the character container");
		assertClose(-0.9, characterDisplay.scaleX, "facing still flips the authored character scale");
		assertClose(0.9, characterDisplay.scaleY, "crouch keeps the authored character scale");
	}

	private static function testRotationUsesFeetPivot():Void {
		var playerDisplay = new Sprite();
		var characterDisplay = new Sprite();
		playerDisplay.addChild(characterDisplay);

		PlayerDisplayPlacement.place(playerDisplay, characterDisplay, 75, 300, 1, -90);

		var feet = playerDisplay.transform.matrix.transformPoint(new Point(LocalPlayerController.STANDING_WIDTH / 2,
			LocalPlayerController.STANDING_HEIGHT));
		assertClose(-90, playerDisplay.rotation, "container stores the requested rotation");
		assertClose(75, feet.x, "rotated container keeps the feet pivot on the requested x");
		assertClose(300, feet.y, "rotated container keeps the feet pivot on the requested y");
		assertClose(0.9, characterDisplay.scaleX, "rotation keeps the authored character x scale");
		assertClose(0.9, characterDisplay.scaleY, "rotation keeps the authored character y scale");
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.0001) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
