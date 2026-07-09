package pr2.character;

import openfl.utils.Assets;

typedef CharacterAtlasLoadCallback = Void->Void;

class CharacterPartSetLoader {
	private static final loaded:Map<String, CharacterAtlas> = new Map();
	private static final pending:Map<String, Array<CharacterAtlasLoadCallback>> = new Map();
	private static final failed:Map<String, Bool> = new Map();

	public static function requestPart(kind:String, id:Int, callback:CharacterAtlasLoadCallback):Void {
		requestAtlas(keyFor(kind, id), pathFor(kind, id), callback);
	}

	public static function atlasForPart(kind:String, id:Int):Null<CharacterAtlas> {
		return loaded.get(keyFor(kind, id));
	}

	private static function requestAtlas(key:String, jsonPath:String, callback:CharacterAtlasLoadCallback):Void {
		if (loaded.exists(key) || failed.exists(key)) {
			callback();
			return;
		}

		var callbacks = pending.get(key);
		if (callbacks != null) {
			callbacks.push(callback);
			return;
		}

		pending.set(key, [callback]);
		var textFuture = Assets.loadText(jsonPath);
		if (textFuture == null) {
			failed.set(key, true);
			flush(key);
			return;
		}
		textFuture.onComplete(function(json:String):Void {
			if (json == null) {
				failed.set(key, true);
				flush(key);
				return;
			}
			var atlas = CharacterAtlas.parse(json, jsonPath);
			var bitmapFuture = Assets.loadBitmapData(atlas.assetImagePath);
			if (bitmapFuture == null) {
				failed.set(key, true);
				flush(key);
				return;
			}
			bitmapFuture.onComplete(function(_):Void {
				loaded.set(key, atlas);
				flush(key);
			}).onError(function(_):Void {
				failed.set(key, true);
				flush(key);
			});
		}).onError(function(_):Void {
			failed.set(key, true);
			flush(key);
		});
	}

	private static function flush(key:String):Void {
		var callbacks = pending.get(key);
		pending.remove(key);
		if (callbacks == null) {
			return;
		}
		for (callback in callbacks) {
			callback();
		}
	}

	private static function keyFor(kind:String, id:Int):String {
		return kind == "hat" ? "hats" : 'part-set:$id';
	}

	private static function pathFor(kind:String, id:Int):String {
		if (kind == "hat") {
			return "assets/character/atlases/hats/atlas@4x.json";
		}
		return 'assets/character/atlases/part-sets/${padPartId(id)}/atlas@4x.json';
	}

	private static function padPartId(id:Int):String {
		if (id < 10) {
			return "00" + id;
		}
		if (id < 100) {
			return "0" + id;
		}
		return Std.string(id);
	}
}
