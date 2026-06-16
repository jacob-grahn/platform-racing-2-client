package pr2.character;

import openfl.display.Sprite;
import openfl.geom.ColorTransform;
import pr2.character.CharacterAppearance.CharacterPartIds;
import pr2.character.CharacterRenderMode;
import pr2.runtime.PR2MovieClip;
import StringTools;

typedef CharacterColors = {
	@:optional var primary:Int;
	@:optional var secondary:Int;
}

class CharacterDisplay extends Sprite {
	public static final STATE_NAMES = [
		"runAnim",
		"standAnim",
		"jumpAnim",
		"superJumpAnim",
		"bumpedAnim",
		"crouchAnim",
		"crouchWalkAnim",
		"swimAnim",
		"frozenSolidAnim"
	];

	private static inline var ATLAS_LAYER_NAME:String = "__atlasLayer";

	public final clip:PR2MovieClip;
	public var renderMode(default, null):CharacterRenderMode;

	private final atlases:Map<String, CharacterAtlasCollection> = new Map();
	private var partIds:CharacterPartIds;
	private var primaryColor:Int;
	private var secondaryColor:Int;
	private var activeStateName:String = "standAnim";
	private var activeStateClip:Null<PR2MovieClip>;

	public function new(?partIds:CharacterPartIds, ?colors:CharacterColors, ?initialRenderMode:CharacterRenderMode) {
		super();
		this.partIds = partIds == null ? {hat: 1, head: 1, body: 1, feet: 1} : partIds;
		primaryColor = colors != null && colors.primary != null ? colors.primary : 0x2E8BFF;
		secondaryColor = colors != null && colors.secondary != null ? colors.secondary : 0xFFD24A;
		renderMode = initialRenderMode == null ? CharacterRenderMode.Layered : initialRenderMode;

		clip = PR2MovieClip.fromLinkage("CharacterGraphic", {maxNestedDepth: 12});
		addChild(clip);
		clip.stopAll();

		setPartIds(this.partIds);
		setState(activeStateName);
	}

	public function setPartIds(partIds:CharacterPartIds):Void {
		this.partIds = partIds;
		CharacterAppearance.applyPartIds(clip, partIds);
		if (activeStateClip != null) {
			renderAtlasParts(activeStateClip);
		}
	}

	public function setColors(primary:Int, secondary:Int):Void {
		primaryColor = primary;
		secondaryColor = secondary;
		if (activeStateClip != null) {
			renderAtlasParts(activeStateClip);
		}
	}

	public function setRenderMode(renderMode:CharacterRenderMode):Void {
		if (this.renderMode == renderMode) {
			return;
		}

		this.renderMode = renderMode;
		if (activeStateClip != null) {
			renderAtlasParts(activeStateClip);
		}
	}

	public function setState(stateName:String):Void {
		if (activeStateName == stateName && activeStateClip != null) {
			return;
		}

		activeStateName = stateName;
		activeStateClip = null;

		for (name in STATE_NAMES) {
			var stateClip = getClipChild(clip, name);
			if (stateClip == null) {
				continue;
			}
			stateClip.visible = name == stateName;
			stateClip.stopAll();
			if (name == stateName) {
				activeStateClip = stateClip;
			}
		}

		if (activeStateClip != null) {
			renderAtlasParts(activeStateClip);
		}
	}

	public function advanceOneFrame():Void {
		if (activeStateClip != null) {
			activeStateClip.advanceOneFrame();
			renderAtlasParts(activeStateClip);
		}
	}

	public function getStateClip(stateName:String):Null<PR2MovieClip> {
		return getClipChild(clip, stateName);
	}

	private function renderAtlasPartsForAllStates():Void {
		for (name in STATE_NAMES) {
			var stateClip = getClipChild(clip, name);
			if (stateClip != null) {
				renderAtlasParts(stateClip);
			}
		}
	}

	private function renderAtlasParts(stateClip:PR2MovieClip):Void {
		renderPartSlot(stateClip, "head", "head", partIds.head);
		renderPartSlot(stateClip, "body", "body", partIds.body);
		renderPartSlot(stateClip, "foot1", "feet", partIds.feet);
		renderPartSlot(stateClip, "foot2", "feet", partIds.feet);

		var hatContainer = partIds.body == 29 ? getClipChild(stateClip, "body") : getClipChild(stateClip, "head");
		if (hatContainer != null) {
			renderPartSlot(hatContainer, "hat1", "hat", partIds.hat);
			renderPartSlot(hatContainer, "hat2", "hat", 1);
			renderPartSlot(hatContainer, "hat3", "hat", 1);
			renderPartSlot(hatContainer, "hat4", "hat", 1);
			bringHatSlotsToFront(hatContainer);
		}
	}

