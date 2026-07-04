package pr2.gameplay.items;

class Mine extends Item {
	public function new() {
		super(pr2.gameplay.Items.MINE, "Mine");
	}

	override public function use(owner:ItemRuntimeOwner):Void {
		owner.performMineItem();
	}
}
