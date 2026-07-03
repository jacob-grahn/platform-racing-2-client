package pr2.runtime;

import haxe.ds.ObjectMap;
import openfl.display.BlendMode;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.FrameLabel;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.audio.TimelineSound;
import pr2.generated.assets.AssetTypes.DisplayElementDef;
import pr2.generated.assets.AssetTypes.FilterDef;
import pr2.generated.assets.AssetTypes.FrameDef;
import pr2.generated.assets.AssetTypes.LayerDef;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;
import pr2.generated.assets.AssetTypes.TimelineDef;
import pr2.util.Dyn;

typedef RuntimeFrame = {
	var elements:Array<DisplayElementDef>;
	// Parallel to `elements`: the source timeline layer index each element came
	// from. Used to reconstruct Animate mask/masked layer relationships.
	var elementLayers:Array<Int>;
	// Sound keyframes that begin on this exact frame. Unlike display elements,
	// sound frames are not expanded across their authored duration: Flash sound
	// commands run once when the playhead enters the keyframe.
	var soundFrames:Array<FrameDef>;
}

typedef PR2MovieClipOptions = {
	@:optional var maxNestedDepth:Int;
	@:optional var soundFrameHandler:FrameDef->Void;
}

class PR2MovieClip extends Sprite {
	public var symbol(default, null):SymbolAssetDef;
	public var currentFrame(default, null):Int = 1;
	public var totalFrames(default, null):Int = 1;
	public var currentLabels(default, null):Array<FrameLabel>;
	public var var_652:Dynamic = null;

	private var timeline:Null<TimelineDef>;
	private var frames:Array<RuntimeFrame> = [];
	private var labelsByName:Map<String, Int> = new Map();
	private var playing:Bool = false;
	private var maxNestedDepth:Int;
	private var nestedDepth:Int;
	private var soundFrameHandler:Null<FrameDef->Void>;
	private var hasEnteredFrame:Bool = false;
	private var frameScripts:Map<Int, Array<Void->Void>> = new Map();
	private var runningFrameScripts:Bool = false;
	private var isButtonSymbol:Bool = false;
	private var suppressConstructorAutoPlay:Bool = false;

	// Mask metadata keyed by source layer `index`. `maskLayers` holds layers
	// flagged `layerType: "mask"`; `maskedLayerParents` maps a masked layer to
	// the index of the mask layer that clips it (`parentLayerIndex`). Empty when
	// the timeline uses no masks, in which case rendering takes the flat path.
	private var maskLayers:Map<Int, Bool> = new Map();
	private var maskedLayerParents:Map<Int, Int> = new Map();
	private var hasMaskLayers:Bool = false;

	// Per-child record of the filter def array last assigned to each child,
	// compared by reference. Frame defs are static catalog data, so an unchanged
	// keyframe yields the same array instance every frame; skipping the
	// reassignment lets OpenFL keep its cached filter raster instead of
	// re-rasterizing the blur and re-uploading the GPU texture every frame (the
	// dominant cost behind the lobby's 1fps render). Entries are removed when a
	// child leaves this container so the map cannot outlive its children.
	private var appliedFilterDefs:ObjectMap<DisplayObject, Array<FilterDef>> = new ObjectMap();

	// Caches the display object built for a static element (shape/text), keyed by
	// the element def reference. Animate emits a fresh element object whenever
	// geometry or transform changes, so a cache hit guarantees identical output:
	// the cached object is reused across frames instead of re-rasterizing the
	// vector shape and re-uploading its GPU texture. Persists for the clip's
	// lifetime (bounded by the clip's distinct static elements) so it also covers
	// looping timelines, not just held keyframes; cleared on teardown.
	private var shapeByElement:ObjectMap<DisplayElementDef, DisplayObject> = new ObjectMap();

	private static inline var MASK_HOLDER_NAME = "__pr2_mask";
	private static inline var MASKED_HOLDER_NAME = "__pr2_masked";

	public static function fromSymbolName(name:String, ?options:PR2MovieClipOptions):PR2MovieClip {
		return new PR2MovieClip(AssetLibrary.requireSymbol(name), options);
	}

	public static function fromLinkage(linkageClassName:String, ?options:PR2MovieClipOptions):PR2MovieClip {
		return new PR2MovieClip(AssetLibrary.requireSymbolByLinkage(linkageClassName), options);
	}

	public function new(symbol:SymbolAssetDef, ?options:PR2MovieClipOptions, nestedDepth:Int = 0) {
		super();
		this.symbol = symbol;
		this.maxNestedDepth = options != null && options.maxNestedDepth != null ? options.maxNestedDepth : 32;
		this.soundFrameHandler = options != null ? options.soundFrameHandler : null;
		this.nestedDepth = nestedDepth;
		timeline = symbol.timelines.length > 0 ? symbol.timelines[0] : null;
		currentLabels = [];

		if (timeline != null) {
			buildTimeline(timeline);
		}
		installAuthoredConstructorFrameScripts();

		gotoFrame(1, false);
		// Button symbols use their extra frames as up/over/down/hit states, not
		// as an animation. Drive those states from the mouse like Flash does.
		isButtonSymbol = symbol.symbolType == "button";
		if (isButtonSymbol) {
			configureButtonSymbol();
		} else if (maybeFlattenSubtree()) {
			// Collapsed into a single cached bitmap; stays stopped, no per-frame work.
		} else if (totalFrames > 1 && !suppressConstructorAutoPlay) {
			play();
		}
	}

