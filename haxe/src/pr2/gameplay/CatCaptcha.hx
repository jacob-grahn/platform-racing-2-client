package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.Loader;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.net.URLRequest;
import openfl.net.URLVariables;
import pr2.lobby.dialogs.Popup;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.runtime.PR2MovieClip;

typedef CaptchaLoad = (onReady:Void->Void, onError:Void->Void) -> Void;
typedef CaptchaSubmit = (answer:Int, onDone:Void->Void, onError:Void->Void) -> Void;

/** Port of Flash `gameplay.CatCaptcha`: server challenge, two cat images, answer submit. */
class CatCaptcha extends Popup {
	public static var loadFactory:CaptchaLoad = defaultLoad;
	public static var submitFactory:CaptchaSubmit = defaultSubmit;
	public static var imageFactory:Int->CaptchaAnswer = function(id:Int) return new CatImage(id);

	private static inline var IMG_X:Int = -215;
	private static inline var IMG_Y:Int = -91;
	private static inline var IMG_SPACING:Int = 220;
	private static inline var IMG_COUNT:Int = 2;

	private var art:PR2MovieClip;
	private var answers:Array<CaptchaAnswer> = [];

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("CatCaptchaPopupGraphic", {maxNestedDepth: 5});
		addChild(art);
		loadFactory(showCatImages, function():Void startFadeOut());
	}

	private function showCatImages():Void {
		for (i in 0...IMG_COUNT) {
			var answer = imageFactory(i);
			answer.display.x = IMG_X + IMG_SPACING * i;
			answer.display.y = IMG_Y;
			answer.display.addEventListener(MouseEvent.CLICK, clickHandler);
			answers.push(answer);
			art.addChild(answer.display);
		}
	}

	private function clickHandler(event:MouseEvent):Void {
		if (fadeOutStarted) {
			return;
		}
		for (answer in answers) {
			if (event.currentTarget == answer.display) {
				submit(answer.id);
				return;
			}
		}
	}

	private function submit(answer:Int):Void {
		submitFactory(answer, function():Void startFadeOut(), function():Void startFadeOut());
		startFadeOut();
	}

	override public function remove():Void {
		for (answer in answers) {
			answer.display.removeEventListener(MouseEvent.CLICK, clickHandler);
			answer.remove();
		}
		answers.resize(0);
		if (art != null && art.parent != null) {
			art.parent.removeChild(art);
		}
		art = null;
		super.remove();
	}

	private static function defaultLoad(onReady:Void->Void, onError:Void->Void):Void {
		TextLoader.load(ServerConfig.catCaptchaUrl(), function(_:String):Void onReady(), function(_:String):Void onError());
	}

	private static function defaultSubmit(answer:Int, onDone:Void->Void, onError:Void->Void):Void {
		var fields = new Map<String, String>();
		fields.set("answer", Std.string(answer));
		FormPostClient.post(ServerConfig.catCaptchaSubmitUrl(), fields, function(_:String):Void onDone(), function(_:String):Void onError());
	}
}

interface CaptchaAnswer {
	public var id(default, null):Int;
	public var display(default, null):DisplayObject;
	public function remove():Void;
}

class CatImage extends Sprite implements CaptchaAnswer {
	public var id(default, null):Int;
	public var display(default, null):DisplayObject;

	private var bg:Shape;
	private var loader:Loader;

	public function new(id:Int) {
		super();
		this.id = id;
		display = this;
		bg = new Shape();
		drawBackground(0xCCCCCC);
		addChild(bg);
		loader = new Loader();
		addChild(loader);
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImgLoad);
		addEventListener(MouseEvent.MOUSE_OVER, onOver);
		addEventListener(MouseEvent.MOUSE_OUT, onOut);
		getImg();
	}

	private function getImg():Void {
		var vars = new URLVariables();
		Reflect.setField(vars, "img", Std.string(id));
		var request = new URLRequest(ServerConfig.catImageUrl());
		request.data = vars;
		loader.load(request);
	}

	private function onImgLoad(_:Event):Void {
		var scale = Math.min(200 / loader.width, 200 / loader.height);
		if (Math.isFinite(scale) && scale < 1) {
			loader.scaleX = scale;
			loader.scaleY = scale;
		}
		loader.x = Math.round((200 - loader.width) / 2) + 5;
		loader.y = Math.round((200 - loader.height) / 2) + 5;
		loader.mouseEnabled = false;
		loader.mouseChildren = false;
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_OVER, onOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onOut);
		if (loader != null) {
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onImgLoad);
			try loader.close() catch (_:Dynamic) {}
			try loader.unload() catch (_:Dynamic) {}
			loader = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function onOver(_:MouseEvent):Void drawBackground(0xC3E7E2);
	private function onOut(_:MouseEvent):Void drawBackground(0xCCCCCC);

	private function drawBackground(color:Int):Void {
		bg.graphics.clear();
		bg.graphics.beginFill(color);
		bg.graphics.drawRect(0, 0, 210, 209.995727539063);
		bg.graphics.endFill();
	}
}
