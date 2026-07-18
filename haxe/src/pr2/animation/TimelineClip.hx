package pr2.animation;

import haxe.Json;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.GlowFilter;
import openfl.geom.ColorTransform;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;
import pr2.runtime.SvgAsset;
import pr2.runtime.FontResolver;

private typedef TimelineLayer = {
	var data:Dynamic;
	var metadata:Dynamic;
	var view:Sprite;
}

/**
	Small Lottie-profile player for authored PR2 presentation animations.

	The standard Lottie fields retain portable timing, assets, layer ordering,
	transforms, opacity, and markers. The namespaced `x_pr2_color` property
	preserves Flash color transforms, while exact Flash glow values live in
	Lottie's user metadata. Behavior and frame scripts remain in typed owners.
**/
class TimelineClip extends Sprite {
	public final sourcePath:String;
	public final totalFrames:Int;
	public final frameRate:Float;
	public final userMetadata:Dynamic;
	public var currentFrame(default, null):Int = 1;
	public var playing(default, null):Bool = true;
	public var looping:Bool = false;
	public var markerHandler:Null<String->Void>;

	private final layers:Array<TimelineLayer> = [];
	private final attachments:Map<String, Sprite> = new Map();
	private final markersByFrame:Map<Int, Array<String>> = new Map();
	private var completed:Bool = false;

	public function new(sourcePath:String) {
		super();
		this.sourcePath = sourcePath;
		var document:Dynamic = Json.parse(loadText(sourcePath));
		frameRate = numberField(document, "fr");
		totalFrames = Std.int(document.op) - Std.int(document.ip);
		userMetadata = customPr2Metadata(document);
		looping = Reflect.field(userMetadata, "loop") == true;
		var firstFrame = Std.int(document.ip);
		var markerDefinitions:Dynamic = Reflect.field(document, "markers");
		if (markerDefinitions != null) {
			for (marker in cast(markerDefinitions, Array<Dynamic>)) {
				var frame = Std.int(marker.tm) - firstFrame + 1;
				var entries = markersByFrame.get(frame);
				if (entries == null) {
					entries = [];
					markersByFrame.set(frame, entries);
				}
				entries.push(Std.string(marker.cm));
			}
		}
		var assets:Map<String, String> = new Map();
		for (asset in cast(document.assets, Array<Dynamic>)) {
			assets.set(Std.string(asset.id), Std.string(asset.u) + Std.string(asset.p));
		}
		var metadata = Reflect.field(userMetadata, "layers");
		if (metadata == null) metadata = {};
		var definitions:Array<Dynamic> = cast document.layers;
		var index = definitions.length;
		while (index > 0) {
			index--;
			var data = definitions[index];
			var view = new Sprite();
			view.name = Std.string(data.nm);
			var layerType = Std.int(data.ty);
			if (layerType == 2) {
				var path = assets.get(Std.string(data.refId));
				if (path == null) throw 'Missing Lottie asset ${data.refId} in $sourcePath';
				view.addChild(SvgAsset.createWithText(path));
			} else if (layerType == 5) {
				var textData:Dynamic = Reflect.field(data, "x_pr2_text");
				if (textData == null) throw 'Missing PR2 text data in $sourcePath';
				var field = new TextField();
				field.x = numberField(textData, "x");
				field.y = numberField(textData, "y");
				field.width = numberField(textData, "width");
				field.height = numberField(textData, "height");
				field.selectable = false;
				field.mouseEnabled = false;
				var format = new TextFormat(FontResolver.resolve(Std.string(textData.font)), Std.int(Math.round(numberField(textData, "size"))), Std.int(textData.color));
				format.letterSpacing = numberField(textData, "letterSpacing");
				field.defaultTextFormat = format;
				field.text = Std.string(textData.text);
				view.addChild(field);
			} else if (layerType != 3) {
				throw 'Unsupported Lottie layer type ${data.ty} in $sourcePath';
			}
			addChild(view);
			layers.push({data: data, metadata: Reflect.field(metadata, Std.string(data.ind)), view: view});
			if (layerType == 3) attachments.set(view.name, view);
		}
		renderFrame(0);
		addEventListener(Event.ENTER_FRAME, advance);
	}

