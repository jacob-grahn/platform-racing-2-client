package pr2.level;

import haxe.Timer;
import openfl.display.Sprite;
import pr2.level.Level.LevelArtLayer;
import pr2.level.Level.LevelDrawAction;
import pr2.level.LevelArtRasterizer.ArtRasterTiles;

/** Incrementally schedules one decoded art layer into the raster engine. */
typedef ArtStrokeState = {
	var color:Int;
	var size:Float;
	var mode:String;
}

class ArtDrawCursor {
	public final container:Sprite;
	public final rasterCanvas:Sprite;
	public final layer:LevelArtLayer;
	public var lastProfileActionIndex(default, null):Int = -1;
	public var lastProfileKind(default, null):String = "";
	public var lastProfilePath(default, null):String = "";
	public var lastProfileMode(default, null):String = "";
	public var lastProfileValueCount(default, null):Int = 0;
	public var lastProfileTileCount(default, null):Int = 0;
	public var lastProfileTileSpanX(default, null):Int = 0;
	public var lastProfileTileSpanY(default, null):Int = 0;
	public var lastProfileMs(default, null):Float = 0;
	private final strokeTiles:ArtRasterTiles;
	private var actionIndex:Int = 0;
	private var objectIndex:Int = 0;
	private var textIndex:Int = 0;

	public function new(container:Sprite, strokeTiles:ArtRasterTiles, layer:LevelArtLayer) {
		this.container = container;
		this.rasterCanvas = strokeTiles.rasterCanvas;
		this.layer = layer;
		this.strokeTiles = strokeTiles;
	}

	public function drawNext(maxActions:Int = 1, ?deadline:Null<Float>):Int {
		lastProfileMs = 0;
		if (actionIndex < layer.drawActions.length) {
			var drawn = 0;
			var batchDrawStrokes = maxActions > 1;
			while (drawn < maxActions && actionIndex < layer.drawActions.length) {
				var currentActionIndex = actionIndex;
				var action = layer.drawActions[actionIndex];
				var actionStarted = Timer.stamp();
				var complete = true;
				complete = strokeTiles.apply(action, batchDrawStrokes, deadline);
				var actionMs = (Timer.stamp() - actionStarted) * 1000;
				if (actionMs >= lastProfileMs) {
					copyStrokeProfile(action, currentActionIndex, actionMs);
				}
				if (!complete) {
					break;
				}
				actionIndex++;
				drawn++;
				if (deadline != null && drawn > 0 && Timer.stamp() >= deadline) {
					break;
				}
			}
			if (batchDrawStrokes && !strokeTiles.hasPendingRasterWork()) {
				var flushStarted = Timer.stamp();
				strokeTiles.flush();
				var flushMs = (Timer.stamp() - flushStarted) * 1000;
				if (flushMs > lastProfileMs) {
					copyFlushProfile(actionIndex - 1, flushMs);
				}
			}
			return drawn;
		}
		var flushStarted = Timer.stamp();
		strokeTiles.flush();
		var flushMs = (Timer.stamp() - flushStarted) * 1000;
		if (flushMs > lastProfileMs) {
			copyFlushProfile(actionIndex - 1, flushMs);
		}
		if (objectIndex < layer.objects.length) {
			var objectStarted = Timer.stamp();
			LevelRenderer.addLayerObject(container, layer.objects[objectIndex++], layer.scale);
			lastProfileMs = (Timer.stamp() - objectStarted) * 1000;
			lastProfileActionIndex = objectIndex - 1;
			lastProfileKind = "object";
			lastProfilePath = "object";
			lastProfileMode = "";
			lastProfileValueCount = 0;
			lastProfileTileCount = 0;
			lastProfileTileSpanX = 0;
			lastProfileTileSpanY = 0;
			return 1;
		}
		if (textIndex < layer.texts.length) {
			var textStarted = Timer.stamp();
			LevelRenderer.addLayerText(container, layer.texts[textIndex++], layer.scale);
			lastProfileMs = (Timer.stamp() - textStarted) * 1000;
			lastProfileActionIndex = textIndex - 1;
			lastProfileKind = "text";
			lastProfilePath = "text";
			lastProfileMode = "";
			lastProfileValueCount = 0;
			lastProfileTileCount = 0;
			lastProfileTileSpanX = 0;
			lastProfileTileSpanY = 0;
			return 1;
		}
		return 0;
	}

	private function copyStrokeProfile(action:LevelDrawAction, actionIndex:Int, elapsedMs:Float):Void {
		lastProfileMs = elapsedMs;
		lastProfileActionIndex = actionIndex;
		lastProfileKind = action.kind;
		lastProfilePath = strokeTiles.lastProfilePath;
		lastProfileMode = strokeTiles.lastProfileMode;
		lastProfileValueCount = action.values.length;
		lastProfileTileCount = strokeTiles.lastProfileTileCount;
		lastProfileTileSpanX = strokeTiles.lastProfileTileSpanX;
		lastProfileTileSpanY = strokeTiles.lastProfileTileSpanY;
	}

	private function copyFlushProfile(actionIndex:Int, elapsedMs:Float):Void {
		lastProfileMs = elapsedMs;
		lastProfileActionIndex = actionIndex;
		lastProfileKind = "flush";
		lastProfilePath = strokeTiles.lastProfilePath;
		lastProfileMode = strokeTiles.lastProfileMode;
		lastProfileValueCount = 0;
		lastProfileTileCount = strokeTiles.lastProfileTileCount;
		lastProfileTileSpanX = strokeTiles.lastProfileTileSpanX;
		lastProfileTileSpanY = strokeTiles.lastProfileTileSpanY;
	}

	public function isComplete():Bool {
		return actionIndex >= layer.drawActions.length && objectIndex >= layer.objects.length && textIndex >= layer.texts.length;
	}
}
