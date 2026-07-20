package pr2.gameplay.player;

import pr2.gameplay.Items;
import pr2.gameplay.BlockController;
import pr2.gameplay.RotationMath;
import pr2.gameplay.player.BlockVisualEvent.BlockVisualEventKind;
import pr2.gameplay.player.LocalPlayerControllerTypes.PendingMinePlacement;
import pr2.gameplay.player.LocalPlayerControllerTypes.PendingProjectileDamage;
import pr2.level.BlockType;
import pr2.level.WorldLevel.LevelBlock;

/** Executes held-item behavior while the controller retains authoritative movement state. */
@:access(pr2.gameplay.player.LocalPlayerController)
class ItemController {
	private final owner:LocalPlayerController;

	public function new(owner:LocalPlayerController) {
		this.owner = owner;
	}

	public function updateReload():Void {
		if (owner.heldItem != null) {
			owner.heldItem.tickReload();
			owner.itemReloadFramesRemaining = owner.heldItem.reloadFramesRemaining;
			return;
		}
		if (owner.itemReloadFramesRemaining > 0) {
			owner.itemReloadFramesRemaining--;
		}
	}

	public function updateTimedEffects():Void {
		if (owner.speedBurstFramesRemaining <= 0) {
			return;
		}
		owner.speedBurstFramesRemaining--;
		if (owner.speedBurstFramesRemaining <= 0) {
			owner.itemId = null;
			owner.itemUses = null;
			owner.heldItem = null;
			owner.speedBurstFromItem = false;
			owner.itemAvailable = false;
			owner.applyMovementStats();
		}
	}

	public function nextRandom(maxValue:Int):Int {
		return Math.floor(owner.itemRandom() * maxValue);
	}

	public function useHeldItem(input:LocalPlayerInput):Void {
		if (owner.heldItem == null || owner.itemId == null) {
			owner.jetPackActive = false;
			return;
		}
		if (owner.itemId == LocalPlayerController.ITEM_JET_PACK && !input.item) {
			owner.jetPackActive = false;
		}
		owner.heldItem.setSpace(input.item, owner);
		owner.itemAvailable = !input.item;
	}

	public function performLaserGunItem():Void useLaserGun();
	public function performMineItem():Void useMineItem();
	public function performLightningItem():Void useLightning();
	public function performTeleportItem():Void useTeleportItem();
	public function performSuperJumpItem():Void useSuperJump();
	public function performJetPackItem():Void useJetPack();
	public function performSpeedBurstItem():Void useSpeedBurst();
	public function performSwordItem():Void useSword();
	public function performIceWaveItem():Void useIceWave();
	public function performSnakeItem():Void useSnake();

	public function grantItemForDebug(itemCode:Int):Void {
		owner.heldItem = Items.getFromCode(itemCode);
		owner.itemId = owner.heldItem == null ? null : Items.getCodeFromItem(owner.heldItem);
		owner.itemUses = owner.heldItem == null ? null : owner.heldItem.initialUses;
		owner.jetPackFuelRemaining = itemCode == LocalPlayerController.ITEM_JET_PACK ? LocalPlayerController.JET_PACK_TOTAL_FUEL : null;
		owner.itemAvailable = true;
	}

	public function useSnake():Void {
		owner.lastItemEffect = "snake_start";
		consumeHeldItemUse();
	}

	public function addSnakeTrail(tileX:Int, tileY:Int):Void {
		var key = owner.blockKey(tileX, tileY);
		if (!owner.snakeTrailBlocks.exists(key)) {
			owner.snakeTrailBlocks.set(key, new LevelBlock(tileX, tileY, BlockType.SnakeTrail));
		}
	}

	public function removeSnakeTrail(tileX:Int, tileY:Int):Void {
		owner.snakeTrailBlocks.remove(owner.blockKey(tileX, tileY));
	}

	public function clearSnakeTrails():Void {
		owner.snakeTrailBlocks.clear();
	}

