package pr2.gameplay.items;

class Teleport extends Item {
	public function new() {
		super(pr2.gameplay.Items.TELEPORT, "Teleport");
	}

	override public function use(owner:ItemRuntimeOwner):Void {
		owner.performTeleportItem();
	}
}
