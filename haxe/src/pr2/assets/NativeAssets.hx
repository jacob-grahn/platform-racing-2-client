package pr2.assets;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.media.Sound;
import openfl.utils.Assets;
import pr2.assets.NativeAssetIds.BitmapAsset;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.SoundAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.runtime.FontResolver;
import pr2.runtime.SvgAsset;

/** Typed entry point for assets used by native PR2 presentation code. */
final class NativeAssets {
	public static function svg(id:StaticSvg):Shape {
		return SvgAsset.create(id);
	}

	public static function bitmap(id:BitmapAsset):Bitmap {
		var data = Assets.getBitmapData(id, false);
		#if eval
		// The interpreter backend cannot decode JPEG bytes. Keep deterministic
		// lifecycle tests runnable; browser/native exports use the manifest path.
		if (data == null && id == BitmapAsset.Mine) data = new BitmapData(30, 30, true, 0);
		#end
		if (data == null) throw 'Missing bitmap asset $id';
		return new Bitmap(data);
	}

	public static function font(id:FontAsset):String {
		return FontResolver.resolve(id);
	}

	public static function sound(id:SoundAsset):Sound {
		var value = Assets.getSound(id, false);
		if (value == null) throw 'Missing sound asset $id';
		return value;
	}
}
