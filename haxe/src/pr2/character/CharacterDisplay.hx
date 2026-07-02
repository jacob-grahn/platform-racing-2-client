package pr2.character;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import pr2.character.CharacterAppearance.CharacterPartIds;
import pr2.character.CharacterRenderMode;
import pr2.runtime.PR2MovieClip;
import StringTools;

typedef CharacterColors = {
	@:optional var primary:Int;
	@:optional var secondary:Int;
}

/** Per-part tint; `secondary < 0` means the part has no epic (second) color. */
typedef PartColor = {
	var primary:Int;
	var secondary:Int;
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
	// Optional per-part overrides (hat/head/body/feet). Empty => global colors.
	private final partColors:Map<String, PartColor> = new Map();
	private var activeStateName:String = "standAnim";
	private var activeStateClip:Null<PR2MovieClip>;
	private var itemFrameName:String = "None";
	// When enabled, the active state's authored animation (e.g. the standing
	// idle) plays one timeline frame per stage frame, the way a Flash
	// `Character` MovieClip auto-plays. Off by default so gameplay/campaign can
	// keep driving frames manually in lock-step with the physics tick.
	private var idleAnimationEnabled:Bool = false;
	private var idleTicking:Bool = false;
	private var superJumpWobbleRandom:Void->Float = Math.random;

	public function new(?partIds:CharacterPartIds, ?colors:CharacterColors, ?initialRenderMode:CharacterRenderMode) {
		super();
		this.partIds = partIds == null ? {hat: 1, head: 1, body: 1, feet: 1} : partIds;
		primaryColor = colors != null && colors.primary != null ? colors.primary : 0x2E8BFF;
		secondaryColor = colors != null && colors.secondary != null ? colors.secondary : 0xFFD24A;
		renderMode = initialRenderMode == null ? CharacterRenderMode.Layered : initialRenderMode;

		// The authored CharacterGraphic keeps the frozenSolidAnim state on an
		// eye-hidden layer. PR2MovieClip renders every layer regardless of its
		// authoring visibility (matching Flash's published SWF), so the state clip
		// is instantiated like the others and setState below selects the active one
		// — previously the frozen state was missing and the character vanished while
		// frozen (e.g. during the rotate-block spin).
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

	/**
		Tint a single part kind (`hat`/`head`/`body`/`feet`) independently of the
		others. `secondary < 0` removes that part's epic colour. Used by the Account
		customize preview, where each part carries its own colour.
	**/
	public function setPartColor(kind:String, primary:Int, secondary:Int):Void {
		partColors.set(kind, {primary: primary, secondary: secondary});
		if (activeStateClip != null) {
			renderAtlasParts(activeStateClip);
		}
	}

	private function colorFor(kind:String):PartColor {
		var partOverride = partColors.get(kind);
		return partOverride != null ? partOverride : {primary: primaryColor, secondary: secondaryColor};
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

		if (activeStateName == "superJumpAnim") {
			endSuperJumpWobble();
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
				// Rewind the entered state so non-looping animations (jump,
				// super-jump charge) replay from the start instead of resuming on
				// the last frame they were left frozen on.
				stateClip.gotoAndStop(1);
				activeStateClip = stateClip;
			}
		}

		if (activeStateClip != null) {
			renderAtlasParts(activeStateClip);
		}
		applyItemFrame();
		if (activeStateName == "superJumpAnim") {
			startSuperJumpWobble();
		}
	}

	public function setItemFrameName(frameName:String):Void {
		itemFrameName = frameName == null || frameName == "" ? "None" : frameName;
		applyItemFrame();
	}

	// States whose animation plays once and holds on its final frame instead of
	// looping. The jump pose and the super-jump charge both freeze at the end in
	// the original Flash; every other state loops.
	private static final NON_LOOPING_STATES = ["jumpAnim", "superJumpAnim"];

	public function advanceOneFrame():Void {
		if (activeStateClip == null) {
			return;
		}

		if (NON_LOOPING_STATES.indexOf(activeStateName) != -1) {
			if (activeStateClip.currentFrame < activeStateClip.totalFrames) {
				activeStateClip.advanceOneFrame();
				if (activeStateClip.currentFrame >= activeStateClip.totalFrames) {
					// At the final pose, freeze the whole subtree. Nested multi-frame
					// clips (e.g. the super-jump charge aura) auto-play on their own
					// ENTER_FRAME tick, so stopping the top-level timeline alone is not
					// enough to hold the animation — they would keep looping.
					activeStateClip.stopAll();
				}
			}
		} else {
			activeStateClip.advanceOneFrame();
		}
		renderAtlasParts(activeStateClip);
		applyItemFrame();
	}

	public function getStateClip(stateName:String):Null<PR2MovieClip> {
		return getClipChild(clip, stateName);
	}

	/**
		Play the active state's authored idle animation continuously, advancing
		one timeline frame per stage frame like a Flash `Character` MovieClip.
		Ticks are bound to the stage lifecycle so the listener never leaks when
		the display is detached (customize preview, account tab, loadout/preset
		previews). Gameplay and campaign do not call this; they advance frames
		manually in step with the physics tick.
	**/
	public function enableIdleAnimation():Void {
		if (idleAnimationEnabled) {
			return;
		}
		idleAnimationEnabled = true;
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		if (stage != null) {
			startIdleTicks();
		}
	}

	private function onAddedToStage(_:Event):Void {
		startIdleTicks();
	}

	private function onRemovedFromStage(_:Event):Void {
		stopIdleTicks();
	}

	private function startIdleTicks():Void {
		if (idleTicking) {
			return;
		}
		idleTicking = true;
		addEventListener(Event.ENTER_FRAME, onIdleTick);
	}

	private function stopIdleTicks():Void {
		if (!idleTicking) {
			return;
		}
		idleTicking = false;
		removeEventListener(Event.ENTER_FRAME, onIdleTick);
	}

	private function onIdleTick(_:Event):Void {
		advanceOneFrame();
	}

	@:allow(pr2.character.CharacterDisplayTest)
	private function setSuperJumpWobbleRandomForTest(random:Void->Float):Void {
		superJumpWobbleRandom = random == null ? Math.random : random;
	}

	private function startSuperJumpWobble():Void {
		addEventListener(Event.ENTER_FRAME, superJumpWobbleTick);
	}

	private function endSuperJumpWobble():Void {
		removeEventListener(Event.ENTER_FRAME, superJumpWobbleTick);
		scaleY = 1;
	}

	private function superJumpWobbleTick(_:Event):Void {
		if (activeStateClip == null) {
			return;
		}
		var amount = activeStateClip.currentFrame / 2;
		scaleY = (superJumpWobbleRandom() * amount + (100 - amount / 2)) / 100;
	}

	private function renderAtlasPartsForAllStates():Void {
		for (name in STATE_NAMES) {
			var stateClip = getClipChild(clip, name);
			if (stateClip != null) {
				renderAtlasParts(stateClip);
			}
		}
	}

	private function applyItemFrame():Void {
		for (name in STATE_NAMES) {
			var stateClip = getClipChild(clip, name);
			if (stateClip == null) {
				continue;
			}
			var weapon = getClipChild(stateClip, "weapon");
			if (weapon != null) {
				weapon.gotoAndStop(itemFrameName);
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

		renderLayeredPartSlot(partClip, kind, layeredFrameName, yOffset, colorFor(kind));
	}

	private function renderLayeredPartSlot(partClip:PR2MovieClip, kind:String, frameName:String, yOffset:Float, color:PartColor):Void {
		ensureAtlasLayer(partClip, kind, "static", frameName, null, yOffset);
		ensureChannelAtlasLayer(partClip, kind, "colorMC", "primary", frameName, color.primary, yOffset);
		if (color.secondary >= 0) {
			ensureChannelAtlasLayer(partClip, kind, "colorMC2", "secondary", frameName, color.secondary, yOffset);
		} else {
			hideChannelAtlasLayer(partClip, kind, "colorMC2", "secondary");
		}
		removeAtlasLayer(partClip, kind, "composite");
		removeUnusedAtlasLayers(partClip, kind, ["static", "primary", "secondary"]);

		// The static line art must sit in front of the colorMC/colorMC2 fill
		// containers (which are pre-existing timeline children), matching the
		// original Flash z-order where the black outline draws over the fills.
		bringAtlasLayerToFront(partClip, kind, "static");
	}

	private function bringAtlasLayerToFront(parent:PR2MovieClip, kind:String, channel:String):Void {
		var layer = findAtlasLayer(parent, kind, channel);
		if (layer != null && layer.parent == parent) {
			parent.setChildIndex(layer, parent.numChildren - 1);
		}
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
