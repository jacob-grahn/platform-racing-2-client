package pr2.gameplay;

import pr2.gameplay.RotationMath.RotatedPoint;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;

typedef MovementLimits = {
	final minX:Int;
	final maxX:Int;
	final minY:Int;
	final maxY:Int;
}

/** Shared tile lookup and rotation math for lightweight physics objects. */
class BlockCollision {
	public static function blockFromPos(level:Level, posX:Int, posY:Int, rotation:Int):Null<LevelBlock> {
		var probeX = posX;
		var probeY = posY;
		if (rotation != 0) {
			var pos = RotationMath.rotatePoint(posX, posY, rotation);
			probeX = pos.x;
			probeY = pos.y;
		}
		return level.blockAt(Math.floor(probeX / level.tileSize), Math.floor(probeY / level.tileSize));
	}

	public static function isActiveBlock(block:Null<LevelBlock>):Bool {
		if (block == null) return false;
		return block.type.isSolid();
	}

	public static function rotatedBlockPos(block:LevelBlock, rotation:Int):RotatedPoint {
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
		return RotationMath.rotatePoint(block.worldX + offsetX, block.worldY + offsetY, -rotation);
	}

	public static function movementLimits(level:Level, rotation:Int):MovementLimits {
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
