package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.Assets;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.runtime.SvgAsset;

/** Explicit vector replacement for the editor's small timeline-backed controls. */
class EditorNativeGraphic extends Sprite {
	public var titleBox(default, null):Null<TextField>;
	public var valueBox(default, null):Null<TextField>;
	private var authoredStates:Null<Array<String>>;
	private var authoredDisplay:Null<DisplayObject>;

	public function new(kind:String) {
		super();
		name = kind;
		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;
		draw(kind);
	}

	public function dispose():Void {
		if (authoredStates != null) {
			removeEventListener(MouseEvent.ROLL_OVER, onAuthoredOver);
			removeEventListener(MouseEvent.ROLL_OUT, onAuthoredOut);
			removeEventListener(MouseEvent.MOUSE_DOWN, onAuthoredDown);
			removeEventListener(MouseEvent.MOUSE_UP, onAuthoredUp);
		}
		if (parent != null) parent.removeChild(this);
	}

	private function draw(kind:String):Void {
		if (kind == "BlockOptionsButton") {
			drawBlockOptionsButton();
			return;
		}
		if (kind == "DeleteButton") {
			drawAuthoredButton([
				"assets/svg/editor/delete_up.svg",
				"assets/svg/editor/delete_over.svg",
				"assets/svg/editor/delete_down.svg"
			], "assets/svg/editor/delete_hit.svg");
			return;
		}
		if (kind == "ResizeButton") {
			drawAuthoredButton([
				"assets/svg/editor/resize_up.svg",
				"assets/svg/editor/resize_over.svg",
				"assets/svg/editor/resize_down.svg"
			], "assets/svg/editor/resize_hit.svg");
			return;
		}
		if (kind == "EditTextButton") {
			drawAuthoredButton([
				"assets/svg/editor/edit_text_up.svg",
				"assets/svg/editor/edit_text_over.svg",
				"assets/svg/editor/edit_text_down.svg"
			], "assets/svg/editor/edit_text_hit.svg");
			return;
		}
		if (kind == "HatPickerArrow") {
			drawAuthoredButton([
				"assets/svg/editor/hat_arrow_up.svg",
				"assets/svg/editor/hat_arrow_over.svg",
				"assets/svg/editor/hat_arrow_down.svg"
			], "assets/svg/editor/hat_arrow_hit.svg");
			return;
		}
		if (kind == "ReportInfoButton") {
			drawAuthoredButton([
				"assets/svg/editor/report_info_up.svg",
				"assets/svg/editor/report_info_over.svg",
				"assets/svg/editor/report_info_down.svg"
			], "assets/svg/editor/report_info_hit.svg");
			return;
		}
		if (kind == "CancelTextButton") {
			drawAuthoredButton([
				"assets/svg/editor/cancel_text_up.svg",
				"assets/svg/editor/cancel_text_over.svg",
				"assets/svg/editor/cancel_text_down.svg"
			], "assets/svg/editor/cancel_text_hit.svg");
			return;
		}
		if (kind == "ValueButtonGraphic") {
			drawValueButton();
			return;
		}
		if (kind == "ItemButtonGraphic") {
			drawItemButton();
			return;
		}
		var staticPath = authoredStaticPath(kind);
		if (staticPath != null) {
			var display = SvgAsset.create(staticPath);
			display.name = "authoredStatic";
			addChild(display);
			return;
		}
		throw 'Unknown editor graphic $kind';
	}

	private function drawValueButton():Void {
		var title = field("titleBox", 0.75, 4, 27.55, 12.15, 10, 0x666666, false);
		title.scaleY = 1.00177001953125;
		title.text = "title";
		titleBox = title;
		var value = field("valueBox", 0.75, 13.75, 27.55, 14.55, 12, 0x024775, false);
		value.scaleY = 1.00177001953125;
		value.text = "val";
		valueBox = value;
	}

