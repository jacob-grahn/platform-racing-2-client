package pr2.character;

import haxe.ds.StringMap;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.PixelSnapping;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.BlurFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.Constants;
import pr2.character.CharacterRig.CharacterRigDefinition;
import pr2.character.CharacterRig.RigAnimation;
import pr2.character.CharacterRig.RigHeldItem;
import pr2.character.CharacterRig.RigPartChannels;
import pr2.character.CharacterRig.RigPartChannelAnimation;
import pr2.character.CharacterRig.RigPartKind;
import pr2.character.CharacterRig.RigSlot;
import pr2.runtime.ExplicitBitmapCache;
import pr2.runtime.SvgAsset;

typedef CharacterViewPartIds = {
	var head:Int;
	var body:Int;
	var feet:Int;
}

typedef CharacterViewPartColor = {
	var primary:Int;
	var secondary:Int;
}

typedef CharacterViewPartColors = {
	var head:CharacterViewPartColor;
	var body:CharacterViewPartColor;
	var feet:CharacterViewPartColor;
}

/**
	Native deterministic renderer for every authored CharacterGraphic state.

	Animation advances only through `advanceOneFrame`; it has no ENTER_FRAME
	listener and therefore remains synchronized with the gameplay clock.
**/
@:access(openfl.display.Graphics)
class CharacterView extends Sprite {
	public static final STATE_NAMES = ["run", "stand", "jump", "superJump", "bumped", "crouch", "crouchWalk", "swim", "frozen"];
	private static inline var VANISH_ASSET:String = "assets/blocks/vanish.png";
	private static inline var PART_CACHE_PADDING:Int = 2;
	private static final BITMAP_CACHE_SLOTS:Array<String> = ["head", "body", "frontFoot", "backFoot"];

	public var currentFrame(default, null):Int = 1;
	public var currentState(default, null):String = "stand";
	public var frameCount(default, null):Int = 0;
	public var frameRate(default, null):Int = 27;
	public var primaryColor(default, null):Int;
	public var secondaryColor(default, null):Int;
	public var endSignal(default, null):Null<String>;
	public final heldItemSocket:Sprite;
	public final hatSocket:Sprite;
	public final hatSlots:Array<Sprite> = [];
	public var itemFrameName(default, null):String = "None";
	public var itemActionFrame(default, null):Int = 1;
	public var itemActionPlaying(default, null):Bool = false;
	public var jetActive(default, null):Bool = false;
	public var jetFireScale(default, null):Float = 1;
	public var jetFireAlpha(default, null):Float = 1;
	public var bodyChannelAnimationFrame(default, null):Int = 1;

	private final rig:CharacterRigDefinition;
	private final rigRoot:Sprite;
	private var animation:RigAnimation;
	private var completeDispatched:Bool = false;
	private final slots:StringMap<Sprite> = new StringMap();
	private final slotKinds:StringMap<String> = new StringMap();
	private var partIds:CharacterViewPartIds;
	private final partColors:StringMap<CharacterViewPartColor> = new StringMap();
	private var hatIds:Array<Int>;
	private var hatColors:Array<CharacterViewPartColor> = [];
	private var activeItem:Null<RigHeldItem>;
	private var idleAnimationEnabled:Bool = false;
	private var idleTicking:Bool = false;
	private var superJumpWobbleRandom:Void->Float = Math.random;
	private var partBitmapCacheEnabled:Bool = #if pr2_explicit_character_part_bitmap_cache true #else false #end;
	private final partBitmapCaches:StringMap<ExplicitBitmapCache> = new StringMap();
	private final partBitmapCacheScales:StringMap<Float> = new StringMap();
	@:allow(pr2.character.CharacterViewTest)
	private final hatAnimationFrames:Array<Int> = [1, 1, 1, 1];
	private final hatOverlayFrameData:Array<Null<Array<BitmapData>>> = [null, null, null, null];
	private final hatOverlayBitmaps:Array<Null<Bitmap>> = [null, null, null, null];
	private final hatOverlayRasterScales:Array<Float> = [0, 0, 0, 0];

	public function new(
		primaryColor:Int = 0x2E8BFF,
		secondaryColor:Int = 0xFFD24A,
		?rig:CharacterRigDefinition,
		state:String = "stand",
		?partIds:CharacterViewPartIds,
		?hatIds:Array<Int>
	) {
		super();
		mouseEnabled = false;
		mouseChildren = false;
		this.primaryColor = primaryColor;
		this.secondaryColor = secondaryColor;
		this.rig = rig == null ? CharacterRig.loadClassic() : rig;
		this.partIds = partIds == null ? {head: 1, body: 1, feet: 1} : copyPartIds(partIds);
		this.hatIds = hatIds == null ? [1, 1, 1, 1] : hatIds.copy();
		for (kind in ["head", "body", "feet"]) partColors.set(kind, {primary: primaryColor, secondary: secondaryColor});
		for (_ in 0...4) hatColors.push({primary: primaryColor, secondary: secondaryColor});
		validatePartIds(this.partIds);
		validateHatIds(this.hatIds);

		rigRoot = new Sprite();
		rigRoot.name = "rigRoot";
		addChild(rigRoot);
		createAllSlots();
		heldItemSocket = requireSlot("heldItem");
		var head = requireSlot("head");
		hatSocket = new Sprite();
		hatSocket.name = "hatSocket";
		head.addChild(hatSocket);
		createHatSlots();
		setColors(primaryColor, secondaryColor);
		setState(state);
		#if (html5 && pr2_explicit_character_part_bitmap_cache)
		addEventListener(Event.EXIT_FRAME, refreshPartVectorCaches);
		#end
	}

