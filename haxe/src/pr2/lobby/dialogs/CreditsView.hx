package pr2.lobby.dialogs;

import haxe.Json;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.Assets;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Data-driven exact composition of the six authored Credits XFL symbols. */
class CreditsView extends NativeView {
	private static inline var ROOT_SYMBOL = "UI/Popups (outside levels)/Credits/CreditsPopup";
	private static inline var SHADOW_BG = "UI/ShadowBG";

	public var closeButton(default, null):GameButton;
	public var panel(default, null):DisplayObject;
	private final symbols:Dynamic;

	public function new() {
		super();
		symbols = Reflect.field(Json.parse(loadCreditsData()), "symbols");
		var root = buildSymbol(ROOT_SYMBOL);
		while (root.numChildren > 0) addChild(root.removeChildAt(0));
	}

	private function buildSymbol(symbolName:String):Sprite {
		var holder = new Sprite();
		var records:Array<Dynamic> = cast Reflect.field(symbols, symbolName);
		if (records == null) throw 'Missing credits symbol data: $symbolName';
		for (record in records) {
			switch (Std.string(Reflect.field(record, "kind"))) {
				case "symbol":
					var childSymbol = Std.string(Reflect.field(record, "symbol"));
					var child:DisplayObject = childSymbol == SHADOW_BG ? NativeAssets.svg(StaticSvg.QuantityPanel) : buildSymbol(childSymbol);
					if (symbolName == ROOT_SYMBOL && childSymbol == SHADOW_BG) panel = child;
					var childName = Reflect.field(record, "name");
					if (childName != null) child.name = Std.string(childName);
					applyMatrix(child, Reflect.field(record, "matrix"));
					holder.addChild(child);
				case "text": holder.addChild(buildText(record));
				case "button":
					var matrix = Reflect.field(record, "matrix");
					var button = ownControl(new GameButton(Std.string(Reflect.field(record, "label"))));
					button.name = Std.string(Reflect.field(record, "name"));
					button.x = number(matrix, "tx", 0);
					button.y = number(matrix, "ty", 0);
					button.setSize(100 * number(matrix, "a", 1), 22 * number(matrix, "d", 1));
					if (button.name == "close_bt") closeButton = button;
					holder.addChild(button);
				default: throw 'Unsupported credits record: ${Reflect.field(record, "kind")}';
			}
		}
		return holder;
	}

	private function buildText(record:Dynamic):TextField {
		var field = new TextField();
		var fieldName = Reflect.field(record, "name");
		if (fieldName != null) field.name = Std.string(fieldName);
		field.width = number(record, "width", 1);
		field.height = number(record, "height", 1);
		field.multiline = Reflect.field(record, "multiline") == true;
		field.wordWrap = false;
		field.selectable = Reflect.field(record, "selectable") == true;
		var runs:Array<Dynamic> = cast Reflect.field(record, "runs");
		var value = "";
		var hasUrl = false;
		for (run in runs) {
			value += normalizeText(Std.string(Reflect.field(run, "text")));
			var attrs = Reflect.field(run, "attrs");
			if (Reflect.field(attrs, "url") != null) hasUrl = true;
		}
		field.mouseEnabled = hasUrl || field.selectable || Reflect.field(record, "dynamic") == true;
		field.text = value;
		var offset = 0;
		for (run in runs) {
			var text = normalizeText(Std.string(Reflect.field(run, "text")));
			field.setTextFormat(runFormat(Reflect.field(run, "attrs")), offset, offset + text.length);
			offset += text.length;
		}
		var matrix = Reflect.field(record, "matrix");
		var left = number(record, "left", 0);
		field.transform.matrix = new Matrix(number(matrix, "a", 1), number(matrix, "b", 0), number(matrix, "c", 0), number(matrix, "d", 1),
			number(matrix, "tx", 0) + number(matrix, "a", 1) * left, number(matrix, "ty", 0) + number(matrix, "b", 0) * left);
		return field;
	}

	private function runFormat(attrs:Dynamic):TextFormat {
		var face = stringValue(attrs, "face", "Verdana");
		var size = Math.round(number(attrs, "size", number(attrs, "bitmapSize", 200) / 20));
		var color = parseColor(stringValue(attrs, "fillColor", "#000000"));
		var format = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, face.indexOf("Bold") >= 0, face.indexOf("Italic") >= 0,
			false, nullableString(attrs, "url"), nullableString(attrs, "target"), alignment(stringValue(attrs, "alignment", "left")));
		format.letterSpacing = number(attrs, "letterSpacing", 0);
		return format;
	}

	private static function applyMatrix(target:DisplayObject, value:Dynamic):Void {
		target.transform.matrix = new Matrix(number(value, "a", 1), number(value, "b", 0), number(value, "c", 0), number(value, "d", 1),
			number(value, "tx", 0), number(value, "ty", 0));
	}

	private static function alignment(value:String):TextFormatAlign return switch (value) {
		case "center": TextFormatAlign.CENTER;
		case "right": TextFormatAlign.RIGHT;
		case "justify": TextFormatAlign.JUSTIFY;
		default: TextFormatAlign.LEFT;
	}

	private static function parseColor(value:String):Int {
		var parsed = Std.parseInt("0x" + StringTools.replace(value, "#", ""));
		return parsed == null ? 0 : parsed;
	}

	private static function number(value:Dynamic, field:String, fallback:Float):Float {
		var found = value == null ? null : Reflect.field(value, field);
		return found == null ? fallback : Std.parseFloat(Std.string(found));
	}

	private static function stringValue(value:Dynamic, field:String, fallback:String):String {
		var found = value == null ? null : Reflect.field(value, field);
		return found == null ? fallback : Std.string(found);
	}

	private static function nullableString(value:Dynamic, field:String):Null<String> {
		var found = value == null ? null : Reflect.field(value, field);
		return found == null || Std.string(found) == "" ? null : Std.string(found);
	}

	private static function normalizeText(value:String):String return StringTools.replace(value, "\r", "\n");

	private static function loadCreditsData():String {
		try {
			var embedded = Assets.getText("assets/ui/credits.json");
			if (embedded != null && embedded != "") return embedded;
		} catch (_:Dynamic) {}
		#if sys
		return sys.io.File.getContent("art/ui/credits.json");
		#else
		throw "Missing embedded credits data";
		#end
	}
}
