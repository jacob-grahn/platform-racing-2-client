package pr2.gameplay.player;

class LocalPlayerInput {
	public var left:Bool;
	public var right:Bool;
	public var jump:Bool;
	public var down:Bool;
	public var item:Bool;
	/** Sustain an existing jump (or paddle upward), without initiating a jump. */
	public var jumpHold:Bool;

	public function new(left:Bool = false, right:Bool = false, jump:Bool = false, down:Bool = false, item:Bool = false, jumpHold:Bool = false) {
		this.left = left;
		this.right = right;
		this.jump = jump;
		this.down = down;
		this.item = item;
		this.jumpHold = jumpHold;
	}

	public function copy():LocalPlayerInput {
		return new LocalPlayerInput(left, right, jump, down, item, jumpHold);
	}

	public function clear():Void {
		left = false;
		right = false;
		jump = false;
		down = false;
		item = false;
		jumpHold = false;
	}
}