	public function snakeTileAtPixel(pixelX:Float, pixelY:Float):{x:Int, y:Int} {
		var tile = owner.rotatedTileAtPixel(pixelX, pixelY);
		return {x: tile.x, y: tile.y};
	}

	public function snakeGridDirection(dx:Int, dy:Int):{x:Int, y:Int} {
		var rotated = RotationMath.rotatePoint(dx, dy, owner.courseRotation);
		return {x: Math.round(rotated.x), y: Math.round(rotated.y)};
	}

	/**
		Resolve an owner-authoritative Snake head entering a world tile.
		Returns "clear" when movement may continue and "hazard" otherwise.
	**/
	public function enterSnakeTile(tileX:Int, tileY:Int):String {
		if (owner.snakeTrailBlocks.exists(owner.blockKey(tileX, tileY))) {
			return "hazard";
		}
		var block = owner.level.blockAt(tileX, tileY);
		if (block == null || owner.isBlockRemoved(block)) {
			return "clear";
		}
			switch (block.type) {
			case BlockType.Basic:
				owner.activateBlock(block, "snake", true);
				return "clear";
			case BlockType.Brick:
				owner.activateBlock(block, "", true);
				return "clear";
			case BlockType.Crumble:
				owner.activateBlock(block, "50", true);
				return "clear";
			case BlockType.Mine:
				owner.activateBlock(block, "", true);
				return "hazard";
			case BlockType.Water:
				return "hazard";
			default:
				return block.type.isSolid() ? "hazard" : "clear";
		}
	}

	public function useLaserGun():Void {
		var direction = owner.facingDirection < 0 ? "left" : "right";
		owner.vx += owner.facingDirection < 0 ? 15 : -15;
		owner.lastItemEffect = "laser:" + direction;
		queueProjectileBlockDamage(owner.facingDirection < 0 ? 180 : 0, owner.facingDirection * LocalPlayerController.LASER_SHOT_SPEED, 100);
		consumeHeldItemUse();
	}

	public function useMineItem():Void {
		var tile = owner.rotatedTileAtPixel(owner.x + owner.facingDirection * owner.level.tileSize, owner.y - 15);
		if (owner.level.blockAt(tile.x, tile.y) != null) {
			return;
		}
		var effectPos = LocalPlayerController.rotatePoint(tile.x * owner.level.tileSize + 15, tile.y * owner.level.tileSize + 15, owner.courseRotation);
		owner.lastItemEffect = "mine:" + effectPos.x + "," + effectPos.y + ":" + owner.courseRotation;
		owner.pendingMinePlacements.push({tileX: tile.x, tileY: tile.y, framesRemaining: LocalPlayerController.MINE_APPEAR_FRAMES});
		consumeHeldItemUse();
	}

	public function updatePendingMinePlacements():Void {
		if (owner.pendingMinePlacements.length == 0) {
			return;
		}
		var stillPending:Array<PendingMinePlacement> = [];
		for (placement in owner.pendingMinePlacements) {
			placement.framesRemaining--;
			if (placement.framesRemaining <= 0) {
				if (owner.level.blockAt(placement.tileX, placement.tileY) == null) {
					owner.level.blocks.push(new LevelBlock(placement.tileX, placement.tileY, BlockType.Mine));
				}
			} else {
				stillPending.push(placement);
			}
		}
		owner.pendingMinePlacements = stillPending;
	}

	public function queueProjectileBlockDamage(angleDegrees:Float, damageForce:Float, maxFrames:Int):Void {
		var radians = angleDegrees * Math.PI / 180;
		var shotX = owner.x + (angleDegrees == 180 ? -20 : 20);
		var shotY = owner.y - 25;
		// Flash's ShotEffect queries blocks directly: a Top Hat only changes the
		// character's collision, not which block a laser damages.
		var immediateBlock = owner.getBlockAtPixel(shotX, shotY, true);
		if (immediateBlock != null) {
			damageBlockFromItem(immediateBlock, Math.cos(radians) * LocalPlayerController.SHOT_EFFECT_DEFAULT_SPEED);
			return;
		}
		owner.pendingProjectileDamages.push({
			shotX: shotX,
			shotY: shotY,
			velX: Math.cos(radians) * LocalPlayerController.LASER_SHOT_SPEED,
			velY: Math.sin(radians) * LocalPlayerController.LASER_SHOT_SPEED,
			damageForce: damageForce,
			framesRemaining: maxFrames
		});
	}

