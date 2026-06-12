package pr2.runtime;

import openfl.display.Graphics;
import openfl.display.Shape;
import pr2.generated.assets.AssetTypes.DisplayElementDef;
import pr2.generated.assets.AssetTypes.EdgeDef;
import pr2.generated.assets.AssetTypes.IndexedStyleDef;
import pr2.generated.assets.AssetTypes.StyleValueDef;

class VectorShapeRenderer {
	public static function render(element:DisplayElementDef):Null<Shape> {
		if (element.edges == null || element.edges.length == 0) {
			return null;
		}

		var shape = new Shape();
		var drew = false;

		if (element.fills != null) {
			for (fill in element.fills) {
				if (fill.index == null || fill.value == null) {
					continue;
				}
				var fillColor = colorForStyle(fill.value);
				shape.graphics.beginFill(fillColor.color, fillColor.alpha);
				if (drawEdges(shape.graphics, element.edges, function(edge) {
					return edge.fillStyle0 == fill.index || edge.fillStyle1 == fill.index;
				})) {
					drew = true;
				}
				shape.graphics.endFill();
			}
		}

		if (element.strokes != null) {
			for (stroke in element.strokes) {
				if (stroke.index == null || stroke.value == null) {
					continue;
				}
				var strokeFill = stroke.value.fill != null ? stroke.value.fill : stroke.value;
				var strokeColor = colorForStyle(strokeFill);
				shape.graphics.lineStyle(stroke.value.weight == null ? 1 : stroke.value.weight, strokeColor.color, strokeColor.alpha);
				if (drawEdges(shape.graphics, element.edges, function(edge) {
					return edge.strokeStyle == stroke.index;
				})) {
					drew = true;
				}
			}
		}

		return drew ? shape : null;
	}

	private static function drawEdges(graphics:Graphics, edges:Array<EdgeDef>, predicate:EdgeDef->Bool):Bool {
		var drew = false;
		for (edge in edges) {
			if (!predicate(edge)) {
				continue;
			}

			var path = edge.edges != null ? edge.edges : edge.cubics;
			if (path == null || path == "") {
				continue;
			}

			new EdgePathParser(path, graphics).draw();
			drew = true;
		}
		return drew;
	}

	private static function colorForStyle(style:StyleValueDef):{color:Int, alpha:Float} {
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

		return {color: 0, alpha: 1};
	}

	private static function parseColor(value:String):Int {
		var hex = StringTools.replace(value, "#", "0x");
		return Std.parseInt(hex);
	}

	private function new() {}
}

private class EdgePathParser {
	private var text:String;
	private var graphics:Graphics;
	private var pos:Int = 0;
	private var currentX:Float = 0;
	private var currentY:Float = 0;

	public function new(text:String, graphics:Graphics) {
		this.text = text;
		this.graphics = graphics;
	}

	public function draw():Void {
		while (pos < text.length) {
			var command = text.charAt(pos++);
			switch (command) {
				case "!":
					var point = readPoint();
					if (point != null) {
						graphics.moveTo(point.x, point.y);
						currentX = point.x;
						currentY = point.y;
					}
				case "|":
					var point = readPoint();
					if (point != null) {
						graphics.lineTo(point.x, point.y);
						currentX = point.x;
						currentY = point.y;
					}
				case "[":
					var control = readPoint();
					var anchor = readPoint();
					if (control != null && anchor != null) {
						graphics.curveTo(control.x, control.y, anchor.x, anchor.y);
						currentX = anchor.x;
						currentY = anchor.y;
					}
				case "Q":
					var control = readPoint();
					skipSeparators();
					if (pos < text.length && text.charAt(pos) == "q") {
						pos++;
					}
					var anchor = readPoint();
					if (control != null && anchor != null) {
						graphics.curveTo(control.x, control.y, anchor.x, anchor.y);
						currentX = anchor.x;
						currentY = anchor.y;
					}
				case "q":
					drawLinePoints();
				case "S":
					readNumber();
				default:
			}
		}
	}

	private function drawLinePoints():Void {
		var points:Array<{x:Float, y:Float}> = [];
		while (true) {
			var checkpoint = pos;
			var point = readPoint();
			if (point == null) {
				pos = checkpoint;
				break;
			}
			points.push(point);
			skipSeparators();
			if (pos >= text.length || isCommand(text.charAt(pos))) {
				break;
			}
		}

		var startIndex = points.length > 1 && samePoint(points[0], currentX, currentY) ? 1 : 0;
		for (i in startIndex...points.length) {
			var point = points[i];
			graphics.lineTo(point.x, point.y);
			currentX = point.x;
			currentY = point.y;
		}
	}

	private function readPoint():Null<{x:Float, y:Float}> {
		var x = readNumber();
		var y = readNumber();
		if (x == null || y == null) {
			return null;
		}
		return {x: x, y: y};
	}

	private function readNumber():Null<Float> {
		skipSeparators();
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

	private function skipSeparators():Void {
		while (pos < text.length) {
			var char = text.charAt(pos);
			if (char == " " || char == "\n" || char == "\r" || char == "\t" || char == "," || char == ";" || char == "(" || char == ")") {
				pos++;
			} else {
				break;
			}
		}
	}

	private function isCommand(char:String):Bool {
		return char == "!" || char == "|" || char == "[" || char == "S" || char == "Q" || char == "q";
	}

	private function samePoint(point:{x:Float, y:Float}, x:Float, y:Float):Bool {
		return Math.abs(point.x - x) < 0.0001 && Math.abs(point.y - y) < 0.0001;
	}
}
