package pr2.runtime;

import openfl.display.Graphics;
import openfl.display.GraphicsPath;
import openfl.display.GraphicsPathWinding;
import openfl.display.GradientType;
import openfl.display.InterpolationMethod;
import openfl.display.LineScaleMode;
import openfl.display.Shape;
import openfl.display.SpreadMethod;
import openfl.geom.Matrix;
import pr2.generated.assets.AssetTypes.DisplayElementDef;
import pr2.generated.assets.AssetTypes.EdgeDef;
import pr2.generated.assets.AssetTypes.StyleValueDef;

private typedef Pt = {x:Float, y:Float};

private enum Seg {
	Line(p:Pt);
	Quad(c:Pt, p:Pt);
}

private typedef Contour = {start:Pt, segs:Array<Seg>};

class VectorShapeRenderer {
	// Points within this many pixels are treated as the same vertex when
	// deciding whether a moveTo continues a contour or starts a new one.
	public static inline var EPS:Float = 1e-4;

	public static function render(element:DisplayElementDef):Null<Shape> {
		if (element.type == "DOMRectangleObject" || element.type == "DOMOvalObject") {
			return renderPrimitive(element);
		}

		if (element.edges == null || element.edges.length == 0) {
			return null;
		}

		var shape = new Shape();
		var drew = false;

		// Fills: the XFL edge format does not store closed rings. Each edge
		// records the fill on its left (fillStyle0) and right (fillStyle1)
		// sides. To fill correctly we gather every edge touching a fill style,
		// reverse the ones where the fill is on side 1 so all edges wind the
		// same way, then stitch them head-to-tail into closed contours before
		// handing them to beginFill. (This is the SWF "shape -> contours" step.)
		if (element.fills != null) {
			for (fill in element.fills) {
				if (fill.index == null || fill.value == null) {
					continue;
				}
				var contours = collectFillContours(element.edges, fill.index);
				var rings = stitch(contours);
				if (rings.length == 0) {
					continue;
				}

				beginStyleFill(shape.graphics, fill.value);
				emitFillContours(shape.graphics, rings);
				shape.graphics.endFill();
				drew = true;
			}
		}

		if (element.strokes != null) {
			for (stroke in element.strokes) {
				if (stroke.index == null || stroke.value == null) {
					continue;
				}
				var strokeFill = stroke.value.fill != null ? stroke.value.fill : stroke.value;
				var strokeColor = colorForStyle(strokeFill);
				applyLineStyle(shape.graphics, stroke.value, strokeColor.color, strokeColor.alpha);
				if (drawStrokes(shape.graphics, element.edges, stroke.index)) {
					drew = true;
				}
			}
		}

		return drew ? shape : null;
	}

	// Render an Animate primitive drawing object (DOMRectangleObject /
	// DOMOvalObject). These carry their geometry as attributes rather than as
	// `edges`, plus a single direct `fill`/`stroke` style. The element matrix is
	// applied by the caller (PR2MovieClip.applyElementProperties), so the
	// geometry is drawn here in the element's local coordinate space, exactly as
	// DOMShape edges are.
	private static function renderPrimitive(element:DisplayElementDef):Null<Shape> {
		var shape = new Shape();
		var graphics = shape.graphics;
		var drew = false;

		if (element.stroke != null) {
			applyStrokeStyle(graphics, element.stroke);
			drew = true;
		}

		var hasFill = element.fill != null;
		if (hasFill) {
			beginStyleFill(graphics, element.fill);
			drew = true;
		}

		drawPrimitiveGeometry(graphics, element);

		if (hasFill) {
			graphics.endFill();
		}

		return drew ? shape : null;
	}

