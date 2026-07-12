package pr2.gameplay.items;

/** A single, hold-to-maintain Snake deployment. */
class Snake extends Item {
	public function new() {
		super(pr2.gameplay.Items.SNAKE, "Snake");
	}

	override public function use(owner:ItemRuntimeOwner):Void {
		owner.performSnakeItem();
	}
}
