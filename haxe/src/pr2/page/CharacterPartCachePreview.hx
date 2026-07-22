package pr2.page;

import haxe.Timer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import pr2.Constants;
import pr2.app.DebugSignal;
import pr2.character.CharacterView;

/** Eight-character HTML5 benchmark for ordinary Shape textures versus explicit part-level bitmap caches. */
class CharacterPartCachePreview extends Sprite {
	private static inline var WARMUP_FRAMES:Int = 60;
	private static inline var SAMPLE_FRAMES:Int = 240;
	private static final PHASES:Array<Bool> = [true, false, false, true];

	private final characters:Array<CharacterView> = [];
	private final cacheRenderTimes:Array<Float> = [];
	private final refreshRenderTimes:Array<Float> = [];
	private final cacheFrameTimes:Array<Float> = [];
	private final refreshFrameTimes:Array<Float> = [];
	private var status:TextField;
	private var phaseIndex:Int = 0;
	private var phaseFrame:Int = 0;
	private var renderStarted:Float = 0;
	private var previousRenderStarted:Float = 0;
	private var originalFrameRate:Float = 27;
	private var renderWindow:Null<lime.ui.Window>;

	public function new() {
		super();
		graphics.beginFill(0x17202A);
		graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		graphics.endFill();

		var title = makeLabel("8 CHARACTER RENDER BENCHMARK", 18, 0xFFFFFF, true);
		title.x = (Constants.STAGE_WIDTH - title.width) / 2;
		title.y = 14;
		addChild(title);

		status = makeLabel("Preparing benchmark...", 13, 0xB9C7D5, false);
		status.x = (Constants.STAGE_WIDTH - status.width) / 2;
		status.y = 42;
		addChild(status);

		for (index in 0...8) addCharacter(index);
		addEventListener(Event.ADDED_TO_STAGE, startBenchmark);
		addEventListener(Event.REMOVED_FROM_STAGE, stopBenchmark);
	}

	private function addCharacter(index:Int):Void {
		var primaryColors = [0x3399FF, 0xF15B5B, 0x5BCB77, 0xF4B942, 0x9B6DFF, 0x48C9B0, 0xEC70A1, 0xAAB7B8];
		var secondaryColors = [0xFFD24A, 0x81D4FA, 0xFF8A65, 0xE6EE9C, 0x80CBC4, 0xFFCC80, 0x90CAF9, 0xCE93D8];
		var mixed = index % 2 == 1;
		var character = new CharacterView(primaryColors[index], secondaryColors[index], null, "run",
			mixed ? {head: 37, body: 28, feet: 40} : {head: 1, body: 1, feet: 1}, mixed ? [6, 5, 1, 1] : [5, 1, 1, 1]);
		character.x = 72 + (index % 4) * 136;
		character.y = 155 + Std.int(index / 4) * 165;
		// Gameplay applies 0.9 to CharacterView; its rig root already contains the
		// authored 0.15 transform.
		character.scaleX = character.scaleY = 0.9;
		addChild(character);
		characters.push(character);
	}

	private function startBenchmark(_:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, startBenchmark);
		originalFrameRate = stage.frameRate;
		stage.frameRate = 120;
		renderWindow = stage.window;
		renderWindow.onRender.add(beforeRender, false, 10000);
		renderWindow.onRender.add(afterRender, false, -10000);
		addEventListener(Event.ENTER_FRAME, animateCharacters);
		startPhase(0);
	}

	private function stopBenchmark(_:Event):Void {
		if (renderWindow != null) {
			renderWindow.frameRate = originalFrameRate;
			renderWindow.onRender.remove(beforeRender);
			renderWindow.onRender.remove(afterRender);
		}
		removeEventListener(Event.ENTER_FRAME, animateCharacters);
	}

	private function startPhase(index:Int):Void {
		phaseIndex = index;
		phaseFrame = 0;
		previousRenderStarted = 0;
		var cacheEnabled = PHASES[phaseIndex];
		for (character in characters) character.setPartBitmapCacheEnabled(cacheEnabled);
		setStatus('Pass ${phaseIndex + 1}/${PHASES.length}: ${cacheEnabled ? "explicit part cache" : "ordinary vectors"}');
		DebugSignal.set("character-part-cache", cacheEnabled ? "running-part-cache" : "running-vectors");
	}

	private function animateCharacters(_:Event):Void {
		for (character in characters) character.advanceOneFrame();
	}

	private function beforeRender(_:Dynamic):Void {
		renderStarted = Timer.stamp();
	}

	private function afterRender(_:Dynamic):Void {
		if (phaseIndex >= PHASES.length) return;
		var elapsed = (Timer.stamp() - renderStarted) * 1000;
		var cacheEnabled = PHASES[phaseIndex];
		if (phaseFrame >= WARMUP_FRAMES) {
			(cacheEnabled ? cacheRenderTimes : refreshRenderTimes).push(elapsed);
			if (previousRenderStarted > 0) {
				(cacheEnabled ? cacheFrameTimes : refreshFrameTimes).push((renderStarted - previousRenderStarted) * 1000);
			}
		}
		previousRenderStarted = renderStarted;
		phaseFrame++;
		if (phaseFrame < WARMUP_FRAMES + SAMPLE_FRAMES) return;
		if (phaseIndex + 1 < PHASES.length) {
			startPhase(phaseIndex + 1);
			return;
		}
		finishBenchmark();
	}

	private function finishBenchmark():Void {
		phaseIndex = PHASES.length;
		renderWindow.onRender.remove(beforeRender);
		renderWindow.onRender.remove(afterRender);
		stage.frameRate = originalFrameRate;
		removeEventListener(Event.ENTER_FRAME, animateCharacters);

		var explicit = summarize(cacheRenderTimes, cacheFrameTimes);
		var vectors = summarize(refreshRenderTimes, refreshFrameTimes);
		var ratio = vectors.meanRender / explicit.meanRender;
		var result = 'explicit=${format(explicit.meanRender)}ms p95=${format(explicit.p95Render)}ms fps=${format(explicit.fps)}; '
			+ 'vectors=${format(vectors.meanRender)}ms p95=${format(vectors.p95Render)}ms fps=${format(vectors.fps)}; '
			+ 'vectors/explicit=${format(ratio)}x';
		setStatus(result);
		DebugSignal.set("character-part-cache", result);
	}

	private function summarize(renderTimes:Array<Float>, frameTimes:Array<Float>):{meanRender:Float, p95Render:Float, fps:Float} {
		var sorted = renderTimes.copy();
		sorted.sort(function(left:Float, right:Float):Int return left < right ? -1 : left > right ? 1 : 0);
		return {
			meanRender: mean(renderTimes),
			p95Render: sorted[Std.int((sorted.length - 1) * 0.95)],
			fps: 1000 / mean(frameTimes)
		};
	}

	private function mean(values:Array<Float>):Float {
		var total = 0.0;
		for (value in values) total += value;
		return total / values.length;
	}

	private function setStatus(value:String):Void {
		status.text = value;
		status.x = (Constants.STAGE_WIDTH - status.width) / 2;
	}

	private function format(value:Float):String return Std.string(Math.round(value * 100) / 100);

	private function makeLabel(value:String, size:Int, color:Int, bold:Bool):TextField {
		var label = new TextField();
		label.defaultTextFormat = new TextFormat("_sans", size, color, bold);
		label.selectable = false;
		label.mouseEnabled = false;
		label.autoSize = TextFieldAutoSize.LEFT;
		label.text = value;
		return label;
	}
}
