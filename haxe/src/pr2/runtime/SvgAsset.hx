package pr2.runtime;

import format.SVG;
import haxe.Json;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

/** Loads Animate-exported SVG text and renders it as OpenFL vector graphics. */
class SvgAsset {
	private static inline var TIMELINE_PREFIX = "assets/svg/timeline/";
	private static inline var TIMELINE_PACK_PREFIX = "assets/svg-packs/timeline/";
	private static final parsed:Map<String, SVG> = new Map();
	private static final timelinePackEntries:Map<String, Dynamic> = new Map();

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

	/** Returns artwork normalized to its visible top-left and fitted to a box. */
	public static function createFitted(assetPath:String, width:Float, height:Float):Sprite {
		var container = new Sprite();
		var shape = create(assetPath);
		var bounds = shape.getBounds(shape);
		shape.x = -bounds.x;
		shape.y = -bounds.y;
		if (bounds.width > 0 && bounds.height > 0) {
			shape.scaleX = width / bounds.width;
			shape.scaleY = height / bounds.height;
		}
		container.addChild(shape);
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
			// Packed timeline entries deliberately have no individual OpenFL asset.
		}
		#if sys
		if (content == null && StringTools.startsWith(assetPath, "assets/svg/")) {
			content = sys.io.File.getContent("art/svg/" + assetPath.substr("assets/svg/".length));
		}
		#end
		if (content == null && StringTools.startsWith(assetPath, TIMELINE_PREFIX)) {
			content = loadTimelinePackEntry(assetPath);
		}
		if (content == null) {
			throw 'Missing SVG asset $assetPath';
		}
		return content;
	}

	private static function loadTimelinePackEntry(assetPath:String):Null<String> {
		var group = timelinePackGroup(assetPath);
		var entries = timelinePackEntries.get(group);
		if (entries == null) {
			var packPath = TIMELINE_PACK_PREFIX + group + ".json";
			var packText = Assets.getText(packPath);
			if (packText == null) {
				throw 'Missing timeline SVG pack $packPath';
			}
			var pack:Dynamic = Json.parse(packText);
			entries = Reflect.field(pack, "entries");
			if (entries == null) {
				throw 'Invalid timeline SVG pack $packPath';
			}
			timelinePackEntries.set(group, entries);
		}
		var content:Dynamic = Reflect.field(entries, assetPath);
		return content == null ? null : Std.string(content);
	}

	private static function timelinePackGroup(assetPath:String):String {
		var relative = assetPath.substr(TIMELINE_PREFIX.length);
		var slash = relative.indexOf("/");
		var slug = slash < 0 ? relative : relative.substr(0, slash);
		for (group in ["buttons", "components", "graphics", "images", "movieclips", "parts", "ui"]) {
			if (StringTools.startsWith(slug, group + "_")) {
				return group;
			}
		}
		return "misc";
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
		return document.toString();
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
}
