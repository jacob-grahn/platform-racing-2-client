package pr2.gameplay;

import haxe.crypto.Md5;
import pr2.effects.BlockPiece;
import pr2.gameplay.player.BlockVisualEvent;
import pr2.gameplay.player.BlockVisualEvent.BlockVisualEventKind;
import pr2.level.ServerLevelWorldAdapter;
import pr2.net.LobbySocket;

/** Applies authoritative block-runtime events to rendering, sound, and networking. */
@:access(pr2.gameplay.Course)
class CourseBlockVisualController {
	private final owner:Course;

	public function new(owner:Course) {
		this.owner = owner;
	}

	public function syncBlockVisuals():Void {
		syncMoveBlockArrows();
		syncMoveBlockDisplays();
		// Only blocks with non-default alpha/tint (fading/removed/depleted) need
		// restyling; iterating all blocks here was O(blocks) per frame and dropped
		// large levels to a few fps. Update just the active set, and reset any block
		// that returned to default since last frame.
		var current:Map<String, Bool> = new Map();
		for (key in owner.player.activeVisualBlockKeys()) {
			current.set(key, true);
			var tileX = tileKeyX(key);
			var tileY = tileKeyY(key);
			applyBlockVisual(tileX, tileY, owner.player.blockAlphaAt(tileX, tileY), owner.player.blockColorMultiplierAt(tileX, tileY),
				owner.player.blockIceOverlayAlphaAt(tileX, tileY));
		}
		for (key in owner.activeVisualBlocks.keys()) {
			if (!current.exists(key)) {
				applyBlockVisual(tileKeyX(key), tileKeyY(key), 1, 1, 0);
			}
		}
		owner.activeVisualBlocks = current;
		for (event in owner.player.consumeBlockVisualEvents()) {
			switch (event.kind) {
				case LocalActivate:
					emitLocalBlockActivation(event);
				case ArrowAnimate:
					owner.levelRenderer.animateArrow(worldXOf(event), worldYOf(event));
				case MineExplode:
					owner.levelRenderer.showMineExplosion(worldXOf(event), worldYOf(event));
				case BrickPieces:
					showBlockPieces(event, "BrickPieceGraphic", 10, 10, 25);
				case BasicDigPieces:
					owner.levelRenderer.showBasicBlockPieces(worldXOf(event), worldYOf(event), event.count, 10, 10, 25);
				case CrumblePieces:
					showBlockPieces(event, "CrumblePieceGraphic", 5, 5, 15);
				case MinePieces:
					showBlockPieces(event, "MinePieceGraphic", 30, 30, 50);
				case WaterRipple:
					owner.levelRenderer.triggerWaterRipple(worldXOf(event), worldYOf(event));
				case SafetyPoof:
					owner.levelRenderer.showTeleportPop(worldXOf(event), worldYOf(event));
				case TeleportBlockPop:
					emitLocalTeleportPop(event);
				case BlockBumpSound:
					owner.levelRenderer.animateBlockBump(worldXOf(event), worldYOf(event), event.hitX, event.hitY);
					playBlockBumpSound(event);
				case ItemBlockSound:
					playItemBlockSound();
				case HappyBlockSound:
					playStatBlockSound(event, RaceSounds.BUMP_HAPPY_SOUND);
				case SadBlockSound:
					playStatBlockSound(event, RaceSounds.BUMP_SAD_SOUND);
				case TimeBlockSound:
					playTimeBlockSound();
				case SuperJumpSound:
					owner.playSuperJumpSound();
				case PushBlockMove:
					if (event.toTileX != null && event.toTileY != null) {
						owner.levelRenderer.moveBlockDisplay(
							worldXOf(event),
							worldYOf(event),
							worldTileX(event.toTileX),
							worldTileY(event.toTileY)
						);
					}
			}
		}
		owner.publishMultiplayerDiagnostics();
	}

	public function resetActiveBlockVisuals():Void {
		for (key in owner.activeVisualBlocks.keys()) {
			applyBlockVisual(tileKeyX(key), tileKeyY(key), 1, 1, 0);
		}
		owner.activeVisualBlocks = new Map();
	}

