package pr2.runtime;

import openfl.display._internal.DrawCommandType;
import openfl.display._internal.DrawCommandReader;
import openfl.display.LineScaleMode;
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
		var nestedSymbolSource = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20"><g data-xfl-symbol="keep"><path fill="#ff0000" d="M 0 0 L 10 0 L 10 10 Z"/></g><g data-xfl-symbol="remove"><path fill="#00ff00" d="M 10 10 L 20 10 L 20 20 Z"/></g></svg>';
		var nestedDocument = Xml.parse(nestedSymbolSource);
		@:privateAccess SvgAsset.removeSymbol(nestedDocument.firstElement(), "remove");
		assertTrue(nestedDocument.toString().indexOf('data-xfl-symbol="keep"') >= 0, "symbol filtering preserves unrelated composition art");
		assertFalse(nestedDocument.toString().indexOf('data-xfl-symbol="remove"') >= 0, "symbol filtering removes the selected nested symbol");
		var gradientStrokeSource = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20"><defs><linearGradient id="outline"><stop offset="0%" stop-color="#333333"/><stop offset="100%" stop-color="#999999"/></linearGradient></defs><path id="hairline" fill="none" stroke="url(#outline)" stroke-width="0" d="M 1 1 L 19 1 L 19 19 Z"/></svg>';
		var gradientStrokeShape = SvgAsset.createFromText(gradientStrokeSource);
		@:privateAccess var hasGradientStroke = gradientStrokeShape.graphics.__commands.types.indexOf(DrawCommandType.LINE_GRADIENT_STYLE) >= 0;
		assertTrue(hasGradientStroke, "Flash hairlines retain their authored gradient stroke when rendered by OpenFL");
		assertTrue(hasHairlineCommand(gradientStrokeShape), "Flash gradient hairlines retain zero-width semantics on native targets");
		var solidHairlineSource = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20"><path fill="none" stroke="#333333" stroke-width="0" d="M 1 1 L 19 1 L 19 19 Z"/></svg>';
		assertTrue(hasHairlineCommand(SvgAsset.createFromText(solidHairlineSource)),
			"Flash solid-color hairlines retain zero-width semantics on native targets");
		var authoredHairline = SvgAsset.createFromText(solidHairlineSource);
		@:privateAccess var compensatedHairline = SvgAsset.shapeFromPreparedAtHairlineThickness(SvgAsset.prepare(solidHairlineSource), 0.2);
		assertNear(authoredHairline.width, compensatedHairline.width, 0.000001,
			"HTML5 hairline compensation does not enlarge authored layout width");
		assertNear(authoredHairline.height, compensatedHairline.height, 0.000001,
			"HTML5 hairline compensation does not enlarge authored layout height");
		assertNear(0.2, HairlineScale.thicknessForScale(5), 0.000001,
			"HTML5 compensates a five-times stage scale with a one-fifth local stroke");
		@:privateAccess assertEquals("effects", SvgAsset.packGroup("assets/svg/effects/mine_piece_01.svg"),
			"top-level SVG assets select their category pack");
		@:privateAccess assertEquals("character_hat", SvgAsset.packGroup("assets/svg/character/hat/001_classic/primary.svg"),
			"character SVG assets select their slot pack");
		var packedPath = "assets/svg/ui/shadow_bg.svg";
		var packedShape = SvgAsset.create(packedPath);
		assertTrue(packedShape.graphics != null, "production SVG renders through the stable asset-path API");
		@:privateAccess assertTrue(SvgAsset.parsed.exists(packedPath), "parsed production SVG is cached by asset path");
		var cachedCopy = SvgAsset.create(packedPath);
		assertTrue(cachedCopy != packedShape, "cached SVG rendering returns an independent display object");
		@:privateAccess var cachedCommandCount = cachedCopy.graphics.__commands.types.length;
		packedShape.graphics.clear();
		@:privateAccess assertTrue(cachedCommandCount > 0 && cachedCopy.graphics.__commands.types.length == cachedCommandCount,
			"mutating one cached SVG shape does not alter another shape's drawing commands");
		#if sys
		var squarePanel = SvgAsset.create("assets/svg/native/square_panel.svg");
		assertTrue(hasLineGradient(squarePanel),
			"production panel retains its Flash gradient hairline outline");
		assertTrue(hasHairlineCommand(squarePanel), "production panel retains its authored hairline command");
		assertTrue(hasHairlineCommand(SvgAsset.create("assets/svg/native/half_square_panel.svg")),
			"lobby side-panel retains its authored hairline command");
		assertTrue(hasLineGradient(SvgAsset.create("assets/svg/ui/reload_button_up.svg")),
			"production refresh icon button retains its Flash gradient hairline outline");
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

	private static function hasLineGradient(shape:openfl.display.Shape):Bool {
		@:privateAccess return shape.graphics.__commands.types.indexOf(DrawCommandType.LINE_GRADIENT_STYLE) >= 0;
	}

	private static function hasHairlineCommand(shape:openfl.display.Shape):Bool {
		@:privateAccess var reader = new DrawCommandReader(shape.graphics.__commands);
		@:privateAccess var types = shape.graphics.__commands.types;
		for (type in types) {
			switch (type) {
				case DrawCommandType.LINE_STYLE:
					var line = reader.readLineStyle();
					if (line.thickness == 0 && line.scaleMode == LineScaleMode.NONE) return true;
				case DrawCommandType.BEGIN_BITMAP_FILL: reader.readBeginBitmapFill();
				case DrawCommandType.BEGIN_FILL: reader.readBeginFill();
				case DrawCommandType.BEGIN_GRADIENT_FILL: reader.readBeginGradientFill();
				case DrawCommandType.CUBIC_CURVE_TO: reader.readCubicCurveTo();
				case DrawCommandType.CURVE_TO: reader.readCurveTo();
				case DrawCommandType.END_FILL: reader.readEndFill();
				case DrawCommandType.LINE_GRADIENT_STYLE: reader.readLineGradientStyle();
				case DrawCommandType.LINE_TO: reader.readLineTo();
				case DrawCommandType.MOVE_TO: reader.readMoveTo();
				default: throw 'Unhandled SVG draw command $type';
			}
		}
		return false;
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

	private static function assertNear(expected:Float, actual:Float, tolerance:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) throw '$message: expected $expected, got $actual';
	}
}