	private function installAuthoredConstructorFrameScripts():Void {
		return switch (symbol.linkageClassName) {
			case "PR2_Graphics_1_Apr_2014_fla.ag_intro_mc_247":
				setFrameScript(0, function():Void gotoAndPlay(2));
				setFrameScript(218, function():Void stop());
			case "PR2_Graphics_1_Apr_2014_fla.bubbleSpin_12" | "PR2_Graphics_1_Apr_2014_fla.bubbleShineSpin_17":
				setFrameScript(20, function():Void gotoAndPlay(1));
			case "PR2_Graphics_1_Apr_2014_fla.bubblebox_logo_ro_254":
				setFrameScript(0, function():Void stop());
				suppressConstructorAutoPlay = true;
			case "PR2_Graphics_1_Apr_2014_fla.bubblxbox_play_latest_text_252":
				setFrameScript(0, function():Void stop());
				setFrameScript(9, function():Void stop());
				suppressConstructorAutoPlay = true;
			case "PR2_Graphics_1_Apr_2014_fla.bumpedAnim_59":
				setFrameScript(55, function():Void var_652 = true);
			case "PR2_Graphics_1_Apr_2014_fla.frozenSolidAnim_65":
				setFrameScript(47, function():Void {
					stop();
					dispatchEvent(new Event(Event.COMPLETE));
				});
			case "PR2_Graphics_1_Apr_2014_fla.gunFireAnim_40"
				| "PR2_Graphics_1_Apr_2014_fla.iceWaveFireAnim_55"
				| "PR2_Graphics_1_Apr_2014_fla.jetPackStates_47"
				| "PR2_Graphics_1_Apr_2014_fla.swordAnim_53"
				| "PR2_Graphics_1_Apr_2014_fla.hatColor_24"
				| "PR2_Graphics_1_Apr_2014_fla.hatColor2_25"
				| "PlayersTabListGraphic":
				setFrameScript(0, function():Void stop());
				suppressConstructorAutoPlay = true;
			case "PR2_Graphics_1_Apr_2014_fla.buttonGlowAnim_182":
				setFrameScript(1, function():Void stop());
				setFrameScript(36, function():Void gotoAndPlay("on"));
			case "PR2_Graphics_1_Apr_2014_fla.jumpAnim_61":
				setFrameScript(49, function():Void stop());
			case "PR2_Graphics_1_Apr_2014_fla.superJumpAnim_60":
				setFrameScript(50, function():Void stop());
			case "PR2_Graphics_1_Apr_2014_fla.logoAnim_258":
				setFrameScript(0, function():Void {
					mouseEnabled = false;
					mouseChildren = false;
				});
				setFrameScript(Std.int(Math.min(232, totalFrames - 1)), function():Void stop());
			case "PointyStar" | "TeleportAnimation":
				setFrameScript(15, function():Void stop());
			case "SlashAnimation":
				setFrameScript(5, function():Void stop());
			default:
		}
	}

	// Spike (opt-in via `-D pr2_flatten_cache`): when a top-level clip's whole
	// subtree is provably static AND render-safe to flatten, freeze it and let the
	// GPU composite it as one quad instead of N. This is the cacheAsBitmap lever for
	// the lobby's ~198 static objects; gated on `FlattenPolicy` so it never touches
	// a subtree that could change, and on `nestedDepth == 0` so each flattened region
	// is cached once at its root rather than redundantly at every nesting level.
	// `stopAll` freezes any held-keyframe descendants whose per-frame re-render would
	// otherwise keep invalidating the cache.
	private function maybeFlattenSubtree():Bool {
		#if pr2_flatten_cache
		if (nestedDepth == 0 && FlattenPolicy.isFlattenable(symbol)) {
			stopAll();
			cacheAsBitmap = true;
			return true;
		}
		#end
		return false;
	}

	public function play():Void {
		if (playing) {
			return;
		}
		playing = true;
		addEventListener(Event.ENTER_FRAME, advanceFrame);
	}

	public function stop():Void {
		TimelineSound.stopStream(this);
		if (!playing) {
			return;
		}
		playing = false;
		removeEventListener(Event.ENTER_FRAME, advanceFrame);
	}

	public function stopAll():Void {
		stop();
		for (i in 0...numChildren) {
			var childClip = Std.downcast(getChildAt(i), PR2MovieClip);
			if (childClip != null) {
				childClip.stopAll();
			}
		}
	}

	public function dispose():Void {
		stop();
		TimelineSound.stopOwner(this);
		if (isButtonSymbol) {
			removeEventListener(MouseEvent.ROLL_OVER, onButtonRollOver);
			removeEventListener(MouseEvent.ROLL_OUT, onButtonRollOut);
			removeEventListener(MouseEvent.MOUSE_DOWN, onButtonMouseDown);
			removeEventListener(MouseEvent.MOUSE_UP, onButtonMouseUp);
		}
		disposeChildren();
	}

