package pr2.character;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.character.CharacterAppearance.CharacterPartIds;
import pr2.gameplay.Items;
import pr2.gameplay.RotationMath;
import pr2.gameplay.RotationMath.RotatedPoint;
import pr2.runtime.PR2MovieClip;

/** A `(x, y)` block-touch probe point in stage space (see `blockTouchProbes`). */
typedef BlockTouchProbe = {
	final x:Float;
	final y:Float;
}

typedef ParticleEmitterRequest = {
	final kind:String;
	final intervalMs:Int;
	final durationMs:Int;
	final target:Character;
}

typedef DjinnEmitterRequest = {
	final slot:String;
	final graphic:String;
	final colors:Array<Int>;
	final life:Int;
	final startAlpha:Float;
	final minVelAlpha:Float;
	final maxVelAlpha:Float;
	final minVelX:Null<Float>;
	final maxVelX:Null<Float>;
	final minVelY:Null<Float>;
	final maxVelY:Null<Float>;
	final velScaleX:Float;
	final velScaleY:Float;
	final fricX:Null<Float>;
	final fricY:Null<Float>;
	final minOffsetX:Float;
	final maxOffsetX:Float;
	final minOffsetY:Float;
	final maxOffsetY:Float;
	final minScale:Float;
	final maxScale:Float;
	final offsetX:Float;
	final offsetY:Float;
	final target:Character;
}

typedef CharacterSoundRequest = {
	final kind:String;
	final x:Float;
	final y:Float;
	final volume:Float;
	final target:Character;
}

/**
	Faithful port of the `character.Character` base class (`flash/character/Character.as`)
	— the shared state for both the player-controlled `LocalCharacter` (B2/B3) and
	the network-driven `RemoteCharacter` (B4).

	What is ported here (B1, no networking yet):

	- The appearance model: head/body/feet ids + per-part primary/epic colours, and
	  the four-slot hat stack (`hat1`..`hat4`) with the special-hat flag bookkeeping
	  (`resetHats`/`setHats`/`getHighestHat`). Visible assembly is delegated to the
	  existing `CharacterDisplay`, which owns the atlas/`CharacterGraphic` rendering.
	- The animation state machine (`changeState`), driving `CharacterDisplay.setState`
	  and the jump-sound hook (the original plays `JumpSound` on entering `jump`).
	- Position/geometry helpers: `getPos`/`setPos`/`rotate`/`updateSegs`, plus the
	  block-touch *classification* (`blockTouchProbes`) that B4's `processBlockTouches`
	  consumes to drive remote block activation.
	- The recovery/invincibility flash and the fade-out removal lifecycle.

	Deferred (need still-unported subsystems, documented at the call sites): the
	actual particle/audio rendering — wired through injectable hooks so the live Game
	shell can supply them without changing this base.
**/
class Character extends Sprite {
	// Special-hat flag keys (Character.as static consts). The original stores
	// these in a `SecureStore`; here they are a plain flag map — the obfuscation
	// only mattered against client tampering of the live game.
	public static inline var PROP:String = "p";
	public static inline var CROWN:String = "c";
	public static inline var COWBOY:String = "g";
	public static inline var SANTA:String = "s";
	public static inline var PARTY:String = "a";
	public static inline var TOP:String = "t";
	public static inline var JUMP_START:String = "h";
	public static inline var MOON:String = "m";
	public static inline var JIGG:String = "j";
	public static inline var ARTIFACT:String = "b";
	public static inline var JELLYFISH:String = "f"; // (fish)
	public static inline var CHEESE:String = "ch";
	private static final MONTH_NAMES:Array<String> = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
	public static var dateStringNow:Void->String = function():String {
		return dateString(Date.now());
	};

	public final display:CharacterDisplay;
	public var dateControlsReversed(default, null):Bool = false;

	// ---- appearance: hats ------------------------------------------------
	public var hat1(get, set):Int;
	public var hat2(get, set):Int;
	public var hat3(get, set):Int;
	public var hat4(get, set):Int;
	public var hat1Color(get, set):Int;
	public var hat2Color(get, set):Int;
	public var hat3Color(get, set):Int;
	public var hat4Color(get, set):Int;
	public var hat1Color2(get, set):Int;
	public var hat2Color2(get, set):Int;
	public var hat3Color2(get, set):Int;
	public var hat4Color2(get, set):Int;

