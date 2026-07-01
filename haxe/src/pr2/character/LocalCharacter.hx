package pr2.character;

import pr2.harness.LocalPlayerController;
import pr2.harness.LocalPlayerDebugState;
import pr2.harness.LocalPlayerInput;
import pr2.level.FixtureLevel;
import pr2.net.LobbySocket;

/**
	`LocalCharacter` physics bridge for B2.

	The audited land/block/item physics still lives in `LocalPlayerController`;
	this class gives the multiplayer character hierarchy a `Character` subclass
	that owns that controller and mirrors its authoritative motion state.
**/
class LocalCharacter extends Character {
	public final controller:LocalPlayerController;

	public var grounded(get, never):Bool;
	public var crouching(get, never):Bool;
	public var facingScaleX(get, never):Int;
	public var courseTweenRotation(get, never):Int;
	public var characterRotation(get, never):Int;
	public var lastSafeX(get, never):Float;
	public var lastSafeY(get, never):Float;
	public var networkPlayerCount:Int = 1;

	private var lastNetScaleX:Null<Float>;
	private var exactX:Int = 0;
	private var exactY:Int = 0;
	private var lastNetState:Null<String>;
	private var lastNetParent:Null<String>;
	private var lastNetItem:Int = 0;
	private var exactPosNextUpdate:Bool = false;
	private final baseGravityMultiplier:Float;

	public function new(level:FixtureLevel, hatId:Int = 1, headId:Int = 1, bodyId:Int = 1, feetId:Int = 1) {
		super(hatId, headId, bodyId, feetId);
		type = "local";
		baseGravityMultiplier = level.gravity;
		controller = new LocalPlayerController(level);
		syncFromController();
	}

	override public function setHats(hatArray:Array<Int>):Void {
		var hadMoon = hasHatFlag(Character.MOON);
		var hadCowboy = hasHatFlag(Character.COWBOY);
		var hadSanta = hasHatFlag(Character.SANTA);
		super.setHats(hatArray);
		controller.santaHatActive = hasHatFlag(Character.SANTA);
		controller.cowboyHatActive = hasHatFlag(Character.COWBOY);
		controller.crownHatActive = hasHatFlag(Character.CROWN);
		controller.partyHatActive = hasHatFlag(Character.PARTY);
		controller.topHatActive = hasHatFlag(Character.TOP);
		if (hadMoon && !hasHatFlag(Character.MOON)) {
			controller.setGravity(baseGravityMultiplier);
		}
		if (hasHatFlag(Character.MOON) && !hadMoon) {
			controller.setGravity(baseGravityMultiplier * 0.85);
		}
		if (hadCowboy && !hasHatFlag(Character.COWBOY)) {
			controller.cowboyHatActive = false;
			controller.resetStats();
		}
		if (hasHatFlag(Character.COWBOY) && !hadCowboy) {
			controller.ensureCowboyStats();
		}
		if (hadSanta && !hasHatFlag(Character.SANTA)) {
			controller.resetStats();
		}
		if (hasHatFlag(Character.SANTA) && !hadSanta && !(hasHatFlag(Character.COWBOY) && !hadCowboy)) {
			controller.ensureSantaStats();
		}
		syncFromController();
	}

	public function step(input:LocalPlayerInput):Void {
		controller.propellerHatActive = hasHatFlag(Character.PROP);
		controller.cowboyHatActive = hasHatFlag(Character.COWBOY);
		controller.crownHatActive = hasHatFlag(Character.CROWN);
		controller.santaHatActive = hasHatFlag(Character.SANTA);
		controller.partyHatActive = hasHatFlag(Character.PARTY);
		controller.topHatActive = hasHatFlag(Character.TOP);
		controller.step(input);
		syncFromController();
	}

	public function initNetworkEmission():Void {
		framesSinceUpdate = 0;
		exactX = 0;
		exactY = 0;
		exactPosNextUpdate = true;
		LobbySocket.write("p`0`0");
	}

	public function emitNetworkUpdate(?parentLayer:Null<String>):Void {
		x = Math.round(x);
		y = Math.round(y);
		updateSegs(characterRotation);
		framesSinceUpdate++;
		if (framesSinceUpdate >= updateInterval) {
			if (playersInPosUpdateRange() || framesSinceUpdate >= 16) {
				framesSinceUpdate = 0;
				var curX = Math.round(x);
				var curY = Math.round(y);
				var deltaX = curX - exactX;
				var deltaY = curY - exactY;
				exactX = curX;
				exactY = curY;
				if (deltaX != 0 || deltaY != 0) {
					LobbySocket.write('p`$deltaX`$deltaY');
				}
				if (exactPosNextUpdate) {
					exactPosNextUpdate = false;
					LobbySocket.write('exact_pos`$curX`$curY');
				}
			}
			emitChangedVars(parentLayer);
		}
	}

	public function forceExactPositionOnNextUpdate():Void {
		exactPosNextUpdate = true;
	}

	public function setNetworkRotation(rotation:Int):Void {
		this.rotation = Math.round(rotation);
		LobbySocket.write("set_var`rotMod`" + this.rotation);
	}

	override public function rotate(direction:String):Void {
		super.rotate(direction);
		// Safe-coordinate rotation is owned by the delegated controller during
		// live physics; keep the network side-effect here for the multiplayer port.
		LobbySocket.write("set_var`rot`" + -controller.courseRotation);
		exactPosNextUpdate = true;
	}

	public function emitSquash(remoteTempId:Int):Void {
		LobbySocket.write('squash`$remoteTempId`' + Math.round(x) + "`" + Math.round(y));
	}

