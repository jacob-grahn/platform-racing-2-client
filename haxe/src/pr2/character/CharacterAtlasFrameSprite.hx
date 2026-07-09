package pr2.character;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PixelSnapping;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Assets;
import pr2.character.CharacterAtlas.CharacterAtlasFrame;

class CharacterAtlasFrameSprite extends Sprite {
	private static final bitmapDataByFrame:Map<String, BitmapData> = new Map();

	public final atlas:CharacterAtlas;
	public final frameName:String;
	public final frame:CharacterAtlasFrame;
	public final bitmap:Bitmap;

	public var logicalX(get, never):Float;
	public var logicalY(get, never):Float;
	public var logicalWidth(get, never):Float;
	public var logicalHeight(get, never):Float;

	public function new(atlas:CharacterAtlas, frameName:String) {
		super();
		this.atlas = atlas;
		this.frameName = frameName;
		var atlasFrame = atlas.getFrame(frameName);
		if (atlasFrame == null) {
			throw 'Missing character atlas frame: $frameName';
		}
		frame = atlasFrame;

		var scale = frame.scale;
		var bitmapData = bitmapDataForFrame(atlas, frame);
		bitmap = new Bitmap(bitmapData, PixelSnapping.AUTO, true);
		bitmap.x = frame.sourceTrim.x / scale;
		bitmap.y = frame.sourceTrim.y / scale;
		bitmap.scaleX = 1 / scale;
		bitmap.scaleY = 1 / scale;
		addChild(bitmap);
	}

	public static function load(atlasAssetPath:String, frameName:String):CharacterAtlasFrameSprite {
		return new CharacterAtlasFrameSprite(CharacterAtlas.load(atlasAssetPath), frameName);
	}

	private static function bitmapDataForFrame(atlas:CharacterAtlas, frame:CharacterAtlasFrame):BitmapData {
		var key = bitmapDataCacheKey(atlas, frame);
		var cached = bitmapDataByFrame.get(key);
		if (cached != null) {
			return cached;
		}

		var bitmapData = frame.sourceTrim.empty ? new BitmapData(1, 1, true, 0) : cropFrame(atlas, frame);
		bitmapDataByFrame.set(key, bitmapData);
		return bitmapData;
	}

	private static function cropFrame(atlas:CharacterAtlas, frame:CharacterAtlasFrame):BitmapData {
		var source = Assets.getBitmapData(atlas.assetImagePath);
		var cropped = new BitmapData(frame.frame.width, frame.frame.height, true, 0);
		cropped.copyPixels(
			source,
			new Rectangle(frame.frame.x, frame.frame.y, frame.frame.width, frame.frame.height),
			new Point()
		);
		return cropped;
	}

	private static function bitmapDataCacheKey(atlas:CharacterAtlas, frame:CharacterAtlasFrame):String {
		return atlas.assetImagePath + ":" + frame.name + ":" + frame.frame.x + "," + frame.frame.y + "," + frame.frame.width + "," + frame.frame.height;
	}

	private function get_logicalX():Float {
		return frame.sourceTrim.x / frame.scale;
	}

	private function get_logicalY():Float {
		return frame.sourceTrim.y / frame.scale;
	}

	private function get_logicalWidth():Float {
		return frame.sourceTrim.width / frame.scale;
	}

	private function get_logicalHeight():Float {
		return frame.sourceTrim.height / frame.scale;
	}
}
