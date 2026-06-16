package pr2.character;

import openfl.utils.AssetType;
import openfl.utils.Assets;

class CharacterAtlasCollection {
	private static final PAGE_SUFFIXES = ["-p01", "-p02", "-p03", "-p04"];

	public final kind:String;
	public final channel:String;
	private final atlases:Array<CharacterAtlas>;

	public function new(kind:String, channel:String, atlases:Array<CharacterAtlas>) {
		this.kind = kind;
		this.channel = channel;
		this.atlases = atlases;
	}

	public static function load(kind:String, channel:String):CharacterAtlasCollection {
		var atlases:Array<CharacterAtlas> = [];
		for (suffix in PAGE_SUFFIXES) {
			var pagedPath = atlasPath(kind, channel, suffix);
			if (Assets.exists(pagedPath, AssetType.TEXT)) {
				atlases.push(CharacterAtlas.load(pagedPath));
			}
		}

		if (atlases.length == 0) {
			var singlePath = atlasPath(kind, channel, "");
			if (Assets.exists(singlePath, AssetType.TEXT)) {
				atlases.push(CharacterAtlas.load(singlePath));
			}
		}

		return new CharacterAtlasCollection(kind, channel, atlases);
	}

	public function getFrameNameById(id:Int):Null<String> {
		for (atlas in atlases) {
			var name = atlas.getFrameNameById(id);
			if (name != null) {
				return name;
			}
		}
		return null;
	}

	public function getAtlasForFrame(frameName:String):Null<CharacterAtlas> {
		for (atlas in atlases) {
			if (atlas.getFrame(frameName) != null) {
				return atlas;
			}
		}
		return null;
	}

	public function hasFrameId(id:Int):Bool {
		return getFrameNameById(id) != null;
	}

	private static function atlasPath(kind:String, channel:String, suffix:String):String {
		return 'assets/character/atlases/$kind/$channel@4x$suffix.json';
	}
}
