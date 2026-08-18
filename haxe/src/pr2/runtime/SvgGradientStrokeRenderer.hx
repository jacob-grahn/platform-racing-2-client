package pr2.runtime;

import format.gfx.GfxGraphics;
import format.svg.FillType;
import format.svg.Path;
import format.svg.RenderContext;
import format.svg.SVGData;
import format.svg.SVGRenderer;
import openfl.display.Graphics;
import openfl.display.LineScaleMode;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

/** Adds the gradient-stroke support missing from format.svg's OpenFL renderer. */
@:access(format.svg.SVGData)
@:access(format.svg.SVGRenderer)
@:access(format.gfx.GfxGraphics)
class SvgGradientStrokeRenderer extends SVGRenderer {
	private var strokeGradients:Map<String, String>;

	public function new(svg:SVGData, content:String) {
		super(svg);
		strokeGradients = collectStrokeGradients(Xml.parse(content).firstElement());
	}

	override public function iteratePath(path:Path):Void {
		var gradientId = strokeGradients.get(path.name);
		if (gradientId == null || !mSvg.mGrads.exists(gradientId) || !Std.isOfType(mGfx, GfxGraphics)) {
			super.iteratePath(path);
			return;
		}
		if (mFilter != null && !mFilter(path.name, mGroupPath)) return;
		if (path.segments.length == 0 || mGfx == null) return;

		var matrix:Matrix = path.matrix.clone();
		matrix.concat(mMatrix);
		var context = new RenderContext(matrix, mScaleRect, mScaleW, mScaleH);
		if (!mGfx.geometryOnly()) {
			path.segments[0].toGfx(mGfx, context);
			switch (path.fill) {
				case FillGrad(gradient):
					gradient.updateMatrix(matrix);
					mGfx.beginGradientFill(gradient);
				case FillSolid(color): mGfx.beginFill(color, path.fill_alpha * path.alpha);
				case FillNone:
			}

			var scale = Math.sqrt(matrix.a * matrix.a + matrix.d * matrix.d) / SVGRenderer.SQRT2;
			var graphics = (cast mGfx:GfxGraphics).graphics;
			graphics.lineStyle(path.stroke_width * scale, 0, 1, false, LineScaleMode.NORMAL, path.stroke_caps, path.joint_style, path.miter_limit);
			var gradient = mSvg.mGrads.get(gradientId);
			gradient.updateMatrix(matrix);
			var alpha = path.stroke_alpha * path.alpha;
			var alphas = [for (value in gradient.alphas) value * alpha];
			graphics.lineGradientStyle(gradient.type, gradient.colors, alphas, gradient.ratios, gradient.matrix, gradient.spread, gradient.interp,
				gradient.focus);
		}

		for (segment in path.segments) segment.toGfx(mGfx, context);
		mGfx.endLineStyle();
		mGfx.endFill();
	}

	private static function collectStrokeGradients(root:Xml):Map<String, String> {
		var result:Map<String, String> = new Map();
		if (root != null) collectGradientChildren(root, result, null);
		return result;
	}

	private static function collectGradientChildren(node:Xml, result:Map<String, String>, inheritedStroke:Null<String>):Void {
		if (node.nodeType != Xml.Element) return;
		var id = node.get("id");
		var stroke = node.get("stroke");
		if (stroke == null && node.exists("style")) stroke = styleValue(node.get("style"), "stroke");
		if (stroke == null) stroke = inheritedStroke;
		if (id != null && stroke != null && StringTools.startsWith(stroke, "url(#") && StringTools.endsWith(stroke, ")")) {
			result.set(id, stroke.substr(5, stroke.length - 6));
		}
		for (child in node.elements()) collectGradientChildren(child, result, stroke);
	}

	private static function styleValue(style:String, name:String):Null<String> {
		for (entry in style.split(";")) {
			var separator = entry.indexOf(":");
			if (separator > 0 && StringTools.trim(entry.substr(0, separator)) == name) return StringTools.trim(entry.substr(separator + 1));
		}
		return null;
	}
}
