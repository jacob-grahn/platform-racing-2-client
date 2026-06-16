package pr2.level;

/**
	A decoded server level: background color plus the placed blocks in absolute
	PR2 pixel space (the Flash editor stores everything offset by ~10000, so
	`minX`/`minY` are kept for the renderer to translate from). Art/draw/text
	layers are intentionally not decoded yet — see the Bit 4 TODO.
**/
class ServerLevel {
	public final bgColor:Int;
	public final blocks:Array<DecodedBlock>;
	public final minX:Int;
	public final minY:Int;
	public final maxX:Int;
	public final maxY:Int;

	public function new(bgColor:Int, blocks:Array<DecodedBlock>) {
		this.bgColor = bgColor;
		this.blocks = blocks;

		var minX = 0, minY = 0, maxX = 0, maxY = 0;
		var first = true;
		for (block in blocks) {
			if (first) {
				minX = maxX = block.x;
				minY = maxY = block.y;
				first = false;
			} else {
				if (block.x < minX) minX = block.x;
				if (block.y < minY) minY = block.y;
				if (block.x > maxX) maxX = block.x;
				if (block.y > maxY) maxY = block.y;
			}
		}
		this.minX = minX;
		this.minY = minY;
		this.maxX = maxX;
		this.maxY = maxY;
	}

	/** Blocks whose resolved code is one of the four start positions (111-114). **/
	public function startBlocks():Array<DecodedBlock> {
		return blocks.filter(function(block) {
			return block.code >= ObjectCodes.BLOCK_START1 && block.code <= ObjectCodes.BLOCK_START4;
		});
	}

	public function finishBlocks():Array<DecodedBlock> {
		return blocks.filter(function(block) {
			return block.code == ObjectCodes.BLOCK_FINISH;
		});
	}
}

/**
	A single placed block at absolute pixel coordinates. `code` is the resolved
	`Objects` block code (100-132); `opts` carries the raw option string used by
	move/teleport/custom-stats blocks (only present in m4 payloads).
**/
class DecodedBlock {
	public final code:Int;
	public final x:Int;
	public final y:Int;
	public final opts:String;

	public function new(code:Int, x:Int, y:Int, opts:String = "") {
		this.code = code;
		this.x = x;
		this.y = y;
		this.opts = opts;
	}
}