	private static function drawPrimitiveGeometry(graphics:Graphics, element:DisplayElementDef):Void {
		var x = element.x == null ? 0.0 : element.x;
		var y = element.y == null ? 0.0 : element.y;
		var w = element.objectWidth == null ? 0.0 : element.objectWidth;
		var h = element.objectHeight == null ? 0.0 : element.objectHeight;

		if (element.type == "DOMOvalObject") {
			graphics.drawEllipse(x, y, w, h);
			return;
		}

		var tl = element.topLeftRadius == null ? 0.0 : element.topLeftRadius;
		var tr = element.topRightRadius == null ? 0.0 : element.topRightRadius;
		var bl = element.bottomLeftRadius == null ? 0.0 : element.bottomLeftRadius;
		var br = element.bottomRightRadius == null ? 0.0 : element.bottomRightRadius;

		if (tl == 0 && tr == 0 && bl == 0 && br == 0) {
			graphics.drawRect(x, y, w, h);
		} else if (tl == tr && tl == bl && tl == br) {
			// drawRoundRect takes ellipse width/height (diameter), i.e. 2x radius.
			graphics.drawRoundRect(x, y, w, h, tl * 2, tl * 2);
		} else {
			graphics.drawRoundRectComplex(x, y, w, h, tl, tr, bl, br);
		}
	}

	// Apply a primitive's stroke. The XFL stroke is a SolidStroke whose paint is
	// itself a nested fill (solid or gradient); mirror the DOMShape stroke path
	// and resolve it to a single line color/alpha.
	private static function applyStrokeStyle(graphics:Graphics, stroke:StyleValueDef):Void {
		var strokeFill = stroke.fill != null ? stroke.fill : stroke;
		var color = colorForStyle(strokeFill);
		applyLineStyle(graphics, stroke, color.color, color.alpha);
	}

	private static function applyLineStyle(graphics:Graphics, stroke:StyleValueDef, color:Int, alpha:Float):Void {
		var isHairline = stroke.solidStyle == "hairline";
		var weight = isHairline ? 0.0 : (stroke.weight == null ? 1.0 : stroke.weight);
		var pixelHinting = stroke.pixelHinting == true || isHairline;
		var scaleMode = isHairline ? LineScaleMode.NONE : lineScaleMode(stroke.scaleMode);
		graphics.lineStyle(weight, color, alpha, pixelHinting, scaleMode);
	}

	private static function lineScaleMode(value:Dynamic):LineScaleMode {
		return switch (value) {
			case "horizontal": LineScaleMode.HORIZONTAL;
			case "none": LineScaleMode.NONE;
			case "vertical": LineScaleMode.VERTICAL;
			default: LineScaleMode.NORMAL;
		}
	}

	// Gather all contour pieces touching the given fill style, reversing those
	// where the fill sits on side 1 so every piece winds consistently.
	private static function collectFillContours(edges:Array<EdgeDef>, index:Int):Array<Contour> {
		var contours:Array<Contour> = [];
		for (edge in edges) {
			if (edge.edges == null || edge.edges == "") {
				continue;
			}
			if (edge.fillStyle0 == index) {
				for (c in EdgeContourParser.parse(edge.edges)) {
					contours.push(c);
				}
			}
			if (edge.fillStyle1 == index) {
				for (c in EdgeContourParser.parse(edge.edges)) {
					contours.push(reverse(c));
				}
			}
		}
		return contours;
	}

	// Connect contour pieces end-to-start into closed rings. Pieces that are
	// already closed (or that cannot be extended) are emitted as-is; beginFill
	// auto-closes any remaining gap.
	private static function stitch(contours:Array<Contour>):Array<Contour> {
		var rings:Array<Contour> = [];
		if (contours.length == 0) {
			return rings;
		}

		var byStart = new Map<String, Array<Int>>();
		var used = [for (_ in contours) false];
		for (i in 0...contours.length) {
			var key = pointKey(contours[i].start);
			if (!byStart.exists(key)) {
				byStart.set(key, []);
			}
			byStart.get(key).push(i);
		}

		for (i in 0...contours.length) {
			if (used[i]) {
				continue;
			}
			used[i] = true;
			var ring:Contour = {start: contours[i].start, segs: contours[i].segs.copy()};
			var startKey = pointKey(ring.start);
			var endKey = pointKey(endPoint(ring));

			while (endKey != startKey) {
				var next = takeUnused(byStart, endKey, used);
				if (next == -1) {
					break;
				}
				used[next] = true;
				for (s in contours[next].segs) {
					ring.segs.push(s);
				}
				endKey = pointKey(endPoint(contours[next]));
			}

			rings.push(ring);
		}

		return rings;
	}