	public function updatePendingProjectileDamages():Void {
		if (owner.pendingProjectileDamages.length == 0) {
			return;
		}
		var stillPending:Array<PendingProjectileDamage> = [];
		for (projectile in owner.pendingProjectileDamages) {
			projectile.shotX += projectile.velX;
			projectile.shotY += projectile.velY;
			projectile.framesRemaining--;
			var block = owner.getBlockAtPixel(projectile.shotX, projectile.shotY, true);
			if (block != null) {
				damageBlockFromItem(block, projectile.damageForce);
			} else if (projectile.framesRemaining > 0) {
				stillPending.push(projectile);
			}
		}
		owner.pendingProjectileDamages = stillPending;
	}

	public function useLightning():Void {
		owner.lastItemEffect = "zap`";
		consumeHeldItemUse();
	}

	public function useTeleportItem():Void {
		var startX = owner.x;
		var startY = owner.y - 25;
		var destX = owner.x + LocalPlayerController.TELEPORT_ITEM_DISTANCE * owner.facingDirection;
		if (owner.getBlockAtPixel(destX, owner.y - 5) != null) {
			return;
		}
		owner.setPlayerX(destX);
		owner.lastItemEffect = "teleport:" + Std.int(startX) + "," + Std.int(startY) + ":" + Std.int(owner.x) + "," + Std.int(owner.y - 25);
		consumeHeldItemUse();
	}

