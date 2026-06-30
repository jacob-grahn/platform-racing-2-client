package pr2.harness;

enum BlockVisualEventKind {
	ArrowAnimate;
	MineExplode;
	BrickPieces;
	CrumblePieces;
	MinePieces;
	WaterRipple;
	SafetyPoof;
	BlockBumpSound;
	ItemBlockSound;
	SuperJumpSound;
}

class BlockVisualEvent {
	public final kind:BlockVisualEventKind;
	public final tileX:Int;
	public final tileY:Int;
	public final count:Int;

	public function new(kind:BlockVisualEventKind, tileX:Int, tileY:Int, count:Int = 1) {
		this.kind = kind;
		this.tileX = tileX;
		this.tileY = tileY;
		this.count = count;
	}
}