	public function resetMovedBlockDisplays():Void {
		for (i in owner.displayedMoveBlockPositions.keys()) {
			var displayed = owner.displayedMoveBlockPositions.get(i);
			if (displayed != null && (displayed.worldX != displayed.originalWorldX || displayed.worldY != displayed.originalWorldY)) {
				owner.levelRenderer.moveBlockDisplay(displayed.worldX, displayed.worldY, displayed.originalWorldX, displayed.originalWorldY);
			}
		}
		owner.displayedMoveBlockPositions.clear();
	}

	public function syncMoveBlockDisplays():Void {
		if (owner.levelRenderer == null || owner.worldLevel == null) {
			return;
		}
		var worldBlocks = owner.worldLevel.blocks;
		for (i in 0...worldBlocks.length) {
			var worldBlock = worldBlocks[i];
			if (worldBlock.type != pr2.level.BlockType.Move || i >= owner.level.blocks.length) {
				continue;
			}
			var currentWorldX = worldBlock.x * ServerLevelWorldAdapter.TILE_SIZE;
			var currentWorldY = worldBlock.y * ServerLevelWorldAdapter.TILE_SIZE;
			var displayed = owner.displayedMoveBlockPositions.get(i);
			if (displayed == null) {
				// World conversion omits spawn-marker blocks, so its indices do not
				// correspond to ServerLevel.blocks. Capture this move block's own initial
				// coordinate rather than moving whichever decoded block shares its index.
				owner.displayedMoveBlockPositions.set(i, {
					worldX: currentWorldX,
					worldY: currentWorldY,
					originalWorldX: currentWorldX,
					originalWorldY: currentWorldY
				});
				displayed = owner.displayedMoveBlockPositions.get(i);
			}
			if (displayed.worldX != currentWorldX || displayed.worldY != currentWorldY) {
				owner.levelRenderer.moveBlockDisplay(displayed.worldX, displayed.worldY, currentWorldX, currentWorldY);
				owner.displayedMoveBlockPositions.set(i, {
					worldX: currentWorldX,
					worldY: currentWorldY,
					originalWorldX: displayed.originalWorldX,
					originalWorldY: displayed.originalWorldY
				});
			}
		}
	}

	public function syncMoveBlockArrows():Void {
		if (owner.levelRenderer == null || owner.worldLevel == null || owner.player == null) {
			return;
		}
		var current:Map<String, Bool> = new Map();
		var directions = owner.player.activeMoveBlockDirections();
		for (tileKey in directions.keys()) {
			var tileX = tileKeyX(tileKey);
			var tileY = tileKeyY(tileKey);
			var worldX = tileX * ServerLevelWorldAdapter.TILE_SIZE;
			var worldY = tileY * ServerLevelWorldAdapter.TILE_SIZE;
			var worldKey = '$worldX,$worldY';
			current.set(worldKey, true);
			owner.levelRenderer.showMoveBlockArrow(worldX, worldY, directions.get(tileKey));
		}
		for (worldKey in owner.displayedMoveBlockArrows.keys()) {
			if (!current.exists(worldKey)) {
				owner.levelRenderer.hideMoveBlockArrow(tileKeyX(worldKey), tileKeyY(worldKey));
			}
		}
		owner.displayedMoveBlockArrows = current;
	}

	public function playBlockBumpSound(event:BlockVisualEvent):Void {
		owner.raceSounds.playBlockBumpSound(worldXOf(event), worldYOf(event));
	}

	public function playItemBlockSound():Void {
		owner.raceSounds.playItemBlockSound();
	}

	public function playStatBlockSound(event:BlockVisualEvent, path:String):Void {
		owner.raceSounds.playStatBlockSound(path);
	}

	public function playTimeBlockSound():Void {
		owner.raceSounds.playTimeBlockSound();
	}

	public function applyBlockVisual(tileX:Int, tileY:Int, alpha:Float, multiplier:Float, iceOverlayAlpha:Float):Void {
		var worldX = tileX * ServerLevelWorldAdapter.TILE_SIZE;
		var worldY = tileY * ServerLevelWorldAdapter.TILE_SIZE;
		owner.levelRenderer.setBlockAlpha(worldX, worldY, alpha);
		owner.levelRenderer.setBlockColorMultiplier(worldX, worldY, multiplier);
		owner.levelRenderer.setBlockIceOverlayAlpha(worldX, worldY, iceOverlayAlpha);
	}