	// ---- appearance: body parts ------------------------------------------
	public var head:Int;
	public var body:Int;
	public var feet:Int;
	public var headColor:Int = 0;
	public var bodyColor:Int = 0;
	public var feetColor:Int = 0;
	public var headColor2:Int = -1;
	public var bodyColor2:Int = -1;
	public var feetColor2:Int = -1;

	// ---- identity / race state -------------------------------------------
	public var userName:String = "";
	public var groupStr:String = "0";
	public var item:Int = 0;
	public var velX:Float = 0;
	public var velY:Float = 0;
	public var type:String = "remote";
	public var state:Null<String>;
	public var tempID:Int = 0;
	public var removed:Bool = false;

	// ---- geometry --------------------------------------------------------
	// Shared by the floor/wall/ceiling probes (LocalCharacter) and the remote
	// block-touch probes (RemoteCharacter); same defaults as both AS3 classes.
	public var halfWidth:Float = 10;
	public var charHeight:Float = 55;
	public var seg1:Null<RotatedPoint>;
	public var seg2:Null<RotatedPoint>;

	// ---- protected / internal state --------------------------------------
	private var reversedControls:Bool = false;
	private var recoveryFrames:Float = 0;
	private var updateInterval:Int = 5;
	private var framesSinceUpdate:Int = 0;
	private var fadeOutStarted:Bool = false;

	// Special-hat flags (replaces the AS3 `SecureStore`).
	private final hatFlags:Map<String, Bool> = new Map();
	private final hatIds:Array<Int> = [1, 1, 1, 1];
	private final hatColors:Array<Int> = [0, 0, 0, 0];
	private final hatColors2:Array<Int> = [-1, -1, -1, -1];

	// Injectable side-effects deferred from B1 (see class doc). Defaulted to
	// no-ops so the deterministic base needs no audio/particle subsystem.
	public var onPlayJumpSound:Null<Float->Float->Void> = null;
	public var onPlayCharacterSound:Null<CharacterSoundRequest->Void> = null;
	public var onStartJetSound:Null<CharacterSoundRequest->Void> = null;
	public var onStopJetSound:Null<Character->Void> = null;
	public var onStartParticleEmitter:Null<ParticleEmitterRequest->Void> = null;
	public var onClearParticleEmitter:Null<Void->Void> = null;
	public var onStartDjinnEmitter:Null<DjinnEmitterRequest->Void> = null;
	public var onClearDjinnEmitters:Null<Void->Void> = null;

	private var recoveryRandom:Void->Float = Math.random;
	private var jetFlameRandom:Void->Float = Math.random;
	private var activeParticleEmitter:Null<ParticleEmitterRequest> = null;
	private var djinnEmittersActive:Bool = false;
	private var djinnAlpha:Float = 0.5;
	private var jetSoundActive:Bool = false;

	public function new(hatId:Int = 1, headId:Int = 1, bodyId:Int = 1, feetId:Int = 1) {
		super();
		setHatSlot(1, hatId);
		this.head = headId;
		this.body = bodyId;
		this.feet = feetId;
		dateControlsReversed = dateStringNow() == "Apr 1";
		reversedControls = dateControlsReversed;

		display = new CharacterDisplay(currentPartIds());
		addChild(display);
		addEventListener(Event.ADDED, onAdded);
		addEventListener(Event.REMOVED, onRemoved);

		resetHats();
		changeState("stand");
		applyAppearance();
	}

	// ---- colours ---------------------------------------------------------

	public function setColors(hatColor:Int, hatColor2:Int, headColor:Int, headColor2:Int, bodyColor:Int, bodyColor2:Int, feetColor:Int,
			feetColor2:Int):Void {
		setHatColors(hatColor, hatColor2);
		setHeadColors(headColor, headColor2);
		setBodyColors(bodyColor, bodyColor2);
		setFeetColors(feetColor, feetColor2);
	}

