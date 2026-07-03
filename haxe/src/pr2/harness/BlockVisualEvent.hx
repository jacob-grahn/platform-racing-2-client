package pr2.harness;

enum BlockVisualEventKind {
	ArrowAnimate;
	MineExplode;
	BrickPieces;
	CrumblePieces;
	MinePieces;
	WaterRipple;
	SafetyPoof;
	TeleportBlockPop;
	BlockBumpSound;
	ItemBlockSound;
	HappyBlockSound;
	SadBlockSound;
	TimeBlockSound;
	SuperJumpSound;
	PushBlockMove;
	LocalActivate;
}

class BlockVisualEvent {
	public final kind:BlockVisualEventKind;
	public final tileX:Int;
	public final tileY:Int;
	public final toTileX:Null<Int>;
	public final toTileY:Null<Int>;
	public final count:Int;
	public final hitX:Float;
	public final hitY:Float;
	public final activationPayload:Null<String>;

	public function new(kind:BlockVisualEventKind, tileX:Int, tileY:Int, count:Int = 1, ?toTileX:Int, ?toTileY:Int, hitX:Float = 0, hitY:Float = -15,
			?activationPayload:String) {
		this.kind = kind;
		this.tileX = tileX;
		this.tileY = tileY;
		this.count = count;
		this.toTileX = toTileX;
		this.toTileY = toTileY;
		this.hitX = hitX;
		this.hitY = hitY;
		this.activationPayload = activationPayload;
	}
}
