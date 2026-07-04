package pr2.ui;

import com.jcward.workers.JPEGEncoder;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Loader;
import openfl.display.PixelSnapping;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import openfl.net.URLRequest;
import openfl.net.URLRequestHeader;
import openfl.net.URLRequestMethod;
import openfl.utils.ByteArray;
import pr2.net.SuperLoader;

class EmblemLoader extends Sprite {
	public static inline var FINISH_LOADING:String = "FINISH_LOADING";
	public static inline var BEGIN_LOADING:String = "BEGIN_LOADING";

	private static inline var DEFAULT_FILE:String = "default-emblem.jpg";
	private static inline var DEFAULT_COLOR:Int = 0xFFFFFF;

	private var emblemWidth:Int;
	private var emblemHeight:Int;
	private var uploadUrl:String;
	private var imageBaseUrl:String;
	private var fileName:String = DEFAULT_FILE;
	private var loading:Bool = false;
	private var removed:Bool = false;

	private var file:Null<FileReference>;
	private var loader:Null<Loader>;
	private var superLoader:Null<SuperLoader>;
	private var bitmap:Null<Bitmap>;
	private var bitmapData:Null<BitmapData>;
	private var encoder:Null<JPEGEncoder>;

	public function new(width:Int, height:Int, uploadUrl:String, imageBaseUrl:String) {
		super();
		emblemWidth = width;
		emblemHeight = height;
		this.uploadUrl = uploadUrl;
		this.imageBaseUrl = imageBaseUrl;

		file = new FileReference();
		file.addEventListener(Event.SELECT, fileSelected);
		file.addEventListener(Event.COMPLETE, fileComplete);

		loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, drawAndUpload);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, imageLoadError);
		loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, imageLoadError);

		superLoader = new SuperLoader(true, SuperLoader.j);
		superLoader.addEventListener(SuperLoader.d, gotFileName);
		superLoader.addEventListener(SuperLoader.e, fileNameError);

		bitmapData = new BitmapData(emblemWidth, emblemHeight, false, DEFAULT_COLOR);
		bitmap = new Bitmap(bitmapData, PixelSnapping.AUTO, true);
		addChild(bitmap);
		encoder = new JPEGEncoder(90);
	}

	public function openBrowse():Void {
		if (file == null) return;
		file.browse([new FileFilter("Images", "*.jpg;*.jpeg;*.gif;*.png;*.JPG;*.JPEG;*.GIF;*.PNG")]);
	}

	public function getImage(fileName:String):Void {
		this.fileName = fileName == null || fileName == "" ? DEFAULT_FILE : fileName;
		if (loader == null) return;
		try {
			loader.load(new URLRequest(imageBaseUrl + this.fileName));
		} catch (_:Dynamic) {
			makeDefault();
		}
	}

	public function getFileName():String {
		return fileName;
	}

	public function isLoading():Bool {
		return loading;
	}

	public function imageUrl():String {
		return imageBaseUrl + fileName;
	}

	public function uploadEndpoint():String {
		return uploadUrl;
	}

	public function setFileNameForTests(fileName:String, loading:Bool = false):Void {
		this.fileName = fileName == null || fileName == "" ? DEFAULT_FILE : fileName;
		this.loading = loading;
		makeDefault();
		if (!loading) {
			dispatchEvent(new Event(FINISH_LOADING));
		}
	}

	public function drawLocalBitmapForTests(source:BitmapData):Void {
		drawBitmapData(source);
		uploadImage();
	}

	public function drawRemoteBitmapForTests(source:BitmapData, sourceUrl:String):Void {
		drawBitmapData(source);
		if (shouldUpload(sourceUrl)) {
			uploadImage();
		}
	}

	public function pixelForTests(x:Int, y:Int):Int {
		return bitmapData == null ? 0 : bitmapData.getPixel(x, y);
	}

	public function remove():Void {
		removed = true;
		loading = false;
		if (file != null) {
			file.removeEventListener(Event.SELECT, fileSelected);
			file.removeEventListener(Event.COMPLETE, fileComplete);
			file = null;
		}
		if (loader != null) {
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, drawAndUpload);
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, imageLoadError);
			loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, imageLoadError);
			try {
				loader.unload();
			} catch (_:Dynamic) {}
			loader = null;
		}
		if (superLoader != null) {
			superLoader.removeEventListener(SuperLoader.d, gotFileName);
			superLoader.removeEventListener(SuperLoader.e, fileNameError);
			superLoader.remove();
			superLoader = null;
		}
		if (bitmap != null) {
			if (bitmap.parent == this) removeChild(bitmap);
			bitmap.bitmapData = null;
			bitmap = null;
		}
		if (bitmapData != null) {
			bitmapData.dispose();
			bitmapData = null;
		}
		encoder = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function fileSelected(_:Event):Void {
		if (file != null) {
			file.load();
		}
	}

	private function fileComplete(_:Event):Void {
		if (loader != null && file != null && file.data != null) {
			loader.loadBytes(file.data);
		}
	}

	private function drawAndUpload(_:Event):Void {
		if (loader == null) return;
		var loadedBitmap = Std.downcast(loader.content, Bitmap);
		if (loadedBitmap != null && loadedBitmap.bitmapData != null) {
			drawBitmapData(loadedBitmap.bitmapData);
		} else {
			drawDisplay(loader, loader.width, loader.height);
		}
		if (shouldUpload(loader.contentLoaderInfo.url)) {
			uploadImage();
		}
	}

	private function imageLoadError(_:Event):Void {
		if (removed) return;
		makeDefault();
		dispatchEvent(new Event(FINISH_LOADING));
	}

	private function uploadImage():Void {
		if (loading || bitmapData == null || encoder == null || superLoader == null) return;
		dispatchEvent(new Event(BEGIN_LOADING));
		loading = true;
		var request = new URLRequest(uploadUrl);
		request.requestHeaders.push(new URLRequestHeader("Content-type", "application/octet-stream"));
		request.method = URLRequestMethod.POST;
		request.data = encoder.encode(bitmapData);
		superLoader.load(request);
	}

	private function gotFileName(_:Event):Void {
		if (removed || superLoader == null) return;
		loading = false;
		var nextFileName = Reflect.field(superLoader.parsedData, "filename");
		if (nextFileName != null) {
			fileName = Std.string(nextFileName);
		}
		dispatchEvent(new Event(FINISH_LOADING));
	}

	private function fileNameError(_:Event):Void {
		if (removed) return;
		loading = false;
		dispatchEvent(new Event(FINISH_LOADING));
	}

	private function drawBitmapData(source:BitmapData):Void {
		if (source == null) return;
		if (bitmapData == null || source.width <= 0 || source.height <= 0) return;
		var scaleX = source.width > emblemWidth ? emblemWidth / source.width : 1;
		var scaleY = source.height > emblemHeight ? emblemHeight / source.height : 1;
		var scale = scaleX < scaleY ? scaleX : scaleY;
		var drawWidth = Std.int(Math.round(source.width * scale));
		var drawHeight = Std.int(Math.round(source.height * scale));
		var targetX = Std.int(Math.round((emblemWidth - drawWidth) / 2));
		var targetY = Std.int(Math.round((emblemHeight - drawHeight) / 2));
		makeDefault();
		for (y in 0...drawHeight) {
			var sourceY = Std.int(Math.min(source.height - 1, Math.floor(y / scale)));
			for (x in 0...drawWidth) {
				var sourceX = Std.int(Math.min(source.width - 1, Math.floor(x / scale)));
				bitmapData.setPixel(targetX + x, targetY + y, source.getPixel(sourceX, sourceY));
			}
		}
	}

	private function drawDisplay(source:DisplayObject, sourceWidth:Float, sourceHeight:Float):Void {
		if (bitmapData == null || source == null || sourceWidth <= 0 || sourceHeight <= 0) return;
		var scaleX = sourceWidth > emblemWidth ? emblemWidth / sourceWidth : 1;
		var scaleY = sourceHeight > emblemHeight ? emblemHeight / sourceHeight : 1;
		var scale = scaleX < scaleY ? scaleX : scaleY;
		var targetX = Std.int(Math.round((emblemWidth - (sourceWidth * scale)) / 2));
		var targetY = Std.int(Math.round((emblemHeight - (sourceHeight * scale)) / 2));
		var matrix = new Matrix();
		matrix.createBox(scale, scale, 0, targetX, targetY);
		makeDefault();
		bitmapData.draw(source, matrix, null, null, null, true);
	}

	private function makeDefault():Void {
		if (bitmapData != null) {
			bitmapData.fillRect(new Rectangle(0, 0, bitmapData.width, bitmapData.height), DEFAULT_COLOR);
		}
	}

	private function shouldUpload(sourceUrl:String):Bool {
		return fileName != null && fileName != "" && (sourceUrl == null || sourceUrl.indexOf(fileName) == -1);
	}
}
