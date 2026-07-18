package pr2.runtime;

import format.SVG;
import format.svg.FillType;
import format.svg.Group;
import format.svg.Group.DisplayElement;
import format.svg.Text;
import haxe.Json;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.utils.Assets;

/** Loads Animate-exported SVG text and renders it as OpenFL vector graphics. */
class SvgAsset {
	private static inline var SVG_PREFIX = "assets/svg/";
	private static inline var SVG_PACK_PREFIX = "assets/svg-packs/";
	private static final parsed:Map<String, SVG> = new Map();
	private static final packEntries:Map<String, Dynamic> = new Map();

	public static function create(assetPath:String):Shape {
		var shape = new Shape();
		get(assetPath).render(shape.graphics);
		return shape;
	}

	/**
		Renders an SVG plus its static text elements. The `format.svg` Graphics
		backend deliberately no-ops `renderText`, so source-derived presentation
		frames containing authored text otherwise appear blank. TextFields retain
		the SVG parser's composed matrices and use the embedded PR2 font faces.
	**/
	public static function createWithText(assetPath:String):Sprite {
		var content = prepare(loadText(assetPath));
		var svg = new SVG(content);
		var container = new Sprite();
		var shape = new Shape();
		svg.render(shape.graphics);
		container.addChild(shape);

		var descriptors:Array<Text> = [];
		collectTextDescriptors(svg.data, descriptors);
		var values:Array<String> = [];
		collectTextValues(Xml.parse(content).firstElement(), values);
		for (i in 0...descriptors.length) {
			if (i >= values.length || values[i] == "") continue;
			var descriptor = descriptors[i];
			var color = switch (descriptor.fill) {
				case FillSolid(value): value;
				default: 0x000000;
			};
			var field = new TextField();
			field.autoSize = TextFieldAutoSize.LEFT;
			field.embedFonts = true;
			field.mouseEnabled = false;
			field.selectable = false;
			field.defaultTextFormat = new TextFormat(FontResolver.resolve(descriptor.font_family), Math.round(descriptor.font_size), color);
			field.text = values[i];
			// TextField includes a two-pixel gutter; remove it and align its top to
			// the SVG baseline before applying the fully composed SVG matrix.
			field.x = descriptor.x - 2;
			field.y = descriptor.y - descriptor.font_size - 2;
			field.alpha = descriptor.fill_alpha;
			var textContainer = new Sprite();
			textContainer.transform.matrix = descriptor.matrix;
			textContainer.addChild(field);
			container.addChild(textContainer);
		}
		return container;
	}

	private static function collectTextDescriptors(group:Group, output:Array<Text>):Void {
		for (child in group.children) {
			switch (child) {
				case DisplayText(text): output.push(text);
				case DisplayGroup(childGroup): collectTextDescriptors(childGroup, output);
				case DisplayPath(_):
			}
		}
	}

	private static function collectTextValues(node:Xml, output:Array<String>):Void {
		if (node == null) return;
		if (node.nodeType == Xml.Element && localName(node.nodeName) == "text") {
			output.push(xmlText(node));
			return;
		}
		if (node.nodeType != Xml.Element && node.nodeType != Xml.Document) return;
		for (child in node) collectTextValues(child, output);
	}

	private static function xmlText(node:Xml):String {
		var value = "";
		for (child in node) {
			switch (child.nodeType) {
				case Xml.PCData, Xml.CData: value += child.nodeValue;
				case Xml.Element: value += xmlText(child);
				default:
			}
		}
		return value;
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
		#if sys
		if (StringTools.startsWith(assetPath, SVG_PREFIX)) {
			content = sys.io.File.getContent("art/svg/" + assetPath.substr(SVG_PREFIX.length));
		}
		#end
		if (content == null && StringTools.startsWith(assetPath, SVG_PREFIX)) {
			content = loadPackEntry(assetPath);
		}
		// Non-SVG text assets retain the ordinary OpenFL lookup path.
		try {
			if (content == null) content = Assets.getText(assetPath);
		} catch (_:Dynamic) {
			// Direct `<asset>` SVG entries are classified as binary by OpenFL.
			// Fall through to getBytes for any remaining legacy asset.
		}
		if (content == null) {
			try {
				var bytes = Assets.getBytes(assetPath);
				if (bytes != null) content = bytes.toString();
			} catch (_:Dynamic) {
				// Packed SVG entries deliberately have no individual OpenFL asset.
			}
		}
		if (content == null) {
			throw 'Missing SVG asset $assetPath';
		}
		return content;
	}

	private static function loadPackEntry(assetPath:String):Null<String> {
		var group = packGroup(assetPath);
		var entries = packEntries.get(group);
		if (entries == null) {
			var packPath = SVG_PACK_PREFIX + group + ".json";
			var packText = Assets.getText(packPath);
			if (packText == null) throw 'Missing SVG pack $packPath';
			var pack:Dynamic = Json.parse(packText);
			entries = Reflect.field(pack, "entries");
			if (entries == null) throw 'Invalid SVG pack $packPath';
			packEntries.set(group, entries);
		}
		var content:Dynamic = Reflect.field(entries, assetPath);
		return content == null ? null : Std.string(content);
	}

	private static function packGroup(assetPath:String):String {
		var relative = assetPath.substr(SVG_PREFIX.length);
		var parts = relative.split("/");
		return parts[0] == "character" ? "character_" + parts[1] : parts[0];
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
		var expandedDefinitions:Map<String, Xml> = new Map();
		collectIds(root, expandedDefinitions);
		bakeGroupOpacity(root, 1, expandedDefinitions, new Map());
		return document.toString();
	}

	private static function bakeGroupOpacity(node:Xml, inherited:Float, definitions:Map<String, Xml>, gradientFactors:Map<String, Float>):Void {
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
			multiplyGradientOpacity(node, combined, definitions, gradientFactors);
			multiplyOpacity(node, "stroke-opacity", combined);
			combined = 1;
		}
		for (child in node.elements()) bakeGroupOpacity(child, combined, definitions, gradientFactors);
	}

	/** `format.svg` applies path alpha to solid fills but not gradient fills. */
	private static function multiplyGradientOpacity(node:Xml, inherited:Float, definitions:Map<String, Xml>, gradientFactors:Map<String, Float>):Void {
		if (inherited == 1) return;
		var fill = node.get("fill");
		if (fill == null || !StringTools.startsWith(fill, "url(#") || !StringTools.endsWith(fill, ")")) return;
		var id = fill.substr(5, fill.length - 6);
		var gradient = definitions.get(id);
		if (gradient == null) return;
		var previous = gradientFactors.get(id);
		if (previous != null && previous == inherited) return;
		var factor = previous == null || previous == 0 ? inherited : inherited / previous;
		for (stop in gradient.elements()) multiplyOpacity(stop, "stop-opacity", factor);
		gradientFactors.set(id, inherited);
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