	private function renderPartSlot(parent:PR2MovieClip, slotName:String, kind:String, partId:Int):Void {
		var partClip = getClipChild(parent, slotName);
		if (partClip == null) {
			return;
		}

		hideExistingChildren(partClip);

		var yOffset = kind == "hat" ? -partClip.transform.matrix.ty : 0;
		var layeredFrameName = frameNameForChannels(kind, partId, ["static", "primary", "secondary"]);
		var compositeFrameName = frameNameForChannels(kind, partId, ["composite"]);

		if (renderMode == CharacterRenderMode.Composite || layeredFrameName == null) {
			renderCompositePartSlot(partClip, kind, compositeFrameName, yOffset);
			return;
		}

		renderLayeredPartSlot(partClip, kind, layeredFrameName, yOffset);
	}

	private function renderLayeredPartSlot(partClip:PR2MovieClip, kind:String, frameName:String, yOffset:Float):Void {
		ensureAtlasLayer(partClip, kind, "static", frameName, null, yOffset);
		ensureChannelAtlasLayer(partClip, kind, "colorMC", "primary", frameName, primaryColor, yOffset);
		ensureChannelAtlasLayer(partClip, kind, "colorMC2", "secondary", frameName, secondaryColor, yOffset);
		removeAtlasLayer(partClip, kind, "composite");
		removeUnusedAtlasLayers(partClip, kind, ["static", "primary", "secondary"]);
	}

	private function renderCompositePartSlot(partClip:PR2MovieClip, kind:String, frameName:Null<String>, yOffset:Float):Void {
		hideChannelAtlasLayer(partClip, kind, "colorMC", "primary");
		hideChannelAtlasLayer(partClip, kind, "colorMC2", "secondary");

		if (frameName == null) {
			removeAtlasLayers(partClip);
			return;
		}

		ensureAtlasLayer(partClip, kind, "composite", frameName, null, yOffset);
		removeAtlasLayer(partClip, kind, "static");
		removeAtlasLayer(partClip, kind, "primary");
		removeAtlasLayer(partClip, kind, "secondary");
		removeUnusedAtlasLayers(partClip, kind, ["composite"]);
	}

	private function ensureChannelAtlasLayer(
		partClip:PR2MovieClip,
		kind:String,
		containerName:String,
		channel:String,
		frameName:String,
		tint:Int,
		yOffset:Float
	):Void {
		var container = getClipChild(partClip, containerName);
		if (container == null) {
			ensureAtlasLayer(partClip, kind, channel, frameName, tint, yOffset);
			return;
		}

		container.visible = true;
		hideExistingChildren(container);
		ensureAtlasLayer(container, kind, channel, frameName, tint, yOffset);
		removeUnusedAtlasLayers(container, kind, [channel]);
	}

	private function hideChannelAtlasLayer(partClip:PR2MovieClip, kind:String, containerName:String, channel:String):Void {
		var container = getClipChild(partClip, containerName);
		if (container == null) {
			removeAtlasLayer(partClip, kind, channel);
		} else {
			container.visible = false;
			removeAtlasLayer(container, kind, channel);
		}
	}

	private function ensureAtlasLayer(partClip:PR2MovieClip, kind:String, channel:String, frameName:String, tint:Null<Int>, yOffset:Float):Void {
		var atlas = atlasForFrame(kind, channel, frameName);
		if (atlas == null) {
			removeAtlasLayer(partClip, kind, channel);
			return;
		}

		var existing = findAtlasLayer(partClip, kind, channel);
		if (existing != null && existing.atlas.assetImagePath == atlas.assetImagePath && existing.frameName == frameName) {
			existing.visible = true;
			applyTint(existing, tint);
			existing.y = yOffset;
			return;
		}

		removeAtlasLayer(partClip, kind, channel);
		var sprite = new CharacterAtlasFrameSprite(atlas, frameName);
		sprite.name = atlasLayerName(kind, channel);
		sprite.y = yOffset;
		applyTint(sprite, tint);
		partClip.addChildAt(sprite, atlasLayerCount(partClip));
	}

	private function frameNameForChannels(kind:String, partId:Int, channels:Array<String>):Null<String> {
		for (channel in channels) {
			var collection = atlasCollection(kind, channel);
			var frameName = collection.getFrameNameById(partId);
			if (frameName != null) {
				return frameName;
			}
		}
		return null;
	}

