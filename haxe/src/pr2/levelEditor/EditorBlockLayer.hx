package pr2.levelEditor;

import openfl.display.Sprite;
import openfl.geom.Point;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.BlockType;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevelDecoder;

class EditorBlockLayer extends Sprite {
	public final editor:LevelEditor;
	public final blocks:Array<EditorBlockObject> = [];
	public final saveArray:Array<String> = [];
	public final redoArray:Array<String> = [];
	private final blocksBySeg:Map<String, EditorBlockObject> = new Map();
	private var initialSaveString:String = "";
	private var historyBatchDepth:Int = 0;
	private var historyBatchDirty:Bool = false;

	public function new(editor:LevelEditor) {
		super();
		this.editor = editor;
		name = "editorBlockLayer";
		addInitialStartBlocks();
		initialSaveString = getSaveString();
	}

	public function resetToInitialBlocks():Void {
		historyBatchDepth = 0;
		historyBatchDirty = false;
		editor.selectBlock(null);
		while (blocks.length > 0) {
			removeBlock(blocks[blocks.length - 1], false);
		}
		blocksBySeg.clear();
		addInitialStartBlocks();
		initialSaveString = getSaveString();
		saveArray.resize(0);
		redoArray.resize(0);
		notifyHistoryChanged();
	}

	private function addInitialStartBlocks():Void {
		for (code in ObjectCodes.BLOCK_START1...ObjectCodes.BLOCK_START4 + 1) {
			var start = addBlockAtLocal(code, BlockType.Start, code * LevelEditor.segSize + 10000, LevelEditor.segSize * 2 + 10000, false);
			start.deleteable = false;
		}
	}

	public function addBlockAtStage(code:Int, type:Null<BlockType>, stageX:Float, stageY:Float, select:Bool = true):Null<EditorBlockObject> {
		var point = globalToLocal(new Point(stageX - 15, stageY - 15));
		var segX = Math.round(point.x / LevelEditor.segSize);
		var segY = Math.round(point.y / LevelEditor.segSize);
		var existing = getBlockAtSeg(segX, segY);
		if (existing != null) {
			return null;
		}
		var block = addBlockAtLocal(code, type, point.x, point.y, select);
		recordSnapshot();
		return block;
	}

	public function getBlockAtSeg(segX:Int, segY:Int):Null<EditorBlockObject> {
		return blocksBySeg.get(segKey(segX, segY));
	}

	public function beginHistoryBatch():Void {
		historyBatchDepth++;
	}

	public function endHistoryBatch():Void {
		if (historyBatchDepth <= 0) {
			return;
		}
		historyBatchDepth--;
		if (historyBatchDepth == 0 && historyBatchDirty) {
			historyBatchDirty = false;
			recordSnapshot();
		}
	}

	public function getBlockAtStage(stageX:Float, stageY:Float):Null<EditorBlockObject> {
		var point = globalToLocal(new Point(stageX - 15, stageY - 15));
		return getBlockAtSeg(Math.round(point.x / LevelEditor.segSize), Math.round(point.y / LevelEditor.segSize));
	}

	public function removeBlock(block:EditorBlockObject, record:Bool = true):Void {
		var index = blocks.indexOf(block);
		if (index < 0) {
			return;
		}
		if (editor.selectedBlock == block) {
			editor.selectBlock(null);
		}
		blocks.splice(index, 1);
		blocksBySeg.remove(segKey(block.segX, block.segY));
		block.remove();
		if (record) {
			recordSnapshot();
		}
	}

	public function moveBlockToSeg(block:EditorBlockObject, nextSegX:Int, nextSegY:Int):Bool {
		if (blocks.indexOf(block) < 0) {
			return false;
		}
		var existing = getBlockAtSeg(nextSegX, nextSegY);
		if (existing != null && existing != block) {
			if (!existing.deleteable) {
				return false;
			}
			removeBlock(existing, false);
		}
		blocksBySeg.remove(segKey(block.segX, block.segY));
		block.setSeg(nextSegX, nextSegY);
		blocksBySeg.set(segKey(block.segX, block.segY), block);
		recordSnapshot();
		return true;
	}

	public function updateBlockControlScales():Void {
		for (block in blocks) {
			block.updateControlScale();
		}
	}

	public function loadBlocks(decodedBlocks:Array<DecodedBlock>):Void {
		historyBatchDepth = 0;
		historyBatchDirty = false;
		editor.selectBlock(null);
		while (blocks.length > 0) {
			removeBlock(blocks[blocks.length - 1], false);
		}
		blocksBySeg.clear();
		for (decoded in decodedBlocks) {
			var block = addBlockAtLocal(decoded.code, typeForCode(decoded.code), decoded.x, decoded.y, false, decoded.opts);
			block.deleteable = !isStartBlockCode(decoded.code);
		}
		initialSaveString = getSaveString();
		saveArray.resize(0);
		redoArray.resize(0);
		notifyHistoryChanged();
	}

