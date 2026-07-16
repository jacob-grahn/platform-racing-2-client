package pr2.character;

import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.ds.ObjectMap;
import pr2.character.CharacterAppearance.CharacterPartIds;
import pr2.runtime.ExplicitBitmapCache;
import pr2.runtime.PR2MovieClip;

typedef CharacterColors = {
	@:optional var primary:Int;
	@:optional var secondary:Int;
}

/** Per-part tint; `secondary < 0` means the part has no epic (second) color. */
typedef PartColor = {
	var primary:Int;
	var secondary:Int;
}

private typedef ExplicitPartCacheRecord = {
	var cache:ExplicitBitmapCache;
	var revision:Int;
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

	private static inline var SNAKE_ITEM_NAME:String = "__snakeHeldItem";
	private static inline var VANISH_ASSET:String = "assets/blocks/vanish.png";
	private static inline var PART_CACHE_SCALE:Float = 0.3;
	private static inline var PART_CACHE_PADDING:Int = 2;

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
	private final explicitPartCacheEnabled:Bool;
	private final explicitPartCaches:ObjectMap<PR2MovieClip, ExplicitPartCacheRecord> = new ObjectMap();
	private var explicitPartCacheRevision:Int = 0;

	public function new(?partIds:CharacterPartIds, ?colors:CharacterColors, explicitPartCacheEnabled:Bool = true) {
		super();
		this.explicitPartCacheEnabled = explicitPartCacheEnabled;
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
		explicitPartCacheRevision++;
		CharacterAppearance.applyPartIds(clip, partIds);
		applyAuthoredColors();
	}

	public function setColors(primary:Int, secondary:Int):Void {
		primaryColor = primary;
		secondaryColor = secondary;
		explicitPartCacheRevision++;
		applyAuthoredColors();
	}

	/**
		Tint a single part kind (`hat`/`head`/`body`/`feet`) independently of the
		others. `secondary < 0` removes that part's epic colour. Used by the Account
		customize preview, where each part carries its own colour.
	**/
	public function setPartColor(kind:String, primary:Int, secondary:Int):Void {
		partColors.set(kind, {primary: primary, secondary: secondary});
		explicitPartCacheRevision++;
		applyAuthoredColors();
	}

	public function setHatSlotColors(colors:Array<PartColor>):Void {
		hatSlotColors = colors == null ? [] : [for (color in colors) {primary: color.primary, secondary: color.secondary}];
		explicitPartCacheRevision++;
		applyAuthoredColors();
	}

	private function colorFor(kind:String):PartColor {
		var partOverride = partColors.get(kind);
		return partOverride != null ? partOverride : {primary: primaryColor, secondary: secondaryColor};
	}

	private function colorForHatSlot(slot:Int):PartColor {
		return hatSlotColors.length > slot ? hatSlotColors[slot] : colorFor("hat");
	}

	public function setState(stateName:String):Void {
		if (activeStateName == stateName && activeStateClip != null) {
			return;
		}

		if (activeStateClip != null) {
			resetItemUseAnimation(activeStateClip);
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

		CharacterAppearance.applyPartIds(clip, partIds);
		applyAuthoredColors();
		applyItemFrame();
		if (activeStateName == "superJumpAnim") {
			startSuperJumpWobble();
		}
	}

	public function setItemFrameName(frameName:String):Void {
		itemFrameName = frameName == null || frameName == "" ? "None" : frameName;
		applyItemFrame();
	}

	public function playItemUseAnimation(itemName:String):Bool {
		if (activeStateClip == null) {
			return false;
		}
		var weapon = getClipChild(activeStateClip, "weapon");
		if (weapon == null) {
			return false;
		}
		applyWeaponItemFrame(weapon);
		var childName = itemName == "Laser" ? "gun" : itemName == "Sword" ? "sword" : null;
		var label = itemName == "Laser" ? "shoot" : itemName == "Sword" ? "swing" : null;
		if (childName == null || label == null) {
			return false;
		}
		var animation = getClipChild(weapon, childName);
		if (animation == null) {
			return false;
		}
		animation.gotoAndPlay(label);
		return true;
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
		CharacterAppearance.applyPartIds(clip, partIds);
		applyAuthoredColors();
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
				applyWeaponItemFrame(weapon);
			}
		}
	}

	private function applyWeaponItemFrame(weapon:PR2MovieClip):Void {
		var targetName = itemFrameName == "Snake" ? "None" : itemFrameName;
		var targetFrame = frameNumberForLabel(weapon, targetName);
		// Re-selecting an unchanged weapon frame reconstructs its unnamed nested
		// clips. That reset prevented the gun recoil and sword swing timelines from
		// advancing past their first frame.
		if (targetFrame == null || weapon.currentFrame != targetFrame) {
			weapon.gotoAndStop(targetName);
		}
		if (itemFrameName == "Snake") {
			var existing = weapon.getChildByName(SNAKE_ITEM_NAME);
			if (existing == null) weapon.addChild(createSnakeHeldItem());
		} else {
			var existing = weapon.getChildByName(SNAKE_ITEM_NAME);
			if (existing != null) weapon.removeChild(existing);
		}
	}

	private static function frameNumberForLabel(clip:PR2MovieClip, label:String):Null<Int> {
		for (frameLabel in clip.currentLabels) {
			if (frameLabel.name == label) {
				return frameLabel.frame;
			}
		}
		return null;
	}

	private static function resetItemUseAnimation(stateClip:PR2MovieClip):Void {
		var weapon = getClipChild(stateClip, "weapon");
		if (weapon == null) {
			return;
		}
		for (childName in ["gun", "sword"]) {
			var animation = getClipChild(weapon, childName);
			if (animation != null) {
				animation.gotoAndStop(1);
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

	/** Apply colors to Animate's authored part containers, matching Character.as. */
	private function applyAuthoredColors():Void {
		for (stateName in STATE_NAMES) {
			var stateClip = getClipChild(clip, stateName);
			if (stateClip == null) {
				continue;
			}

			applyPartColor(getClipChild(stateClip, "head"), colorFor("head"));
			applyPartColor(getClipChild(stateClip, "body"), colorFor("body"));
			applyPartColor(getClipChild(stateClip, "foot1"), colorFor("feet"));
			applyPartColor(getClipChild(stateClip, "foot2"), colorFor("feet"));

			var hatContainer = getClipChild(stateClip, partIds.body == 29 ? "body" : "head");
			if (hatContainer != null) {
				var hats = partIds.hats != null ? partIds.hats : [partIds.hat, 1, 1, 1];
				for (slot in 0...4) {
					var hatId = hats.length > slot ? hats[slot] : 1;
					var color = colorForHatSlot(slot);
					// Flash makes the cheese hat's secondary channel black when no
					// epic color is supplied instead of hiding it.
					if (hatId == 16 && color.secondary < 0) {
						color = {primary: color.primary, secondary: 0};
					}
					applyPartColor(getClipChild(hatContainer, "hat" + (slot + 1)), color);
				}
			}

			cachePart(getClipChild(stateClip, "head"));
			cachePart(getClipChild(stateClip, "body"));
			cachePart(getClipChild(stateClip, "foot1"));
			cachePart(getClipChild(stateClip, "foot2"));
		}
	}

	private function applyPartColor(part:Null<PR2MovieClip>, color:PartColor):Void {
		if (part == null) {
			return;
		}
		if (!preparePartForUpdate(part)) {
			return;
		}
		var primary = getClipChild(part, "colorMC");
		if (primary != null) {
			if (!primary.visible) {
				primary.visible = true;
			}
			applyColorTransform(primary, colorTransformFor(color.primary));
		}
		var secondary = getClipChild(part, "colorMC2");
		if (secondary != null) {
			var secondaryVisible = color.secondary >= 0;
			if (secondary.visible != secondaryVisible) {
				secondary.visible = secondaryVisible;
			}
			if (secondary.visible) {
				applyColorTransform(secondary, colorTransformFor(color.secondary));
			}
		}
	}

	private function preparePartForUpdate(part:PR2MovieClip):Bool {
		if (!explicitPartCacheEnabled) {
			return true;
		}
		var record = explicitPartCaches.get(part);
		if (record == null) {
			return true;
		}
		if (record.revision == explicitPartCacheRevision) {
			return false;
		}
		record.cache.invalidate();
		return true;
	}

	private function cachePart(part:Null<PR2MovieClip>):Void {
		if (!explicitPartCacheEnabled || part == null) {
			return;
		}
		var existing = explicitPartCaches.get(part);
		if (existing != null) {
			if (existing.revision == explicitPartCacheRevision) {
				return;
			}
			existing.cache.refresh();
			existing.revision = explicitPartCacheRevision;
			return;
		}

		var cache = ExplicitBitmapCache.attach(part, {
			scale: PART_CACHE_SCALE,
			padding: PART_CACHE_PADDING,
			bitmapName: "__explicitPartCache"
		});
		explicitPartCaches.set(part, {
			cache: cache,
			revision: explicitPartCacheRevision
		});
	}

	@:allow(pr2.character.CharacterDisplayTest)
	private function explicitPartCacheForTest(part:PR2MovieClip):Null<Bitmap> {
		var record = explicitPartCaches.get(part);
		return record == null ? null : record.cache.bitmap;
	}

	private static function applyColorTransform(target:PR2MovieClip, desired:ColorTransform):Void {
		var current = target.transform.colorTransform;
		if (current.redMultiplier == desired.redMultiplier
			&& current.greenMultiplier == desired.greenMultiplier
			&& current.blueMultiplier == desired.blueMultiplier
			&& current.alphaMultiplier == desired.alphaMultiplier
			&& current.redOffset == desired.redOffset
			&& current.greenOffset == desired.greenOffset
			&& current.blueOffset == desired.blueOffset
			&& current.alphaOffset == desired.alphaOffset) {
			return;
		}
		target.transform.colorTransform = desired;
	}

	private static function colorTransformFor(color:Int):ColorTransform {
		return new ColorTransform(
			0, 0, 0, 1,
			(color >> 16) & 0xFF,
			(color >> 8) & 0xFF,
			color & 0xFF,
			0
		);
	}

	private static function getClipChild(parent:PR2MovieClip, childName:String):Null<PR2MovieClip> {
		return Std.downcast(parent.getChildByTimelineName(childName), PR2MovieClip);
	}
}