	#if (html5 && pr2_explicit_character_part_bitmap_cache)
	/**
		Rasterize each part in its own local coordinate system at its final browser
		scale. The explicit bitmap is positioned at the source's exact local bounds,
		so animated slot transforms and registration points remain untouched.
	**/
	private function refreshPartVectorCaches(_:Event):Void {
		if (!partBitmapCacheEnabled) return;
		for (slotName in BITMAP_CACHE_SLOTS) {
			var part = requireSlot(slotName);
			var artwork = Std.downcast(part.getChildByName("artwork"), Sprite);
			if (artwork == null) continue;
			refreshExplicitBitmapCache(slotName, artwork);
		}
		for (index in 0...hatSlots.length) {
			if (!hatSlots[index].visible) continue;
			var artwork = Std.downcast(hatSlots[index].getChildByName("artwork"), Sprite);
			if (artwork != null) refreshExplicitBitmapCache(hatCacheKey(index), artwork);
			refreshHatOverlayCache(index);
		}
	}

	private function refreshExplicitBitmapCache(cacheKey:String, artwork:Sprite):Void {
		var effectiveScale = currentPartRasterScale(artwork);
		if (effectiveScale <= 0) return;
		var existing = partBitmapCaches.get(cacheKey);
		var cachedScale = partBitmapCacheScales.get(cacheKey);
		if (existing != null && existing.target == artwork && cachedScale != null && effectiveScale <= cachedScale + 0.0001) return;
		disposePartBitmapCache(cacheKey);
		invalidateVectorCache(artwork);
		var cache = ExplicitBitmapCache.attach(artwork, {
			scale: effectiveScale,
			padding: PART_CACHE_PADDING,
			bitmapName: '__characterPartCache_$cacheKey'
		});
		if (!cache.valid) {
			cache.dispose();
			return;
		}
		partBitmapCaches.set(cacheKey, cache);
		partBitmapCacheScales.set(cacheKey, effectiveScale);
	}

	private function refreshHatOverlayCache(index:Int):Void {
		var channels = partVariant("hat", hatIds[index]);
		var animation = channels.overlayAnimation;
		if (animation == null) return;
		var overlay = Std.downcast(hatSlots[index].getChildByName("animatedOverlay"), Sprite);
		if (overlay == null) return;
		var effectiveScale = currentPartRasterScale(overlay);
		if (effectiveScale <= 0) return;
		var currentFrames = hatOverlayFrameData[index];
		if (currentFrames != null && effectiveScale <= hatOverlayRasterScales[index] + 0.0001) return;

		disposeHatOverlayCache(index, false);
		var frameArt:Array<DisplayObject> = [];
		var union:Null<Rectangle> = null;
		for (assetPath in animation.frames) {
			var frame = SvgAsset.create(assetPath);
			invalidateVectorCache(frame);
			overlay.addChild(frame);
			var bounds = frame.getBounds(overlay);
			union = union == null ? bounds.clone() : union.union(bounds);
			overlay.removeChild(frame);
			frameArt.push(frame);
		}
		if (union == null || union.width <= 0 || union.height <= 0) return;

		var pixelWidth = Std.int(Math.ceil(union.width * effectiveScale)) + PART_CACHE_PADDING * 2;
		var pixelHeight = Std.int(Math.ceil(union.height * effectiveScale)) + PART_CACHE_PADDING * 2;
		var renderedFrames:Array<BitmapData> = [];
		for (frame in frameArt) {
			var data = new BitmapData(pixelWidth, pixelHeight, true, 0);
			var drawMatrix = new Matrix(
				effectiveScale,
				0,
				0,
				effectiveScale,
				-union.x * effectiveScale + PART_CACHE_PADDING,
				-union.y * effectiveScale + PART_CACHE_PADDING
			);
			data.draw(frame, drawMatrix, null, null, null, true);
			renderedFrames.push(data);
		}
		while (overlay.numChildren > 0) overlay.removeChildAt(0);
		var bitmap = new Bitmap(renderedFrames[hatAnimationFrames[index] - 1], PixelSnapping.NEVER, true);
		bitmap.name = "__animatedHatOverlayCache";
		bitmap.scaleX = bitmap.scaleY = 1 / effectiveScale;
		bitmap.x = union.x - PART_CACHE_PADDING / effectiveScale;
		bitmap.y = union.y - PART_CACHE_PADDING / effectiveScale;
		overlay.addChild(bitmap);
		hatOverlayFrameData[index] = renderedFrames;
		hatOverlayBitmaps[index] = bitmap;
		hatOverlayRasterScales[index] = effectiveScale;
	}

