package pr2.gameplay.items;

class IceWave extends Item {
	public function new() {
		super(pr2.gameplay.Items.ICE_WAVE, "Ice Wave", 3, 1000, 27);
	}

	override public function use(owner:ItemRuntimeOwner):Void {
		owner.performIceWaveItem();
	}
}
