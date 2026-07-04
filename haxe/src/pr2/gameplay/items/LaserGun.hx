package pr2.gameplay.items;

class LaserGun extends Item {
	public function new() {
		super(pr2.gameplay.Items.LASER_GUN, "Laser", 3, 800, 22);
	}

	override public function use(owner:ItemRuntimeOwner):Void {
		owner.performLaserGunItem();
	}
}