	private static function takeUnused(byStart:Map<String, Array<Int>>, key:String, used:Array<Bool>):Int {
		var bucket = byStart.get(key);
		if (bucket == null) {
			return -1;
		}
		for (idx in bucket) {
			if (!used[idx]) {
				return idx;
			}
		}
		return -1;
	}

	private static function endPoint(c:Contour):Pt {
		if (c.segs.length == 0) {
			return c.start;
		}
		return switch (c.segs[c.segs.length - 1]) {
			case Line(p): p;
			case Quad(_, p): p;
		};
	}

	// Reverse a contour piece: walk its vertices backwards. Line segments keep
	// their type, quad segments keep their control point but flip endpoints.
	private static function reverse(c:Contour):Contour {
		var pts = [c.start];
		for (s in c.segs) {
			pts.push(switch (s) {
				case Line(p): p;
				case Quad(_, p): p;
			});
		}
		var n = c.segs.length;
		var rev:Contour = {start: pts[n], segs: []};
		var i = n - 1;
		while (i >= 0) {
			var to = pts[i];
			rev.segs.push(switch (c.segs[i]) {
				case Line(_): Line(to);
				case Quad(ctrl, _): Quad(ctrl, to);
			});
			i--;
		}
		return rev;
	}

	// XFL/SWF fills use non-zero winding. OpenFL's incremental Graphics path
	// defaults to even-odd winding, which incorrectly punches holes where stamp
	// contours overlap. Submit the complete fill as one explicit non-zero path;
	// collectFillContours has already oriented outer and inner boundaries by the
	// side of the edge carrying this fill.
	private static function emitFillContours(graphics:Graphics, contours:Array<Contour>):Void {
		var path = new GraphicsPath();
		for (contour in contours) {
			emitContour(path, contour);
		}
		graphics.drawPath(path.commands, path.data, GraphicsPathWinding.NON_ZERO);
	}

	private static function emitContour(path:GraphicsPath, c:Contour):Void {
		path.moveTo(c.start.x, c.start.y);
		for (s in c.segs) {
			switch (s) {
				case Line(p): path.lineTo(p.x, p.y);
				case Quad(ctrl, p): path.curveTo(ctrl.x, ctrl.y, p.x, p.y);
			}
		}
	}

	private static function pointKey(p:Pt):String {
		// Round to whole twips (the source unit) so endpoints that should join
		// match despite float rounding from the pixel conversion.
		return Math.round(p.x * 20) + ":" + Math.round(p.y * 20);
	}

	private static function drawStrokes(graphics:Graphics, edges:Array<EdgeDef>, index:Int):Bool {
		var drew = false;
		for (edge in edges) {
			if (edge.strokeStyle != index) {
				continue;
			}
			if (edge.edges == null || edge.edges == "") {
				continue;
			}
			new EdgePathParser(edge.edges, graphics).draw();
			drew = true;
		}
		return drew;
	}

	// Begin a fill for an XFL fill style: a real gradient fill for
	// Linear/RadialGradient styles, otherwise a flat solid fill.
	private static function beginStyleFill(graphics:Graphics, style:StyleValueDef):Void {
		if (style != null && (style.type == "LinearGradient" || style.type == "RadialGradient")
			&& style.entries != null && style.entries.length > 0) {
			var colors:Array<Int> = [];
			var alphas:Array<Float> = [];
			var ratios:Array<Int> = [];
			for (entry in (style.entries : Array<Dynamic>)) {
				colors.push(entry.color == null ? 0 : parseColor(entry.color));
				alphas.push(entry.alpha == null ? 1.0 : entry.alpha);
				var ratio = entry.ratio == null ? 0.0 : (entry.ratio : Float);
				var scaled = Math.round(ratio * 255);
				ratios.push(scaled < 0 ? 0 : (scaled > 255 ? 255 : scaled));
			}
			var type = style.type == "RadialGradient" ? GradientType.RADIAL : GradientType.LINEAR;
			var focal = style.focalPointRatio == null ? 0.0 : (style.focalPointRatio : Float);
			graphics.beginGradientFill(type, colors, alphas, ratios, gradientMatrix(style.matrix),
				SpreadMethod.PAD, InterpolationMethod.RGB, focal);
			return;
		}

		var solid = colorForStyle(style);
		graphics.beginFill(solid.color, solid.alpha);
	}