	public function useSuperJump():Void {
		if (owner.crouching) {
			return;
		}
		owner.blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.SuperJumpSound, 0, 0));
		owner.vy -= 25;
		consumeHeldItemUse();
	}

	public function useSpeedBurst():Void {
		if (owner.speedBurstFramesRemaining > 0) {
			return;
		}
		owner.speedBurstFromItem = true;
		activateSpeedBurst(LocalPlayerController.SPEED_BURST_FRAMES);
	}

	public function activateSpeedBurst(frames:Int):Void {
		if (frames <= 0) {
			return;
		}
		owner.accel *= 2;
		owner.maxVelX *= 2;
		owner.speedBurstFramesRemaining = frames;
	}

	public static function msToFrames(ms:Int):Int {
		return Std.int(Math.round(ms * LocalPlayerController.FRAME_RATE / 1000));
	}

	public function useJetPack():Void {
		if (owner.jetPackFuelRemaining == null || owner.jetPackFuelRemaining <= 0 || owner.crouching) {
			return;
		}
		owner.vy -= owner.vy > -5 ? 1.25 : 0.5;
		owner.jetPackActive = true;
		owner.jetPackFuelRemaining--;
		owner.itemUses = Std.int(Math.ceil((owner.jetPackFuelRemaining / LocalPlayerController.JET_PACK_TOTAL_FUEL) * 3));
		if (owner.jetPackFuelRemaining <= 0) {
			consumeHeldItemCompletely();
		}
	}

	public function useSword():Void {
		var direction = owner.facingDirection < 0 ? "left" : "right";
		owner.vx += owner.facingDirection < 0 ? -8 : 8;
		owner.lastItemEffect = "slash:" + direction;
		damageSwordArea();
		consumeHeldItemUse();
	}

	private function damageSwordArea():Void {
		var startX = owner.x;
		var startY = owner.y - 25;
		var reach = owner.facingDirection < 0 ? -29 : 29;
		for (step in 0...3) {
			var probeX = startX + reach * step;
			damageSwordProbe(probeX, startY - 14, reach);
			damageSwordProbe(probeX, startY + 14, reach);
		}
	}

	private function damageSwordProbe(pixelX:Float, pixelY:Float, damageForce:Float):Void {
		var block = owner.getBlockAtPixel(pixelX, pixelY);
		if (block != null) {
			damageBlockFromItem(block, damageForce);
		}
	}

	public function useIceWave():Void {
		var direction = owner.facingDirection < 0 ? "left" : "right";
		owner.lastItemEffect = "ice_wave:" + direction;
		freezeFirstShotBlockHit(owner.facingDirection < 0 ? 180 : 0);
		consumeHeldItemUse();
	}

	public function freezeFirstShotBlockHit(angleDegrees:Float):Void {
		var shotX = owner.x + (angleDegrees == 180 ? -20 : 20);
		var shotY = owner.y - 25;
		var radians = angleDegrees * Math.PI / 180;
		var velX = Math.cos(radians) * 5;
		var velY = Math.sin(radians) * 5;
		for (_ in 0...100) {
			var block = owner.getBlockAtPixel(shotX, shotY);
			if (block != null) {
				if (block.type != BlockType.Ice) {
					var state = owner.blockState(owner.blockKey(block.x, block.y));
					state.frozenIceAlpha = BlockController.SANTA_ICE_OVERLAY_START_ALPHA;
					state.frozenIceFadeRate = BlockController.SANTA_ICE_OVERLAY_FADE_RATE;
				}
				return;
			}
			shotX += velX;
			shotY += velY;
		}
	}

	public function animateForwardBlockDamage(angleDegrees:Float, damageForce:Float, maxSteps:Int):Void {
		var shotX = owner.x + (angleDegrees == 180 ? -20 : 20);
		var shotY = owner.y - 25;
		var radians = angleDegrees * Math.PI / 180;
		var velX = Math.cos(radians) * 5;
		var velY = Math.sin(radians) * 5;
		for (_ in 0...maxSteps) {
			var block = owner.getBlockAtPixel(shotX, shotY);
			if (block != null) {
				damageBlockFromItem(block, damageForce);
				return;
			}
			shotX += velX;
			shotY += velY;
		}
	}

	public function damageBlockFromItem(block:LevelBlock, damageForce:Float):Void {
		var clampedHitX = LocalPlayerController.clamp(damageForce, -20, 20);
		owner.blockVisualEvents.push(new BlockVisualEvent(BlockVisualEventKind.BlockBumpSound, block.x, block.y, 1, null, null, clampedHitX, 0));
			switch (block.type) {
			case BlockType.Brick:
				owner.activateBlock(block, "", true);
			case BlockType.Crumble:
				owner.applyCrumbleForce(block, 5);
			case BlockType.Mine:
				owner.activateBlock(block, "", true);
			case BlockType.Vanish:
				owner.activateVanish(block);
			default:
		}
	}

	public function consumeHeldItemUse():Void {
		if (owner.heldItem != null) {
			if (owner.heldItem.consumeUse()) {
				consumeHeldItemCompletely();
			} else {
				owner.itemUses = owner.heldItem.uses();
				owner.itemReloadFramesRemaining = owner.heldItem.reloadFramesRemaining;
			}
			return;
		}
		if (owner.itemUses == null || owner.itemUses <= 1) {
			consumeHeldItemCompletely();
			return;
		}
		owner.itemUses--;
		owner.itemReloadFramesRemaining = 0;
	}

	public function applyJetPackThrust(input:LocalPlayerInput):Void {
		if (input.item && owner.itemId == LocalPlayerController.ITEM_JET_PACK && !owner.crouching) owner.jumpHeld = false;
	}

	public function consumeHeldItemCompletely():Void {
		owner.itemId = null;
		owner.itemUses = null;
		owner.heldItem = null;
		owner.itemReloadFramesRemaining = 0;
		owner.jetPackFuelRemaining = null;
		owner.jetPackActive = false;
		owner.itemAvailable = false;
	}

}
