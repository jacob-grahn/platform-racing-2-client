package pr2.gameplay;

import pr2.Constants;
import pr2.gameplay.player.LocalPlayerBlockStateStore;
import pr2.gameplay.player.LocalPlayerBlockStateStore.LocalPlayerBlockState;
import pr2.gameplay.player.LocalPlayerController;
import pr2.level.BlockType;
import pr2.level.WorldLevel;
import pr2.level.WorldLevel.LevelBlock;
import pr2.util.FlashRandom;

enum MoveBlockPhase {
	Preview;
	Cooldown;
}

/** Course-level owner for moving, vanish, teleport, frozen, and supply block runtime state. */
@:access(pr2.gameplay.player.LocalPlayerController)
class BlockController {
	public static inline var VANISH_FADE_FRAMES:Int = 10;
	public static inline var VANISH_REAPPEAR_FRAMES:Int = 54;
	public static inline var SANTA_ICE_OVERLAY_START_ALPHA:Float = 1;
	public static inline var SANTA_ICE_OVERLAY_FADE_RATE:Float = 0.025;
	public static inline var ICE_OVERLAY_REMOVE_ALPHA:Float = 0.05;
	public static inline var TELEPORT_RESET_FRAMES:Int = Constants.FRAME_RATE * 3;
	public static inline var MOVE_PREVIEW_MS:Int = 1000;
	public static inline var MOVE_INTERVAL_MS:Int = 5000;

	private final level:WorldLevel;
	private final clock:Void->Float;
	private var owner:LocalPlayerController;
	private final blockStates:LocalPlayerBlockStateStore = new LocalPlayerBlockStateStore();
	private final disabledTeleportFrames:Map<String, Int> = new Map();
	private final moveBlockDirections:Map<String, Int> = new Map();
	private final originalBlocks:Array<LevelBlock> = [];
	private var moveBlockPhase:MoveBlockPhase = Preview;
	private var moveBlockDeadlineMs:Null<Float> = null;
	private var moveStartTimeMs:Float = 0;
	private var moveCount:Int = 0;
	private var moveRandom:FlashRandom = new FlashRandom(1);
	public var onBlockRemoved:Null<LevelBlock->Void> = null;
	public var onBlockAdded:Null<LevelBlock->Void> = null;
	public var onBlocksReset:Null<Void->Void> = null;

	public function new(level:WorldLevel, ?clock:Void->Float) {
		this.level = level;
		this.clock = clock == null ? function():Float return haxe.Timer.stamp() * 1000 : clock;
		for (block in level.blocks) {
			originalBlocks.push(copyBlock(block));
		}
	}

	public function bindPlayer(owner:LocalPlayerController, startImmediately:Bool):Void {
		this.owner = owner;
		if (startImmediately) {
			startGameplay();
		}
	}

	public function startGameplay():Void {
		moveStartTimeMs = clock();
		moveCount = 0;
		determineMoveBlockDirections();
		moveBlockPhase = Preview;
		moveBlockDeadlineMs = moveStartTimeMs + MOVE_PREVIEW_MS;
	}

	public function update():Void {
		updateFrozenBlocks();
		updateVanishBlocks();
		updateTeleportBlocks();
		updateMoveBlocks();
		updateBlockBounces();
	}

	/** Mirrors Block.hitRotated; collision snapping reads this live displacement in Flash. */
	public function startBlockBounce(block:LevelBlock, hitX:Float, hitY:Float):Void {
		var velocity = RotationMath.rotatePoint(hitX, hitY, owner.courseRotation);
		var state = stateFor(block);
		state.bounceVelocityX = velocity.x;
		state.bounceVelocityY = velocity.y;
	}

	public function blockBounceOffset(block:LevelBlock):{x:Float, y:Float} {
		var state = stateAt(owner.blockKey(block.x, block.y));
		if (state == null) {
			return {x: 0, y: 0};
		}
		var offset = RotationMath.rotatePoint(state.bounceOffsetX, state.bounceOffsetY, owner.courseRotation);
		return {x: offset.x, y: offset.y};
	}

