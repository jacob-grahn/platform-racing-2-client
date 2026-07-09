package pr2.level;

import openfl.display.BitmapData;
import openfl.utils.Assets;

typedef ArtBackgroundLoadCallback = Null<BitmapData>->Void;

class ArtBackgroundLoader {
	private static final loaded:Map<String, BitmapData> = new Map();
	private static final pending:Map<String, Array<ArtBackgroundLoadCallback>> = new Map();
	private static final failed:Map<String, Bool> = new Map();

	public static function request(assetPath:String, callback:ArtBackgroundLoadCallback):Void {
		if (loaded.exists(assetPath)) {
			callback(loaded.get(assetPath));
			return;
		}
		if (failed.exists(assetPath)) {
			callback(null);
			return;
		}

		var callbacks = pending.get(assetPath);
		if (callbacks != null) {
			callbacks.push(callback);
			return;
		}

		pending.set(assetPath, [callback]);
		var future = Assets.loadBitmapData(assetPath);
		if (future == null) {
			failed.set(assetPath, true);
			flush(assetPath, null);
			return;
		}
		future.onComplete(function(bitmapData:BitmapData):Void {
			if (bitmapData == null) {
				failed.set(assetPath, true);
				flush(assetPath, null);
				return;
			}
			loaded.set(assetPath, bitmapData);
			flush(assetPath, bitmapData);
		}).onError(function(_):Void {
			failed.set(assetPath, true);
			flush(assetPath, null);
		});
	}

	private static function flush(assetPath:String, bitmapData:Null<BitmapData>):Void {
		var callbacks = pending.get(assetPath);
		pending.remove(assetPath);
		if (callbacks == null) {
			return;
		}
		for (callback in callbacks) {
			callback(bitmapData);
		}
	}
}
