package pr2.page;

import openfl.display.Sprite;

/**
	Hosts the active `Page` and swaps between pages, ported from the Flash
	`page.PageHolder`. Swapping removes the current page (giving it a chance to
	tear down listeners) before initializing and adding the next one.
**/
class PageHolder extends Sprite {
	private var currentPage:Null<Page>;

	public function new(?page:Page) {
		super();
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
