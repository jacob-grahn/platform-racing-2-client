package pr2.gameplay;

/** Optional presentation assets warmed while the course is loading. */
interface ResultsAssets {
	public function prepareShell():openfl.display.DisplayObject;
	public function prepareRating():openfl.display.DisplayObject;
	public function prepareExpGain():openfl.display.DisplayObject;
	public function dispose():Void;
}
