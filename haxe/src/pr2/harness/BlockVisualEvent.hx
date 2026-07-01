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
	HappyBlockSound;
	SadBlockSound;
	SuperJumpSound;
	PushBlockMove;
}

class BlockVisualEvent {
	public final kind:BlockVisualEventKind;
	public final tileX:Int;
	public final tileY:Int;
	public final toTileX:Null<Int>;
	public final toTileY:Null<Int>;
	public final count:Int;

	public function new(kind:BlockVisualEventKind, tileX:Int, tileY:Int, count:Int = 1, ?toTileX:Int, ?toTileY:Int) {
		this.kind = kind;
		this.tileX = tileX;
		this.tileY = tileY;
		this.count = count;
		this.toTileX = toTileX;
		this.toTileY = toTileY;
	}
}
