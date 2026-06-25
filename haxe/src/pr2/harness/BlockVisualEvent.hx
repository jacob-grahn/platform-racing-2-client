package pr2.harness;

enum BlockVisualEventKind {
	MineExplode;
}

class BlockVisualEvent {
	public final kind:BlockVisualEventKind;
	public final tileX:Int;
	public final tileY:Int;

	public function new(kind:BlockVisualEventKind, tileX:Int, tileY:Int) {
		this.kind = kind;
		this.tileX = tileX;
		this.tileY = tileY;
	}
}