	private function resetHats():Void {
		for (key in [PROP, CROWN, COWBOY, SANTA, PARTY, TOP, JUMP_START, MOON, JIGG, ARTIFACT, JELLYFISH, CHEESE]) {
			hatFlags.set(key, false);
		}
	}

	private function refreshHatFlags():Void {
		resetHats();
		for (hatId in hatIds) {
			var flag = hatFlagForId(hatId);
			if (flag != null) {
				hatFlags.set(flag, true);
			}
		}
	}

	/** True when the character is currently wearing the given special hat. */
	public function hasHatFlag(flag:String):Bool {
		return hatFlags.exists(flag) && hatFlags.get(flag);
	}

	public var hatsAllowed(default, null):Bool = true;

	public function setHatsAllowed(allowed:Bool):Void {
		hatsAllowed = allowed;
		if (!allowed) {
			setHats([]);
		}
	}

	/**
		Apply a flat hat array (`[hatId, hatColor, hatColor2, hatId, ...]`) into the
		four hat slots, mirroring `Character.setHats`: reset every slot to the empty
		hat, then fill slots 1..4 in order and raise the special-hat flag for any of
		the recognised hat ids.
	**/
	public function setHats(hatArray:Array<Int>):Void {
		if (!hatsAllowed) {
			hatArray = [];
		}
		for (slot in 1...5) {
			setHatSlot(slot, 1, 0xFFFFFF, -1);
		}
		resetHats();

		var hatSlot = 1;
		var i = 0;
		while (i < hatArray.length && hatSlot <= 4) {
			var hatId = hatArray[i];
			var hatColor = i + 1 < hatArray.length ? hatArray[i + 1] : 0;
			var hatColor2 = i + 2 < hatArray.length ? hatArray[i + 2] : 0;
			setHatSlot(hatSlot, hatId, hatColor, hatColor2);

			hatSlot++;
			i += 3;
		}
		refreshHatFlags();
		applyAppearance();
	}

	private static function hatFlagForId(hatId:Int):Null<String> {
		return switch (hatId) {
			case 4: PROP;
			case 5: COWBOY;
			case 6: CROWN;
			case 7: SANTA;
			case 8: PARTY;
			case 9: TOP;
			case 10: JUMP_START;
			case 11: MOON;
			case 13: JIGG;
			case 14: ARTIFACT;
			case 15: JELLYFISH;
			case 16: CHEESE;
			default: null;
		};
	}

	public function setHatId(id:Int):Void {
		setHatSlot(1, hatsAllowed ? id : 1);
		refreshHatFlags();
		applyAppearance();
	}

	public function setHeadId(id:Int):Void {
		head = id;
		applyAppearance();
	}

	public function setBodyId(id:Int):Void {
		body = id;
		applyAppearance();
	}

	public function setFeetId(id:Int):Void {
		feet = id;
		applyAppearance();
	}

	public function setHatColors(color:Int, epic:Int, hatNum:Int = 1):Void {
		setHatSlotColors(numLimit(hatNum, 1, 4), color, epic);
		applyAppearance();
	}

	public function setHeadColors(color:Int, epic:Int):Void {
		headColor = color;
		headColor2 = epic;
		applyAppearance();
	}

	public function setBodyColors(color:Int, epic:Int):Void {
		bodyColor = color;
		bodyColor2 = epic;
		applyAppearance();
	}

	public function setFeetColors(color:Int, epic:Int):Void {
		feetColor = color;
		feetColor2 = epic;
		applyAppearance();
	}

	/**
		Pop the highest-numbered occupied hat slot back to empty and return its
		`{hatNum, hatColor, hatColor2}`, mirroring `Character.getHighestHat` — the hat-stack
		shed used by the hat-loss / hat-to-start race events. Returns `{0, 0}` when
		the character has no hats on.
	**/
	public function getHighestHat():{hatNum:Int, hatColor:Int, hatColor2:Int} {
		var hatNum = 0;
		var hatColor = 0;
		var hatColor2 = -1;
		var hatSlot = 4;
		while (hatSlot >= 1) {
			var slotIndex = hatSlot - 1;
			if (hatIds[slotIndex] != 1) {
				hatNum = hatIds[slotIndex];
				hatColor = hatColors[slotIndex];
				hatColor2 = hatColors2[slotIndex];
				setHatSlot(hatSlot, 1);
				break;
			}
			hatSlot--;
		}
		refreshHatFlags();
		applyAppearance();
		return {hatNum: hatNum, hatColor: hatColor, hatColor2: hatColor2};
	}

