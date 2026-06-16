package pr2.harness;

class LocalPlayerInput {
	public var left:Bool;
	public var right:Bool;
	public var jump:Bool;
	public var down:Bool;

	public function new(left:Bool = false, right:Bool = false, jump:Bool = false, down:Bool = false) {
		this.left = left;
		this.right = right;
		this.jump = jump;
		this.down = down;
	}

	public function copy():LocalPlayerInput {
		return new LocalPlayerInput(left, right, jump, down);
	}
}
