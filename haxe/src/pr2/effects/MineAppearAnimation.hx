package pr2.effects;

import openfl.display.Bitmap;
import openfl.geom.ColorTransform;
import pr2.animation.AnimationClip;
import pr2.assets.NativeAssetIds.BitmapAsset;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;

/** Native rendering of the 33 authored MineAppearAnimation frames. */
class MineAppearAnimation extends NativeView {
	public final bitmap:Bitmap;
	public final playback:AnimationClip;

	private static final SCALE_X:Array<Float> = [
		4.29489135742188, 3.99566650390625, 3.7156982421875, 3.45506286621094, 3.21376037597656, 2.99172973632813, 2.78903198242188,
		2.60560607910156, 2.44149780273438, 2.29666137695312, 2.17123413085938, 2.06500244140625, 1.97816467285156, 1.91059875488281,
		1.8623046875, 1.83334350585938, 1.82369995117188, 1.772216796875, 1.72073364257813, 1.66925048828125, 1.6177978515625,
		1.56632995605469, 1.51481628417969, 1.46333312988281, 1.41184997558594, 1.36036682128906, 1.30889892578125, 1.25741577148438,
		1.2059326171875, 1.15444946289062, 1.10296630859375, 1.05148315429688, 1.0
	];
	private static final SCALE_Y:Array<Float> = [
		4.30657958984375, 4.00640869140625, 3.72541809082031, 3.4638671875, 3.22172546386719, 2.99888610839844, 2.79544067382812,
		2.61137390136719, 2.44670104980469, 2.30140686035156, 2.17550659179688, 2.06890869140625, 1.98171997070313, 1.91389465332031,
		1.86546325683594, 1.83642578125, 1.82669067382813, 1.77503967285156, 1.72335815429688, 1.67169189453125, 1.62004089355469,
		1.56832885742188, 1.51669311523438, 1.46501159667969, 1.41336059570312, 1.36167907714844, 1.31001281738281, 1.25836181640625,
		1.20668029785156, 1.15499877929688, 1.10333251953125, 1.05168151855469, 1.0
	];
	private static final POS_X:Array<Float> = [
		-62.6, -58.3, -54.2, -50.4, -46.9, -43.65, -40.7, -38.05, -35.65, -33.5, -31.75, -30.15, -28.9, -27.9, -27.2, -26.75,
		-26.6, -25.8, -25.05, -24.3, -23.55, -22.8, -22.05, -21.3, -20.55, -19.8, -19.05, -18.3, -17.55, -16.8, -16.05, -15.3, -14.55
	];
	private static final POS_Y:Array<Float> = [
		-64.6, -60.1, -55.9, -51.95, -48.4, -45, -41.95, -39.15, -36.7, -34.5, -32.65, -31.05, -29.7, -28.7, -28, -27.55,
		-27.4, -26.6, -25.85, -25, -24.3, -23.45, -22.75, -21.9, -21.2, -20.35, -19.65, -18.85, -18.1, -17.3, -16.55, -15.75, -15
	];
	private static final TINT_MULTIPLIER:Array<Float> = [
		1, .87890625, .76953125, .66015625, .55859375, .46875, .390625, .3203125, .25, .19140625, .140625, .1015625, .05859375,
		.0390625, .01953125, 0, 0, .05859375, .12890625, .19140625, .25, .30859375, .37890625, .44140625, .5, .55859375,
		.62890625, .69140625, .75, .80859375, .87890625, .94140625, 1
	];
	private static final TINT_OFFSET:Array<Float> = [
		0, 31, 60, 87, 112, 134, 155, 174, 191, 206, 219, 230, 239, 246, 251, 254, 255, 239, 223, 207, 191, 175, 159, 143,
		128, 112, 96, 80, 64, 48, 32, 16, 0
	];
	private static final ALPHA:Array<Float> = [
		0, .12109375, .23046875, .33984375, .44140625, .53125, .609375, .6796875, .75, .80859375, .859375, .8984375,
		.94140625, .9609375, .98046875, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	];

	public function new(?onComplete:Void->Void) {
		super();
		bitmap = NativeAssets.bitmap(BitmapAsset.Mine);
		addChild(bitmap);
		playback = ownAnimation(AnimationClip.frames(33, renderFrame));
		playback.onComplete = onComplete;
		playback.play();
	}

	private function renderFrame(frame:Int):Void {
		var index = Std.int(Math.min(32, frame));
		bitmap.x = POS_X[index];
		bitmap.y = POS_Y[index];
		bitmap.scaleX = SCALE_X[index];
		bitmap.scaleY = SCALE_Y[index];
		var multiplier = TINT_MULTIPLIER[index];
		var offset = TINT_OFFSET[index];
		bitmap.transform.colorTransform = new ColorTransform(multiplier, multiplier, multiplier, ALPHA[index], offset, offset, offset);
	}
}
