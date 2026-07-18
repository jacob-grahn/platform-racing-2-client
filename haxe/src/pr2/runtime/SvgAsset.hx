package pr2.runtime;

import format.SVG;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

/** Loads Animate-exported SVG text and renders it as OpenFL vector graphics. */
class SvgAsset {
	private static final parsed:Map<String, SVG> = new Map();

	public static function create(assetPath:String):Shape {
		var shape = new Shape();
		get(assetPath).render(shape.graphics);
		return shape;
	}

	public static function createFromText(content:String):Shape {
		var shape = new Shape();
		new SVG(prepare(content)).render(shape.graphics);
		return shape;
	}

	/** Applies Flash-style solid color channels to named XFL instance groups before rendering. */
	public static function createTinted(assetPath:String, tints:Map<String, Int>, hidden:Array<String>):Shape {
		var document = Xml.parse(prepare(loadText(assetPath)));
		var root = document.firstElement();
		if (root == null) throw 'Invalid SVG asset $assetPath';
		applyNamedTints(root, tints, hidden, null);
		var shape = new Shape();
		new SVG(document.toString()).render(shape.graphics);
		return shape;
	}

	/** Renders the local contents of one named XFL instance without its attachment matrix. */
	public static function createInstanceContents(assetPath:String, instanceName:String):Shape {
		var document = Xml.parse(prepare(loadText(assetPath)));
		var root = document.firstElement();
		if (root == null) throw 'Invalid SVG asset $assetPath';
		var instance = findNamedInstance(root, instanceName);
		if (instance == null) throw 'SVG asset $assetPath has no instance $instanceName';
		var content = "";
		for (child in instance) content += child.toString();
		var width = root.get("width");
		var height = root.get("height");
		var viewBox = root.get("viewBox");
		var isolated = '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="$viewBox">$content</svg>';
		return createFromText(isolated);
	}

	/** Returns artwork translated so its visible bounds begin at local (0, 0). */
	public static function createNormalized(assetPath:String):Sprite {
		var container = new Sprite();
		var shape = create(assetPath);
		var bounds = shape.getBounds(shape);
		shape.x = -bounds.x;
		shape.y = -bounds.y;
		container.addChild(shape);
		return container;
	}

	/** Returns artwork normalized to its visible top-left and fitted to a box. */
	public static function createFitted(assetPath:String, width:Float, height:Float):Sprite {
		var container = createNormalized(assetPath);
		var shape = container.getChildAt(0);
		var bounds = shape.getBounds(shape);
		if (bounds.width > 0 && bounds.height > 0) {
			shape.scaleX = width / bounds.width;
			shape.scaleY = height / bounds.height;
		}
		return container;
	}

	public static function bounds(assetPath:String):Rectangle {
		var shape = create(assetPath);
		return shape.getBounds(shape);
	}

	private static function get(assetPath:String):SVG {
		var svg = parsed.get(assetPath);
		if (svg == null) {
			svg = new SVG(prepare(loadText(assetPath)));
			parsed.set(assetPath, svg);
		}
		return svg;
	}

	private static function loadText(assetPath:String):String {
		var content:Null<String> = null;
		try {
			content = Assets.getText(assetPath);
		} catch (_:Dynamic) {
			// Direct `<asset>` SVG entries are classified as binary by OpenFL.
			// Fall through to getBytes before the sys-only source-tree fallback.
		}
		if (content == null) {
			try {
				var bytes = Assets.getBytes(assetPath);
				if (bytes != null) content = bytes.toString();
			} catch (_:Dynamic) {
				// Packed timeline entries deliberately have no individual OpenFL asset.
			}
		}
		#if sys
		if (content == null && StringTools.startsWith(assetPath, "assets/svg/")) {
			content = sys.io.File.getContent("art/svg/" + assetPath.substr("assets/svg/".length));
		}
		#end
		if (content == null) {
			throw 'Missing SVG asset $assetPath';
		}
		return content;
	}

