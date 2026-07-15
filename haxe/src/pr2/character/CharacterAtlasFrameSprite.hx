package pr2.character;

import openfl.display.Shape;
import openfl.display.Sprite;
import pr2.character.CharacterAtlas.CharacterAtlasFrame;
import pr2.runtime.SvgAsset;

class CharacterAtlasFrameSprite extends Sprite {
	public final atlas:CharacterAtlas;
	public final frameName:String;
	public final frame:CharacterAtlasFrame;
	public final vector:Shape;

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

		vector = SvgAsset.create(svgAssetPath(frame));
		addChild(vector);
	}

	public static function load(atlasAssetPath:String, frameName:String):CharacterAtlasFrameSprite {
		return new CharacterAtlasFrameSprite(CharacterAtlas.load(atlasAssetPath), frameName);
	}

	private static function svgAssetPath(frame:CharacterAtlasFrame):String {
		var path = StringTools.replace(frame.pngPath, "art/png/", "assets/svg/");
		return StringTools.replace(path, "@4x.png", ".svg");
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
