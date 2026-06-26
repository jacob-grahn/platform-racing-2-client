package pr2.character;

import pr2.harness.LocalPlayerController;
import pr2.harness.LocalPlayerDebugState;
import pr2.harness.LocalPlayerInput;
import pr2.level.FixtureLevel;

/**
	`LocalCharacter` physics bridge for B2.

	The audited land/block/item physics still lives in `LocalPlayerController`;
	this class gives the multiplayer character hierarchy a `Character` subclass
	that owns that controller and mirrors its authoritative motion state.
**/
class LocalCharacter extends Character {
	public final controller:LocalPlayerController;

	public var grounded(get, never):Bool;
	public var crouching(get, never):Bool;
	public var facingScaleX(get, never):Int;

	public function new(level:FixtureLevel, hatId:Int = 1, headId:Int = 1, bodyId:Int = 1, feetId:Int = 1) {
		super(hatId, headId, bodyId, feetId);
		type = "local";
		controller = new LocalPlayerController(level);
		syncFromController();
	}

	public function step(input:LocalPlayerInput):Void {
		controller.step(input);
		syncFromController();
	}

	public function setGravity(multiplier:Float):Void {
		controller.setGravity(multiplier);
	}

	public function debugState():LocalPlayerDebugState {
		return controller.debugState();
	}

	public function blockAlphaAt(tileX:Int, tileY:Int):Float {
		return controller.blockAlphaAt(tileX, tileY);
	}

	public function blockColorMultiplierAt(tileX:Int, tileY:Int):Float {
		return controller.blockColorMultiplierAt(tileX, tileY);
	}

	private function syncFromController():Void {
		var state = controller.debugState();
		x = state.x;
		y = state.y;
		velX = state.vx;
		velY = state.vy;
		setItem(state.itemId == null ? 0 : state.itemId);
		changeState(state.animation);
		display.scaleX = 0.9 * controller.facingScaleX;
		display.scaleY = 0.9;
	}

	private function get_grounded():Bool {
		return controller.grounded;
	}

	private function get_crouching():Bool {
		return controller.crouching;
	}

	private function get_facingScaleX():Int {
		return controller.facingScaleX;
	}
}