	/** openfl/svg does not implement SVG <use>; Animate relies on it heavily. */
	public static function prepare(content:String):String {
		// Animate writes `matrix( 1, ...)`; openfl/svg's permissive separator
		// regex interprets that leading space as an empty first operand.
		var normalized = ~/matrix\(\s+/g.replace(content, "matrix(");
		var document = Xml.parse(normalized);
		var root = document.firstElement();
		if (root == null) {
			return content;
		}
		var definitions:Map<String, Xml> = new Map();
		collectIds(root, definitions);
		expandChildren(root, definitions, false);
		bakeGroupOpacity(root, 1);
		return document.toString();
	}

	private static function bakeGroupOpacity(node:Xml, inherited:Float):Void {
		if (node.nodeType != Xml.Element || localName(node.nodeName) == "defs") return;
		var local = 1.0;
		if (node.exists("opacity")) {
			var parsed = Std.parseFloat(node.get("opacity"));
			if (!Math.isNaN(parsed)) local = parsed;
			node.remove("opacity");
		}
		var combined = inherited * local;
		if (isPaintedElement(localName(node.nodeName))) {
			multiplyOpacity(node, "fill-opacity", combined);
			multiplyOpacity(node, "stroke-opacity", combined);
			combined = 1;
		}
		for (child in node.elements()) bakeGroupOpacity(child, combined);
	}

	private static function multiplyOpacity(node:Xml, attribute:String, inherited:Float):Void {
		if (inherited == 1) return;
		var own = node.exists(attribute) ? Std.parseFloat(node.get(attribute)) : 1.0;
		if (Math.isNaN(own)) own = 1;
		node.set(attribute, Std.string(own * inherited));
	}

	private static function isPaintedElement(name:String):Bool {
		return ["path", "rect", "circle", "ellipse", "line", "polyline", "polygon", "text"].indexOf(name) >= 0;
	}

	private static function collectIds(node:Xml, definitions:Map<String, Xml>):Void {
		if (node.nodeType != Xml.Element) {
			return;
		}
		if (node.exists("id")) {
			definitions.set(node.get("id"), node);
		}
		for (child in node.elements()) {
			collectIds(child, definitions);
		}
	}

	private static function expandChildren(parent:Xml, definitions:Map<String, Xml>, insideDefs:Bool):Void {
		var children = [for (child in parent) child];
		for (child in children) {
			parent.removeChild(child);
		}
		for (child in children) {
			if (child.nodeType != Xml.Element) {
				parent.addChild(child);
				continue;
			}
			var childInsideDefs = insideDefs || localName(child.nodeName) == "defs";
			if (!childInsideDefs && localName(child.nodeName) == "use") {
				var replacement = expandedUse(child, definitions);
				if (replacement != null) {
					expandChildren(replacement, definitions, false);
					parent.addChild(replacement);
				}
				continue;
			}
			expandChildren(child, definitions, childInsideDefs);
			parent.addChild(child);
		}
	}

	private static function expandedUse(use:Xml, definitions:Map<String, Xml>):Null<Xml> {
		var href = use.exists("xlink:href") ? use.get("xlink:href") : use.get("href");
		if (href == null || href.charAt(0) != "#") {
			return null;
		}
		var source = definitions.get(href.substr(1));
		if (source == null) {
			return null;
		}

		var clone = Xml.parse(source.toString()).firstElement();
		var wrapper = Xml.createElement("g");
		for (attribute in use.attributes()) {
			if (attribute != "href" && attribute != "xlink:href" && attribute != "x" && attribute != "y") {
				wrapper.set(attribute, use.get(attribute));
			}
		}
		var x = use.exists("x") ? Std.parseFloat(use.get("x")) : 0.0;
		var y = use.exists("y") ? Std.parseFloat(use.get("y")) : 0.0;
		if (x != 0 || y != 0) {
			var translated = Xml.createElement("g");
			translated.set("transform", 'translate($x,$y)');
			translated.addChild(clone);
			wrapper.addChild(translated);
		} else {
			wrapper.addChild(clone);
		}
		return wrapper;
	}

	private static inline function localName(name:String):String {
		var colon = name.indexOf(":");
		return colon < 0 ? name : name.substr(colon + 1);
	}

	private static function findNamedInstance(node:Xml, instanceName:String):Null<Xml> {
		if (node.nodeType != Xml.Element) return null;
		if (node.get("data-xfl-instance") == instanceName) return node;
		for (child in node.elements()) {
			var found = findNamedInstance(child, instanceName);
			if (found != null) return found;
		}
		return null;
	}

	private static function applyNamedTints(node:Xml, tints:Map<String, Int>, hidden:Array<String>, inherited:Null<Int>):Bool {
		if (node.nodeType != Xml.Element) return true;
		var instance = node.get("data-xfl-instance");
		if (instance != null && hidden.indexOf(instance) >= 0) return false;
		var color = inherited;
		if (instance != null && tints.exists(instance)) color = tints.get(instance);
		if (color != null) {
			var encoded = "#" + StringTools.hex(color, 6);
			for (attribute in ["fill", "stroke", "stop-color", "flood-color"]) {
				var value = node.get(attribute);
				if (value != null && StringTools.startsWith(value, "#")) node.set(attribute, encoded);
			}
		}
		var children = [for (child in node) child];
		for (child in children) if (!applyNamedTints(child, tints, hidden, color)) node.removeChild(child);
		return true;
	}
}