	private function configureButtonSymbol():Void {
		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;
		addEventListener(MouseEvent.ROLL_OVER, onButtonRollOver);
		addEventListener(MouseEvent.ROLL_OUT, onButtonRollOut);
		addEventListener(MouseEvent.MOUSE_DOWN, onButtonMouseDown);
		addEventListener(MouseEvent.MOUSE_UP, onButtonMouseUp);
	}

	private function onButtonRollOver(_:MouseEvent):Void {
		showButtonFrame(2);
	}

	private function onButtonRollOut(_:MouseEvent):Void {
		showButtonFrame(1);
	}

	private function onButtonMouseDown(_:MouseEvent):Void {
		showButtonFrame(3);
	}

	private function onButtonMouseUp(_:MouseEvent):Void {
		showButtonFrame(2);
	}

	private function showButtonFrame(frame:Int):Void {
		// Flash buttons conventionally have up/over/down/hit frames. A few PR2
		// symbols omit duplicate state frames, so clamp to the final visible frame.
		var visibleFrames = totalFrames >= 4 ? totalFrames - 1 : totalFrames;
		gotoAndStop(Std.int(Math.min(frame, Math.max(1, visibleFrames))));
	}

	public function gotoAndPlay(frame:Dynamic):Void {
		gotoFrame(frame, true);
		play();
	}

	public function gotoAndStop(frame:Dynamic):Void {
		gotoFrame(frame, false);
		stop();
	}

	public function advanceOneFrame():Void {
		var next = currentFrame + 1;
		if (next > totalFrames) {
			next = 1;
		}
		gotoFrame(next, true);
	}

	public function getChildByTimelineName(name:String):Null<DisplayObject> {
		for (i in 0...numChildren) {
			var child = getChildAt(i);
			if (child.name == name) {
				return child;
			}
			// Mask/content holders are synthetic wrappers, not part of the
			// authored timeline, so look through them for the named instance.
			if (child.name == MASK_HOLDER_NAME || child.name == MASKED_HOLDER_NAME) {
				var holder:Sprite = cast child;
				for (j in 0...holder.numChildren) {
					if (holder.getChildAt(j).name == name) {
						return holder.getChildAt(j);
					}
				}
			}
		}
		return null;
	}

	public function setFrameScript(frameIndex:Int, script:Null<Void->Void>):Void {
		var frameNumber = frameIndex + 1;
		if (frameNumber < 1 || frameNumber > totalFrames) {
			throw 'Frame script out of range for ${symbol.name}: $frameIndex';
		}

		if (script == null) {
			frameScripts.remove(frameNumber);
		} else {
			frameScripts.set(frameNumber, [script]);
		}
	}

	private function buildTimeline(source:TimelineDef):Void {
		totalFrames = source.frameCount < 1 ? 1 : source.frameCount;
		for (i in 0...totalFrames) {
			frames.push({elements: [], elementLayers: [], soundFrames: []});
		}

		for (label in source.labels) {
			var frameNumber = label.frame + 1;
			labelsByName.set(label.name, frameNumber);
			currentLabels.push(new FrameLabel(label.name, frameNumber));
		}

		// Record Animate mask relationships before flattening: a "mask" layer
		// clips every layer whose `parentLayerIndex` points back at it.
		for (layer in source.layers) {
			if (layer.layerType == "mask") {
				maskLayers.set(layer.index, true);
				hasMaskLayers = true;
			}
			if (layer.parentLayerIndex != null) {
				maskedLayerParents.set(layer.index, layer.parentLayerIndex);
			}
		}

		// Animate/XFL serializes layers from top to bottom. OpenFL display
		// children are painted from index 0 upward, so apply bottom layers first.
		var layerIndex = source.layers.length - 1;
		while (layerIndex >= 0) {
			applyLayer(source.layers[layerIndex]);
			layerIndex--;
		}
	}

	private function applyLayer(layer:LayerDef):Void {
		// A layer's eye-icon (`visible`) is an authoring-only toggle; Flash's
		// published SWF renders every layer regardless, so we ignore it here.
		// Guide layers are the exception — Flash never exports them (they hold
		// motion paths and authoring notes), so their content must be skipped.
		if (layer.layerType == "guide" || layer.layerType == "folder") {
			return;
		}

		for (frame in layer.frames) {
			var start = frame.index == null ? 0 : frame.index;
			var duration = frame.duration == null ? 1 : frame.duration;
			var elements = frame.elements == null ? [] : frame.elements;
			var end = Std.int(Math.min(totalFrames, start + duration));

			if (frame.soundName != null && start >= 0 && start < totalFrames) {
				if (frame.soundSync == "stream") {
					for (frameIndex in start...end) {
						frames[frameIndex].soundFrames.push(frame);
					}
				} else {
					frames[start].soundFrames.push(frame);
				}
			}

			for (frameIndex in start...end) {
				for (element in elements) {
					frames[frameIndex].elements.push(element);
					frames[frameIndex].elementLayers.push(layer.index);
				}
			}
		}
	}

	private function advanceFrame(event:Event):Void {
		advanceOneFrame();
	}