	// Convert an XFL gradient matrix to the OpenFL gradient matrix. XFL gradients
	// are defined over a local box of +/-16384 twips while OpenFL's gradient box
	// is +/-819.2 px (a 20x = twips-per-pixel ratio). The XFL matrix maps the
	// twip-local box to pixels with tx/ty already in pixels, so scaling a/b/c/d
	// by 20 (and keeping tx/ty) maps OpenFL's px-local box to the same pixels.
	private static function gradientMatrix(m:Dynamic):Matrix {
		if (m == null) {
			return new Matrix();
		}
		var a:Float = m.a == null ? 1.0 : m.a;
		var b:Float = m.b == null ? 0.0 : m.b;
		var c:Float = m.c == null ? 0.0 : m.c;
		var d:Float = m.d == null ? 1.0 : m.d;
		var tx:Float = m.tx == null ? 0.0 : m.tx;
		var ty:Float = m.ty == null ? 0.0 : m.ty;
		var s = 20.0;
		return new Matrix(a * s, b * s, c * s, d * s, tx, ty);
	}

	@:allow(pr2.runtime.PR2MovieClipRuntimeTest)
	private static function colorForStyle(style:StyleValueDef):{color:Int, alpha:Float} {
		if (style == null) {
			return {color: 0, alpha: 1};
		}
		if (style.color != null) {
			return {color: parseColor(style.color), alpha: style.alpha == null ? 1 : style.alpha};
		}

		if (style.entries != null && style.entries.length > 0) {
			var entry = style.entries[0];
			return {color: entry.color == null ? 0 : parseColor(entry.color), alpha: entry.alpha == null ? 1 : entry.alpha};
		}

		if (style.fill != null) {
			return colorForStyle(style.fill);
		}

		return {color: 0, alpha: style.alpha == null ? 1 : style.alpha};
	}

	private static function parseColor(value:String):Int {
		var hex = StringTools.replace(value, "#", "0x");
		return Std.parseInt(hex);
	}

	private function new() {}
}

// Parses the XFL `edges` string into closed-ish contour pieces. A new piece is
// started whenever a moveTo (`!`) jumps to a point other than the current
// position; consecutive segments that chain through shared endpoints stay in
// one piece.
private class EdgeContourParser {
	public static function parse(text:String):Array<Contour> {
		var r = new EdgeReader(text);
		var contours:Array<Contour> = [];
		var cur:Contour = null;
		var x = 0.0;
		var y = 0.0;

		while (!r.eof()) {
			var command = r.next();
			switch (command) {
				case "!":
					var p = r.readPoint();
					if (p == null) {
						continue;
					}
					if (cur == null || Math.abs(p.x - x) > VectorShapeRenderer.EPS || Math.abs(p.y - y) > VectorShapeRenderer.EPS) {
						if (cur != null && cur.segs.length > 0) {
							contours.push(cur);
						}
						cur = {start: p, segs: []};
					}
					x = p.x;
					y = p.y;
				case "|", "/":
					var p = r.readPoint();
					if (p == null || cur == null) {
						continue;
					}
					cur.segs.push(Line(p));
					x = p.x;
					y = p.y;
				case "[", "]":
					var control = r.readPoint();
					var anchor = r.readPoint();
					if (control == null || anchor == null || cur == null) {
						continue;
					}
					cur.segs.push(Quad(control, anchor));
					x = anchor.x;
					y = anchor.y;
				default:
					// Cubic tokens are handled by EdgePathParser, not here.
			}
		}

		if (cur != null && cur.segs.length > 0) {
			contours.push(cur);
		}
		return contours;
	}

	private function new() {}
}

// Draws an XFL styled `edges` string straight to a Graphics, used for strokes
// (fills go through the stitching path instead). Styled edges only ever use the
// quadratic commands `! | / [ ] S`; the `/` and `]` forms are the same geometry
// as `|`/`[` (they only differ by a "cubic segment" hint bit), so they are drawn
// identically. The redundant cubic-Bézier `cubics` representation is dropped at
// extraction (it carries no style and Flash renders only these quadratics), so
// this parser never needs the cubic tokens.
private class EdgePathParser {
	private var reader:EdgeReader;
	private var graphics:Graphics;

