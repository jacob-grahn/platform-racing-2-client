package pr2.character;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.character.CharacterAppearance.CharacterPartIds;
import pr2.gameplay.Items;
import pr2.gameplay.RotationMath;
import pr2.gameplay.RotationMath.RotatedPoint;

/** A `(x, y)` block-touch probe point in stage space (see `blockTouchProbes`). */
typedef BlockTouchProbe = {
	final x:Float;
	final y:Float;
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
	particle emitters (sparkles / arrow-sparkle / rainbow-star), the jet-pack flame
	loop, `DjinnEffects`, and the actual sound playback — all wired through
	injectable hooks so the live Game shell (B5) can supply them without changing
	this base.
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

	public final display:CharacterDisplay;

	// ---- appearance: hats ------------------------------------------------
	public var hat1:Int;
	public var hat2:Int = 1;
	public var hat3:Int = 1;
	public var hat4:Int = 1;
	public var hat1Color:Int = 0;
	public var hat2Color:Int = 0;
	public var hat3Color:Int = 0;
	public var hat4Color:Int = 0;
	public var hat1Color2:Int = -1;
	public var hat2Color2:Int = -1;
	public var hat3Color2:Int = -1;
	public var hat4Color2:Int = -1;

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

	// Injectable side-effects deferred from B1 (see class doc). Defaulted to
	// no-ops so the deterministic base needs no audio/particle subsystem.
	public var onPlayJumpSound:Null<Float->Float->Void> = null;

	private var recoveryRandom:Void->Float = Math.random;

	public function new(hatId:Int = 1, headId:Int = 1, bodyId:Int = 1, feetId:Int = 1) {
		super();
		this.hat1 = hatId;
		this.head = headId;
		this.body = bodyId;
		this.feet = feetId;

		display = new CharacterDisplay(currentPartIds());
		addChild(display);

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

	/** True when the character is currently wearing the given special hat. */
	public function hasHatFlag(flag:String):Bool {
		return hatFlags.exists(flag) && hatFlags.get(flag);
	}

	/**
		Apply a flat hat array (`[hatId, hatColor, hatColor2, hatId, ...]`) into the
		four hat slots, mirroring `Character.setHats`: reset every slot to the empty
		hat, then fill slots 1..4 in order and raise the special-hat flag for any of
		the recognised hat ids.
	**/
	public function setHats(hatArray:Array<Int>):Void {
		hat1 = hat2 = hat3 = hat4 = 1;
		hat1Color = hat2Color = hat3Color = hat4Color = 0xFFFFFF;
		hat1Color2 = hat2Color2 = hat3Color2 = hat4Color2 = -1;
		resetHats();

		var hatSlot = 1;
		var i = 0;
		while (i < hatArray.length) {
			var hatId = hatArray[i];
			var hatColor = hatArray[i + 1] != null ? hatArray[i + 1] : 0;
			var hatColor2 = hatArray[i + 2] != null ? hatArray[i + 2] : 0;
			switch (hatSlot) {
				case 1:
					hat1 = hatId;
					hat1Color = hatColor;
					hat1Color2 = hatColor2;
				case 2:
					hat2 = hatId;
					hat2Color = hatColor;
					hat2Color2 = hatColor2;
				case 3:
					hat3 = hatId;
					hat3Color = hatColor;
					hat3Color2 = hatColor2;
				case 4:
					hat4 = hatId;
					hat4Color = hatColor;
					hat4Color2 = hatColor2;
			}

			var flag = hatFlagForId(hatId);
			if (flag != null) {
				hatFlags.set(flag, true);
			}
			hatSlot++;
			i += 3;
		}
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
		hat1 = id;
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
		hatNum = numLimit(hatNum, 1, 4);
		switch (hatNum) {
			case 1:
				hat1Color = color;
				hat1Color2 = epic;
			case 2:
				hat2Color = color;
				hat2Color2 = epic;
			case 3:
				hat3Color = color;
				hat3Color2 = epic;
			case 4:
				hat4Color = color;
				hat4Color2 = epic;
		}
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
		`{hatNum, hatColor}`, mirroring `Character.getHighestHat` — the hat-stack
		shed used by the hat-loss / hat-to-start race events. Returns `{0, 0}` when
		the character has no hats on.
	**/
	public function getHighestHat():{hatNum:Int, hatColor:Int} {
		var hatNum = 0;
		var hatColor = 0;
		var hatSlot = 4;
		while (hatSlot >= 1) {
			switch (hatSlot) {
				case 4 if (hat4 != 1):
					hatNum = hat4;
					hatColor = hat4Color;
					hat4 = 1;
					break;
				case 3 if (hat3 != 1):
					hatNum = hat3;
					hatColor = hat3Color;
					hat3 = 1;
					break;
				case 2 if (hat2 != 1):
					hatNum = hat2;
					hatColor = hat2Color;
					hat2 = 1;
					break;
				case 1 if (hat1 != 1):
					hatNum = hat1;
					hatColor = hat1Color;
					hat1 = 1;
					break;
				default:
			}
			hatSlot--;
		}
		applyAppearance();
		return {hatNum: hatNum, hatColor: hatColor};
	}

	public function setItem(itemCode:Int):Void {
		item = itemCode;
		applyItem();
	}

	private function applyAppearance():Void {
		display.setPartIds(currentPartIds());
		display.setPartColor("hat", hat1Color, hat1Color2);
		display.setPartColor("head", headColor, headColor2);
		display.setPartColor("body", bodyColor, bodyColor2);
		display.setPartColor("feet", feetColor, feetColor2);
		applyItem();
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

	/** Last resolved held-item frame name (e.g. "Laser", "None"). */
	public var itemFrameName(default, null):String = "None";

	private inline function currentPartIds():CharacterPartIds {
		return {hat: hat1, head: head, body: body, feet: feet};
	}

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

	/**
		Become invincible for `frames` frames (the recovery flash). The original also
		spawns a `RainbowStarEmitter`; the particle emitters are deferred (B-later),
		so only the flash is applied here.
	**/
	public function becomeInvincible(frames:Int):Void {
		beginRecovery(frames);
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
	}

	public function remove():Void {
		removeListeners();
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

	// ---- helpers ---------------------------------------------------------

	/** Mirrors `Data.numLimit`: clamp to the inclusive [min, max] range. */
	private static inline function numLimit(value:Int, min:Int, max:Int):Int {
		return value < min ? min : (value > max ? max : value);
	}
}
