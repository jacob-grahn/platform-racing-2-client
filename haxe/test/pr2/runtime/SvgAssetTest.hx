package pr2.runtime;

import pr2.animation.TimelineClip;
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
		var gradientOpacitySource = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20"><defs><linearGradient id="fade"><stop offset="0%" stop-color="#ffffff"/><stop offset="100%" stop-color="#ffffff" stop-opacity="0.5"/></linearGradient></defs><g opacity="0.25"><path fill="url(#fade)" d="M 0 0 L 10 0 L 10 10 Z"/></g></svg>';
		var preparedGradientOpacity = SvgAsset.prepare(gradientOpacitySource);
		assertTrue(preparedGradientOpacity.indexOf('stop-opacity="0.25"') >= 0,
			"group alpha is baked into opaque gradient stops for the OpenFL SVG renderer");
		assertTrue(preparedGradientOpacity.indexOf('stop-opacity="0.125"') >= 0,
			"group alpha multiplies an authored gradient stop fade");
		var shape = SvgAsset.createFromText(source);
		assertTrue(shape.graphics != null, "expanded SVG renders into OpenFL graphics");
		@:privateAccess assertEquals("effects", SvgAsset.packGroup("assets/svg/effects/mine_piece_01.svg"),
			"top-level SVG assets select their category pack");
		@:privateAccess assertEquals("character_hat", SvgAsset.packGroup("assets/svg/character/hat/001_classic/primary.svg"),
			"character SVG assets select their slot pack");
		var packedPath = "assets/svg/ui/shadow_bg.svg";
		var packedShape = SvgAsset.create(packedPath);
		assertTrue(packedShape.graphics != null, "production SVG renders through the stable asset-path API");
		@:privateAccess assertTrue(SvgAsset.parsed.exists(packedPath), "parsed production SVG is cached by asset path");
		#if sys
		var muteBase = File.getContent("art/svg/login/mute_button_base.svg");
		var muteWaves = File.getContent("art/svg/login/mute_button_waves.svg");
		var fadedSlash = new TimelineClip("assets/effects/slash.lottie.json");
		fadedSlash.gotoAndStop(5);
		assertTrue(minVisibleAlpha(fadedSlash) <= 0.04, "sword swoosh terminal frame retains its authored Lottie alpha fade");
		var fadedLaser = new TimelineClip("assets/effects/laser.lottie.json");
		fadedLaser.gotoAndStop(15);
		assertTrue(minVisibleAlpha(fadedLaser) <= 0.02, "laser impact retains independently fading authored Lottie layers");
		fadedSlash.dispose();
		fadedLaser.dispose();
		assertFalse(muteBase.indexOf("MovieClips_Symbol_109") >= 0, "mute base excludes the authored wave paths");
		assertTrue(muteWaves.indexOf('<use xlink:href="#MovieClips_Symbol_109_0_Layer0_0_1_STROKES"/>') >= 0,
			"mute waves export retains the authored wave layer");
		assertFalse(muteWaves.indexOf('<use xlink:href="#Graphics_Symbol_107') >= 0, "mute waves export excludes the speaker layer");
		assertFalse(muteWaves.indexOf('stroke-width="0.05"') >= 0, "mute waves use normalized hairline widths");
		#end
		trace('SvgAssetTest passed $assertions assertions');
	}

	private static function minVisibleAlpha(timeline:TimelineClip):Float {
		var result = 1.0;
		for (index in 0...timeline.numChildren) {
			var child = timeline.getChildAt(index);
			if (child.visible) result = Math.min(result, child.transform.colorTransform.alphaMultiplier);
		}
		return result;
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
