package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.geom.ColorTransform;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevel;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.runtime.PR2MovieClip;
import pr2.gameplay.RotationMath.RotatedPoint;

typedef HatEffectInfo = {
	final x:Float;
	final y:Float;
	final rot:Int;
	final num:Int;
	final color:Int;
	final color2:Int;
	final id:Int;
}

/**
	Loose hat state/display ported from `effects.Hat` for hat-attack side effects.
	Physics movement is owned by `Course`; this class covers the lifecycle,
	authored hat graphic, color channels, and remote remove command.
**/
class HatEffect {
	public final id:Int;
	public final display:PR2MovieClip;
	public var posX:Float;
	public var posY:Float;
	public var rot:Int;
	public var velX:Float = 0;
	public var velY:Float = -5;
	public var num(default, null):Int;
	public var color(default, null):Int;
	public var color2(default, null):Int;
	public var grounded(default, null):Bool = false;
	private final owner:Course;
	private final commandHandler:CommandHandler;

	public function new(owner:Course, x:Int, y:Int, rot:Int, num:Int, color:Int, color2:Int, id:Int, ?displayLayer:Sprite,
			?commandHandler:CommandHandler) {
		this.owner = owner;
		this.id = id;
		this.posX = x;
		this.posY = y;
		this.rot = rot;
		this.num = num;
		this.color = color;
		this.color2 = color2;
		this.commandHandler = commandHandler != null ? commandHandler : CommandHandler.commandHandler;

		display = PR2MovieClip.fromLinkage("HatGraphic", {maxNestedDepth: 8});
		display.gotoAndStop(num);
		display.x = x;
		display.y = y;
		display.rotation = rot;
		display.scaleX = 0.15;
		display.scaleY = 0.15;
		setupColorChannel("colorMC", color, true);
		setupColorChannel("colorMC2", num == 16 && color2 == -1 ? 0 : color2, color2 != -1 || num == 16);
		if (displayLayer != null) {
			displayLayer.addChild(display);
		}
		this.owner.looseHats.set(id, this);
		this.commandHandler.defineCommand('removeHat$id', function(_:Array<String>):Void remove());
	}

	public function step(level:ServerLevel, courseRotation:Int, ?playerX:Float, ?playerY:Float, playerCrouching:Bool = false,
			playerRemoved:Bool = false, donePlaying:Bool = false):Void {
		velY += 0.2;
		if (velY > 8) {
			velY = 8;
		}
		posY += velY;
		posX += velX;
		var displayRotation = RotationMath.normalizeDisplayRotation(courseRotation - rot);
		var rotatedPos = RotationMath.rotatePoint(posX, posY, -displayRotation);
		if (velX != 0) {
			var wallProbe = RotationMath.rotatePoint(posX + velX, posY - 10, -displayRotation);
			var wallBlock = blockFromPos(level, wallProbe.x, wallProbe.y, courseRotation);
			if (isActiveBlock(wallBlock)) {
				var blockPos = rotatedBlockPos(wallBlock, rot);
				posX = velX < 0 ? blockPos.x + 31 : blockPos.x - 1;
			}
		}
		var groundBlock = blockFromPos(level, rotatedPos.x, rotatedPos.y, courseRotation);
		if (isActiveBlock(groundBlock)) {
			grounded = true;
			var blockPos = rotatedBlockPos(groundBlock, rot);
			if (velY < 0) {
				velY *= -0.5;
				posY = blockPos.y + 31;
			} else {
				velY = 0;
				posY = blockPos.y;
			}
		} else {
			grounded = false;
		}
		rotatedPos = RotationMath.rotatePoint(posX, posY, -displayRotation);
		display.x = rotatedPos.x;
		display.y = rotatedPos.y;
		display.rotation = displayRotation;
		if (!donePlaying
			&& playerX != null
			&& playerY != null
			&& isNearLocalPlayer(rotatedPos.x, rotatedPos.y, playerX, playerY, playerCrouching, playerRemoved)) {
			remove();
			LobbySocket.write('get_hat`$id');
		}
	}

	public function info():HatEffectInfo {
		return {
			x: posX,
			y: posY,
			rot: rot,
			num: num,
			color: color,
			color2: color2,
			id: id
		};
	}

	public function remove():Void {
		if (display.parent != null) {
			display.parent.removeChild(display);
		}
		if (owner.looseHats != null) {
			owner.looseHats.remove(id);
		}
		commandHandler.defineCommand('removeHat$id', null);
	}

	private function setupColorChannel(name:String, tint:Int, visible:Bool):Void {
		var child = findByName(display, name);
		if (child == null) {
			return;
		}
		child.visible = visible;
		if (visible) {
			child.transform.colorTransform = colorTransformFor(tint);
		}
	}

	private static function findByName(root:DisplayObject, name:String):Null<DisplayObject> {
		if (root.name == name) {
			return root;
		}
		var container = Std.downcast(root, Sprite);
		if (container == null) {
			return null;
		}
		for (i in 0...container.numChildren) {
			var found = findByName(container.getChildAt(i), name);
			if (found != null) {
				return found;
			}
		}
		return null;
	}

	private static function colorTransformFor(color:Int):ColorTransform {
		return new ColorTransform(0, 0, 0, 1, (color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF, 0);
	}

	private static function blockFromPos(level:ServerLevel, posX:Int, posY:Int, rotation:Int):Null<DecodedBlock> {
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

	private static function isActiveBlock(block:Null<DecodedBlock>):Bool {
		if (block == null) {
			return false;
		}
		return switch (block.code) {
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4
				| ObjectCodes.BLOCK_WATER | ObjectCodes.BLOCK_SAFETY:
				false;
			default:
				true;
		}
	}

	private static function rotatedBlockPos(block:DecodedBlock, rot:Int):RotatedPoint {
		var offsetX = 0;
		var offsetY = 0;
		if (rot == 90) {
			offsetY = 30;
		} else if (Math.abs(rot) == 180) {
			offsetX = 30;
			offsetY = 30;
		} else if (rot == -90) {
			offsetX = 30;
		}
		return RotationMath.rotatePoint(block.x + offsetX, block.y + offsetY, -rot);
	}

	private static function isNearLocalPlayer(px:Int, py:Int, playerX:Float, playerY:Float, playerCrouching:Bool, playerRemoved:Bool):Bool {
		if (playerRemoved) {
			return false;
		}
		return Math.abs(playerX - px) < 25
			&& playerY > py - 5
			&& ((!playerCrouching && playerY < py + 65) || (playerCrouching && playerY < py + 25));
	}
}