	private function updateBlockBounces():Void {
		for (state in blockStates) {
			if (state.bounceVelocityX == null || state.bounceVelocityY == null) {
				continue;
			}
			state.bounceVelocityX *= 0.5;
			state.bounceVelocityY *= 0.5;
			state.bounceOffsetX += state.bounceVelocityX;
			state.bounceOffsetY += state.bounceVelocityY;
			state.bounceOffsetX += -state.bounceOffsetX * 0.35;
			state.bounceOffsetY += -state.bounceOffsetY * 0.35;
			if (Math.abs(state.bounceOffsetX) < 0.25 && Math.abs(state.bounceOffsetY) < 0.25) {
				state.bounceOffsetX = 0;
				state.bounceOffsetY = 0;
				state.bounceVelocityX = null;
				state.bounceVelocityY = null;
			}
		}
	}

	public function updateMoveBlocks():Void {
		if (moveBlockDeadlineMs == null || moveBlockDirections.keys().hasNext() == false) {
			return;
		}

		var now = clock();
		if (now < moveBlockDeadlineMs) {
			return;
		}

		switch (moveBlockPhase) {
			case Preview:
				shiftMoveBlocks();
				moveBlockPhase = Cooldown;
				var correction = moveStartTimeMs + moveCount * MOVE_INTERVAL_MS - now;
				if (correction < 1) {
					correction = 1;
				}
				moveBlockDeadlineMs = now + correction + MOVE_INTERVAL_MS;
				moveCount++;
			case Cooldown:
				determineMoveBlockDirections();
				moveBlockPhase = Preview;
				moveBlockDeadlineMs = now + MOVE_PREVIEW_MS;
		}
	}

	public function determineMoveBlockDirections():Void {
		moveBlockDirections.clear();
		for (block in level.blocks) {
			if (block.type == BlockType.Move) {
				moveBlockDirections.set(owner.blockKey(block.x, block.y), moveBlockDirection(block));
			}
		}
	}

	public function shiftMoveBlocks():Void {
		var moveBlocks = level.blocks.filter(function(block) return block.type == BlockType.Move);
		for (block in moveBlocks) {
			var direction = moveBlockDirections.get(owner.blockKey(block.x, block.y));
			if (direction == null) {
				continue;
			}
			switch (direction) {
				case 0:
					owner.pushBlock(block, 0, 1);
				case 1:
					owner.pushBlock(block, 0, -1);
				case 2:
					owner.pushBlock(block, 1, 0);
				case 3:
					owner.pushBlock(block, -1, 0);
				default:
			}
		}
	}

	public function moveBlockDirection(block:LevelBlock):Int {
		return switch (block.options) {
			case "down": 0;
			case "up": 1;
			case "right": 2;
			case "left": 3;
			default: nextMoveRandom(4);
		}
	}

	public function nextMoveRandom(maxValue:Int):Int {
		return moveRandom.nextMinMax(0, maxValue);
	}

	public function updateVanishBlocks():Void {
		// Three separate passes over every tracked tile, matching the original's
		// three map snapshots. The order matters: a fade that completes in the
		// first pass starts its reappear timer, which the third pass then ticks
		// down within the same frame; the fade-in the third pass starts is only
		// ticked on the following frame (the fade-in pass has already run).
		for (state in blockStates) {
			if (state.vanishFadeFrames != null) {
				var frames = state.vanishFadeFrames - 1;
				if (frames <= 0) {
					state.vanishFadeFrames = null;
					state.removed = true;
					state.vanishReappearFrames = VANISH_REAPPEAR_FRAMES;
				} else {
					state.vanishFadeFrames = frames;
				}
			}
		}

		for (state in blockStates) {
			if (state.vanishFadeInFrames != null) {
				var frames = state.vanishFadeInFrames - 1;
				if (frames <= 0) {
					state.vanishFadeInFrames = null;
				} else {
					state.vanishFadeInFrames = frames;
				}
			}
		}

		for (key => state in blockStates) {
			if (state.vanishReappearFrames != null) {
				var frames = state.vanishReappearFrames - 1;
				if (frames > 0) {
					state.vanishReappearFrames = frames;
				} else if (!playerOccupiesBlock(key)) {
					state.vanishReappearFrames = null;
					state.removed = false;
					state.vanishFadeInFrames = VANISH_FADE_FRAMES - 2;
				} else {
					state.vanishReappearFrames = VANISH_REAPPEAR_FRAMES;
				}
			}
		}
	}