	public function recordBlockOptionsChanged():Void {
		recordSnapshot();
	}

	public function refreshItemBlocksForAllowedItems(allowedItems:Array<Int>):Int {
		var changed = 0;
		for (block in blocks) {
			if (block.refreshItemOptionsForAllowedItems(allowedItems)) {
				changed++;
			}
		}
		return changed;
	}

	public function undo():Bool {
		if (saveArray.length == 0) {
			return false;
		}
		var snapshot = saveArray.pop();
		if (snapshot != null) {
			redoArray.push(snapshot);
		}
		rebuildFromSaveString(saveArray.length == 0 ? initialSaveString : saveArray[saveArray.length - 1]);
		notifyHistoryChanged();
		return true;
	}

	public function redo():Bool {
		if (redoArray.length == 0) {
			return false;
		}
		var snapshot = redoArray.pop();
		if (snapshot != null) {
			saveArray.push(snapshot);
			rebuildFromSaveString(snapshot);
		}
		notifyHistoryChanged();
		return true;
	}

	public function getSaveString():String {
		var out:Array<String> = [];
		var lastX = 0;
		var lastY = 0;
		var lastCode = 0;
		for (block in blocks) {
			var code = block.code - 100;
			var relX = block.segX - lastX;
			var relY = block.segY - lastY;
			lastX = block.segX;
			lastY = block.segY;
			var row = relX + ";" + relY;
			if (code != lastCode || block.options != "") {
				lastCode = code;
				row += ";" + code;
				if (block.options != "") {
					row += ";" + block.options;
				}
			}
			out.push(row);
		}
		return out.join(",");
	}