	private function drawItemButton():Void {
		var data = Assets.getBitmapData("assets/blocks/item.png");
		#if eval
		// The interpreter cannot decode PNG bytes; production targets use the
		// exact exported ItemBitmap above while layout tests use matching bounds.
		if (data == null) data = new BitmapData(30, 30, true, 0);
		#elseif sys
		if (data == null) {
			var image = lime.graphics.Image.fromBytes(sys.io.File.getBytes("assets/blocks/item.png"));
			if (image != null) data = BitmapData.fromImage(image);
		}
		#end
		if (data == null) throw "Missing authored ItemBitmap";
		var positions = [[3.0, 1.0], [9.0, 8.25], [15.0, 15.0]];
		for (index in 0...positions.length) {
			var bitmap = new Bitmap(data);
			bitmap.name = 'authoredBitmap$index';
			bitmap.smoothing = false;
			bitmap.scaleX = 0.5;
			bitmap.scaleY = 0.5;
			bitmap.x = positions[index][0];
			bitmap.y = positions[index][1];
			addChild(bitmap);
		}
	}

	private function drawBlockOptionsButton():Void {
		drawAuthoredButton([
			"assets/svg/native/editor_block_options_up.svg",
			"assets/svg/native/editor_block_options_over.svg",
			"assets/svg/native/editor_block_options_down.svg"
		], "assets/svg/editor/block_options_hit.svg");
	}

	private function drawAuthoredButton(states:Array<String>, hitPath:String):Void {
		authoredStates = states;
		var hit = SvgAsset.create(hitPath);
		hit.name = "authoredHit";
		hit.alpha = 0;
		addChild(hit);
		showAuthoredState(0);
		addEventListener(MouseEvent.ROLL_OVER, onAuthoredOver, false, 0, true);
		addEventListener(MouseEvent.ROLL_OUT, onAuthoredOut, false, 0, true);
		addEventListener(MouseEvent.MOUSE_DOWN, onAuthoredDown, false, 0, true);
		addEventListener(MouseEvent.MOUSE_UP, onAuthoredUp, false, 0, true);
	}

	private static function authoredStaticPath(kind:String):Null<String> {
		return switch (kind) {
			case "BrushButtonGraphic": "assets/svg/editor/brush_button.svg";
			case "BrushGraphic": "assets/svg/editor/brush_cursor.svg";
			case "EraserButtonGraphic": "assets/svg/editor/eraser_button.svg";
			case "HatsButtonGraphic": "assets/svg/editor/hats_button.svg";
			case "LandscapeGraphic": "assets/svg/editor/landscape.svg";
			case "MusicNoteGraphic": "assets/svg/editor/music_note.svg";
			case "ObjectDeleterButtonGraphic": "assets/svg/editor/object_deleter.svg";
			case "TextToolButtonGraphic": "assets/svg/editor/text_tool_button.svg";
			case "TextToolCursorGraphic": "assets/svg/editor/text_tool_cursor.svg";
			default: null;
		}
	}

	private function onAuthoredOver(_:MouseEvent):Void showAuthoredState(1);
	private function onAuthoredOut(_:MouseEvent):Void showAuthoredState(0);
	private function onAuthoredDown(_:MouseEvent):Void showAuthoredState(2);
	private function onAuthoredUp(_:MouseEvent):Void showAuthoredState(1);

	private function showAuthoredState(index:Int):Void {
		if (authoredDisplay != null && authoredDisplay.parent == this) removeChild(authoredDisplay);
		var states = authoredStates;
		if (states == null) return;
		var display = SvgAsset.create(states[index]);
		display.name = 'authoredState$index';
		authoredDisplay = display;
		addChild(display);
	}

	private function field(name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, color:Int = 0xFFFFFF,
		bold:Bool = true):TextField {
		var text = new TextField();
		if (name != null) text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.mouseEnabled = false;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null,
			TextFormatAlign.CENTER);
		addChild(text);
		return text;
	}
}
