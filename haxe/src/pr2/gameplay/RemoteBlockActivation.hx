package pr2.gameplay;

import pr2.level.BlockType;
import pr2.level.ServerLevelFixtureAdapter;
import pr2.level.ServerLevelFixtureAdapter.ServerFixtureLevel;
import pr2.level.ServerLevelRenderer;

/**
	RemoteCharacter.processBlockTouches mirrors Flash by activating only the
	remote-visible block effects: arrows animate, vanish blocks disappear, and
	water ripples. Physics remains server/local-authoritative.
**/
class RemoteBlockActivation {
	private final fixture:ServerFixtureLevel;
	private final renderer:ServerLevelRenderer;

	public function new(fixture:ServerFixtureLevel, renderer:ServerLevelRenderer) {
		this.fixture = fixture;
		this.renderer = renderer;
	}

	public function touch(tileX:Int, tileY:Int):Void {
		var block = fixture.fixture.blockAt(tileX, tileY);
		if (block == null) {
			return;
		}
		var worldX = (block.x + fixture.originTileX) * ServerLevelFixtureAdapter.TILE_SIZE;
		var worldY = (block.y + fixture.originTileY) * ServerLevelFixtureAdapter.TILE_SIZE;
		activateBlock(block.type, worldX, worldY);
	}

	public function activateSegment(segX:Int, segY:Int, payload:String = ""):Void {
		var tileX = segX - fixture.originTileX;
		var tileY = segY - fixture.originTileY;
		var block = fixture.fixture.blockAt(tileX, tileY);
		if (block == null) {
			return;
		}
		activateBlock(block.type, segX * ServerLevelFixtureAdapter.TILE_SIZE, segY * ServerLevelFixtureAdapter.TILE_SIZE, payload);
	}

	private function activateBlock(type:BlockType, worldX:Int, worldY:Int, payload:String = ""):Void {
		switch (type) {
			case BlockType.ArrowDown | BlockType.ArrowUp | BlockType.ArrowLeft | BlockType.ArrowRight:
				renderer.animateArrow(worldX, worldY);
			case BlockType.Vanish:
				renderer.activateVanish(worldX, worldY);
			case BlockType.Water:
				renderer.triggerWaterRipple(worldX, worldY);
			case BlockType.Brick:
				renderer.showBlockPieces("BrickPieceGraphic", worldX, worldY, 6, 10, 10, 25);
				renderer.removeBlockDisplay(worldX, worldY);
			case BlockType.Crumble:
				var force = Std.parseInt(payload);
				var count = force == null ? 10 : Std.int(Math.min(Math.floor(force / 4) * 2, 20));
				renderer.showBlockPieces("CrumblePieceGraphic", worldX, worldY, count, 5, 5, 15);
				if (force == null || force >= 20) {
					renderer.removeBlockDisplay(worldX, worldY);
				}
			case BlockType.Mine:
				renderer.showBlockPieces("MinePieceGraphic", worldX, worldY, 10, 30, 30, 50);
				renderer.showMineExplosion(worldX, worldY);
				renderer.removeBlockDisplay(worldX, worldY);
			case BlockType.Push:
				activatePush(worldX, worldY, payload);
			default:
		}
	}

	private function activatePush(worldX:Int, worldY:Int, payload:String):Void {
		var dx = 0;
		var dy = 0;
		switch (payload) {
			case "down": dy = 1;
			case "up": dy = -1;
			case "right": dx = 1;
			case "left": dx = -1;
			default:
		}
		if (dx != 0 || dy != 0) {
			renderer.moveBlockDisplay(worldX, worldY, worldX + dx * ServerLevelFixtureAdapter.TILE_SIZE,
				worldY + dy * ServerLevelFixtureAdapter.TILE_SIZE);
		}
	}
}