	private function gotoFrame(frame:Dynamic, streamEnabled:Bool):Void {
		var frameNumber = resolveFrame(frame);
		if (frameNumber < 1 || frameNumber > totalFrames) {
			throw 'Frame out of range for ${symbol.name}: $frameNumber';
		}

		var sequential = hasEnteredFrame && frameNumber == currentFrame + 1;
		currentFrame = frameNumber;
		hasEnteredFrame = true;
		var runtimeFrame = frames[frameNumber - 1];
		renderFrame(runtimeFrame);
		playFrameSounds(runtimeFrame, frameNumber, sequential, streamEnabled);
		runFrameScripts(frameNumber);
	}

	private function playFrameSounds(frame:RuntimeFrame, frameNumber:Int, sequential:Bool, streamEnabled:Bool):Void {
		if (soundFrameHandler == null) {
			var hasStream = false;
			for (soundFrame in frame.soundFrames) {
				if (soundFrame.soundSync == "stream") {
					hasStream = true;
					break;
				}
			}
			if (!hasStream) {
				TimelineSound.stopStream(this);
			}
		}
		for (soundFrame in frame.soundFrames) {
			if (soundFrameHandler != null) {
				soundFrameHandler(soundFrame);
			} else {
				TimelineSound.processFrame(soundFrame, this, frameNumber, sequential, streamEnabled);
			}
		}
	}

	private function resolveFrame(frame:Dynamic):Int {
		if (Std.isOfType(frame, String)) {
			var label = Std.string(frame);
			if (!labelsByName.exists(label)) {
				throw 'Unknown frame label for ${symbol.name}: $label';
			}
			return labelsByName.get(label);
		}
		return Std.int(frame);
	}

	private function renderFrame(frame:RuntimeFrame):Void {
		if (hasMaskLayers) {
			renderFrameWithMasks(frame);
			return;
		}

		var reusableClips:Map<String, Array<PR2MovieClip>> = collectReusableClips();
		var desiredChildren:Array<DisplayObject> = [];
		var desiredChildSet:ObjectMap<DisplayObject, Bool> = new ObjectMap();

		for (i in 0...frame.elements.length) {
			var element = frame.elements[i];
			// Static visuals (shapes/text) are pure functions of their element def:
			// Animate emits a new element object whenever geometry or transform
			// changes, so the same element reference always renders identically.
			// Reuse the previously built object instead of re-rasterizing it and
			// re-uploading its GPU texture every frame. The cached object already
			// carries the element's transform/visibility/filters, so its properties
			// do not need re-applying.
			var child:DisplayObject = null;
			var cached = shapeByElement.get(element);
			if (cached != null && !desiredChildSet.exists(cached)) {
				child = cached;
			} else {
				child = createDisplayObject(element, takeReusableClip(reusableClips, element));
				applyElementProperties(child, element);
				if (isCacheableElement(element)) {
					shapeByElement.set(element, child);
				} else if (isCacheableSymbolInstance(element)) {
					// A nested instance whose whole subtree is provably static renders
					// identically every frame, so build it once and reuse it like a
					// shape instead of rebuilding the clip (and re-rasterizing its
					// shapes) each frame. Freeze any residual ENTER_FRAME ticks first
					// (e.g. a single-frame child set to "loop" in place): the output is
					// constant, so stopping is visually a no-op, it drops the per-frame
					// re-render/allocation, and — having no listeners — the clip is then
					// safe to leave intact on removal for reuse, exactly like a shape.
					var staticClip = Std.downcast(child, PR2MovieClip);
					if (staticClip != null) {
						staticClip.stopAll();
					}
					shapeByElement.set(element, child);
				}
			}
			desiredChildren.push(child);
			desiredChildSet.set(child, true);
		}

		// Children kept in `shapeByElement` (static shapes/text and provably-static
		// symbol instances) are reused across frames, so they must survive removal
		// rather than be disposed. Snapshot the current cache values once.
		var cachedObjects:ObjectMap<DisplayObject, Bool> = new ObjectMap();
		for (cachedChild in shapeByElement) {
			cachedObjects.set(cachedChild, true);
		}

		var index = numChildren - 1;
		while (index >= 0) {
			var child = getChildAt(index);
			if (!desiredChildSet.exists(child)) {
				appliedFilterDefs.remove(child);
				removeChildAt(index);
				// A detached nested clip that is not reused this frame must be
				// disposed, not just removed: an auto-playing clip keeps its
				// ENTER_FRAME listener, which OpenFL holds in a static
				// `__broadcastEvents` array, so it stays referenced (and keeps
				// ticking, spawning more orphans) forever otherwise. Cached children
				// (plain shapes/text, and the static instances frozen above) have no
				// listeners, so they are left intact for reuse via `shapeByElement`.
				var clip = Std.downcast(child, PR2MovieClip);
				if (clip != null && !cachedObjects.exists(clip)) {
					clip.dispose();
				}
			}
			index--;
		}

		for (i in 0...desiredChildren.length) {
			var child = desiredChildren[i];
			if (child.parent == this) {
				setChildIndex(child, i);
			} else {
				addChildAt(child, i);
			}
		}
		disposeUnusedReusableClips(reusableClips);
		// A frame-by-frame animation removes children every frame. OpenFL queues
		// each removed child in `__removedChildren` and only flushes it while the
		// container is rendered (CanvasDisplayObjectContainer.renderDrawable). A
		// clip that keeps advancing via ENTER_FRAME while OFF the rendered path
		// (an inactive lobby tab, alpha 0, or any non-renderable ancestor) is never
		// drawn, so that vector — and the matrices/transforms its orphans retain —
		// grows without bound. ENTER_FRAME broadcasts fire regardless of
		// visibility, so the idle lobby leaked here. Flush eagerly each frame.
		__cleanupRemovedChildren();
	}

