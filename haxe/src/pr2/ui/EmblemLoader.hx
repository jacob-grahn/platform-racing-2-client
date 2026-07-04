package pr2.ui;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;

class EmblemLoader extends Sprite {
	public static inline var FINISH_LOADING:String = "finishLoading";
	public static inline var BEGIN_LOADING:String = "beginLoading";

	private var box:Shape;
	private var emblemWidth:Int;
	private var emblemHeight:Int;
	private var uploadUrl:String;
	private var imageBaseUrl:String;
	private var fileName:String = "default-emblem.jpg";
	private var loading:Bool = false;

	public function new(width:Int, height:Int, uploadUrl:String, imageBaseUrl:String) {
		super();
		emblemWidth = width;
		emblemHeight = height;
		this.uploadUrl = uploadUrl;
		this.imageBaseUrl = imageBaseUrl;
		box = new Shape();
		addChild(box);
		draw();
	}

	public function getImage(fileName:String):Void {
		this.fileName = fileName == null || fileName == "" ? "default-emblem.jpg" : fileName;
		loading = false;
		draw();
	}

	public function openBrowse():Void {
		loading = false;
		dispatchEvent(new Event(FINISH_LOADING));
	}

	public function isLoading():Bool {
		return loading;
	}

	public function getFileName():String {
		return fileName;
	}

	public function setFileNameForTests(fileName:String, loading:Bool = false):Void {
		this.fileName = fileName;
		this.loading = loading;
		draw();
		if (!loading) {
			dispatchEvent(new Event(FINISH_LOADING));
		}
	}

	public function imageUrl():String {
		return imageBaseUrl + fileName;
	}

	public function uploadEndpoint():String {
		return uploadUrl;
	}

	public function remove():Void {
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function draw():Void {
		box.graphics.clear();
		box.graphics.lineStyle(1, 0x777777);
		box.graphics.beginFill(fileName == "default-emblem.jpg" ? 0xEEEEEE : 0xDCEEFF);
		box.graphics.drawRect(0, 0, emblemWidth, emblemHeight);
		box.graphics.endFill();
	}
}