	public function setItem(itemCode:Int):Void {
		item = itemCode;
		applyItem();
	}

	private function applyAppearance():Void {
		display.setPartIds(currentPartIds());
		display.setPartColor("hat", hatColors[0], hatColors2[0]);
		display.setHatSlotColors([for (slot in 0...4) {primary: hatColors[slot], secondary: hatColors2[slot]}]);
		display.setPartColor("head", headColor, headColor2);
		display.setPartColor("body", bodyColor, bodyColor2);
		display.setPartColor("feet", feetColor, feetColor2);
		applyItem();
		updateDjinnEffects();
	}

	/**
		Hold/use the current item. Flash applies `Items.getNameFromCode` to every
		character-state `weapon` clip so the authored held-item frames stay in sync
		across animation changes.
	**/
	private function applyItem():Void {
		itemFrameName = Items.getNameFromCode(item);
		display.setItemFrameName(itemFrameName);
	}

	public function playItemUseAnimation(itemName:String):Bool {
		return display.playItemUseAnimation(itemName);
	}

	/** Last resolved held-item frame name (e.g. "Laser", "None"). */
	public var itemFrameName(default, null):String = "None";

	private inline function currentPartIds():CharacterPartIds {
		return {hat: hatIds[0], hats: hatIds.copy(), head: head, body: body, feet: feet};
	}

	private function setHatSlot(slot:Int, id:Int, ?color:Int, ?color2:Int):Void {
		var index = slotIndex(slot);
		hatIds[index] = id;
		if (color != null) {
			hatColors[index] = color;
		}
		if (color2 != null) {
			hatColors2[index] = color2;
		}
	}

	private function setHatSlotColors(slot:Int, color:Int, color2:Int):Void {
		var index = slotIndex(slot);
		hatColors[index] = color;
		hatColors2[index] = color2;
	}

	private inline function slotIndex(slot:Int):Int {
		return numLimit(slot, 1, 4) - 1;
	}

	private inline function get_hat1():Int return hatIds[0];
	private inline function set_hat1(value:Int):Int return hatIds[0] = value;
	private inline function get_hat2():Int return hatIds[1];
	private inline function set_hat2(value:Int):Int return hatIds[1] = value;
	private inline function get_hat3():Int return hatIds[2];
	private inline function set_hat3(value:Int):Int return hatIds[2] = value;
	private inline function get_hat4():Int return hatIds[3];
	private inline function set_hat4(value:Int):Int return hatIds[3] = value;
	private inline function get_hat1Color():Int return hatColors[0];
	private inline function set_hat1Color(value:Int):Int return hatColors[0] = value;
	private inline function get_hat2Color():Int return hatColors[1];
	private inline function set_hat2Color(value:Int):Int return hatColors[1] = value;
	private inline function get_hat3Color():Int return hatColors[2];
	private inline function set_hat3Color(value:Int):Int return hatColors[2] = value;
	private inline function get_hat4Color():Int return hatColors[3];
	private inline function set_hat4Color(value:Int):Int return hatColors[3] = value;
	private inline function get_hat1Color2():Int return hatColors2[0];
	private inline function set_hat1Color2(value:Int):Int return hatColors2[0] = value;
	private inline function get_hat2Color2():Int return hatColors2[1];
	private inline function set_hat2Color2(value:Int):Int return hatColors2[1] = value;
	private inline function get_hat3Color2():Int return hatColors2[2];
	private inline function set_hat3Color2(value:Int):Int return hatColors2[2] = value;
	private inline function get_hat4Color2():Int return hatColors2[3];
	private inline function set_hat4Color2(value:Int):Int return hatColors2[3] = value;