	// Elements whose built object can be reused across frames keyed by element def
	// reference: Animate emits a new element object whenever geometry/transform/
	// params change, so a stable reference means identical output.
	//   - Static visuals (shapes/text) are pure functions of their def.
	//   - `DOMComponentInstance` (fl.controls Button/TextInput/…) MUST be reused, not
	//     rebuilt every frame: a held button on an animated clip's static layer keeps
	//     the same element ref each frame, so without caching `createDisplayObject`
	//     mints a fresh `FlButton` (and its `PR2MovieClip` skins) every frame and the
	//     discarded one is never disposed — a per-frame leak. Reusing the instance
	//     also preserves its interactive state (hover/toggle/focus).
	// Animated symbol instances keep playback state and are handled by the
	// name-based clip pool, so they are not cached here — but a *provably static*
	// instance is (see `isCacheableSymbolInstance`).
	private function isCacheableElement(element:DisplayElementDef):Bool {
		return switch (element.type) {
			case "DOMShape" | "DOMRectangleObject" | "DOMOvalObject" | "DOMStaticText"
				| "DOMComponentInstance": true;
			default: false;
		}
	}

	// Memoized analysis of whether a symbol's whole subtree is temporally static.
	static var staticAnalyzer:StaticSubtreeAnalyzer;

	// True for a nested symbol instance whose rendered output never changes over
	// time (the entire descendant tree included). Graphic symbols carry no authored
	// instance name, so the name-based clip pool can never reuse them; without this
	// every held graphic instance (e.g. the lobby's single-frame `Graphics/Symbol *`
	// art, which dominated the idle render churn) is rebuilt — clip + nested shapes
	// re-rasterized — on every frame. A static instance is a pure function of its
	// element def, exactly like a shape, so it is safe to build once and reuse via
	// `shapeByElement`. (Temporal staticness only; this clip still renders normally
	// each frame, so masks/filters/blends are unaffected — no flatten-safety gate
	// is needed.)
	private function isCacheableSymbolInstance(element:DisplayElementDef):Bool {
		if (element.type != "DOMSymbolInstance" || element.libraryItemName == null) {
			return false;
		}
		var childSymbol = AssetLibrary.getSymbol(element.libraryItemName);
		if (childSymbol == null) {
			return false;
		}
		if (staticAnalyzer == null) {
			staticAnalyzer = new StaticSubtreeAnalyzer();
		}
		return staticAnalyzer.isStaticSymbol(childSymbol);
	}

	// Rebuilds the frame honoring Animate mask layers. Masked layers are grouped
	// into a holder Sprite that is clipped by a sibling holder containing the
	// mask layer's shapes (`content.mask = maskHolder`). Mask symbols in the
	// catalog are static single-frame graphics, so this rebuilds from scratch
	// rather than reusing the pooled-clip fast path used by `renderFrame`.
	private function renderFrameWithMasks(frame:RuntimeFrame):Void {
		disposeChildren();

		// One content holder + one mask holder per mask layer index, created
		// lazily the first time an element belonging to that group is seen. The
		// flat element list is already in bottom-to-top paint order, so adding
		// holders to `this` on first use yields the correct stacking.
		var maskHolders:Map<Int, Sprite> = new Map();
		var contentHolders:Map<Int, Sprite> = new Map();

		for (i in 0...frame.elements.length) {
			var element = frame.elements[i];
			var layerIndex = frame.elementLayers[i];
			var child = createDisplayObject(element, null);
			applyElementProperties(child, element);

			if (maskLayers.exists(layerIndex)) {
				var holder = maskHolders.get(layerIndex);
				if (holder == null) {
					holder = createHolder(MASK_HOLDER_NAME);
					maskHolders.set(layerIndex, holder);
					addChild(holder);
				}
				holder.addChild(child);
				continue;
			}

			var parent = maskedLayerParents.get(layerIndex);
			if (parent != null && maskLayers.exists(parent)) {
				var content = contentHolders.get(parent);
				if (content == null) {
					content = createHolder(MASKED_HOLDER_NAME);
					contentHolders.set(parent, content);
					addChild(content);
				}
				content.addChild(child);
				continue;
			}

			addChild(child);
		}

		// Wire each content holder to its mask. A mask must be on the display
		// list to clip; it then renders only as the clip region, not as art.
		for (maskIndex in contentHolders.keys()) {
			var holder = maskHolders.get(maskIndex);
			if (holder != null) {
				contentHolders.get(maskIndex).mask = holder;
			}
		}
	}

	private function createHolder(name:String):Sprite {
		var holder = new Sprite();
		holder.name = name;
		holder.mouseEnabled = false;
		return holder;
	}