	private function atlasForFrame(kind:String, channel:String, frameName:String):Null<CharacterAtlas> {
		return atlasCollection(kind, channel).getAtlasForFrame(frameName);
	}

	private function atlasCollection(kind:String, channel:String):CharacterAtlasCollection {
		var key = kind + "/" + channel;
		var collection = atlases.get(key);
		if (collection == null) {
			collection = CharacterAtlasCollection.load(kind, channel);
			atlases.set(key, collection);
		}
		return collection;
	}

	private function removeAtlasLayers(parent:PR2MovieClip):Void {
		var index = parent.numChildren - 1;
		while (index >= 0) {
			var child = parent.getChildAt(index);
			if (isAtlasLayer(child.name)) {
				parent.removeChildAt(index);
			}
			index--;
		}
	}

	private function removeAtlasLayer(parent:PR2MovieClip, kind:String, channel:String):Void {
		var layerName = atlasLayerName(kind, channel);
		var index = parent.numChildren - 1;
		while (index >= 0) {
			if (parent.getChildAt(index).name == layerName) {
				parent.removeChildAt(index);
			}
			index--;
		}
	}

	private function removeUnusedAtlasLayers(parent:PR2MovieClip, kind:String, allowedChannels:Array<String>):Void {
		var index = parent.numChildren - 1;
		while (index >= 0) {
			var child = parent.getChildAt(index);
			if (isAtlasLayer(child.name) && !isAllowedAtlasLayer(child.name, kind, allowedChannels)) {
				parent.removeChildAt(index);
			}
			index--;
		}
	}

	private function isAllowedAtlasLayer(name:Null<String>, kind:String, allowedChannels:Array<String>):Bool {
		for (channel in allowedChannels) {
			if (name == atlasLayerName(kind, channel)) {
				return true;
			}
		}
		return false;
	}

	private function findAtlasLayer(parent:PR2MovieClip, kind:String, channel:String):Null<CharacterAtlasFrameSprite> {
		var layerName = atlasLayerName(kind, channel);
		for (i in 0...parent.numChildren) {
			var child = parent.getChildAt(i);
			if (child.name == layerName) {
				return Std.downcast(child, CharacterAtlasFrameSprite);
			}
		}
		return null;
	}

	private function hideExistingChildren(parent:PR2MovieClip):Void {
		for (i in 0...parent.numChildren) {
			var child = parent.getChildAt(i);
			if (!isAtlasLayer(child.name) && !isPositioningContainer(child.name)) {
				child.visible = false;
			}
		}
	}

	private function bringHatSlotsToFront(parent:PR2MovieClip):Void {
		for (name in ["hat4", "hat3", "hat2", "hat1"]) {
			var child = parent.getChildByTimelineName(name);
			if (child != null && child.parent == parent) {
				parent.setChildIndex(child, parent.numChildren - 1);
			}
		}
	}

	private function atlasLayerCount(parent:PR2MovieClip):Int {
		var count = 0;
		for (i in 0...parent.numChildren) {
			if (isAtlasLayer(parent.getChildAt(i).name)) {
				count++;
			}
		}
		return count;
	}

	private function atlasLayerName(kind:String, channel:String):String {
		return ATLAS_LAYER_NAME + ":" + kind + ":" + channel;
	}

	private function isAtlasLayer(name:Null<String>):Bool {
		return name != null && StringTools.startsWith(name, ATLAS_LAYER_NAME);
	}

	private function applyTint(sprite:CharacterAtlasFrameSprite, tint:Null<Int>):Void {
		sprite.transform.colorTransform = tint == null ? new ColorTransform() : colorTransformFor(tint);
	}

	private function isPositioningContainer(name:Null<String>):Bool {
		return name == "colorMC"
			|| name == "colorMC2"
			|| name == "hat1"
			|| name == "hat2"
			|| name == "hat3"
			|| name == "hat4";
	}

	private static function colorTransformFor(color:Int):ColorTransform {
		return new ColorTransform(
			((color >> 16) & 0xFF) / 255,
			((color >> 8) & 0xFF) / 255,
			(color & 0xFF) / 255,
			1
		);
	}

	private static function getClipChild(parent:PR2MovieClip, childName:String):Null<PR2MovieClip> {
		return Std.downcast(parent.getChildByTimelineName(childName), PR2MovieClip);
	}
}
