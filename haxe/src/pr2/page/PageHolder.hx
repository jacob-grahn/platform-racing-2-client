package pr2.page;

import openfl.display.Sprite;
import pr2.runtime.FrameClock;

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
	private static var rootHolder:Null<PageHolder>;
	private var currentPage:Null<Page>;
	private final isRootHolder:Bool;

	public function new(?page:Page, root:Bool = false) {
		super();
		isRootHolder = root;
		if (isRootHolder) {
			rootHolder = this;
			pr2.lobby.level.LevelLaunch.install(this);
		}
		if (page != null) {
			changePage(page);
		}
	}

	public function changePage(page:Page):Void {
		if (isRootHolder) {
			FrameClock.resetCurrentPresentationPhase();
		}
		if (currentPage != null) {
			currentPage.remove();
			if (currentPage.parent != null) {
				currentPage.parent.removeChild(currentPage);
			}
		}

		if (page != null) {
			if (isRootHolder) pr2.app.PageViewport.apply(page.fullViewport);
			page.pageHolder = this;
			page.initialize();
			addChild(page);
			currentPage = page;
		}
	}

	public function getCurrentPage():Null<Page> {
		return currentPage;
	}

	/** The stage-root holder, equivalent to Flash's `Main.pageHolder`. */
	public static function getRootHolder():Null<PageHolder> {
		return rootHolder;
	}
}