	private function disposeChildren():Void {
		while (numChildren > 0) {
			var child = removeChildAt(numChildren - 1);
			appliedFilterDefs.remove(child);
			var clip = Std.downcast(child, PR2MovieClip);
			if (clip != null) {
				clip.dispose();
				continue;
			}
			// Groups, component skins, and mask holders can contain animated clips
			// at any depth. Walk the full subtree so none of their ENTER_FRAME
			// listeners survive after the owning timeline is disposed.
			var container = Std.downcast(child, DisplayObjectContainer);
			if (container != null) {
				disposeContainer(container);
			}
		}
		// Flush OpenFL's pending-removed-children queue (see renderFrame): the
		// masked render path tears down and rebuilds every child each frame, so
		// without this the orphans pile up when the clip is off the rendered path.
		__cleanupRemovedChildren();
		// Drop cached static children that were detached (kept for reuse across
		// frames) so they cannot outlive the cleared display list.
		shapeByElement = new ObjectMap();
	}

	private function disposeContainer(container:DisplayObjectContainer):Void {
		container.mask = null;
		while (container.numChildren > 0) {
			var nestedChild = container.removeChildAt(container.numChildren - 1);
			appliedFilterDefs.remove(nestedChild);
			var nested = Std.downcast(nestedChild, PR2MovieClip);
			if (nested != null) {
				nested.dispose();
				continue;
			}
			var nestedContainer = Std.downcast(nestedChild, DisplayObjectContainer);
			if (nestedContainer != null) {
				disposeContainer(nestedContainer);
			}
		}
	}

	private function runFrameScripts(frameNumber:Int):Void {
		var scripts = frameScripts.get(frameNumber);
		if (scripts == null || runningFrameScripts) {
			return;
		}

		runningFrameScripts = true;
		try {
			for (script in scripts.copy()) {
				script();
			}
		} catch (error:Dynamic) {
			runningFrameScripts = false;
			throw error;
		}
		runningFrameScripts = false;
	}

	private function collectReusableClips():Map<String, Array<PR2MovieClip>> {
		var reusableClips:Map<String, Array<PR2MovieClip>> = new Map();
		for (i in 0...numChildren) {
			var clip = Std.downcast(getChildAt(i), PR2MovieClip);
			if (clip == null || clip.name == null || clip.symbol.name == null) {
				continue;
			}

			var key = reusableClipKey(clip.name, clip.symbol.name);
			var clips = reusableClips.get(key);
			if (clips == null) {
				clips = [];
				reusableClips.set(key, clips);
			}
			clips.push(clip);
		}
		return reusableClips;
	}

	private function takeReusableClip(reusableClips:Map<String, Array<PR2MovieClip>>, element:DisplayElementDef):Null<PR2MovieClip> {
		if (element.name == null || element.libraryItemName == null) {
			return null;
		}

		var clips = reusableClips.get(reusableClipKey(element.name, element.libraryItemName));
		if (clips == null || clips.length == 0) {
			return null;
		}
		return clips.shift();
	}

	private function disposeUnusedReusableClips(reusableClips:Map<String, Array<PR2MovieClip>>):Void {
		// Provably-static symbol instances are kept in `shapeByElement` and reused
		// across frames (one cached clip per frame element). They also land in the
		// reusable pool because OpenFL auto-names every clip, but `takeReusableClip`
		// never draws them (their element has no authored name), so they linger here.
		// Such a clip is only *detached* while another frame is showing — it is still
		// live and will be re-added when its frame comes back — so disposing it would
		// empty a cached instance and blank it out on return (arrow blocks lost their
		// chevron after animating). Skip anything still referenced by the cache.
		var cached:ObjectMap<DisplayObject, Bool> = new ObjectMap();
		for (cachedChild in shapeByElement) {
			cached.set(cachedChild, true);
		}
		for (clips in reusableClips) {
			for (clip in clips) {
				// A clip still parented to `this` was reused this frame via the
				// `shapeByElement` static-instance cache (it never went through
				// `takeReusableClip`, so it stayed in the pool). The remove loop above
				// has already detached every genuinely unused child, so a surviving
				// parent means the clip is in use — disposing it would empty a visible
				// instance (e.g. a held graphic re-rendered by gotoAndStop).
				if (clip.parent == this || cached.exists(clip)) {
					continue;
				}
				clip.dispose();
			}
		}
	}

	private function reusableClipKey(name:String, symbolName:String):String {
		return name + "\n" + symbolName;
	}

