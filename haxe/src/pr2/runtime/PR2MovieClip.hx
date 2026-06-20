package pr2.runtime;

import haxe.ds.ObjectMap;
import openfl.display.DisplayObject;
import openfl.display.FrameLabel;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.generated.assets.AssetTypes.DisplayElementDef;
import pr2.generated.assets.AssetTypes.LayerDef;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;
import pr2.generated.assets.AssetTypes.TimelineDef;

typedef RuntimeFrame = {
	var elements:Array<DisplayElementDef>;
	// Parallel to `elements`: the source timeline layer index each element came
	// from. Used to reconstruct Animate mask/masked layer relationships.
	var elementLayers:Array<Int>;
}

typedef PR2MovieClipOptions = {
	@:optional var maxNestedDepth:Int;
}

class PR2MovieClip extends Sprite {
	public var symbol(default, null):SymbolAssetDef;
	public var currentFrame(default, null):Int = 1;
	public var totalFrames(default, null):Int = 1;
	public var currentLabels(default, null):Array<FrameLabel>;

	private var timeline:Null<TimelineDef>;
	private var frames:Array<RuntimeFrame> = [];
	private var labelsByName:Map<String, Int> = new Map();
	private var playing:Bool = false;
	private var maxNestedDepth:Int;
	private var nestedDepth:Int;
	private var frameScripts:Map<Int, Array<Void->Void>> = new Map();
	private var runningFrameScripts:Bool = false;
	private var isButtonSymbol:Bool = false;

	// Mask metadata keyed by source layer `index`. `maskLayers` holds layers
	// flagged `layerType: "mask"`; `maskedLayerParents` maps a masked layer to
	// the index of the mask layer that clips it (`parentLayerIndex`). Empty when
	// the timeline uses no masks, in which case rendering takes the flat path.
	private var maskLayers:Map<Int, Bool> = new Map();
	private var maskedLayerParents:Map<Int, Int> = new Map();
	private var hasMaskLayers:Bool = false;

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
		this.nestedDepth = nestedDepth;
		timeline = symbol.timelines.length > 0 ? symbol.timelines[0] : null;
		currentLabels = [];

		if (timeline != null) {
			buildTimeline(timeline);
		}

