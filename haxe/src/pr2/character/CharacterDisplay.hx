package pr2.character;

import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.character.CharacterAppearance.CharacterPartIds;
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
	private static inline var SNAKE_ITEM_NAME:String = "__snakeHeldItem";
	private static inline var VANISH_ASSET:String = "assets/blocks/vanish.png";

	public final clip:PR2MovieClip;

	private var partIds:CharacterPartIds;
	private var primaryColor:Int;
	private var secondaryColor:Int;
	// Optional per-part overrides (hat/head/body/feet). Empty => global colors.
	private final partColors:Map<String, PartColor> = new Map();
	private var hatSlotColors:Array<PartColor> = [];
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

	public function new(?partIds:CharacterPartIds, ?colors:CharacterColors) {
		super();
		this.partIds = partIds == null ? {hat: 1, head: 1, body: 1, feet: 1} : partIds;
		primaryColor = colors != null && colors.primary != null ? colors.primary : 0x2E8BFF;
		secondaryColor = colors != null && colors.secondary != null ? colors.secondary : 0xFFD24A;

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
		requestPartAtlases();
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

	public function setHatSlotColors(colors:Array<PartColor>):Void {
		hatSlotColors = colors == null ? [] : [for (color in colors) {primary: color.primary, secondary: color.secondary}];
		if (activeStateClip != null) {
			renderAtlasParts(activeStateClip);
		}
	}

	private function colorFor(kind:String):PartColor {
		var partOverride = partColors.get(kind);
		return partOverride != null ? partOverride : {primary: primaryColor, secondary: secondaryColor};
	}

	private function requestPartAtlases():Void {
		requestPartAtlas("head", partIds.head);
		requestPartAtlas("body", partIds.body);
		requestPartAtlas("feet", partIds.feet);

		var hats = partIds.hats != null ? partIds.hats : [partIds.hat, 1, 1, 1];
		for (hatId in hats) {
			requestPartAtlas("hat", hatId);
		}
	}

	private function requestPartAtlas(kind:String, partId:Int):Void {
		CharacterPartSetLoader.requestPart(kind, partId, function():Void {
			if (activeStateClip != null) {
				renderAtlasParts(activeStateClip);
			}
		});
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

	private function applyItemFrame():Void {
		for (name in STATE_NAMES) {
			var stateClip = getClipChild(clip, name);
			if (stateClip == null) {
				continue;
			}
			var weapon = getClipChild(stateClip, "weapon");
			if (weapon != null) {
				if (itemFrameName == "Snake") {
					weapon.gotoAndStop("None");
					var existing = weapon.getChildByName(SNAKE_ITEM_NAME);
					if (existing == null) weapon.addChild(createSnakeHeldItem());
				} else {
					weapon.gotoAndStop(itemFrameName);
					var existing = weapon.getChildByName(SNAKE_ITEM_NAME);
					if (existing != null) weapon.removeChild(existing);
				}
			}
		}
	}

	private function createSnakeHeldItem():Sprite {
		var item = new Sprite();
		item.name = SNAKE_ITEM_NAME;
		// The synthetic held Snake is authored at 22px. Present it at 2x while
		// keeping the same hand-centered registration point.
		item.x = -22;
		item.y = -22;
		item.scaleX = 2;
		item.scaleY = 2;
		if (Assets.exists(VANISH_ASSET, AssetType.IMAGE)) {
			var bitmap = new Bitmap(Assets.getBitmapData(VANISH_ASSET));
			bitmap.width = 22;
			bitmap.height = 22;
			item.addChild(bitmap);
		} else {
			var fallback = new Shape();
			fallback.graphics.beginFill(0x38B84A);
			fallback.graphics.drawRect(0, 0, 22, 22);
			fallback.graphics.endFill();
			item.addChild(fallback);
		}
		var eyes = new Shape();
		eyes.graphics.beginFill(0xFFFFFF);
		eyes.graphics.drawCircle(7, 8, 3);
		eyes.graphics.drawCircle(15, 8, 3);
		eyes.graphics.endFill();
		eyes.graphics.beginFill(0x102010);
		eyes.graphics.drawCircle(7, 8, 1.5);
		eyes.graphics.drawCircle(15, 8, 1.5);
		eyes.graphics.endFill();
		item.addChild(eyes);
		return item;
	}

	private function renderAtlasParts(stateClip:PR2MovieClip):Void {
		renderPartSlot(stateClip, "head", "head", partIds.head);
		renderPartSlot(stateClip, "body", "body", partIds.body);
		renderPartSlot(stateClip, "foot1", "feet", partIds.feet);
		renderPartSlot(stateClip, "foot2", "feet", partIds.feet);

		var hatContainer = partIds.body == 29 ? getClipChild(stateClip, "body") : getClipChild(stateClip, "head");
		if (hatContainer != null) {
			var hats = partIds.hats != null ? partIds.hats : [partIds.hat, 1, 1, 1];
			for (slot in 0...4) {
				renderPartSlot(hatContainer, "hat" + (slot + 1), "hat", hats.length > slot ? hats[slot] : 1, colorForHatSlot(slot));
			}
			bringHatSlotsToFront(hatContainer);
		}
	}

	private function renderPartSlot(parent:PR2MovieClip, slotName:String, kind:String, partId:Int, ?slotColor:PartColor):Void {
		var partClip = getClipChild(parent, slotName);
		if (partClip == null) {
			return;
		}

		hideExistingChildren(partClip);

		var yOffset = kind == "hat" ? -partClip.transform.matrix.ty : 0;
		var layeredFrameName = frameNameForChannel(kind, partId, "static");

		if (layeredFrameName == null) {
			renderWireframePartSlot(partClip, kind, yOffset);
			return;
		}

		renderLayeredPartSlot(partClip, kind, partId, yOffset, slotColor != null ? slotColor : colorFor(kind));
	}

	private function colorForHatSlot(slot:Int):PartColor {
		return hatSlotColors.length > slot ? hatSlotColors[slot] : colorFor("hat");
	}

	private function renderLayeredPartSlot(partClip:PR2MovieClip, kind:String, partId:Int, yOffset:Float, color:PartColor):Void {
		var staticFrameName = frameNameForChannel(kind, partId, "static");
		var primaryFrameName = frameNameForChannel(kind, partId, "primary");
		var secondaryFrameName = frameNameForChannel(kind, partId, "secondary");

		if (staticFrameName == null || primaryFrameName == null) {
			renderWireframePartSlot(partClip, kind, yOffset);
			return;
		}

		ensureAtlasLayer(partClip, kind, "static", staticFrameName, null, yOffset);
		ensureChannelAtlasLayer(partClip, kind, "colorMC", "primary", primaryFrameName, color.primary, yOffset);
		if (color.secondary >= 0) {
			if (secondaryFrameName != null) {
				ensureChannelAtlasLayer(partClip, kind, "colorMC2", "secondary", secondaryFrameName, color.secondary, yOffset);
			} else {
				hideChannelAtlasLayer(partClip, kind, "colorMC2", "secondary");
			}
		} else {
			hideChannelAtlasLayer(partClip, kind, "colorMC2", "secondary");
		}
		removeAtlasLayer(partClip, kind, "wireframe");
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

	private function renderWireframePartSlot(partClip:PR2MovieClip, kind:String, yOffset:Float):Void {
		hideChannelAtlasLayer(partClip, kind, "colorMC", "primary");
		hideChannelAtlasLayer(partClip, kind, "colorMC2", "secondary");
		removeAtlasLayers(partClip);
		ensureWireframeLayer(partClip, kind, yOffset);
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

	private function ensureWireframeLayer(partClip:PR2MovieClip, kind:String, yOffset:Float):Void {
		var existing = findWireframeLayer(partClip, kind);
		if (existing != null) {
			existing.visible = true;
			existing.y = yOffset;
			return;
		}

		var sprite = new Sprite();
		sprite.name = atlasLayerName(kind, "wireframe");
		sprite.y = yOffset;
		drawWireframe(sprite, kind);
		partClip.addChildAt(sprite, atlasLayerCount(partClip));
	}

	private function drawWireframe(sprite:Sprite, kind:String):Void {
		var width = switch (kind) {
			case "hat": 34;
			case "head": 46;
			case "body": 52;
			case "feet": 34;
			default: 40;
		}
		var height = switch (kind) {
			case "hat": 20;
			case "head": 46;
			case "body": 58;
			case "feet": 18;
			default: 40;
		}
		sprite.graphics.lineStyle(1, 0x00FFFF, 0.75);
		sprite.graphics.beginFill(0x00FFFF, 0.08);
		sprite.graphics.drawRect(-width / 2, -height / 2, width, height);
		sprite.graphics.endFill();
		sprite.graphics.moveTo(-width / 2, -height / 2);
		sprite.graphics.lineTo(width / 2, height / 2);
		sprite.graphics.moveTo(width / 2, -height / 2);
		sprite.graphics.lineTo(-width / 2, height / 2);
	}

	private function frameNameForChannel(kind:String, partId:Int, channel:String):Null<String> {
		var atlas = CharacterPartSetLoader.atlasForPart(kind, partId);
		if (atlas == null) {
			return null;
		}
		return atlas.getFrameName(kind, channel, partId);
	}

	private function atlasForFrame(kind:String, channel:String, frameName:String):Null<CharacterAtlas> {
		var partId = switch (kind) {
			case "head": partIds.head;
			case "body": partIds.body;
			case "feet": partIds.feet;
			case "hat": 1;
			default: 1;
		}
		var atlas = CharacterPartSetLoader.atlasForPart(kind, partId);
		if (atlas != null && atlas.getFrame(frameName) != null) {
			return atlas;
		}
		return null;
	}

	// Walk children back-to-front removing every atlas layer for which `keep`
	// returns false. Non-atlas children are never touched. All the atlas-layer
	// removers below are thin predicates over this one traversal.
	private function removeAtlasLayersWhere(parent:PR2MovieClip, keep:Null<String>->Bool):Void {
		var index = parent.numChildren - 1;
		while (index >= 0) {
			var child = parent.getChildAt(index);
			if (isAtlasLayer(child.name) && !keep(child.name)) {
				parent.removeChildAt(index);
			}
			index--;
		}
	}

	private function removeAtlasLayers(parent:PR2MovieClip):Void {
		removeAtlasLayersWhere(parent, _ -> false);
	}

	private function removeAtlasLayer(parent:PR2MovieClip, kind:String, channel:String):Void {
		var layerName = atlasLayerName(kind, channel);
		removeAtlasLayersWhere(parent, name -> name != layerName);
	}

	private function removeUnusedAtlasLayers(parent:PR2MovieClip, kind:String, allowedChannels:Array<String>):Void {
		removeAtlasLayersWhere(parent, name -> isAllowedAtlasLayer(name, kind, allowedChannels));
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

	private function findWireframeLayer(parent:PR2MovieClip, kind:String):Null<Sprite> {
		var layerName = atlasLayerName(kind, "wireframe");
		for (i in 0...parent.numChildren) {
			var child = parent.getChildAt(i);
			if (child.name == layerName) {
				return Std.downcast(child, Sprite);
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
		for (slot in 0...4) {
			var name = "hat" + (4 - slot);
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
			|| isHatSlotName(name);
	}

	private function isHatSlotName(name:Null<String>):Bool {
		if (name == null || !StringTools.startsWith(name, "hat")) {
			return false;
		}
		var slot = Std.parseInt(name.substr(3));
		return slot != null && slot >= 1 && slot <= 4 && name == "hat" + slot;
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