	public function remove():Void {
		while (blocks.length > 0) {
			removeBlock(blocks[blocks.length - 1], false);
		}
		blocksBySeg.clear();
		saveArray.resize(0);
		redoArray.resize(0);
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function addBlockAtLocal(code:Int, type:Null<BlockType>, localX:Float, localY:Float, select:Bool, options:String = ""):EditorBlockObject {
		var block = new EditorBlockObject(editor, code, type, snap(localX), snap(localY), options);
		blocks.push(block);
		blocksBySeg.set(segKey(block.segX, block.segY), block);
		addChild(block);
		if (select) {
			editor.selectBlock(block);
		}
		return block;
	}

	private function recordSnapshot():Void {
		if (historyBatchDepth > 0) {
			historyBatchDirty = true;
			return;
		}
		var snapshot = getSaveString();
		var previous = saveArray.length == 0 ? initialSaveString : saveArray[saveArray.length - 1];
		if (snapshot == previous) {
			return;
		}
		saveArray.push(snapshot);
		redoArray.resize(0);
		notifyHistoryChanged();
	}

	private function rebuildFromSaveString(saveString:String):Void {
		editor.selectBlock(null);
		while (blocks.length > 0) {
			removeBlock(blocks[blocks.length - 1], false);
		}
		blocksBySeg.clear();
		for (decoded in ServerLevelDecoder.decodeBlocks("m4", saveString)) {
			var block = addBlockAtLocal(decoded.code, typeForCode(decoded.code), decoded.x, decoded.y, false, decoded.opts);
			block.deleteable = !isStartBlockCode(decoded.code);
		}
	}

	private function notifyHistoryChanged():Void {
		if (editor.menu != null) {
			editor.menu.updateUndoRedoState();
		}
	}

	private static inline function snap(value:Float):Int {
		return Std.int(Math.round(value / LevelEditor.segSize) * LevelEditor.segSize);
	}

	private static inline function segKey(segX:Int, segY:Int):String {
		return segX + ":" + segY;
	}

	private static function isStartBlockCode(code:Int):Bool {
		return code >= ObjectCodes.BLOCK_START1 && code <= ObjectCodes.BLOCK_START4;
	}

	private static function typeForCode(code:Int):Null<BlockType> {
		return switch (code) {
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4:
				BlockType.Start;
			case ObjectCodes.BLOCK_FINISH:
				BlockType.Finish;
			case ObjectCodes.BLOCK_ICE:
				BlockType.Ice;
			case ObjectCodes.BLOCK_ARROW_DOWN:
				BlockType.ArrowDown;
			case ObjectCodes.BLOCK_ARROW_UP:
				BlockType.ArrowUp;
			case ObjectCodes.BLOCK_ARROW_LEFT:
				BlockType.ArrowLeft;
			case ObjectCodes.BLOCK_ARROW_RIGHT:
				BlockType.ArrowRight;
			case ObjectCodes.BLOCK_MINE:
				BlockType.Mine;
			case ObjectCodes.BLOCK_ITEM:
				BlockType.Item;
			case ObjectCodes.BLOCK_ITEM_INF:
				BlockType.InfiniteItem;
			case ObjectCodes.BLOCK_CRUMBLE:
				BlockType.Crumble;
			case ObjectCodes.BLOCK_VANISH:
				BlockType.Vanish;
			case ObjectCodes.BLOCK_MOVE:
				BlockType.Move;
			case ObjectCodes.BLOCK_WATER:
				BlockType.Water;
			case ObjectCodes.BLOCK_ROTATE_RIGHT:
				BlockType.RotateRight;
			case ObjectCodes.BLOCK_ROTATE_LEFT:
				BlockType.RotateLeft;
			case ObjectCodes.BLOCK_PUSH:
				BlockType.Push;
			case ObjectCodes.BLOCK_SAFETY:
				BlockType.Safety;
			case ObjectCodes.BLOCK_TELEPORT:
				BlockType.Teleport;
			case ObjectCodes.BLOCK_CUSTOM_STATS:
				BlockType.CustomStats;
			case ObjectCodes.BLOCK_BRICK:
				BlockType.Brick;
			case ObjectCodes.BLOCK_HAPPY:
				BlockType.Happy;
			case ObjectCodes.BLOCK_SAD:
				BlockType.Sad;
			case ObjectCodes.BLOCK_HEART:
				BlockType.Heart;
			case ObjectCodes.BLOCK_TIME:
				BlockType.Time;
			case ObjectCodes.BLOCK_BASIC1 | ObjectCodes.BLOCK_BASIC2 | ObjectCodes.BLOCK_BASIC3 | ObjectCodes.BLOCK_BASIC4:
				BlockType.Basic;
			case ObjectCodes.BLOCK_MINION_EGG:
				null;
			default:
				BlockType.Solid;
		}
	}

	public static function specForTool(toolId:String):Null<EditorBlockSpec> {
		return switch (toolId) {
			case "basic1": {code: ObjectCodes.BLOCK_BASIC1, type: BlockType.Basic};
			case "basic2": {code: ObjectCodes.BLOCK_BASIC2, type: BlockType.Basic};
			case "basic3": {code: ObjectCodes.BLOCK_BASIC3, type: BlockType.Basic};
			case "basic4": {code: ObjectCodes.BLOCK_BASIC4, type: BlockType.Basic};
			case "brick": {code: ObjectCodes.BLOCK_BRICK, type: BlockType.Brick};
			case "finish": {code: ObjectCodes.BLOCK_FINISH, type: BlockType.Finish};
			case "ice": {code: ObjectCodes.BLOCK_ICE, type: BlockType.Ice};
			case "item": {code: ObjectCodes.BLOCK_ITEM, type: BlockType.Item};
			case "infItem": {code: ObjectCodes.BLOCK_ITEM_INF, type: BlockType.InfiniteItem};
			case "left": {code: ObjectCodes.BLOCK_ARROW_LEFT, type: BlockType.ArrowLeft};
			case "right": {code: ObjectCodes.BLOCK_ARROW_RIGHT, type: BlockType.ArrowRight};
			case "up": {code: ObjectCodes.BLOCK_ARROW_UP, type: BlockType.ArrowUp};
			case "down": {code: ObjectCodes.BLOCK_ARROW_DOWN, type: BlockType.ArrowDown};
			case "teleport": {code: ObjectCodes.BLOCK_TELEPORT, type: BlockType.Teleport};
			case "mine": {code: ObjectCodes.BLOCK_MINE, type: BlockType.Mine};
			case "crumble": {code: ObjectCodes.BLOCK_CRUMBLE, type: BlockType.Crumble};
			case "vanish": {code: ObjectCodes.BLOCK_VANISH, type: BlockType.Vanish};
			case "move": {code: ObjectCodes.BLOCK_MOVE, type: BlockType.Move};
			case "water": {code: ObjectCodes.BLOCK_WATER, type: BlockType.Water};
			case "rotateR": {code: ObjectCodes.BLOCK_ROTATE_RIGHT, type: BlockType.RotateRight};
			case "rotateL": {code: ObjectCodes.BLOCK_ROTATE_LEFT, type: BlockType.RotateLeft};
			case "push": {code: ObjectCodes.BLOCK_PUSH, type: BlockType.Push};
			case "happy": {code: ObjectCodes.BLOCK_HAPPY, type: BlockType.Happy};
			case "sad": {code: ObjectCodes.BLOCK_SAD, type: BlockType.Sad};
			case "custom": {code: ObjectCodes.BLOCK_CUSTOM_STATS, type: BlockType.CustomStats};
			case "safety": {code: ObjectCodes.BLOCK_SAFETY, type: BlockType.Safety};
			case "heart": {code: ObjectCodes.BLOCK_HEART, type: BlockType.Heart};
			case "time": {code: ObjectCodes.BLOCK_TIME, type: BlockType.Time};
			case "egg": {code: ObjectCodes.BLOCK_MINION_EGG, type: null};
			default: null;
		}
	}
}