	public function updateTeleportBlocks():Void {
		var colors:Array<String> = [for (color in disabledTeleportFrames.keys()) color];
		for (color in colors) {
			var frames = disabledTeleportFrames.get(color) - 1;
			if (frames <= 0) {
				disabledTeleportFrames.remove(color);
				for (block in owner.teleportBlocksOfColor(color)) {
					var state = stateFor(block);
					state.depletedSupply = false;
					state.depletedVisualSupply = false;
				}
			} else {
				disabledTeleportFrames.set(color, frames);
			}
		}
	}

	public function updateFrozenBlocks():Void {
		for (state in blockStates) {
			if (state.frozenIceAlpha != null) {
				var alpha = state.frozenIceAlpha - state.frozenIceFadeRate;
				if (alpha <= ICE_OVERLAY_REMOVE_ALPHA) {
					state.frozenIceAlpha = null;
					state.frozenIceFadeRate = SANTA_ICE_OVERLAY_FADE_RATE;
				} else {
					state.frozenIceAlpha = alpha;
				}
			}
		}
	}

	public function resetPreRaceState():Void {
		blockStates.clear();
		disabledTeleportFrames.clear();
	}

	public function resetTestCourseState():Void {
		level.blocks.resize(0);
		for (block in originalBlocks) {
			level.blocks.push(copyBlock(block));
		}
		resetPreRaceState();
		moveRandom = new FlashRandom(1);
		startGameplay();
		if (onBlocksReset != null) {
			onBlocksReset();
		}
	}

	/** Mirrors Flash Map.removeBlock: evict a destroyed block from the live grid. */
	public function removeBlock(block:LevelBlock):Bool {
		var index = level.blocks.indexOf(block);
		if (index < 0) {
			return false;
		}
		var state = stateFor(block);
		state.removed = true;
		state.evicted = true;
		level.blocks.splice(index, 1);
		if (onBlockRemoved != null) {
			onBlockRemoved(block);
		}
		return true;
	}

	/** Adds a runtime block without inheriting state from a destroyed prior occupant. */
	public function addBlock(block:LevelBlock):Bool {
		if (level.blockAt(block.x, block.y) != null) {
			return false;
		}
		blockStates.remove(owner.blockKey(block.x, block.y));
		level.blocks.push(block);
		if (onBlockAdded != null) {
			onBlockAdded(block);
		}
		return true;
	}

	public function stateAt(key:String):Null<LocalPlayerBlockState> {
		return blockStates.get(key);
	}

	public function stateFor(block:LevelBlock):LocalPlayerBlockState {
		return blockStates.getOrCreate(owner.blockKey(block.x, block.y));
	}

	public function stateForKey(key:String):LocalPlayerBlockState {
		return blockStates.getOrCreate(key);
	}

	public function activeVisualBlockKeys():Array<String> {
		var keys:Array<String> = [];
		for (key => state in blockStates) {
			if (state.vanishFadeFrames != null
				|| state.vanishFadeInFrames != null
				|| (state.removed && !state.evicted)
				|| state.depletedItem
				|| state.depletedVisualSupply
				|| state.frozenIceAlpha != null) {
				keys.push(key);
			}
		}
		return keys;
	}

