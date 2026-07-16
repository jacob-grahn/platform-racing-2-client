package pr2.runtime;

class SvgAssetTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var source = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="20" height="20" viewBox="0 0 20 20"><defs><path id="mark" fill="#ff0000" d="M 0 0 L 10 0 L 10 10 Z"/></defs><g transform="matrix( 1, 0, 0, 1, 3,4) "><use xlink:href="#mark"/></g></svg>';
		var prepared = SvgAsset.prepare(source);
		assertFalse(prepared.indexOf("matrix( ") >= 0, "Animate matrix leading whitespace is normalized");
		assertFalse(prepared.indexOf("<use") >= 0, "SVG use references are expanded");
		var shape = SvgAsset.createFromText(source);
		assertTrue(shape.graphics != null, "expanded SVG renders into OpenFL graphics");
		@:privateAccess assertEquals("graphics", SvgAsset.timelinePackGroup("assets/svg/timeline/graphics_symbol_1/t00.svg"),
			"graphics timeline assets select the graphics pack");
		@:privateAccess assertEquals("movieclips", SvgAsset.timelinePackGroup("assets/svg/timeline/movieclips_symbol_1/t00.svg"),
			"movie clip timeline assets select the movieclips pack");
		@:privateAccess assertEquals("misc", SvgAsset.timelinePackGroup("assets/svg/timeline/trophyicon_1/t00.svg"),
			"root symbols select the miscellaneous pack");
		trace('SvgAssetTest passed $assertions assertions');
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) throw message;
	}

	private static function assertFalse(value:Bool, message:String):Void {
		assertTrue(!value, message);
	}

	private static function assertEquals(expected:String, actual:String, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
