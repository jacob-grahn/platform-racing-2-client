package pr2.gameplay.items;

class JetPack extends Item {
	public function new() {
		super(pr2.gameplay.Items.JET_PACK, "Jet Pack", 3);
	}

	override public function setSpace(pressed:Bool, owner:ItemRuntimeOwner):Void {
		if (pressed) {
			owner.performJetPackItem();
		} else {
			super.setSpace(pressed, owner);
		}
	}

	override public function use(owner:ItemRuntimeOwner):Void {
		owner.performJetPackItem();
	}
}