	private function currentPartRasterScale(artwork:Sprite):Float {
		if (stage == null || stage.window == null) return 0;
		var matrix = artwork.transform.concatenatedMatrix;
		var artworkScaleX = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b);
		var artworkScaleY = Math.sqrt(matrix.c * matrix.c + matrix.d * matrix.d);
		var pixelWidth = stage.window.width * stage.window.scale;
		var pixelHeight = stage.window.height * stage.window.scale;
		var stageScale = Math.min(pixelWidth / Constants.STAGE_WIDTH, pixelHeight / Constants.STAGE_HEIGHT);
		return Math.max(artworkScaleX, artworkScaleY) * stageScale;
	}

	private static function invalidateVectorCache(object:DisplayObject):Void {
		var shape = Std.downcast(object, Shape);
		if (shape != null) shape.graphics.__dirty = true;
		var container = Std.downcast(object, DisplayObjectContainer);
		if (container == null) return;
		for (index in 0...container.numChildren) invalidateVectorCache(container.getChildAt(index));
	}
	#end

	private function disposePartBitmapCache(slotName:String):Void {
		var cache = partBitmapCaches.get(slotName);
		if (cache != null) cache.dispose();
		partBitmapCaches.remove(slotName);
		partBitmapCacheScales.remove(slotName);
	}

	private function disposePartBitmapCaches(?kind:String):Void {
		for (slotName in BITMAP_CACHE_SLOTS) {
			if (kind != null && slotKinds.get(slotName) != kind) continue;
			disposePartBitmapCache(slotName);
		}
	}

	private static inline function hatCacheKey(index:Int):String return 'hat${index + 1}';

	private function disposeHatBitmapCache(index:Int, restoreOverlay:Bool = true):Void {
		disposePartBitmapCache(hatCacheKey(index));
		disposeHatOverlayCache(index, restoreOverlay);
	}

	private function disposeHatBitmapCaches(restoreOverlay:Bool = true):Void {
		for (index in 0...hatSlots.length) disposeHatBitmapCache(index, restoreOverlay);
	}

	private function disposeHatOverlayCache(index:Int, restoreVector:Bool = true):Void {
		var bitmap = hatOverlayBitmaps[index];
		if (bitmap != null && bitmap.parent != null) bitmap.parent.removeChild(bitmap);
		var frames = hatOverlayFrameData[index];
		if (frames != null) for (data in frames) data.dispose();
		hatOverlayFrameData[index] = null;
		hatOverlayBitmaps[index] = null;
		hatOverlayRasterScales[index] = 0;
		if (restoreVector && index < hatSlots.length) renderHatOverlayFrame(index);
	}

	private function createAllSlots():Void {
		var definitions = new StringMap<RigSlot>();
		for (candidate in rig.animations) {
			for (slot in candidate.slots) if (!definitions.exists(slot.name)) definitions.set(slot.name, slot);
		}
		var ordered = [for (slot in definitions) slot];
		ordered.sort(function(left:RigSlot, right:RigSlot):Int return left.drawOrder - right.drawOrder);
		for (slot in ordered) createSlot(slot);
	}

	private function createSlot(slot:RigSlot):Void {
		var container = new Sprite();
		container.name = slot.name;
		slots.set(slot.name, container);
		rigRoot.addChild(container);
		if (slot.asset != null) {
			var art = SvgAsset.create(slot.asset);
			art.name = "artwork";
			container.addChild(art);
			return;
		}
		if (slot.partKind == null) return;
		slotKinds.set(slot.name, slot.partKind);
		createPartArtwork(container, slot.partKind);
	}

	private function createPartArtwork(container:Sprite, kind:String):Void {
		var previous = container.getChildByName("artwork");
		if (previous != null) container.removeChild(previous);
		var artwork = new Sprite();
		artwork.name = "artwork";
		container.addChild(artwork);
		container.setChildIndex(artwork, 0);
		if (isEmptyPart(kind, partId(kind))) return;
		var channels = partVariant(kind, partId(kind));
		var primary = SvgAsset.create(partChannelAsset(channels, "primary"));
		primary.name = "primary";
		artwork.addChild(primary);
		var fixed = SvgAsset.create(partChannelAsset(channels, "static"));
		fixed.name = "static";
		artwork.addChild(fixed);
		var secondary = SvgAsset.create(partChannelAsset(channels, "secondary"));
		secondary.name = "secondary";
		artwork.addChild(secondary);
		applyPartColorToArtwork(kind, artwork);
	}

	private function createHatSlots():Void {
		for (index in 0...4) {
			var slot = new Sprite();
			slot.name = 'hat${index + 1}';
			hatSocket.addChild(slot);
			hatSlots.push(slot);
			createHatArtwork(index);
		}
		applyHatAttachments();
	}

	private function createHatArtwork(index:Int):Void {
		var slot = hatSlots[index];
		disposeHatBitmapCache(index, false);
		while (slot.numChildren > 0) slot.removeChildAt(0);
		hatAnimationFrames[index] = 1;
		slot.visible = hatIds[index] != 1;
		if (!slot.visible) return;
		var channels = partVariant("hat", hatIds[index]);
		var artwork = new Sprite();
		artwork.name = "artwork";
		slot.addChild(artwork);
		var primary = SvgAsset.create(channels.primary);
		primary.name = "primary";
		artwork.addChild(primary);
		var fixed = SvgAsset.create(channels.fixed);
		fixed.name = "static";
		artwork.addChild(fixed);
		var secondary = SvgAsset.create(channels.secondary);
		secondary.name = "secondary";
		artwork.addChild(secondary);
		applyHatColorToArtwork(index, artwork);
		if (channels.overlayAnimation != null) {
			var overlay = new Sprite();
			overlay.name = "animatedOverlay";
			slot.addChild(overlay);
			renderHatOverlayFrame(index);
		}
	}

	private function renderHatOverlayFrame(index:Int):Void {
		if (index >= hatSlots.length || !hatSlots[index].visible) return;
		var channels = partVariant("hat", hatIds[index]);
		var animation = channels.overlayAnimation;
		if (animation == null) return;
		var overlay = Std.downcast(hatSlots[index].getChildByName("animatedOverlay"), Sprite);
		if (overlay == null) return;
		var cachedFrames = hatOverlayFrameData[index];
		var bitmap = hatOverlayBitmaps[index];
		if (cachedFrames != null && bitmap != null) {
			bitmap.bitmapData = cachedFrames[hatAnimationFrames[index] - 1];
			return;
		}
		while (overlay.numChildren > 0) overlay.removeChildAt(0);
		var frame = SvgAsset.create(animation.frames[hatAnimationFrames[index] - 1]);
		frame.name = "vectorFrame";
		overlay.addChild(frame);
	}

	private function advanceHatAnimations():Void {
		for (index in 0...hatSlots.length) {
			var animation = partVariant("hat", hatIds[index]).overlayAnimation;
			if (animation == null) continue;
			hatAnimationFrames[index] = hatAnimationFrames[index] >= animation.frames.length ? 1 : hatAnimationFrames[index] + 1;
			renderHatOverlayFrame(index);
		}
	}

	public function setState(state:String):Void {
		state = normalizeState(state);
		itemActionFrame = 1;
		itemActionPlaying = false;
		renderHeldItem();
		if (currentState == "superJump" && state != "superJump") scaleY = 1;
		animation = CharacterRig.animation(rig, state);
		currentState = state;
		currentFrame = 1;
		frameCount = animation.frameCount;
		frameRate = animation.frameRate;
		endSignal = null;
		completeDispatched = false;
		var root = animation.root;
		rigRoot.transform.matrix = new Matrix(root.a, root.b, root.c, root.d, root.tx, root.ty);
		for (target in slots) target.visible = false;
		var ordered = animation.slots.copy();
		ordered.sort(function(left:RigSlot, right:RigSlot):Int return left.drawOrder - right.drawOrder);
		for (index in 0...ordered.length) {
			var target = requireSlot(ordered[index].name);
			target.visible = true;
			rigRoot.setChildIndex(target, index);
		}
		applyAppearanceHierarchy();
		applyFrame();
	}

	public function isState(state:String):Bool {
		return currentState == normalizeState(state);
	}

	public function setColors(primary:Int, secondary:Int):Void {
		disposePartBitmapCaches();
		disposeHatBitmapCaches();
		primaryColor = primary;
		secondaryColor = secondary;
		for (kind in ["head", "body", "feet"]) partColors.set(kind, {primary: primary, secondary: secondary});
		for (index in 0...4) hatColors[index] = {primary: primary, secondary: secondary};
		applyAllPartColors();
		applyAllHatColors();
	}

	public function setPartIds(ids:CharacterViewPartIds):Void {
		validatePartIds(ids);
		disposePartBitmapCaches();
		if (partIds.body != ids.body) bodyChannelAnimationFrame = 1;
		partIds = copyPartIds(ids);
		for (slotName in slots.keys()) {
			var kind = slotKinds.get(slotName);
			if (kind != null) createPartArtwork(requireSlot(slotName), kind);
		}
		applyAppearanceHierarchy();
	}

	public function setPartId(kind:String, id:Int):Void {
		validatePartId(kind, id);
		var ids = copyPartIds(partIds);
		switch (kind) {
			case "head": ids.head = id;
			case "body": ids.body = id;
			case "feet": ids.feet = id;
			default: throw 'Unsupported character part kind $kind';
		}
		setPartIds(ids);
	}

	public function partId(kind:String):Int {
		return switch (kind) {
			case "head": partIds.head;
			case "body": partIds.body;
			case "feet": partIds.feet;
			default: throw 'Unsupported character part kind $kind';
		}
	}

	public function setPartColor(kind:String, primary:Int, secondary:Int):Void {
		partKind(kind);
		disposePartBitmapCaches(kind);
		partColors.set(kind, {primary: primary, secondary: secondary});
		applyPartColor(kind);
	}

	public function setHatIds(ids:Array<Int>):Void {
		validateHatIds(ids);
		disposeHatBitmapCaches(false);
		hatIds = ids.copy();
		for (index in 0...4) createHatArtwork(index);
		applyAppearanceHierarchy();
	}

	public function hatId(index:Int):Int {
		validateHatSlot(index);
		return hatIds[index];
	}

	public function hatSlot(index:Int):Sprite {
		validateHatSlot(index);
		return hatSlots[index];
	}

	public function setHatSlotColor(index:Int, primary:Int, secondary:Int):Void {
		validateHatSlot(index);
		disposePartBitmapCache(hatCacheKey(index));
		hatColors[index] = {primary: primary, secondary: secondary};
		applyHatColor(index);
	}

	public function setHatSlotColors(colors:Array<CharacterViewPartColor>):Void {
		if (colors == null || colors.length != 4) throw "Native character requires four hat-slot colors";
		for (index in 0...4) disposePartBitmapCache(hatCacheKey(index));
		for (index in 0...4) hatColors[index] = {primary: colors[index].primary, secondary: colors[index].secondary};
		applyAllHatColors();
	}

	public function setAppearance(ids:CharacterViewPartIds, colors:CharacterViewPartColors):Void {
		setPartIds(ids);
		setPartColor("head", colors.head.primary, colors.head.secondary);
		setPartColor("body", colors.body.primary, colors.body.secondary);
		setPartColor("feet", colors.feet.primary, colors.feet.secondary);
	}

	public function advanceOneFrame():Void {
		if (currentFrame < frameCount) {
			currentFrame++;
			if (currentFrame == frameCount) signalLastFrame();
		} else if (animation.endBehavior == "loop") {
			currentFrame = 1;
		}
		applyFrame();
		advanceItemAction();
		advancePartChannelAnimations();
		advanceHatAnimations();
		if (currentState == "superJump") {
			var amount = currentFrame / 2;
			scaleY = (superJumpWobbleRandom() * amount + (100 - amount / 2)) / 100;
		}
	}

	private function advancePartChannelAnimations():Void {
		if (isEmptyPart("body", partIds.body)) return;
		var channels = partVariant("body", partIds.body);
		if (channels.channelAnimations == null || channels.channelAnimations.length == 0) return;
		var frameCount = channels.channelAnimations[0].frames.length;
		bodyChannelAnimationFrame = bodyChannelAnimationFrame >= frameCount ? 1 : bodyChannelAnimationFrame + 1;
		for (slotName in slots.keys()) {
			if (slotKinds.get(slotName) != "body") continue;
			disposePartBitmapCache(slotName);
			var artwork = Std.downcast(requireSlot(slotName).getChildByName("artwork"), Sprite);
			if (artwork == null) continue;
			for (animation in channels.channelAnimations) replaceAnimatedPartChannel(artwork, animation);
			applyPartColorToArtwork("body", artwork);
		}
	}

	private function replaceAnimatedPartChannel(artwork:Sprite, animation:RigPartChannelAnimation):Void {
		var previous = artwork.getChildByName(animation.channel);
		if (previous == null) throw 'Animated body channel ${animation.channel} is missing';
		var index = artwork.getChildIndex(previous);
		artwork.removeChild(previous);
		var replacement = SvgAsset.create(animation.frames[bodyChannelAnimationFrame - 1]);
		replacement.name = animation.channel;
		artwork.addChildAt(replacement, index);
	}

	private function partChannelAsset(channels:RigPartChannels, channel:String):String {
		if (channels.channelAnimations != null) {
			for (animation in channels.channelAnimations) if (animation.channel == channel) return animation.frames[bodyChannelAnimationFrame - 1];
		}
		return switch (channel) {
			case "primary": channels.primary;
			case "static": channels.fixed;
			case "secondary": channels.secondary;
			default: throw 'Unsupported part channel $channel';
		}
	}

	public function setItemFrameName(frameName:String):Void {
		itemFrameName = frameName == null || frameName == "" ? "None" : frameName;
		activeItem = itemFrameName == "None" || itemFrameName == "Snake" ? null : CharacterRig.item(rig, itemFrameName);
		itemActionFrame = 1;
		itemActionPlaying = false;
		jetActive = false;
		renderHeldItem();
	}

	public function playItemUseAnimation(itemName:String):Bool {
		if (activeItem == null || activeItem.name != itemName || activeItem.actionStartFrame <= 1) return false;
		itemActionFrame = activeItem.actionStartFrame;
		itemActionPlaying = true;
		renderHeldItem();
		return true;
	}

	public function gotoItemActionFrame(frame:Int):Void {
		if (activeItem == null) throw "Cannot seek an empty held item";
		itemActionFrame = Std.int(Math.max(1, Math.min(activeItem.frames.length, frame)));
		itemActionPlaying = false;
		renderHeldItem();
	}

	public function setJetActive(active:Bool):Bool {
		if (activeItem == null || activeItem.name != "Jet Pack") return false;
		jetActive = active;
		itemActionFrame = active && activeItem.frames.length > 1 ? 2 : 1;
		renderHeldItem();
		return true;
	}

	public function setJetFlame(scale:Float, alpha:Float):Void {
		jetFireScale = scale;
		jetFireAlpha = alpha;
		var holder = Std.downcast(heldItemSocket.getChildByName("heldItemArtwork"), Sprite);
		var activeArtwork = holder == null ? null : Std.downcast(holder.getChildByName("jetPackActiveArtwork"), Sprite);
		if (activeArtwork == null) return;
		var fire1 = activeArtwork.getChildByName("fire1");
		var fire2 = activeArtwork.getChildByName("fire2");
		if (fire1 != null) fire1.scaleY = scale;
		if (fire2 != null) fire2.alpha = alpha;
	}

	public function effectTarget(slotName:String):Null<Sprite> return slot(slotName);

	/** Enables or disables explicit character-part and hat BitmapData caches. */
	public function setPartBitmapCacheEnabled(enabled:Bool):Void {
		if (partBitmapCacheEnabled == enabled) return;
		partBitmapCacheEnabled = enabled;
		if (!enabled) {
			disposePartBitmapCaches();
			disposeHatBitmapCaches();
		}
	}

	public function enableIdleAnimation():Void {
		if (idleAnimationEnabled) return;
		idleAnimationEnabled = true;
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		if (stage != null) startIdleTicks();
	}

	private function onAddedToStage(_:Event):Void startIdleTicks();
	private function onRemovedFromStage(_:Event):Void stopIdleTicks();
	private function startIdleTicks():Void {
		if (idleTicking) return;
		idleTicking = true;
		addEventListener(Event.ENTER_FRAME, onIdleTick);
	}
	private function stopIdleTicks():Void {
		if (!idleTicking) return;
		idleTicking = false;
		removeEventListener(Event.ENTER_FRAME, onIdleTick);
	}
	private function onIdleTick(_:Event):Void advanceOneFrame();

	@:allow(pr2.character.CharacterViewTest)
	@:allow(pr2.character.CharacterBaseTest)
	private function setSuperJumpWobbleRandomForTest(random:Void->Float):Void {
		superJumpWobbleRandom = random == null ? Math.random : random;
	}

	private function advanceItemAction():Void {
		if (!itemActionPlaying || activeItem == null) return;
		if (itemActionFrame < activeItem.frames.length) itemActionFrame++;
		else if (activeItem.actionEndBehavior == "loop") itemActionFrame = 1;
		else itemActionPlaying = false;
		renderHeldItem();
	}

	private function renderHeldItem():Void {
		while (heldItemSocket.numChildren > 0) heldItemSocket.removeChildAt(0);
		if (itemFrameName == "None") return;
		if (itemFrameName == "Snake") {
			heldItemSocket.addChild(createSnakeHeldItem());
			return;
		}
		if (activeItem == null) return;
		var holder = new Sprite();
		holder.name = "heldItemArtwork";
		var matrix = activeItem.matrix;
		holder.transform.matrix = new Matrix(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
		holder.alpha = matrix.alpha;
		if (activeItem.name == "Mine" && Assets.exists("assets/blocks/mine_block.png", AssetType.IMAGE)) {
			holder.addChild(new Bitmap(Assets.getBitmapData("assets/blocks/mine_block.png")));
		} else if (activeItem.name == "Jet Pack" && jetActive && itemActionFrame > 1) {
			holder.addChild(createActiveJetPackArtwork(activeItem.frames[itemActionFrame - 1]));
		} else {
			holder.addChild(SvgAsset.create(activeItem.frames[itemActionFrame - 1]));
		}
		heldItemSocket.addChild(holder);
	}

	private function createActiveJetPackArtwork(assetPath:String):Sprite {
		var artwork = new Sprite();
		artwork.name = "jetPackActiveArtwork";
		var hidden = ["fire1", "fire2"];
		artwork.addChild(SvgAsset.createTinted(assetPath, new Map<String, Int>(), hidden));
		var fire2 = new Sprite();
		fire2.name = "fire2";
		fire2.transform.matrix = new Matrix(0, 1, -1, 0, 5.35, 146.05);
		fire2.alpha = jetFireAlpha;
		fire2.addChild(SvgAsset.createInstanceContents(assetPath, "fire2"));
		artwork.addChildAt(fire2, 0);
		var fire1 = new Sprite();
		fire1.name = "fire1";
		fire1.x = 4;
		fire1.y = 105.55;
		fire1.scaleY = jetFireScale;
		fire1.addChild(SvgAsset.createInstanceContents(assetPath, "fire1"));
		artwork.addChildAt(fire1, 1);
		return artwork;
	}

	private function createSnakeHeldItem():Sprite {
		var item = new Sprite();
		item.name = "snakeHeldItem";
		item.x = -22;
		item.y = -22;
		item.scaleX = item.scaleY = 2;
		var data = pr2.level.LevelRenderer.blockBitmapData(pr2.level.ObjectCodes.BLOCK_VANISH);
		if (data != null) {
			var bitmap = new Bitmap(data);
			bitmap.width = bitmap.height = 22;
			item.addChild(bitmap);
		} else throw "Missing authored vanish block bitmap for Snake item";
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

	private static function normalizeState(state:String):String {
		return switch (state) {
			case "runAnim": "run";
			case "standAnim": "stand";
			case "jumpAnim" | "fall": "jump";
			case "superJumpAnim": "superJump";
			case "bumpedAnim": "bumped";
			case "crouchAnim": "crouch";
			case "crouchWalkAnim": "crouchWalk";
			case "swimAnim": "swim";
			case "frozenSolidAnim" | "frozenSolid" | "freeze": "frozen";
			default: state;
		}
	}

	public function gotoFrame(frame:Int):Void {
		currentFrame = Std.int(Math.max(1, Math.min(frameCount, frame)));
		endSignal = null;
		completeDispatched = false;
		if (currentFrame == frameCount) signalLastFrame();
		applyFrame();
	}

	public function slot(name:String):Null<Sprite> return slots.get(name);

	private function signalLastFrame():Void {
		endSignal = animation.endSignal;
		if (animation.endBehavior == "hold-complete" && !completeDispatched) {
			completeDispatched = true;
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}

	private function applyFrame():Void {
		var index = currentFrame - 1;
		for (slotDefinition in animation.slots) {
			var target = requireSlot(slotDefinition.name);
			var source = slotDefinition.frames[index];
			var registration = registrationFor(slotDefinition.partKind);
			// The standalone SVG channels are staged away from their nested symbol
			// origins. `registration` is therefore a local-space artwork offset, not
			// an untransformed parent-space translation. Compose it through the slot
			// matrix so rotating/scaling feet and bodies keep the same authored pivot.
			// Adding registration.x/y directly makes the artwork orbit that pivot in
			// strongly rotated poses (most visibly run and jump).
			target.transform.matrix = new Matrix(
				source.a,
				source.b,
				source.c,
				source.d,
				source.tx + source.a * registration.x + source.c * registration.y,
				source.ty + source.b * registration.x + source.d * registration.y
			);
			target.alpha = source.alpha;
			var color = source.colorTransform;
			target.transform.colorTransform = color == null ? new ColorTransform() : new ColorTransform(
				color.redMultiplier,
				color.greenMultiplier,
				color.blueMultiplier,
				color.alphaMultiplier,
				color.redOffset,
				color.greenOffset,
				color.blueOffset,
				color.alphaOffset
			);
			var blur = source.blur;
			target.filters = blur == null ? [] : [new BlurFilter(blur.x, blur.y, blur.quality)];
		}
		positionHeadArtwork();
	}

	private function positionHeadArtwork():Void {
		var head = requireSlot("head");
		var artwork = head.getChildByName("artwork");
		if (artwork == null) return;
		// Animate exported head channels around the stage origin, while headsMC
		// places those channels at its own authored registration. Restore that
		// local registration. Keeping it on the artwork leaves the sibling hat
		// socket in the original headsMC coordinate space as the head rotates.
		var registration = rig.parts.head.registration;
		artwork.transform.matrix = new Matrix(1, 0, 0, 1, registration.x, registration.y);
	}

	private function registrationFor(partKind:Null<String>):{x:Float, y:Float} {
		return switch (partKind) {
			// Head registration belongs to the artwork inside headsMC so its
			// sibling hat sockets retain their authored coordinates.
			case "head": {x: 0, y: 0};
			case "body": rig.parts.body.registration;
			case "feet": rig.parts.feet.registration;
			default: {x: 0, y: 0};
		}
	}

	private function partKind(kind:String):RigPartKind {
		return switch (kind) {
			case "head": rig.parts.head;
			case "body": rig.parts.body;
			case "feet": rig.parts.feet;
			case "hat": rig.parts.hat;
			default: throw 'Unsupported character part kind $kind';
		}
	}

	private function partVariant(kind:String, id:Int):RigPartChannels {
		for (variant in partKind(kind).variants) if (variant.id == id) return variant;
		throw 'Character rig has no supported $kind part $id';
	}

	private function validatePartIds(ids:CharacterViewPartIds):Void {
		validatePartId("head", ids.head);
		validatePartId("body", ids.body);
		validatePartId("feet", ids.feet);
	}

	private function validatePartId(kind:String, id:Int):Void {
		if (isEmptyPart(kind, id)) return;
		partVariant(kind, id);
	}

	private function isEmptyPart(kind:String, id:Int):Bool {
		var ids = switch (kind) {
			case "head": rig.emptyPartIds.head;
			case "body": rig.emptyPartIds.body;
			case "feet": rig.emptyPartIds.feet;
			default: [];
		}
		return ids.indexOf(id) != -1;
	}

	private function validateHatIds(ids:Array<Int>):Void {
		if (ids == null || ids.length != 4) throw "Native character requires four hat ids";
		for (id in ids) partVariant("hat", id);
	}

	private function validateHatSlot(index:Int):Void {
		if (index < 0 || index >= 4) throw 'Invalid hat slot $index';
	}

	private function applyAllPartColors():Void {
		for (kind in ["head", "body", "feet"]) applyPartColor(kind);
	}

	private function applyPartColor(kind:String):Void {
		for (slotName in slots.keys()) {
			if (slotKinds.get(slotName) != kind) continue;
			var artwork = Std.downcast(requireSlot(slotName).getChildByName("artwork"), Sprite);
			if (artwork != null) applyPartColorToArtwork(kind, artwork);
		}
	}

	private function applyPartColorToArtwork(kind:String, artwork:Sprite):Void {
		var color = partColors.get(kind);
		if (color == null) throw 'Character part $kind has no color';
		var primary = Std.downcast(artwork.getChildByName("primary"), Shape);
		if (primary != null) primary.transform.colorTransform = solidColor(color.primary);
		var secondary = Std.downcast(artwork.getChildByName("secondary"), Shape);
		if (secondary != null) {
			secondary.visible = color.secondary >= 0;
			if (secondary.visible) secondary.transform.colorTransform = solidColor(color.secondary);
		}
	}

	private function applyAllHatColors():Void {
		for (index in 0...4) applyHatColor(index);
	}

	private function applyHatColor(index:Int):Void {
		var artwork = Std.downcast(hatSlots[index].getChildByName("artwork"), Sprite);
		if (artwork != null) applyHatColorToArtwork(index, artwork);
	}

	private function applyHatColorToArtwork(index:Int, artwork:Sprite):Void {
		var color = hatColors[index];
		var primary = Std.downcast(artwork.getChildByName("primary"), Shape);
		if (primary != null) primary.transform.colorTransform = solidColor(color.primary);
		var secondary = Std.downcast(artwork.getChildByName("secondary"), Shape);
		if (secondary != null) {
			secondary.visible = color.secondary >= 0;
			if (secondary.visible) secondary.transform.colorTransform = solidColor(color.secondary);
		}
	}

	private function applyHatAttachments():Void {
		var slots = partIds.body == rig.fred.bodyId
			? rig.fred.hatAttachments
			: CharacterRig.hatAttachment(rig, partIds.head).slots;
		for (index in 0...4) {
			var source = slots[index].matrix;
			// These are the matrices of hat1..hat4 inside the authored head/body,
			// so each already contains its complete attachment and stack position.
			// Applying the standalone hat-art registration or another stack step here
			// duplicates offsets that are not present in the original display tree.
			hatSlots[index].transform.matrix = new Matrix(
				source.a,
				source.b,
				source.c,
				source.d,
				source.tx,
				source.ty
			);
			hatSlots[index].alpha = source.alpha;
		}
	}

	private function applyAppearanceHierarchy():Void {
		var fred = partIds.body == rig.fred.bodyId;
		var parent = requireSlot(fred ? "body" : "head");
		if (hatSocket.parent != parent) parent.addChild(hatSocket);
		if (animation != null) {
			for (slotName in rig.fred.hiddenSlots) requireSlot(slotName).visible = !fred;
		}
		applyHatAttachments();
		positionHeadArtwork();
		hatSocket.transform.matrix = new Matrix();
	}

	private static function copyPartIds(ids:CharacterViewPartIds):CharacterViewPartIds {
		return {head: ids.head, body: ids.body, feet: ids.feet};
	}

	private function requireSlot(name:String):Sprite {
		var result = slots.get(name);
		if (result == null) throw 'Character rig is missing slot $name';
		return result;
	}

	private static function solidColor(color:Int):ColorTransform {
		return new ColorTransform(0, 0, 0, 1, (color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF, 0);
	}
}