	private static inline function tileKeyX(key:String):Int {
		return Std.parseInt(key.substring(0, key.indexOf(",")));
	}

	private static inline function tileKeyY(key:String):Int {
		return Std.parseInt(key.substring(key.indexOf(",") + 1));
	}

	public function emitFinishDrawingReady():Void {
		if (owner.finishDrawingEmitted || owner.localCharacter == null) {
			return;
		}
		owner.finishDrawingEmitted = true;
		var cowboyChance = Std.parseInt(owner.config.cowboyChance);
		owner.localCharacter.emitFinishDrawing(
			Md5.encode(owner.data.saveString + Std.int(owner.config.levelId) + owner.data.version + pr2.net.ServerConfig.LEVEL_HASH_SALT),
			owner.config.gameMode,
			finishBlockPositions(),
			owner.level.finishBlocks().length,
			cowboyChance == null ? 5 : cowboyChance,
			owner.config.badHats
		);
	}

	public function finishBlockPositions():String {
		var finishes = owner.level.finishBlocks();
		if (finishes.length > 5) {
			return "all";
		}
		var parts:Array<String> = [];
		for (i in 0...finishes.length) {
			var block = finishes[i];
			parts.push('{"id":${i + 1},"x":${block.x + 15},"y":${block.y + 15}}');
		}
		return "[" + parts.join(",") + "]";
	}

	private inline function worldXOf(event:BlockVisualEvent):Int {
		return event.tileX * ServerLevelWorldAdapter.TILE_SIZE;
	}

	private inline function worldYOf(event:BlockVisualEvent):Int {
		return event.tileY * ServerLevelWorldAdapter.TILE_SIZE;
	}

	private inline function worldTileX(tileX:Int):Int {
		return tileX * ServerLevelWorldAdapter.TILE_SIZE;
	}

	private inline function worldTileY(tileY:Int):Int {
		return tileY * ServerLevelWorldAdapter.TILE_SIZE;
	}

	public function emitLocalBlockActivation(event:BlockVisualEvent):Void {
		var segX = event.tileX;
		var segY = event.tileY;
		var payload = event.activationPayload == null ? "" : event.activationPayload;
		recordCrumbleActivation(event.tileX, event.tileY, payload);
		LobbySocket.write('activate`$segX`$segY`$payload');
	}

	public function emitLocalTeleportPop(event:BlockVisualEvent):Void {
		var worldX = Std.int(Math.round(event.hitX));
		var worldY = Std.int(Math.round(event.hitY));
		owner.levelRenderer.showTeleportPop(worldX, worldY);
		LobbySocket.write('add_effect`Teleport`$worldX`$worldY');
	}

	public function showBlockPieces(event:BlockVisualEvent, linkage:String, spreadX:Float, spreadY:Float, spreadRot:Float):Void {
		if (linkage == "CrumblePieceGraphic") {
			owner.debugCrumblePiecesSpawned += event.count;
		}
		owner.levelRenderer.showBlockPieces(linkage, worldXOf(event), worldYOf(event), event.count, spreadX, spreadY, spreadRot, 0.75, 0.95, 0.05);
	}

	public function debugActiveBlockPieces():Int {
		if (owner.levelRenderer == null) {
			return 0;
		}
		var count = 0;
		var layer = owner.levelRenderer.worldEffectLayer();
		for (i in 0...layer.numChildren) {
			if (Std.isOfType(layer.getChildAt(i), BlockPiece)) {
				count++;
			}
		}
		return count;
	}

	public function recordCrumbleActivation(tileX:Int, tileY:Int, payload:String):Void {
		if (owner.worldLevel == null) {
			return;
		}
		var block = owner.worldLevel.blockAt(tileX, tileY);
		if (block != null && block.type == pr2.level.BlockType.Crumble) {
			owner.debugLastCrumbleForce = payload;
			owner.debugCrumbleActivations++;
		}
	}

}
