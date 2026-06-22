package pr2.level;

/**
	A decoded server level: background color plus the placed blocks in absolute
	PR2 pixel space (the Flash editor stores everything offset by ~10000, so
	`minX`/`minY` are kept for the renderer to translate from).
**/
class ServerLevel {
	public final bgColor:Int;
	public final artBackgroundCode:Null<Int>;
	public final blocks:Array<DecodedBlock>;
	public final artLayers:Array<DecodedArtLayer>;
	public final minX:Int;
	public final minY:Int;
	public final maxX:Int;
	public final maxY:Int;

	public function new(bgColor:Int, blocks:Array<DecodedBlock>, ?artLayers:Array<DecodedArtLayer>, ?artBackgroundCode:Null<Int>) {
		this.bgColor = bgColor;
		this.artBackgroundCode = artBackgroundCode;
		this.blocks = blocks;
		this.artLayers = artLayers == null ? [] : artLayers;

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

class DecodedArtLayer {
	public final drawActions:Array<DecodedDrawAction>;
	public final objects:Array<DecodedArtObject>;
	public final texts:Array<DecodedTextObject>;
	public final scale:Float;

	public function new(?drawActions:Array<DecodedDrawAction>, ?objects:Array<DecodedArtObject>, ?texts:Array<DecodedTextObject>, scale:Float = 1) {
		this.drawActions = drawActions == null ? [] : drawActions;
		this.objects = objects == null ? [] : objects;
		this.texts = texts == null ? [] : texts;
		this.scale = scale;
	}
}

class DecodedDrawAction {
	public final kind:String;
	public final values:Array<Float>;
	public final text:String;

	public function new(kind:String, ?values:Array<Float>, text:String = "") {
		this.kind = kind;
		this.values = values == null ? [] : values;
		this.text = text;
	}
}

class DecodedArtObject {
	public final code:Int;
	public final x:Float;
	public final y:Float;
	public final scaleX:Float;
	public final scaleY:Float;

	public function new(code:Int, x:Float, y:Float, scaleX:Float = 1, scaleY:Float = 1) {
		this.code = code;
		this.x = x;
		this.y = y;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
	}
}

class DecodedTextObject {
	public final text:String;
	public final x:Float;
	public final y:Float;
	public final color:Int;
	public final scaleX:Float;
	public final scaleY:Float;

	public function new(text:String, x:Float, y:Float, color:Int, scaleX:Float = 1, scaleY:Float = 1) {
		this.text = text;
		this.x = x;
		this.y = y;
		this.color = color;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
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