	public function attachment(name:String):Null<Sprite> {
		return attachments.get(name);
	}

	public function play():Void {
		playing = true;
		if (currentFrame < totalFrames || looping) completed = false;
	}
	public function stop():Void playing = false;
	public function markersAtFrame(frame:Int):Array<String> {
		var entries = markersByFrame.get(clampFrame(frame));
		return entries == null ? [] : entries.copy();
	}

	public function emitCurrentMarkers():Void {
		if (markerHandler == null) return;
		for (marker in markersAtFrame(currentFrame)) markerHandler(marker);
	}

	public function gotoAndStop(frame:Int):Void {
		currentFrame = clampFrame(frame);
		playing = false;
		completed = currentFrame >= totalFrames;
		renderFrame(currentFrame - 1);
		emitCurrentMarkers();
	}

	public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, advance);
		playing = false;
		if (parent != null) parent.removeChild(this);
	}

	private function advance(_:Event):Void {
		if (!playing || completed) return;
		if (currentFrame < totalFrames) {
			currentFrame++;
			renderFrame(currentFrame - 1);
			emitCurrentMarkers();
			if (currentFrame >= totalFrames && !looping) {
				playing = false;
				completed = true;
				dispatchEvent(new Event(Event.COMPLETE));
			}
			return;
		}
		if (looping) {
			currentFrame = 1;
			renderFrame(0);
			emitCurrentMarkers();
			return;
		}
		playing = false;
		completed = true;
		dispatchEvent(new Event(Event.COMPLETE));
	}

	private function renderFrame(frame:Int):Void {
		for (record in layers) {
			var data = record.data;
			record.view.visible = frame >= Std.int(data.ip) && frame < Std.int(data.op);
			if (!record.view.visible) continue;
			var transform = LottieTransform.sample(data.ks, frame);
			record.view.transform.matrix = transform.matrix;
			var color:Array<Dynamic> = cast LottieTransform.valueAt(data.x_pr2_color, frame);
			record.view.transform.colorTransform = new ColorTransform(number(color, 0), number(color, 1), number(color, 2), number(color, 3) * transform.opacity, number(color, 4), number(color, 5), number(color, 6), number(color, 7));
			if (record.metadata != null && Reflect.hasField(record.metadata, "glow")) {
				var glow:Array<Dynamic> = cast LottieTransform.valueAt(Reflect.field(record.metadata, "glow"), frame);
				var quality = Reflect.hasField(record.metadata, "glowQuality") ? Std.int(Reflect.field(record.metadata, "glowQuality")) : 1;
				var inner = Reflect.field(record.metadata, "glowInner") == true;
				var knockout = Reflect.field(record.metadata, "glowKnockout") == true;
				record.view.filters = number(glow, 4) > 0 ? [
					new GlowFilter(Std.int(number(glow, 0)), number(glow, 1), number(glow, 2), number(glow, 3), number(glow, 4), quality, inner, knockout)
				] : [];
			}
		}
	}

	private static function customPr2Metadata(document:Dynamic):Dynamic {
		var metadata = Reflect.field(document, "metadata");
		if (metadata == null) return {};
		var customProps = Reflect.field(metadata, "customProps");
		if (customProps == null) return {};
		var pr2 = Reflect.field(customProps, "pr2");
		return pr2 == null ? {} : pr2;
	}

	private static inline function number(values:Array<Dynamic>, index:Int):Float {
		return values[index];
	}

	private static inline function numberField(value:Dynamic, field:String):Float {
		return Reflect.field(value, field);
	}

	private inline function clampFrame(frame:Int):Int {
		return frame < 1 ? 1 : frame > totalFrames ? totalFrames : frame;
	}

	private static function loadText(path:String):String {
		try {
			var content = Assets.getText(path);
			if (content != null) return content;
		} catch (_:Dynamic) {}
		#if sys
		if (StringTools.startsWith(path, "assets/")) {
			var localPath = "art/" + path.substr("assets/".length);
			if (sys.FileSystem.exists(localPath)) return sys.io.File.getContent(localPath);
		}
		#end
		throw 'Missing Lottie timeline $path';
	}
}
