package pr2.runtime;

import haxe.ds.ObjectMap;
import openfl.display.DisplayObject;
import openfl.display.FrameLabel;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.filters.DropShadowFilter;
import openfl.filters.GlowFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.generated.assets.AssetTypes.DisplayElementDef;
import pr2.generated.assets.AssetTypes.FilterDef;
import pr2.generated.assets.AssetTypes.FrameDef;
import pr2.generated.assets.AssetTypes.LabelDef;
import pr2.generated.assets.AssetTypes.LayerDef;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;
import pr2.generated.assets.AssetTypes.TimelineDef;

typedef RuntimeFrame = {
	var elements:Array<DisplayElementDef>;
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
		if (totalFrames > 1) {
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
		while (numChildren > 0) {
			var child = removeChildAt(numChildren - 1);
			var childClip = Std.downcast(child, PR2MovieClip);
			if (childClip != null) {
				childClip.dispose();
			}
		}
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
			frames.push({elements: []});
		}

		for (label in source.labels) {
			var frameNumber = label.frame + 1;
			labelsByName.set(label.name, frameNumber);
			currentLabels.push(new FrameLabel(label.name, frameNumber));
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
			return createComponent(element);
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
		var size = Std.int(dynamicFloat(attrs, "size", dynamicFloat(attrs, "lineHeight", 12)));
		var align = textAlign(dynamicString(attrs, "alignment", "left"));
		var format = new TextFormat(face, size, 0x000000, false, false, false, null, null, align);
		field.defaultTextFormat = format;
		field.setTextFormat(format);
		field.text = element.text == null ? "" : element.text;
		field.x = element.left == null ? 0 : element.left;
		field.y = 0;
		field.width = element.width == null ? Math.max(1, field.textWidth + 4) : element.width + 4;
		field.height = element.height == null ? Math.max(1, field.textHeight + 4) : element.height + 4;
		field.autoSize = TextFieldAutoSize.NONE;
		field.selectable = false;
		field.mouseEnabled = false;
		return field;
	}

	private function createComponent(element:DisplayElementDef):DisplayObject {
		return switch (element.libraryItemName) {
			case "Components/TextInput":
				createTextInputComponent(element);
			case "Components/TextArea":
				createTextAreaComponent(element);
			case "Components/Button":
				createButtonComponent(element);
			case "Components/ComboBox":
				createComboBoxComponent(element);
			case "Components/CheckBox":
				createCheckBoxComponent(element);
			case "Components/Slider":
				createSliderComponent(element);
			case "Components/List":
				createListComponent(element);
			case "Components/UIScrollBar":
				createScrollBarComponent(element);
			default:
				createGenericComponent(element);
		}
	}

	private function createTextInputComponent(element:DisplayElementDef):DisplayObject {
		var input = new FlTextInput(componentString(element, "text", ""));
		input.displayAsPassword = componentBool(element, "displayAsPassword", false);
		input.editable = componentBool(element, "editable", true);
		var restrict = componentString(element, "restrict", "");
		if (restrict != "") {
			input.restrict = restrict;
		}
		var maxChars = Std.parseInt(componentString(element, "maxChars", "0"));
		if (maxChars != null && maxChars > 0) {
			input.maxChars = maxChars;
		}
		var size = componentSize(element, 100, 22);
		input.setSize(size.width, size.height);
		input.enabled = componentBool(element, "enabled", true);
		return input;
	}

	private function createTextAreaComponent(element:DisplayElementDef):DisplayObject {
		var size = componentSize(element, 160, 100);
		var area = new FlTextArea(size.width, size.height);
		area.editable = componentBool(element, "editable", true);
		area.text = componentString(element, "text", "");
		area.enabled = componentBool(element, "enabled", true);
		return area;
	}

	private function createButtonComponent(element:DisplayElementDef):DisplayObject {
		var button = new FlButton(componentString(element, "label", "Button"));
		button.toggle = componentBool(element, "toggle", false);
		button.selected = componentBool(element, "selected", false);
		// `enabled` last: a disabled button must end up greyed and inert even if
		// it was authored selected.
		button.enabled = componentBool(element, "enabled", true);
		return button;
	}

	private function createComboBoxComponent(element:DisplayElementDef):DisplayObject {
		var combo = new FlComboBox(componentString(element, "prompt", ""));
		var size = componentSize(element, 100, 22);
		combo.setSize(size.width, size.height);
		var rowCount = Std.parseInt(componentString(element, "rowCount", "5"));
		if (rowCount != null && rowCount > 0) {
			combo.rowCount = rowCount;
		}
		// Authored dropdown items come through as the Flash collection serialization.
		var items = FlDataProvider.fromCollectionString(componentString(element, "dataProvider", "")).toArray();
		for (item in items) {
			combo.addItem(item);
		}
		// A prompt-less ComboBox with data selects its first row, like fl.controls.
		if (combo.length > 0 && combo.prompt == "" && combo.selectedIndex < 0) {
			combo.selectedIndex = 0;
		}
		combo.enabled = componentBool(element, "enabled", true);
		return combo;
	}

	private function createCheckBoxComponent(element:DisplayElementDef):DisplayObject {
		var checkBox = new FlCheckBox(
			componentString(element, "label", ""),
			componentBool(element, "selected", false)
		);
		checkBox.enabled = componentBool(element, "enabled", true);
		return checkBox;
	}

	private function createSliderComponent(element:DisplayElementDef):DisplayObject {
		var size = componentSize(element, 100, 16);
		var slider = new FlSlider(size.width);
		var min = Std.parseFloat(componentString(element, "minimum", "0"));
		var max = Std.parseFloat(componentString(element, "maximum", "100"));
		slider.minimum = Math.isNaN(min) ? 0 : min;
		slider.maximum = Math.isNaN(max) ? 100 : max;
		var value = Std.parseFloat(componentString(element, "value", "0"));
		slider.value = Math.isNaN(value) ? 0 : value;
		slider.enabled = componentBool(element, "enabled", true);
		return slider;
	}

	private function createListComponent(element:DisplayElementDef):DisplayObject {
		var size = componentSize(element, 150, 100);
		return new FlList(size.width, size.height);
	}

	private function createScrollBarComponent(element:DisplayElementDef):DisplayObject {
		var size = componentSize(element, FlUIScrollBar.WIDTH, 100);
		return new FlUIScrollBar(size.height);
	}

	/** Authored on-stage size from the instance bounds, with component defaults. */
	private function componentSize(element:DisplayElementDef, defaultWidth:Float, defaultHeight:Float):{width:Float, height:Float} {
		if (element.bounds != null) {
			var width = element.bounds.right - element.bounds.left;
			var height = element.bounds.bottom - element.bounds.top;
			if (width > 0 && height > 0) {
				return {width: width, height: height};
			}
		}
		return {width: defaultWidth, height: defaultHeight};
	}

	private function createGenericComponent(element:DisplayElementDef):DisplayObject {
		var label = element.name == null ? "component" : element.name;
		var holder = new Sprite();
		drawComponentBox(holder, 100, 22, 0xF2F2F2, 0x999999);
		var text = componentText(label, 100, 20, 0x555555, false, TextFormatAlign.CENTER);
		text.y = 3;
		holder.addChild(text);
		return holder;
	}

	private function drawComponentBox(target:Sprite, width:Float, height:Float, fill:Int, stroke:Int):Void {
		target.graphics.beginFill(fill);
		target.graphics.lineStyle(1, stroke);
		target.graphics.drawRect(0, 0, width, height);
		target.graphics.endFill();
	}

	private function componentText(label:String, width:Float, height:Float, color:Int, bold:Bool, align:TextFormatAlign):TextField {
		var text = new TextField();
		text.defaultTextFormat = new TextFormat("_sans", 11, color, bold, false, false, null, null, align);
		text.width = width;
		text.height = height;
		text.text = label;
		text.selectable = false;
		text.mouseEnabled = false;
		return text;
	}

	private function componentString(element:DisplayElementDef, name:String, fallback:String):String {
		var params:Dynamic = element.componentParams;
		if (params == null) {
			return fallback;
		}
		var param:Dynamic = Reflect.field(params, name);
		if (param == null || !Reflect.hasField(param, "value")) {
			return fallback;
		}
		var value:Dynamic = Reflect.field(param, "value");
		return value == null ? fallback : Std.string(value);
	}

	private function componentBool(element:DisplayElementDef, name:String, fallback:Bool):Bool {
		var params:Dynamic = element.componentParams;
		if (params == null) {
			return fallback;
		}
		var param:Dynamic = Reflect.field(params, name);
		if (param == null || !Reflect.hasField(param, "value")) {
			return fallback;
		}
		var value:Dynamic = Reflect.field(param, "value");
		if (Std.isOfType(value, Bool)) {
			return value;
		}
		var text = Std.string(value).toLowerCase();
		return text == "true" || text == "1" || text == "yes";
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
			child.transform.matrix = new Matrix(
				matrix.a == null ? 1 : matrix.a,
				matrix.b == null ? 0 : matrix.b,
				matrix.c == null ? 0 : matrix.c,
				matrix.d == null ? 1 : matrix.d,
				matrix.tx == null ? 0 : matrix.tx,
				matrix.ty == null ? 0 : matrix.ty
			);
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
		child.filters = element.filters == null ? null : buildFilters(element.filters);
	}

	private function buildFilters(defs:Array<FilterDef>):Array<BitmapFilter> {
		var result:Array<BitmapFilter> = [];
		for (def in defs) {
			var filter = buildFilter(def);
			if (filter != null) {
				result.push(filter);
			}
		}
		return result;
	}

	/**
		Maps an XFL filter def to its OpenFL equivalent. Missing attributes fall
		back to the OpenFL constructor defaults, which match the Flash authoring
		defaults the XFL omits, so the rendered result matches the original.
	**/
	private function buildFilter(def:FilterDef):Null<BitmapFilter> {
		return switch (def.type) {
			case "BlurFilter":
				new BlurFilter(
					def.blurX == null ? 4 : def.blurX,
					def.blurY == null ? 4 : def.blurY,
					def.quality == null ? 1 : def.quality
				);
			case "GlowFilter":
				new GlowFilter(
					def.color == null ? 0xFF0000 : def.color,
					def.alpha == null ? 1 : def.alpha,
					def.blurX == null ? 6 : def.blurX,
					def.blurY == null ? 6 : def.blurY,
					def.strength == null ? 2 : def.strength,
					def.quality == null ? 1 : def.quality,
					def.inner == null ? false : def.inner,
					def.knockout == null ? false : def.knockout
				);
			case "DropShadowFilter":
				new DropShadowFilter(
					def.distance == null ? 4 : def.distance,
					def.angle == null ? 45 : def.angle,
					def.color == null ? 0 : def.color,
					def.alpha == null ? 1 : def.alpha,
					def.blurX == null ? 4 : def.blurX,
					def.blurY == null ? 4 : def.blurY,
					def.strength == null ? 1 : def.strength,
					def.quality == null ? 1 : def.quality,
					def.inner == null ? false : def.inner,
					def.knockout == null ? false : def.knockout,
					def.hideObject == null ? false : def.hideObject
				);
			default:
				null;
		}
	}
}