		gotoAndStop(1);
		// Button symbols use their extra frames as up/over/down/hit states, not
		// as an animation. Drive those states from the mouse like Flash does.
		isButtonSymbol = symbol.symbolType == "button";
		if (isButtonSymbol) {
			configureButtonSymbol();
		} else if (totalFrames > 1) {
			play();
		}
	}

	public function play():Void {
		if (playing) {
			return;
		}
		playing = true;
		addEventListener(Event.ENTER_FRAME, advanceFrame);
	}

	public function stop():Void {
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
		gotoFrame(frame);
		play();
	}

	public function gotoAndStop(frame:Dynamic):Void {
		gotoFrame(frame);
		stop();
	}

	public function advanceOneFrame():Void {
		var next = currentFrame + 1;
		if (next > totalFrames) {
			next = 1;
		}
		gotoFrame(next);
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
			frames.push({elements: [], elementLayers: []});
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
		if (layer.visible == false) {
			return;
		}

		for (frame in layer.frames) {
			var start = frame.index == null ? 0 : frame.index;
			var duration = frame.duration == null ? 1 : frame.duration;
			var elements = frame.elements == null ? [] : frame.elements;
			var end = Std.int(Math.min(totalFrames, start + duration));

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

	private function gotoFrame(frame:Dynamic):Void {
		var frameNumber = resolveFrame(frame);
		if (frameNumber < 1 || frameNumber > totalFrames) {
			throw 'Frame out of range for ${symbol.name}: $frameNumber';
		}

		currentFrame = frameNumber;
		renderFrame(frames[frameNumber - 1]);
		runFrameScripts(frameNumber);
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

		for (element in frame.elements) {
			var child = createDisplayObject(element, takeReusableClip(reusableClips, element));
			applyElementProperties(child, element);
			desiredChildren.push(child);
			desiredChildSet.set(child, true);
		}

		var index = numChildren - 1;
		while (index >= 0) {
			var child = getChildAt(index);
			if (!desiredChildSet.exists(child)) {
				removeChildAt(index);
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
			var clip = Std.downcast(child, PR2MovieClip);
			if (clip != null) {
				clip.dispose();
				continue;
			}
			// Mask/content holders are plain Sprites; dispose any clips nested
			// inside them so animated children stop their ENTER_FRAME ticks.
			var holder = Std.downcast(child, Sprite);
			if (holder != null) {
				disposeHolder(holder);
			}
		}
	}

	private function disposeHolder(holder:Sprite):Void {
		holder.mask = null;
		while (holder.numChildren > 0) {
			var nested = Std.downcast(holder.removeChildAt(holder.numChildren - 1), PR2MovieClip);
			if (nested != null) {
				nested.dispose();
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
		for (clips in reusableClips) {
			for (clip in clips) {
				clip.dispose();
			}
		}
	}

	private function reusableClipKey(name:String, symbolName:String):String {
		return name + "\n" + symbolName;
	}

	private function createDisplayObject(element:DisplayElementDef, reusableClip:Null<PR2MovieClip>):DisplayObject {
		if (element.type == "DOMStaticText") {
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
					return createPlaceholder(element);
				}

				var clip = reusableClip != null ? reusableClip : new PR2MovieClip(childSymbol, {maxNestedDepth: maxNestedDepth}, nestedDepth + 1);
				if (element.loop == "single frame") {
					clip.gotoAndStop((element.firstFrame == null ? 0 : element.firstFrame) + 1);
				} else if (reusableClip == null && (element.loop == "play once" || element.loop == "loop")) {
					clip.gotoAndPlay((element.firstFrame == null ? 0 : element.firstFrame) + 1);
				}
				return clip;
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
		var face = FontResolver.resolve(dynamicString(attrs, "face", "_sans"));
		// Animate sometimes omits `size`, but `bitmapSize` still carries the font
		// size in twentieths of a pixel (240 = 12px). `lineHeight` is larger than
		// the font and must not be used directly or text is oversized and clipped.
		var bitmapSize = dynamicFloatOrNull(attrs, "bitmapSize");
		var inferredSize = bitmapSize == null ? dynamicFloat(attrs, "lineHeight", 14.4) / 1.2 : bitmapSize / 20;
		var size = Std.int(dynamicFloat(attrs, "size", inferredSize));
		var align = textAlign(dynamicString(attrs, "alignment", "left"));
		// Authored fill color (e.g. the credits' "#254489"); default to black to
		// match Animate's behavior when no fillColor attribute is present.
		var color = parseTextColor(dynamicString(attrs, "fillColor", null), 0x000000);
		var format = new TextFormat(face, size, color, false, false, false, null, null, align);
		// XFL carries the inter-character spacing and inter-line leading as
		// authored; both are dropped if left unset, so apply them here. `rotation`
		// in textAttrs is anti-aliasing metadata, not a transform, so it is ignored.
		var letterSpacing = dynamicFloatOrNull(attrs, "letterSpacing");
		if (letterSpacing != null) {
			format.letterSpacing = letterSpacing;
		}
		var lineSpacing = dynamicFloatOrNull(attrs, "lineSpacing");
		if (lineSpacing != null) {
			format.leading = Math.round(lineSpacing);
		}
		var leftMargin = dynamicFloatOrNull(attrs, "leftMargin");
		if (leftMargin != null) {
			format.leftMargin = Math.round(leftMargin);
		}
		var rightMargin = dynamicFloatOrNull(attrs, "rightMargin");
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
		field.selectable = false;
		field.mouseEnabled = false;
		return field;
	}

	private function dynamicString(data:Dynamic, name:String, fallback:String):String {
		if (data == null) {
			return fallback;
		}
		var value:Dynamic = Reflect.field(data, name);
		return value == null ? fallback : Std.string(value);
	}

	private function dynamicFloat(data:Dynamic, name:String, fallback:Float):Float {
		if (data == null) {
			return fallback;
		}
		var value:Dynamic = Reflect.field(data, name);
		if (value == null) {
			return fallback;
		}
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	private function dynamicFloatOrNull(data:Dynamic, name:String):Null<Float> {
		if (data == null) {
			return null;
		}
		var value:Dynamic = Reflect.field(data, name);
		if (value == null) {
			return null;
		}
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? null : parsed;
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
			// fl.controls.Button consumes instance scaling as its width/height. The
			// factory has already baked those dimensions into the control, so retain
			// only rotation/skew here instead of also distorting the label glyphs.
			if (Std.isOfType(child, FlButton) || Std.isOfType(child, FlTextInput) || Std.isOfType(child, FlComboBox)) {
				var scaleX = Math.max(0.0001, Math.sqrt(a * a + b * b));
				var scaleY = Math.max(0.0001, Math.sqrt(c * c + d * d));
				a /= scaleX;
				b /= scaleX;
				c /= scaleY;
				d /= scaleY;
			}
			var localTextLeft = element.type == "DOMStaticText" && element.left != null ? element.left : 0;
			child.transform.matrix = new Matrix(
				a,
				b,
				c,
				d,
				(matrix.tx == null ? 0 : matrix.tx) + a * localTextLeft,
				(matrix.ty == null ? 0 : matrix.ty) + b * localTextLeft
			);
		} else if (element.type == "DOMStaticText" && element.left != null) {
			child.x = element.left;
		}

		if (element.color != null) {
			var color = element.color;
			child.transform.colorTransform = new ColorTransform(
				color.redMultiplier == null ? 1 : color.redMultiplier,
				color.greenMultiplier == null ? 1 : color.greenMultiplier,
				color.blueMultiplier == null ? 1 : color.blueMultiplier,
				color.alphaMultiplier == null ? 1 : color.alphaMultiplier,
				color.redOffset == null ? 0 : color.redOffset,
				color.greenOffset == null ? 0 : color.greenOffset,
				color.blueOffset == null ? 0 : color.blueOffset,
				color.alphaOffset == null ? 0 : color.alphaOffset
			);
		}

		// Reassign filters every frame so a reused clip drops any filter left
		// over from a previous keyframe; OpenFL only re-renders the filter pass
		// when the array reference is set.
		child.filters = element.filters == null ? null : FilterBuilder.build(element.filters);
	}
}
