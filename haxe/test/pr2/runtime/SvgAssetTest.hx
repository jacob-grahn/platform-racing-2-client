package pr2.runtime;

#if sys
import sys.io.File;
#end

class SvgAssetTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var source = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="20" height="20" viewBox="0 0 20 20"><defs><path id="mark" fill="#ff0000" d="M 0 0 L 10 0 L 10 10 Z"/></defs><g transform="matrix( 1, 0, 0, 1, 3,4) "><use xlink:href="#mark"/></g></svg>';
		var prepared = SvgAsset.prepare(source);
		assertFalse(prepared.indexOf("matrix( ") >= 0, "Animate matrix leading whitespace is normalized");
		assertFalse(prepared.indexOf("<use") >= 0, "SVG use references are expanded");
		var opacitySource = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20"><g opacity="0.5"><path fill="#ffffff" fill-opacity="0.5" d="M 0 0 L 10 0 L 10 10 Z"/></g></svg>';
		var preparedOpacity = SvgAsset.prepare(opacitySource);
		assertFalse(preparedOpacity.indexOf('<g opacity="0.5"') >= 0, "group opacity is removed after being baked into painted children");
		assertTrue(preparedOpacity.indexOf('fill-opacity="0.25"') >= 0, "nested fill alpha includes its inherited group fade");
		var shape = SvgAsset.createFromText(source);
		assertTrue(shape.graphics != null, "expanded SVG renders into OpenFL graphics");
		var timelinePath = "assets/svg/timeline/ui_shadowbg_95643069a8/t00_l000_f0000_r00.svg";
		var timelineShape = SvgAsset.create(timelinePath);
		assertTrue(timelineShape.graphics != null, "declared timeline SVG loads as an individual asset");
		@:privateAccess assertTrue(SvgAsset.parsed.exists(timelinePath), "parsed timeline SVG is cached by asset path");
		#if sys
		var muteBase = File.getContent("art/svg/login/mute_button_base.svg");
		var muteWaves = File.getContent("art/svg/login/mute_button_waves.svg");
		var fadedSlash = SvgAsset.prepare(File.getContent("art/svg/effects/slash_05.svg"));
		var fadedLaser = SvgAsset.prepare(File.getContent("art/svg/effects/laser_15.svg"));
		assertTrue(fadedSlash.indexOf('fill-opacity="0.0390625"') >= 0, "sword swoosh terminal frame bakes its authored alpha fade");
		assertTrue(fadedLaser.indexOf('fill-opacity="0.140625"') >= 0 && fadedLaser.indexOf('fill-opacity="0.01953125"') >= 0,
			"laser impact frame bakes both independently fading authored layers");
		assertFalse(muteBase.indexOf("MovieClips_Symbol_109") >= 0, "mute base excludes the authored wave paths");
		assertTrue(muteWaves.indexOf('<use xlink:href="#MovieClips_Symbol_109_0_Layer0_0_1_STROKES"/>') >= 0,
			"mute waves export retains the authored wave layer");
		assertFalse(muteWaves.indexOf('<use xlink:href="#Graphics_Symbol_107') >= 0, "mute waves export excludes the speaker layer");
		assertFalse(muteWaves.indexOf('stroke-width="0.05"') >= 0, "mute waves use normalized hairline widths");
		#end
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