	public function getName():String {
		return userName;
	}

	public function getGroup():String {
		return groupStr;
	}

	// ---- position / geometry ---------------------------------------------

	public function getPos():{x:Float, y:Float} {
		return {x: x, y: y};
	}

	public function setPos(px:Float, py:Float):Void {
		x = px;
		y = py;
	}

	/** Faithful port of `Character.rotate` (rotates the local position vector). */
	public function rotate(direction:String):Void {
		var nx:Float;
		var ny:Float;
		if (direction == "right") {
			nx = -y;
			ny = x;
		} else {
			nx = y;
			ny = -x;
		}
		x = nx;
		y = ny;
	}

	/**
		Recompute `seg1`/`seg2`, the two grid segments the character occupies under
		the current map `rotation`. Faithful port of `Character.updateSegs`.
	**/
	public function updateSegs(rotation:Float):Void {
		var base = RotationMath.rotatePoint(Math.floor(x / 30), Math.floor(y / 30), rotation);
		var s1x = base.x;
		var s1y = base.y;
		var s2x = s1x;
		var s2y = s1y - 1;
		if (rotation == 90) {
			s1x--;
			s2x--;
		} else if (Math.abs(rotation) == 180) {
			s1x--;
			s2x--;
			s1y++;
			s2y++;
		} else if (rotation == -90) {
			s1y++;
			s2y++;
		}
		seg1 = {x: s1x, y: s1y};
		seg2 = {x: s2x, y: s2y};
	}

	/**
		Classify which block-touch probe points are active for a move of
		`(deltaX, deltaY)` (target minus last position), mirroring the four
		conditionals in `RemoteCharacter.processBlockTouches`. Returned points are in
		stage space; B4 rotates and resolves them against the map. Pure so it can be
		asserted without a live map.
	**/
	public function blockTouchProbes(deltaX:Float, deltaY:Float):Array<BlockTouchProbe> {
		var probes:Array<BlockTouchProbe> = [];
		if (deltaY <= 0) {
			probes.push({x: x, y: y - charHeight - 1});
		}
		if (deltaY >= 0) {
			probes.push({x: x, y: y + 1});
		}
		if (deltaX >= 0) {
			probes.push({x: x + halfWidth + 1, y: y - 10});
		}
		if (deltaX <= 0) {
			probes.push({x: x - halfWidth - 1, y: y - 10});
		}
		return probes;
	}

	// ---- animation state machine -----------------------------------------

	public function changeState(s:String):Void {
		if (state == s) {
			return;
		}
		if (s == "jump" && velY <= 0 && onPlayJumpSound != null) {
			onPlayJumpSound(x, y);
		}
		state = s;
		display.setState(s + "Anim");
		updateDjinnEffects();
	}

	// ---- recovery / invincibility ----------------------------------------

	public function beginRecovery(frames:Float):Void {
		recoveryFrames = frames;
		removeEventListener(Event.ENTER_FRAME, recoveryTick);
		addEventListener(Event.ENTER_FRAME, recoveryTick);
	}

	@:allow(pr2.character.CharacterBaseTest)
	private function recoveryTick(_:Event):Void {
		var phase = recoveryFrames % 8;
		if (!fadeOutStarted) {
			alpha = phase >= 4 ? 0.5 : 0.75;
		}
		recoveryFrames--;
		if (recoveryFrames <= 0) {
			endRecovery();
		}
	}

	private function endRecovery():Void {
		alpha = 1;
		removeEventListener(Event.ENTER_FRAME, recoveryTick);
	}

	/** Become invincible for `frames` frames and start Flash's rainbow-star emitter. */
	public function gainHeart():Void {
		playCharacterSound("bumpHappy", 0.75);
		becomeInvincible(135);
	}

	public function becomeInvincible(frames:Int):Void {
		beginRecovery(frames);
		setParticleEmitter("rainbowStar", 33, 5000);
	}

	public function beginSparkles(durationMs:Int = 5000):Void {
		playCharacterSound("speedUp", 1);
		setParticleEmitter("sparkle", 33, durationMs);
	}