	private function createDisplayObject(element:DisplayElementDef, reusableClip:Null<PR2MovieClip>):DisplayObject {
		if (element.type == "DOMStaticText" || element.type == "DOMDynamicText" || element.type == "DOMInputText") {
			return createStaticText(element);
		}

		if (element.type == "DOMComponentInstance") {
			return FlComponentFactory.create(element);
		}

		if (element.libraryItemName != null) {
			var baked = BakedSymbolAtlas.create(element.libraryItemName);
			if (baked != null) {
				return baked;
			}

			var childSymbol = AssetLibrary.getSymbol(element.libraryItemName);
			if (childSymbol != null) {
				if (nestedDepth >= maxNestedDepth) {
					throw 'PR2 symbol nesting limit ($maxNestedDepth) exceeded while rendering ${element.libraryItemName} in ${symbol.name}';
				}

				// Symbols with an authored scale-grid render through nine-slice
				// tiling (corners fixed, edges/center stretched) rather than a
				// uniform scale; `applyElementProperties` consumes the instance scale
				// as the target size. Falls through to a normal clip when the grid is
				// degenerate.
				if (NineSliceSymbol.hasGrid(childSymbol)) {
					var sliced = NineSliceSymbol.tryCreate(childSymbol, {
						maxNestedDepth: maxNestedDepth
					}, nestedDepth + 1);
					if (sliced != null) {
						return sliced;
					}
				}

				var clip = reusableClip != null ? reusableClip : new PR2MovieClip(childSymbol, {
					maxNestedDepth: maxNestedDepth,
					soundFrameHandler: soundFrameHandler
				}, nestedDepth + 1);
				if (element.loop == "single frame") {
					clip.gotoAndStop((element.firstFrame == null ? 0 : element.firstFrame) + 1);
				} else if (reusableClip == null && (element.loop == "play once" || element.loop == "loop")) {
					clip.gotoAndPlay((element.firstFrame == null ? 0 : element.firstFrame) + 1);
				}
				return clip;
			}

			if (element.type != "DOMBitmapInstance") {
				throw 'Unknown nested PR2 symbol ${element.libraryItemName} in ${symbol.name}';
			}
		}

		if (element.type == "DOMShape" || element.type == "DOMRectangleObject" || element.type == "DOMOvalObject") {
			var vectorShape = VectorShapeRenderer.render(element);
			if (vectorShape != null) {
				return vectorShape;
			}
		}

		if (element.type == "DOMGroup" && element.children != null) {
			var group = new Sprite();
			for (childElement in element.children) {
				var child = createDisplayObject(childElement, null);
				applyElementProperties(child, childElement);
				group.addChild(child);
			}
			return group;
		}

		return createPlaceholder(element);
	}

	private function createStaticText(element:DisplayElementDef):DisplayObject {
		var attrs:Dynamic = element.textAttrs;
		var field = new TextField();
		// Map the original (often proprietary) face name onto an embedded font.
		// The resolved family already encodes weight/style, so bold/italic flags
		// stay off to avoid browser faux-synthesis over the real outlines.
		var face = FontResolver.resolve(Dyn.string(attrs, "face", "_sans"));
		// Animate sometimes omits `size`, but `bitmapSize` still carries the font
		// size in twentieths of a pixel (240 = 12px). `lineHeight` is larger than
		// the font and must not be used directly or text is oversized and clipped.
		var bitmapSize = Dyn.floatOrNull(attrs, "bitmapSize");
		var inferredSize = bitmapSize == null ? Dyn.float(attrs, "lineHeight", 14.4) / 1.2 : bitmapSize / 20;
		var size = Std.int(Dyn.float(attrs, "size", inferredSize));
		var align = textAlign(Dyn.string(attrs, "alignment", "left"));
		// Authored fill color (e.g. the credits' "#254489"); default to black to
		// match Animate's behavior when no fillColor attribute is present.
		var color = parseTextColor(Dyn.string(attrs, "fillColor", null), 0x000000);
		var format = new TextFormat(face, size, color, false, false, false, null, null, align);
		// XFL carries the inter-character spacing and inter-line leading as
		// authored; both are dropped if left unset, so apply them here. `rotation`
		// in textAttrs is anti-aliasing metadata, not a transform, so it is ignored.
		var letterSpacing = Dyn.floatOrNull(attrs, "letterSpacing");
		if (letterSpacing != null) {
			format.letterSpacing = letterSpacing;
		}
		var lineSpacing = Dyn.floatOrNull(attrs, "lineSpacing");
		if (lineSpacing != null) {
			format.leading = Math.round(lineSpacing);
		}
		var leftMargin = Dyn.floatOrNull(attrs, "leftMargin");
		if (leftMargin != null) {
			format.leftMargin = Math.round(leftMargin);
		}
		var rightMargin = Dyn.floatOrNull(attrs, "rightMargin");
		if (rightMargin != null) {
			format.rightMargin = Math.round(rightMargin);
		}
		field.defaultTextFormat = format;
		field.setTextFormat(format);
		field.text = element.text == null ? "" : element.text;
		// `left` is local text-layout geometry, not a parent-space position. It is
		// composed with the authored element matrix in applyElementProperties so
		// assigning that matrix cannot discard the offset.
		field.x = 0;
		field.y = 0;
		field.width = element.width == null ? Math.max(1, field.textWidth + 4) : element.width + 4;
		field.height = element.height == null ? Math.max(1, field.textHeight + 4) : element.height + 4;
		field.autoSize = TextFieldAutoSize.NONE;
		var input = element.type == "DOMInputText";
		field.selectable = input;
		field.type = input ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
		field.mouseEnabled = element.type != "DOMStaticText";
		return field;
	}


	private function parseTextColor(value:String, fallback:Int):Int {
		if (value == null) {
			return fallback;
		}
		var parsed = Std.parseInt(StringTools.replace(value, "#", "0x"));
		return parsed == null ? fallback : parsed;
	}

	private function textAlign(value:String):TextFormatAlign {
		return switch (value) {
			case "center": TextFormatAlign.CENTER;
			case "right": TextFormatAlign.RIGHT;
			default: TextFormatAlign.LEFT;
		}
	}

