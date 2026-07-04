package pr2.gameplay.items;

class Lightning extends Item {
	public function new() {
		super(pr2.gameplay.Items.LIGHTNING, "Lightning");
	}

	override public function use(owner:ItemRuntimeOwner):Void {
		owner.performLightningItem();
	}
}