	public function new(text:String, graphics:Graphics) {
		this.reader = new EdgeReader(text);
		this.graphics = graphics;
	}

	public function draw():Void {
		while (!reader.eof()) {
			var command = reader.next();
			switch (command) {
				case "!":
					var point = reader.readPoint();
					if (point != null) {
						graphics.moveTo(point.x, point.y);
					}
				case "|", "/":
					var point = reader.readPoint();
					if (point != null) {
						graphics.lineTo(point.x, point.y);
					}
				case "[", "]":
					var control = reader.readPoint();
					var anchor = reader.readPoint();
					if (control != null && anchor != null) {
						graphics.curveTo(control.x, control.y, anchor.x, anchor.y);
					}
				case "S":
					// Style-selector hint carrying a single number and no
					// geometry; consume the number and continue.
					reader.readNumber();
				default:
			}
		}
	}
}

// Shared low-level reader for the XFL edge string number/point formats.
private class EdgeReader {
	private static inline var TWIPS_PER_PIXEL:Float = 20;

	public var text:String;
	public var pos:Int = 0;

	public function new(text:String) {
		this.text = text;
	}

	public inline function eof():Bool {
		return pos >= text.length;
	}

	public inline function next():String {
		return text.charAt(pos++);
	}

	public function readPoint():Null<Pt> {
		var x = readNumber();
		var y = readNumber();
		if (x == null || y == null) {
			return null;
		}
		return {x: x / TWIPS_PER_PIXEL, y: y / TWIPS_PER_PIXEL};
	}

	public function readNumber():Null<Float> {
		skipSeparators();
		if (pos < text.length && text.charAt(pos) == "#") {
			return readHexNumber();
		}
		var start = pos;
		if (pos < text.length && (text.charAt(pos) == "-" || text.charAt(pos) == "+")) {
			pos++;
		}
		while (pos < text.length) {
			var char = text.charAt(pos);
			if ((char >= "0" && char <= "9") || char == ".") {
				pos++;
			} else {
				break;
			}
		}
		if (start == pos || (start + 1 == pos && (text.charAt(start) == "-" || text.charAt(start) == "+"))) {
			return null;
		}
		return Std.parseFloat(text.substr(start, pos - start));
	}

	// XFL edge strings encode high-precision coordinates as signed hex
	// fixed-point in twips, e.g. "#13.FB": the part before the dot is the
	// integer twips in hex and each hex digit after the dot is a sixteenth.
	// The plain decimal coordinates and these hex coordinates share the same
	// twip unit, so readPoint() divides both by TWIPS_PER_PIXEL.
	private function readHexNumber():Null<Float> {
		pos++; // consume '#'
		var sign = 1.0;
		if (pos < text.length && (text.charAt(pos) == "-" || text.charAt(pos) == "+")) {
			if (text.charAt(pos) == "-") {
				sign = -1.0;
			}
			pos++;
		}

		var intStart = pos;
		while (pos < text.length && isHexDigit(text.charAt(pos))) {
			pos++;
		}
		if (pos == intStart) {
			return null;
		}
		var value:Float = parseHex(text.substr(intStart, pos - intStart));

		if (pos < text.length && text.charAt(pos) == ".") {
			pos++;
			var fracStart = pos;
			while (pos < text.length && isHexDigit(text.charAt(pos))) {
				pos++;
			}
			var fracLen = pos - fracStart;
			if (fracLen > 0) {
				value += parseHex(text.substr(fracStart, fracLen)) / Math.pow(16, fracLen);
			}
		}

		return sign * value;
	}

	private function isHexDigit(char:String):Bool {
		return (char >= "0" && char <= "9") || (char >= "a" && char <= "f") || (char >= "A" && char <= "F");
	}

	private function parseHex(hex:String):Int {
		var result = Std.parseInt("0x" + hex);
		return result == null ? 0 : result;
	}

	public function skipSeparators():Void {
		while (pos < text.length) {
			var char = text.charAt(pos);
			if (char == " " || char == "\n" || char == "\r" || char == "\t") {
				pos++;
			} else {
				break;
			}
		}
	}
}
