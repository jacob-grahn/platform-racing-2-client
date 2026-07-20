package pr2.level;

import com.jiggmin.data.Objects;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import pr2.level.Level.LevelArtObject;
import pr2.level.Level.LevelDrawAction;
import pr2.level.Level.LevelTextObject;
import pr2.level.LevelArtCursor.ArtStrokeState;
import pr2.level.LevelArtRasterizer.ArtRasterBudget;
import pr2.level.LevelArtRasterizer.ArtRasterTiles;
import pr2.runtime.FontResolver;

/** Builds decoded stroke, stamp, and text display objects for server art layers. */
class LevelArtFactory {
	public static function drawLayerStrokes(brushCanvas:Sprite, actions:Array<LevelDrawAction>):Void {
		var color = 0x000000;
		var size = LevelRenderer.DEFAULT_ART_BRUSH_SIZE;
		var mode = "draw";
		var drawing = false;
		brushCanvas.graphics.lineStyle(size, color);

		for (action in actions) {
			var state = drawStrokeAction(brushCanvas, color, size, mode, action);
			color = state.color;
			size = state.size;
			mode = state.mode;
			if (action.kind == "d" && mode != "erase" && action.values.length >= 2) {
				drawing = true;
			}
		}
		if (!drawing) {
			brushCanvas.graphics.clear();
		}
	}

	public static function renderLayerStrokes(rasterCanvas:Sprite, actions:Array<LevelDrawAction>, ?budget:ArtRasterBudget):Void {
		var tiles = new ArtRasterTiles(rasterCanvas, budget);
		tiles.applyAll(actions);
		tiles.attachQueuedTiles(1000000);
	}

	/**
		Rasterizes the accumulated brush strokes onto transparent square tiles and
		attaches them to `rasterCanvas`, mirroring DrawableBackground.rasterizeTile
		(`new BitmapData(rasterTileSize + 1, rasterTileSize + 1, true, 0)`).

		The original tiles the brush canvas so no single bitmap is huge. The port
		needs the same split for a different but related reason: OpenFL's HTML5
		renderer rasterizes each display object's vector graphics into one offscreen
		texture sized to its bounds. Server art can span the whole level (>8192 px),
		exceeding the GPU's MAX_TEXTURE_SIZE; the upload then fails and the layer
		paints as an opaque black quad (the same failure documented for the login
		background's bg_front). Tiling keeps every texture under the limit, and the
		transparent fill (`true, 0`) lets the level show through between strokes.
	**/
	public static function rasterizeBrushInto(rasterCanvas:Sprite, brushCanvas:Sprite):Void {
		var bounds = brushCanvas.getBounds(brushCanvas);
		if (bounds.width <= 0 || bounds.height <= 0) {
			return;
		}
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		var tileY = Math.floor(bounds.y / tile) * tile;
		var endX = bounds.x + bounds.width;
		var endY = bounds.y + bounds.height;
		while (tileY < endY) {
			var tileX = Math.floor(bounds.x / tile) * tile;
			while (tileX < endX) {
				// +1 overlap between neighbouring tiles hides the seam, as in the original.
				var data = new BitmapData(tile + 1, tile + 1, true, 0);
				var matrix = new Matrix();
				matrix.translate(-tileX, -tileY);
				data.draw(brushCanvas, matrix, null, null, null, true);
				if (data.getColorBoundsRect(0xFF000000, 0x00000000, false).width == 0) {
					// No strokes landed on this tile; keep memory proportional to drawn art.
					data.dispose();
				} else {
					var bitmap = new Bitmap(data);
					bitmap.smoothing = true;
					bitmap.x = tileX;
					bitmap.y = tileY;
					rasterCanvas.addChild(bitmap);
				}
				tileX += tile;
			}
			tileY += tile;
		}
	}

	public static function drawStrokeAction(container:Sprite, color:Int, size:Float, mode:String, action:LevelDrawAction):ArtStrokeState {
		switch (action.kind) {
			case "c":
				color = Std.int(action.values[0]);
				container.graphics.lineStyle(size, color);
			case "t":
				size = action.values[0];
				container.graphics.lineStyle(size, color);
			case "m":
				mode = action.text;
			case "d":
				if (mode != "erase" && action.values.length >= 2) {
					var x = action.values[0];
					var y = action.values[1];
					container.graphics.moveTo(x, y);
					container.graphics.lineTo(x - 0.15, y);
					container.graphics.moveTo(x, y);
					var i = 2;
					while (i + 1 < action.values.length) {
						x += action.values[i];
						y += action.values[i + 1];
						container.graphics.lineTo(x, y);
						i += 2;
					}
				}
			default:
		}
		return {color: color, size: size, mode: mode};
	}

	public static function drawLayerObjects(container:Sprite, objects:Array<LevelArtObject>, layerScale:Float):Void {
		for (object in objects) {
			addLayerObject(container, object, layerScale);
		}
	}

	public static function drawLayerTexts(container:Sprite, texts:Array<LevelTextObject>, layerScale:Float):Void {
		for (text in texts) {
			addLayerText(container, text, layerScale);
		}
	}

	public static function addLayerObject(container:Sprite, object:LevelArtObject, layerScale:Float):Void {
		var display = Objects.getFromCode(object.code);
		if (display == null) {
			return;
		}
		// Bitmap stamps are exported at 4x and normalized by Objects.getFromCode.
		// Compose with that intrinsic scale instead of replacing it in gameplay.
		display.scaleX *= object.scaleX * layerScale;
		display.scaleY *= object.scaleY * layerScale;
		display.x = object.x * layerScale;
		display.y = object.y * layerScale;
		container.addChild(display);
	}

	public static function addLayerText(container:Sprite, text:LevelTextObject, layerScale:Float):Void {
		var field = new TextField();
		var format = new TextFormat(FontResolver.resolve("Verdana"), 18, text.color);
		format.leading = 4;
		field.defaultTextFormat = format;
		field.selectable = false;
		field.wordWrap = false;
		field.multiline = true;
		field.autoSize = TextFieldAutoSize.LEFT;
		field.textColor = text.color;
		field.text = parseTextObjectText(text.text);
		field.scaleX = text.scaleX * layerScale;
		field.scaleY = text.scaleY * layerScale;
		field.height = 24;
		field.x = text.x * layerScale;
		field.y = text.y * layerScale;
		field.cacheAsBitmap = true;
		container.addChild(field);
	}

	private static function parseTextObjectText(value:String):String {
		var parsed = StringTools.replace(value, "#96", "`");
		parsed = StringTools.replace(parsed, "#38", "&");
		parsed = StringTools.replace(parsed, "#44", ",");
		parsed = StringTools.replace(parsed, "#59", ";");
		parsed = StringTools.replace(parsed, "#43", "+");
		parsed = StringTools.replace(parsed, "#45", "-");
		return StringTools.replace(parsed, "#35", "#");
	}
}
