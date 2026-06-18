package pr2.character;

class CharacterStateTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testFromMotionPriorities();
		testClipNames();
		trace('CharacterStateTest passed $assertions assertions');
	}

	private static function testFromMotionPriorities():Void {
		assertEquals(CharacterState.Freeze, CharacterState.fromMotion("freeze", true, false, 0, 0, 0), "freeze mode owns state");
		assertEquals(CharacterState.Bumped, CharacterState.fromMotion("hurt", true, false, 0, 0, 0), "hurt mode owns state");
		assertEquals(CharacterState.Swim, CharacterState.fromMotion("water", true, false, 0, 0, 0), "water mode owns state");
		assertEquals(CharacterState.SuperJump, CharacterState.fromMotion("land", true, false, 26, 0, 0), "charged crouch uses super jump");
		assertEquals(CharacterState.CrouchWalk, CharacterState.fromMotion("land", true, true, 0, 0.1, 0), "moving crouch uses crouch walk");
		assertEquals(CharacterState.Crouch, CharacterState.fromMotion("land", true, true, 0, 0, 0), "still crouch uses crouch");
		assertEquals(CharacterState.Jump, CharacterState.fromMotion("land", false, false, 0, 0, -1), "negative vy uses jump");
		assertEquals(CharacterState.Fall, CharacterState.fromMotion("land", false, false, 0, 0, 1), "positive vy uses fall");
		assertEquals(CharacterState.Run, CharacterState.fromMotion("land", true, false, 0, 0.1, 0), "ground movement uses run");
		assertEquals(CharacterState.Stand, CharacterState.fromMotion("land", true, false, 0, 0, 0), "still grounded uses stand");
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
