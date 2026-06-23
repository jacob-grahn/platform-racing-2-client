package pr2.page;

import openfl.display.Sprite;

/**
	Hosts the active `Page` and swaps between pages, ported from the Flash
	`page.PageHolder`. Swapping removes the current page (giving it a chance to
	tear down listeners) before initializing and adding the next one.

	Only the stage-root holder (Flash's `Main.pageHolder`) hosts top-level pages
	such as the game. The lobby builds its own nested holders (`LobbySide`,
	`PlayersTab`'s inner list holder); those must NOT claim the `startGame`
	launch, or the game mounts inside an offset lobby panel instead of taking
	over the stage. Pass `root = true` only for the holder Main adds to the stage.
**/
class PageHolder extends Sprite {
	private var currentPage:Null<Page>;

	public function new(?page:Page, root:Bool = false) {
		super();
		if (root) {
			pr2.lobby.level.LevelLaunch.install(this);
		}
		if (page != null) {
			changePage(page);
		}
	}

	public function changePage(page:Page):Void {
		if (currentPage != null) {
			currentPage.remove();
			if (currentPage.parent != null) {
				currentPage.parent.removeChild(currentPage);
			}
		}

		if (page != null) {
			page.pageHolder = this;
			page.initialize();
			addChild(page);
			currentPage = page;
		}
	}

	public function getCurrentPage():Null<Page> {
		return currentPage;
	}
}
