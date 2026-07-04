package pr2.gameplay.items;

class SuperJump extends Item {
	public function new() {
		super(pr2.gameplay.Items.SUPER_JUMP, "Super Jump");
	}

	override public function use(owner:ItemRuntimeOwner):Void {
		owner.performSuperJumpItem();
	}
}
