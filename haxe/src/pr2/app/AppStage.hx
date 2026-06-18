package pr2.app;

import openfl.display.Stage;

/**
	Global stage reference standing in for Flash's `Main.stage`.

	Popups and other overlays add themselves directly to the stage rather than to
	a page, so they survive page changes and sit above everything. The document
	class sets this once the stage is available; code that needs it reads
	`AppStage.stage`.
**/
class AppStage {
	public static var stage:Null<Stage> = null;

	private function new() {}
}