	private function createPlaceholder(element:DisplayElementDef):DisplayObject {
		var shape = new Shape();
		if (element.bounds != null) {
			var width = Math.max(1, element.bounds.right - element.bounds.left);
			var height = Math.max(1, element.bounds.bottom - element.bounds.top);
			shape.graphics.lineStyle(1, 0x8FE6FF, 0.85);
			shape.graphics.beginFill(0x8FE6FF, 0.16);
			shape.graphics.drawRect(element.bounds.left, element.bounds.top, width, height);
			shape.graphics.endFill();
		} else {
			shape.graphics.lineStyle(1, 0x8FE6FF, 0.85);
			shape.graphics.moveTo(-4, 0);
			shape.graphics.lineTo(4, 0);
			shape.graphics.moveTo(0, -4);
			shape.graphics.lineTo(0, 4);
		}
		return shape;
	}

	private function applyElementProperties(child:DisplayObject, element:DisplayElementDef):Void {
		if (element.name != null) {
			child.name = element.name;
		}

		child.visible = element.visible != false;

		if (element.matrix != null) {
			var matrix = element.matrix;
			var a = matrix.a == null ? 1 : matrix.a;
			var b = matrix.b == null ? 0 : matrix.b;
			var c = matrix.c == null ? 0 : matrix.c;
			var d = matrix.d == null ? 1 : matrix.d;
			// fl.controls and nine-slice symbols consume instance scaling as their
			// width/height rather than as a uniform transform: the control factory has
			// baked the dimensions in, and a nine-slice re-tiles to the target size.
			// Retain only rotation/skew in the matrix so the content is not also
			// distorted, and hand the scale to the nine-slice so it can lay out.
			var sliced = Std.downcast(child, NineSliceSymbol);
			if (sliced != null || Std.isOfType(child, FlButton) || Std.isOfType(child, FlTextInput) || Std.isOfType(child, FlComboBox) || Std.isOfType(child, FlTextArea)) {
				var scaleX = Math.max(0.0001, Math.sqrt(a * a + b * b));
				var scaleY = Math.max(0.0001, Math.sqrt(c * c + d * d));
				a /= scaleX;
				b /= scaleX;
				c /= scaleY;
				d /= scaleY;
				if (sliced != null) {
					sliced.applyPlacementScale(scaleX, scaleY);
				}
			}
			var localTextLeft = (element.type == "DOMStaticText" || element.type == "DOMDynamicText" || element.type == "DOMInputText") && element.left != null ? element.left : 0;
			child.transform.matrix = new Matrix(
				a,
				b,
				c,
				d,
				(matrix.tx == null ? 0 : matrix.tx) + a * localTextLeft,
				(matrix.ty == null ? 0 : matrix.ty) + b * localTextLeft
			);
		} else if ((element.type == "DOMStaticText" || element.type == "DOMDynamicText" || element.type == "DOMInputText") && element.left != null) {
			child.x = element.left;
		}

		if (element.color != null) {
			applyColorTransform(child, element.color);
		}

		child.blendMode = element.blendMode == null ? BlendMode.NORMAL : element.blendMode;
		applyFilters(child, element.filters);
	}

	// Only assigns a new ColorTransform when a channel actually differs from the
	// child's current transform. Reassigning an equal transform every frame would
	// re-trigger OpenFL's per-pixel color pass needlessly.
	private function applyColorTransform(child:DisplayObject, color:Dynamic):Void {
		var redMultiplier = color.redMultiplier == null ? 1 : color.redMultiplier;
		var greenMultiplier = color.greenMultiplier == null ? 1 : color.greenMultiplier;
		var blueMultiplier = color.blueMultiplier == null ? 1 : color.blueMultiplier;
		var alphaMultiplier = color.alphaMultiplier == null ? 1 : color.alphaMultiplier;
		var redOffset = color.redOffset == null ? 0 : color.redOffset;
		var greenOffset = color.greenOffset == null ? 0 : color.greenOffset;
		var blueOffset = color.blueOffset == null ? 0 : color.blueOffset;
		var alphaOffset = color.alphaOffset == null ? 0 : color.alphaOffset;

		var current = child.transform.colorTransform;
		if (current != null
			&& current.redMultiplier == redMultiplier
			&& current.greenMultiplier == greenMultiplier
			&& current.blueMultiplier == blueMultiplier
			&& current.alphaMultiplier == alphaMultiplier
			&& current.redOffset == redOffset
			&& current.greenOffset == greenOffset
			&& current.blueOffset == blueOffset
			&& current.alphaOffset == alphaOffset) {
			return;
		}

		child.transform.colorTransform = new ColorTransform(
			redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier,
			redOffset, greenOffset, blueOffset, alphaOffset
		);
	}

	// Assigns filters only when the def array differs from the one last applied to
	// this child. Setting `filters` invalidates OpenFL's cached filter raster, so a
	// reused clip whose keyframe is unchanged keeps its existing filter pass rather
	// than rebuilding the blur and re-uploading its texture every frame.
	private function applyFilters(child:DisplayObject, defs:Array<FilterDef>):Void {
		if (defs == null) {
			// Drop any filter left over from a previous keyframe, once.
			if (appliedFilterDefs.exists(child)) {
				child.filters = null;
				appliedFilterDefs.remove(child);
			}
			return;
		}

		if (appliedFilterDefs.get(child) == defs) {
			return;
		}

		child.filters = FilterBuilder.build(defs);
		appliedFilterDefs.set(child, defs);
	}
}
