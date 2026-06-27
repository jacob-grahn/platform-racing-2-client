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
		switch (block.type) {
			case BlockType.ArrowDown | BlockType.ArrowUp | BlockType.ArrowLeft | BlockType.ArrowRight:
				renderer.animateArrow(worldX, worldY);
			case BlockType.Vanish:
				renderer.activateVanish(worldX, worldY);
			case BlockType.Water:
				renderer.triggerWaterRipple(worldX, worldY);
			default:
		}
	}
}