	public function endSparkles(used:Bool = false):Void {
		if (used) {
			playCharacterSound("slowDown", 1);
		}
		clearParticleEmitter();
	}

	public function beginArrowSparkles():Void {
		setParticleEmitter("arrowSparkle", 33, 5000);
	}

	public function djinnUpdateAlpha(newAlpha:Float):Void {
		djinnAlpha = newAlpha;
		updateDjinnEffects();
	}

	public function beginJet():Void {
		removeEventListener(Event.ENTER_FRAME, jetPackTick);
		addEventListener(Event.ENTER_FRAME, jetPackTick);
		setCurrentJetPackFrame("on");
		stopJetSound();
		if (onStartJetSound != null) {
			onStartJetSound({kind: "engine", x: x, y: y, volume: 0.6, target: this});
			jetSoundActive = true;
		}
	}

	public function endJet():Void {
		removeEventListener(Event.ENTER_FRAME, jetPackTick);
		stopJetSound();
		for (stateName in CharacterDisplay.STATE_NAMES) {
			var jetPack = jetPackForState(stateName);
			if (jetPack != null) {
				jetPack.gotoAndStop("off");
			}
		}
	}

	@:allow(pr2.character.CharacterBaseTest)
	private function setJetFlameRandomForTest(random:Void->Float):Void {
		jetFlameRandom = random == null ? Math.random : random;
	}

	@:allow(pr2.character.CharacterBaseTest)
	@:allow(pr2.character.RemoteCharacterConsumeTest)
	private function jetPackForState(stateName:String):Null<PR2MovieClip> {
		var stateClip = display.getStateClip(stateName);
		if (stateClip == null) {
			return null;
		}
		var weapon = Std.downcast(stateClip.getChildByTimelineName("weapon"), PR2MovieClip);
		return weapon == null ? null : Std.downcast(weapon.getChildByTimelineName("jetPack"), PR2MovieClip);
	}

	// ---- removal lifecycle -----------------------------------------------

	public function beginRemove():Void {
		removeListeners();
		if (!fadeOutStarted && !removed) {
			fadeOutStarted = true;
			addEventListener(Event.ENTER_FRAME, fadeOut);
		}
	}

	@:allow(pr2.character.CharacterBaseTest)
	private function fadeOut(_:Event):Void {
		alpha -= 0.02;
		if (alpha <= 0) {
			remove();
		}
	}

	private function removeListeners():Void {
		removeEventListener(Event.ENTER_FRAME, recoveryTick);
		removeEventListener(Event.ENTER_FRAME, jetPackTick);
		stopJetSound();
	}

	public function remove():Void {
		removeListeners();
		clearParticleEmitter();
		clearDjinnEmitters();
		if (!removed) {
			removed = fadeOutStarted = true;
			removeEventListener(Event.ENTER_FRAME, fadeOut);
			if (display.parent == this) {
				removeChild(display);
			}
			if (parent != null) {
				parent.removeChild(this);
			}
		}
	}

	private function setParticleEmitter(kind:String, intervalMs:Int, durationMs:Int):Void {
		clearParticleEmitter();
		activeParticleEmitter = {kind: kind, intervalMs: intervalMs, durationMs: durationMs, target: this};
		if (onStartParticleEmitter != null) {
			onStartParticleEmitter(activeParticleEmitter);
		}
	}

	private function playCharacterSound(kind:String, volume:Float):Void {
		if (onPlayCharacterSound != null) {
			onPlayCharacterSound({kind: kind, x: x, y: y, volume: volume, target: this});
		}
	}

	private function stopJetSound():Void {
		if (!jetSoundActive) {
			return;
		}
		jetSoundActive = false;
		if (onStopJetSound != null) {
			onStopJetSound(this);
		}
	}

	public function controlsReversed():Bool {
		return reversedControls;
	}

	public function setArtifactReversedControls(active:Bool):Void {
		reversedControls = dateControlsReversed || active;
	}

	private function clearParticleEmitter():Void {
		if (activeParticleEmitter == null) {
			return;
		}
		activeParticleEmitter = null;
		if (onClearParticleEmitter != null) {
			onClearParticleEmitter();
		}
	}

