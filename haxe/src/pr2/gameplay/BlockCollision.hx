package pr2.gameplay;

import pr2.gameplay.RotationMath.RotatedPoint;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevel;
import pr2.level.ServerLevel.DecodedBlock;

typedef MovementLimits = {
	final minX:Int;
	final maxX:Int;
	final minY:Int;
	final maxY:Int;
}

/** Shared tile lookup and rotation math for lightweight physics objects. */
class BlockCollision {
	public static function blockFromPos(level:ServerLevel, posX:Int, posY:Int, rotation:Int):Null<DecodedBlock> {
		var probeX = posX;
		var probeY = posY;
		if (rotation != 0) {
			var pos = RotationMath.rotatePoint(posX, posY, rotation);
			probeX = pos.x;
			probeY = pos.y;
		}
		var tileX = Math.floor(probeX / 30);
		var tileY = Math.floor(probeY / 30);
		for (block in level.blocks) {
			if (Math.floor(block.x / 30) == tileX && Math.floor(block.y / 30) == tileY) {
				return block;
			}
		}
		return null;
	}

	public static function isActiveBlock(block:Null<DecodedBlock>):Bool {
		if (block == null) return false;
		return switch (block.code) {
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4
				| ObjectCodes.BLOCK_WATER | ObjectCodes.BLOCK_SAFETY: false;
			default: true;
		}
	}

	public static function rotatedBlockPos(block:DecodedBlock, rotation:Int):RotatedPoint {
		var offsetX = 0;
		var offsetY = 0;
		if (rotation == 90) {
			offsetY = 30;
		} else if (Math.abs(rotation) == 180) {
			offsetX = 30;
			offsetY = 30;
		} else if (rotation == -90) {
			offsetX = 30;
		}
		return RotationMath.rotatePoint(block.x + offsetX, block.y + offsetY, -rotation);
	}

	public static function movementLimits(level:ServerLevel, rotation:Int):MovementLimits {
		var minPoint = RotationMath.rotatePoint(level.minX - 300, level.minY - 300, -rotation);
		var maxPoint = RotationMath.rotatePoint(level.maxX + 300, level.maxY + 300, -rotation);
		return {
			minX: Std.int(Math.min(minPoint.x, maxPoint.x)),
			maxX: Std.int(Math.max(minPoint.x, maxPoint.x)),
			minY: Std.int(Math.min(minPoint.y, maxPoint.y)),
			maxY: Std.int(Math.max(minPoint.y, maxPoint.y)),
		};
	}

	public static function isNearLocalPlayer(px:Int, py:Int, playerX:Float, playerY:Float, playerCrouching:Bool, playerRemoved:Bool):Bool {
		return !playerRemoved
			&& Math.abs(playerX - px) < 25
			&& playerY > py - 5
			&& ((!playerCrouching && playerY < py + 65) || (playerCrouching && playerY < py + 25));
	}

	private function new() {}
}
