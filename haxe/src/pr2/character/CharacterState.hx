package pr2.character;

enum abstract CharacterState(String) from String to String {
	public var Run = "run";
	public var Stand = "stand";
	public var Jump = "jump";
	public var Fall = "fall";
	public var SuperJump = "superJump";
	public var Crouch = "crouch";
	public var CrouchWalk = "crouchWalk";
	public var Swim = "swim";
	public var Freeze = "freeze";
	public var Bumped = "bumped";

	public static function fromMotion(mode:String, grounded:Bool, crouching:Bool, crouchCharge:Float, vx:Float, vy:Float):CharacterState {
		if (mode == "freeze") {
			return Freeze;
		}
		if (mode == "hurt") {
			return Bumped;
		}
		if (mode == "water") {
			return Swim;
		}
		if (crouchCharge > 25) {
			return SuperJump;
		}
		if (crouching) {
			return Math.abs(vx) > 0.05 ? CrouchWalk : Crouch;
		}
		if (!grounded) {
			return vy < 0 ? Jump : Fall;
		}
		return Math.abs(vx) > 0.05 ? Run : Stand;
	}

	public function toClipName():String {
		return switch (cast this : String) {
			case "run": "runAnim";
			case "stand": "standAnim";
			case "jump" | "fall": "jumpAnim";
			case "superJump": "superJumpAnim";
			case "crouch": "crouchAnim";
			case "crouchWalk": "crouchWalkAnim";
			case "swim": "swimAnim";
			case "freeze": "frozenSolidAnim";
			case "bumped": "bumpedAnim";
			default: "standAnim";
		}
	}

	public function toString():String {
		return this;
	}
}