	public function emitSting(remoteTempId:Int):Void {
		LobbySocket.write('sting`$remoteTempId`' + Math.round(x) + "`" + Math.round(y));
	}

	public function emitHeart(remoteTempId:Int):Void {
		LobbySocket.write('heart`$remoteTempId`' + Math.round(x) + "`" + Math.round(y));
	}

	public function emitLooseHat(hatId:Int, hatColor:Int = 0, hatColor2:Int = -1):Void {
		LobbySocket.write('loose_hat`$hatId`$hatColor`$hatColor2`' + Math.round(x) + "`" + Math.round(y));
	}

	public function emitHatToStart(hatId:Int):Void {
		LobbySocket.write('hat_to_start`$hatId');
	}

	public function emitGrabEgg(eggId:Int):Void {
		LobbySocket.write('grab_egg`$eggId');
	}

	public function emitObjectiveReached(finishId:Int, finishX:Int, finishY:Int):Void {
		LobbySocket.write('objective_reached`$finishId`$finishX`$finishY');
	}

	public function emitFinishRace(finishId:Int, finishX:Int, finishY:Int):Void {
		LobbySocket.write('finish_race`$finishId`$finishX`$finishY');
	}

	public function emitQuitRace():Void {
		LobbySocket.write("quit_race`");
	}

	public function emitFinishDrawing(levelHash:String, gameMode:String, finishBlockPositions:String, finishBlockCount:Int, cowboyChance:Int,
			badHats:Array<Int>):Void {
		LobbySocket.write('finish_drawing`$levelHash`$gameMode`$finishBlockPositions`$finishBlockCount`$cowboyChance`' + badHats.join(","));
	}

	public function emitCheckHatCountdown():Void {
		LobbySocket.write("check_hat_countdown`");
	}

	public function beginSparklesNetwork():Void {
		LobbySocket.write("set_var`sparkle`1");
		beginSparkles();
	}

	public function endSparklesNetwork():Void {
		LobbySocket.write("set_var`sparkle`0");
		endSparkles();
	}

	public function beginJetNetwork():Void {
		LobbySocket.write("set_var`jet`1");
		beginJet();
	}

	public function endJetNetwork():Void {
		LobbySocket.write("set_var`jet`0");
		endJet();
	}

	override public function beginRemove():Void {
		changeState("freeze");
		LobbySocket.write("set_var`beginRemove`1");
		super.beginRemove();
	}

	public function setGravity(multiplier:Float):Void {
		controller.setGravity(multiplier);
	}

	public function setAllowedItems(items:Array<Int>):Void {
		controller.setAllowedItems(items);
	}

	public function setGameMode(mode:String):Void {
		controller.setGameMode(mode);
		syncFromController();
	}

	public function setStats(speed:Float, acceleration:Float, jump:Float):Void {
		controller.setStats(speed, acceleration, jump);
		syncFromController();
	}

	public function debugState():LocalPlayerDebugState {
		return controller.debugState();
	}

	public function blockAlphaAt(tileX:Int, tileY:Int):Float {
		return controller.blockAlphaAt(tileX, tileY);
	}

	public function blockColorMultiplierAt(tileX:Int, tileY:Int):Float {
		return controller.blockColorMultiplierAt(tileX, tileY);
	}

	public function consumeBlockVisualEvents():Array<pr2.harness.BlockVisualEvent> {
		return controller.consumeBlockVisualEvents();
	}

	public function activeVisualBlockKeys():Array<String> {
		return controller.activeVisualBlockKeys();
	}

	public function freeze():Void {
		controller.freeze();
		syncFromController();
	}

	public function isFrozen():Bool {
		return controller.isFrozen();
	}

	public function receiveSting():Void {
		controller.receiveSting();
		syncFromController();
	}

	public function receiveZap():Void {
		controller.receiveZap();
		syncFromController();
	}

	private function syncFromController():Void {
		var state = controller.debugState();
		x = state.x;
		y = state.y;
		velX = state.vx;
		velY = state.vy;
		setItem(state.itemId == null ? 0 : state.itemId);
		changeState(state.animation);
		display.scaleX = 0.9 * controller.facingScaleX;
		display.scaleY = 0.9;
	}

	private function emitChangedVars(?parentLayer:Null<String>):Void {
		if (lastNetScaleX == null || lastNetScaleX != display.scaleX) {
			lastNetScaleX = display.scaleX;
			LobbySocket.write("set_var`scaleX`" + display.scaleX);
		}
		if (lastNetState != state) {
			lastNetState = state;
			LobbySocket.write("set_var`state`" + state);
		}
		if (parentLayer != null && lastNetParent != parentLayer) {
			lastNetParent = parentLayer;
			LobbySocket.write("set_var`parent`" + parentLayer);
		}
		if (lastNetItem != item) {
			lastNetItem = item;
			LobbySocket.write("set_var`item`" + item);
		}
	}

	private function playersInPosUpdateRange():Bool {
		return networkPlayerCount > 1;
	}

	private function get_grounded():Bool {
		return controller.grounded;
	}

	private function get_crouching():Bool {
		return controller.crouching;
	}

	private function get_facingScaleX():Int {
		return controller.facingScaleX;
	}

	private function get_courseTweenRotation():Int {
		return controller.courseTweenRotation;
	}

	private function get_characterRotation():Int {
		return controller.characterRotation;
	}

	private function get_lastSafeX():Float {
		return controller.lastSafeX;
	}

	private function get_lastSafeY():Float {
		return controller.lastSafeY;
	}
}