	public function blockAlphaAt(tileX:Int, tileY:Int):Float {
		var state = stateAt(owner.blockKey(tileX, tileY));
		if (state == null) {
			return 1;
		}
		if (state.vanishFadeFrames != null) {
			return Math.min(1, state.vanishFadeFrames / VANISH_FADE_FRAMES);
		}
		if (state.vanishFadeInFrames != null) {
			return 1 - state.vanishFadeInFrames / VANISH_FADE_FRAMES;
		}
		return state.removed ? 0 : 1;
	}

	public function blockColorMultiplierAt(tileX:Int, tileY:Int):Float {
		var state = stateAt(owner.blockKey(tileX, tileY));
		var block = level.blockAt(tileX, tileY);
		return block != null && state != null
			&& ((block.type == BlockType.Item && state.depletedItem) || state.depletedVisualSupply) ? 0.5 : 1;
	}

	public function blockIceOverlayAlphaAt(tileX:Int, tileY:Int):Float {
		var state = stateAt(owner.blockKey(tileX, tileY));
		return state != null && state.frozenIceAlpha != null ? state.frozenIceAlpha : 0;
	}

	public function activeMoveBlockDirections():Map<String, Int> {
		var directions:Map<String, Int> = new Map();
		if (moveBlockPhase != Preview) {
			return directions;
		}
		for (key in moveBlockDirections.keys()) {
			directions.set(key, moveBlockDirections.get(key));
		}
		return directions;
	}

	public function teleportDisabled(color:String):Bool {
		return disabledTeleportFrames.exists(color);
	}

	public function disableTeleports(color:String):Void {
		disabledTeleportFrames.set(color, TELEPORT_RESET_FRAMES);
	}

	public function isBlockRemoved(block:LevelBlock):Bool {
		if (block.type == BlockType.SnakeTrail) {
			return false;
		}
		var state = stateAt(owner.blockKey(block.x, block.y));
		return state != null && state.removed;
	}

	public function isBlockFrozen(block:LevelBlock):Bool {
		var state = stateAt(owner.blockKey(block.x, block.y));
		return state != null && state.frozenIceAlpha != null;
	}

	public function freezeBlock(tileX:Int, tileY:Int, fadeRate:Float = SANTA_ICE_OVERLAY_FADE_RATE):Void {
		var block = level.blockAt(tileX, tileY);
		if (block == null) {
			return;
		}
		var state = stateFor(block);
		state.frozenIceAlpha = SANTA_ICE_OVERLAY_START_ALPHA;
		state.frozenIceFadeRate = fadeRate;
	}

	public function playerOccupiesBlock(key:String):Bool {
		var parts = key.split(",");
		if (parts.length != 2) {
			return false;
		}
		var tileX = Std.parseInt(parts[0]);
		var tileY = Std.parseInt(parts[1]);
		return tileX != null && tileY != null && playerOccupiesTile(tileX, tileY);
	}

	public function playerOccupiesTile(targetTileX:Int, targetTileY:Int):Bool {
		// Map.characterOccupiesSpace checks Character.seg1/seg2, not the
		// character's collision bounds. Character.updateSegs always defines those
		// as the feet tile and the tile immediately above it, even while crouched.
		var baseX = owner.tileIndex(owner.x);
		var baseY = owner.tileIndex(owner.y);
		var seg1 = RotationMath.rotatePoint(baseX, baseY, owner.courseRotation);
		var seg1X = seg1.x;
		var seg1Y = seg1.y;
		var seg2X = seg1X;
		var seg2Y = seg1Y - 1;
		if (owner.courseRotation == 90) {
			seg1X--;
			seg2X--;
		} else if (Math.abs(owner.courseRotation) == 180) {
			seg1X--;
			seg2X--;
			seg1Y++;
			seg2Y++;
		} else if (owner.courseRotation == -90) {
			seg1Y++;
			seg2Y++;
		}
		return (seg1X == targetTileX && seg1Y == targetTileY)
			|| (seg2X == targetTileX && seg2Y == targetTileY);
	}

	private static function copyBlock(block:LevelBlock):LevelBlock {
		return new LevelBlock(block.x, block.y, block.type, block.options);
	}

}
