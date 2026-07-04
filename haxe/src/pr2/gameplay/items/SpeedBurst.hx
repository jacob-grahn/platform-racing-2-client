package pr2.gameplay.items;

class SpeedBurst extends Item {
	public function new() {
		super(pr2.gameplay.Items.SPEED_BURST, "Speed Burst");
	}

	override public function use(owner:ItemRuntimeOwner):Void {
		owner.performSpeedBurstItem();
	}
}
