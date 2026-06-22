package pr2.character;

class CharacterStateTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testFromMotionPriorities();
		testClipNames();
		trace('CharacterStateTest passed $assertions assertions');
	}

	private static function testFromMotionPriorities():Void {
		assertEquals(CharacterState.Freeze, CharacterState.fromMotion("freeze", true, false, 0, false, false), "freeze mode owns state");
		assertEquals(CharacterState.Freeze, CharacterState.fromMotion("frozenSolid", true, false, 0, false, false), "frozen-solid mode owns state");
		assertEquals(CharacterState.Bumped, CharacterState.fromMotion("hurt", true, false, 0, false, false), "hurt mode owns state");
		assertEquals(CharacterState.Swim, CharacterState.fromMotion("water", true, false, 0, false, false), "water mode owns state");
		assertEquals(CharacterState.SuperJump, CharacterState.fromMotion("land", true, false, 26, false, false), "charged crouch uses super jump");
		assertEquals(CharacterState.CrouchWalk, CharacterState.fromMotion("land", true, true, 0, true, false), "held direction uses crouch walk");
		assertEquals(CharacterState.Crouch, CharacterState.fromMotion("land", true, true, 0, false, false), "released direction uses crouch");
		assertEquals(CharacterState.Jump, CharacterState.fromMotion("land", false, false, 0, false, false), "all airborne motion uses jump");
		assertEquals(CharacterState.Run, CharacterState.fromMotion("land", true, false, 0, false, true), "held direction uses run");
		assertEquals(CharacterState.Stand, CharacterState.fromMotion("land", true, false, 0, false, false), "released direction uses stand");
	}

	private static function testClipNames():Void {
		assertEquals("runAnim", CharacterState.Run.toClipName(), "run clip");
		assertEquals("standAnim", CharacterState.Stand.toClipName(), "stand clip");
		assertEquals("jumpAnim", CharacterState.Jump.toClipName(), "jump clip");
		assertEquals("jumpAnim", CharacterState.Fall.toClipName(), "fall reuses jump clip");
		assertEquals("superJumpAnim", CharacterState.SuperJump.toClipName(), "super jump clip");
		assertEquals("crouchAnim", CharacterState.Crouch.toClipName(), "crouch clip");
		assertEquals("crouchWalkAnim", CharacterState.CrouchWalk.toClipName(), "crouch walk clip");
		assertEquals("swimAnim", CharacterState.Swim.toClipName(), "swim clip");
		assertEquals("frozenSolidAnim", CharacterState.Freeze.toClipName(), "freeze clip");
		assertEquals("bumpedAnim", CharacterState.Bumped.toClipName(), "bumped clip");
	}

	private static function assertEquals<T>(expected:T, actual:T, message:String):Void {
		assertions++;
		if (actual != expected) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
