package pr2.gameplay.items;

class Sword extends Item {
	public function new() {
		super(pr2.gameplay.Items.SWORD, "Sword", 3, 800, 22);
	}

	override public function use(owner:ItemRuntimeOwner):Void {
		owner.performSwordItem();
	}
}