	private function updateDjinnEffects():Void {
		clearDjinnEmitters();
		if (parent == null) {
			return;
		}
		if (body == 35) {
			startDjinnEmitter(djinnBodyRequest());
		}
		if (feet == 35) {
			startDjinnEmitter(djinnFeetRequest("foot1"));
			startDjinnEmitter(djinnFeetRequest("foot2"));
		}
	}

	private function startDjinnEmitter(request:DjinnEmitterRequest):Void {
		djinnEmittersActive = true;
		if (onStartDjinnEmitter != null) {
			onStartDjinnEmitter(request);
		}
	}

	private function djinnBodyRequest():DjinnEmitterRequest {
		return {
			slot: "body",
			graphic: "DjinnIceGraphic",
			colors: [bodyColor, bodyColor2],
			life: 16,
			startAlpha: djinnAlpha / 5,
			minVelAlpha: 0,
			maxVelAlpha: djinnAlpha,
			minVelX: null,
			maxVelX: null,
			minVelY: 2,
			maxVelY: 3,
			velScaleX: 0.1,
			velScaleY: 0.1,
			fricX: 1.05,
			fricY: 0.9,
			minOffsetX: -5,
			maxOffsetX: 5,
			minOffsetY: -10,
			maxOffsetY: 10,
			minScale: -1,
			maxScale: -0.75,
			offsetX: -15,
			offsetY: -10,
			target: this
		};
	}

	private function djinnFeetRequest(slot:String):DjinnEmitterRequest {
		return {
			slot: slot,
			graphic: "DjinnIceGraphic",
			colors: [feetColor, feetColor2],
			life: 8,
			startAlpha: djinnAlpha / 5,
			minVelAlpha: 0,
			maxVelAlpha: djinnAlpha,
			minVelX: -2,
			maxVelX: 2,
			minVelY: null,
			maxVelY: null,
			velScaleX: 0.1,
			velScaleY: 0.1,
			fricX: null,
			fricY: null,
			minOffsetX: -5,
			maxOffsetX: 5,
			minOffsetY: -5,
			maxOffsetY: 5,
			minScale: 0.075,
			maxScale: 0.1,
			offsetX: 0,
			offsetY: 0,
			target: this
		};
	}

	private function clearDjinnEmitters():Void {
		if (!djinnEmittersActive) {
			return;
		}
		djinnEmittersActive = false;
		if (onClearDjinnEmitters != null) {
			onClearDjinnEmitters();
		}
	}

	private function onAdded(event:Event):Void {
		if (event.target == this) {
			updateDjinnEffects();
		}
	}

	private function onRemoved(event:Event):Void {
		if (event.target == this) {
			clearDjinnEmitters();
		}
	}

	private function jetPackTick(_:Event):Void {
		var jetPack = setCurrentJetPackFrame("on");
		if (jetPack == null) {
			return;
		}
		var anim = Std.downcast(jetPack.getChildByTimelineName("anim"), PR2MovieClip);
		if (anim == null) {
			return;
		}
		var fire1 = anim.getChildByTimelineName("fire1");
		var fire2 = anim.getChildByTimelineName("fire2");
		if (fire1 != null) {
			fire1.scaleY = jetFlameRandom() * 0.5 + 0.5;
		}
		if (fire2 != null) {
			fire2.alpha = jetFlameRandom() * 0.5 + 0.5;
		}
	}

	private function setCurrentJetPackFrame(frame:String):Null<PR2MovieClip> {
		var jetPack = state == null ? null : jetPackForState(state + "Anim");
		if (jetPack != null) {
			jetPack.gotoAndStop(frame);
		}
		return jetPack;
	}

	// ---- helpers ---------------------------------------------------------

	/** Mirrors `Data.numLimit`: clamp to the inclusive [min, max] range. */
	private static inline function numLimit(value:Int, min:Int, max:Int):Int {
		return value < min ? min : (value > max ? max : value);
	}

	private static function dateString(date:Date):String {
		return MONTH_NAMES[date.getMonth()] + " " + date.getDate();
	}
}
