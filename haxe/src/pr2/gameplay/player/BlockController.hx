package pr2.gameplay.player;

import pr2.level.BlockType;
import pr2.level.WorldLevel.LevelBlock;

/** Owns moving, vanish, teleport, and frozen block state for the local simulation. */
@:access(pr2.gameplay.player.LocalPlayerController)
class BlockController {
	private final owner:LocalPlayerController;

	public function new(owner:LocalPlayerController) {
		this.owner = owner;
	}

	public function update():Void {
		updateFrozenBlocks();
		updateVanishBlocks();
		updateTeleportBlocks();
		updateMoveBlocks();
	}

	public function updateMoveBlocks():Void {
		if (owner.moveBlockDirections.keys().hasNext() == false) {
			return;
		}

		owner.moveBlockTimer--;
		if (owner.moveBlockTimer > 0) {
			return;
		}

		if (owner.moveBlockPhase == "shift") {
			shiftMoveBlocks();
			owner.moveBlockPhase = "reselect";
			owner.moveBlockTimer = LocalPlayerController.MOVE_RESELECT_FRAMES;
		} else {
			determineMoveBlockDirections();
			owner.moveBlockPhase = "shift";
			owner.moveBlockTimer = LocalPlayerController.MOVE_PREVIEW_FRAMES;
		}
	}

	public function determineMoveBlockDirections():Void {
		owner.moveBlockDirections.clear();
		for (block in owner.level.blocks) {
			if (block.type == BlockType.Move) {
				owner.moveBlockDirections.set(owner.blockKey(block.x, block.y), moveBlockDirection(block));
			}
		}
	}

	public function shiftMoveBlocks():Void {
		var moveBlocks = owner.level.blocks.filter(function(block) return block.type == BlockType.Move);
		for (block in moveBlocks) {
			var direction = owner.moveBlockDirections.get(owner.blockKey(block.x, block.y));
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
		return owner.moveRandom.nextMinMax(0, maxValue);
	}

	public function updateVanishBlocks():Void {
		// Three separate passes over every tracked tile, matching the original's
		// three map snapshots. The order matters: a fade that completes in the
		// first pass starts its reappear timer, which the third pass then ticks
		// down within the same frame; the fade-in the third pass starts is only
		// ticked on the following frame (the fade-in pass has already run).
		for (state in owner.blockStates) {
			if (state.vanishFadeFrames != null) {
				var frames = state.vanishFadeFrames - 1;
				if (frames <= 0) {
					state.vanishFadeFrames = null;
					state.removed = true;
					state.vanishReappearFrames = LocalPlayerController.VANISH_REAPPEAR_FRAMES;
				} else {
					state.vanishFadeFrames = frames;
				}
			}
		}

		for (state in owner.blockStates) {
			if (state.vanishFadeInFrames != null) {
				var frames = state.vanishFadeInFrames - 1;
				if (frames <= 0) {
					state.vanishFadeInFrames = null;
				} else {
					state.vanishFadeInFrames = frames;
				}
			}
		}

		for (key => state in owner.blockStates) {
			if (state.vanishReappearFrames != null) {
				var frames = state.vanishReappearFrames - 1;
				if (frames > 0) {
					state.vanishReappearFrames = frames;
				} else if (!playerOccupiesBlock(key)) {
					state.vanishReappearFrames = null;
					state.removed = false;
					state.vanishFadeInFrames = LocalPlayerController.VANISH_FADE_FRAMES - 2;
				} else {
					state.vanishReappearFrames = LocalPlayerController.VANISH_REAPPEAR_FRAMES;
				}
			}
		}
	}

	public function updateTeleportBlocks():Void {
		var colors:Array<String> = [for (color in owner.disabledTeleportFrames.keys()) color];
		for (color in colors) {
			var frames = owner.disabledTeleportFrames.get(color) - 1;
			if (frames <= 0) {
				owner.disabledTeleportFrames.remove(color);
				for (block in owner.teleportBlocksOfColor(color)) {
					var state = owner.blockState(owner.blockKey(block.x, block.y));
					state.depletedSupply = false;
					state.depletedVisualSupply = false;
				}
			} else {
				owner.disabledTeleportFrames.set(color, frames);
			}
		}
	}

	public function updateFrozenBlocks():Void {
		for (state in owner.blockStates) {
			if (state.frozenIceAlpha != null) {
				var alpha = state.frozenIceAlpha - state.frozenIceFadeRate;
				if (alpha <= LocalPlayerController.ICE_OVERLAY_REMOVE_ALPHA) {
					state.frozenIceAlpha = null;
					state.frozenIceFadeRate = LocalPlayerController.SANTA_ICE_OVERLAY_FADE_RATE;
				} else {
					state.frozenIceAlpha = alpha;
				}
			}
		}
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
		var left = owner.tileIndex(owner.x - LocalPlayerController.HALF_WIDTH);
		var right = owner.tileIndex(owner.x + LocalPlayerController.HALF_WIDTH);
		var top = owner.tileIndex(owner.y - (owner.crouching ? LocalPlayerController.CROUCHING_HEIGHT : LocalPlayerController.STANDING_HEIGHT));
		var bottom = owner.tileIndex(owner.y);
		for (tileX in left...right + 1) {
			for (tileY in top...bottom + 1) {
				if (tileX == targetTileX && tileY == targetTileY) {
					return true;
				}
			}
		}
		return false;
	}

}
