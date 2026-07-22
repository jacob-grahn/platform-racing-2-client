package pr2.gameplay;

import pr2.character.Character;
import pr2.character.LocalCharacter;
import pr2.character.RemoteCharacter;
import pr2.effects.StingEffect;
import pr2.effects.ZapEffect;
import pr2.gameplay.GameCommandShell.LocalCharacterInit;
import pr2.gameplay.GameCommandShell.RemoteCharacterInit;
import pr2.lobby.LobbySession;

/** Owns race command registration and the local/remote character roster lifecycle. */
@:access(pr2.gameplay.Course)
class CourseRosterController {
	private final owner:Course;

	public function new(owner:Course) {
		this.owner = owner;
	}

	public function createLocalCharacter(init:LocalCharacterInit):LocalCharacter {
		if (owner.localCharacter == null) {
			return null;
		}
		unregisterLocalCommands();
		var previousTempId = owner.localCharacter.tempID;
		if (owner.playerArray != null && previousTempId >= 0 && previousTempId < owner.playerArray.length && owner.playerArray[previousTempId] == owner.localCharacter
				&& previousTempId != init.tempId) {
			owner.playerArray[previousTempId] = null;
		}
		owner.localCharacter.tempID = init.tempId;
		owner.localCharacter.groupStr = init.group;
		owner.localCharacter.setHatId(Std.int(init.hatId));
		owner.localCharacter.setHeadId(Std.int(init.headId));
		owner.localCharacter.setBodyId(Std.int(init.bodyId));
		owner.localCharacter.setFeetId(Std.int(init.feetId));
		owner.localCharacter.setColors(Std.int(init.hatColor), Std.int(init.hatColor2), Std.int(init.headColor), Std.int(init.headColor2),
			Std.int(init.bodyColor), Std.int(init.bodyColor2), Std.int(init.feetColor), Std.int(init.feetColor2));
		if (owner.config.gameMode == Modes.roguelike) {
			owner.localCharacter.setStats(0, 0, 0);
		} else {
			owner.localCharacter.setStats(init.speed, init.accel, init.jump);
		}
		owner.playerArray[init.tempId] = owner.localCharacter;
		registerLocalCommands(init.tempId);
		owner.positionLocalAtStartCenter();
		return owner.localCharacter;
	}

	public function registerLocalCommands(tempId:Int):Void {
		owner.localCommandNames = ["zap", "setHats" + tempId, "squash" + tempId, "sting" + tempId];
		owner.commandHandler.defineCommand("zap", zapCommand);
		owner.commandHandler.defineCommand("setHats" + tempId, setLocalHatsCommand);
		owner.commandHandler.defineCommand("squash" + tempId, squashCommand);
		owner.commandHandler.defineCommand("sting" + tempId, stingCommand);
	}

	public function unregisterLocalCommands():Void {
		for (name in owner.localCommandNames) {
			owner.commandHandler.defineCommand(name, null);
		}
		owner.localCommandNames = [];
	}

	public function setLocalHatsCommand(args:Array<String>):Void {
		if (owner.localCharacter != null) {
			owner.localCharacter.setHats(args.length == 1 && args[0] == "" ? [] : [for (arg in args) Course.parseIntArg(arg)]);
		}
	}

	public function squashCommand(_:Array<String>):Void {
		if (owner.localCharacter == null) {
			return;
		}
		owner.localCharacter.receiveSquash();
	}

	public function stingCommand(args:Array<String>):Void {
		if (owner.localCharacter == null || owner.characterLayer == null || args.length == 0) {
			return;
		}
		var source = playerByTempId(Course.parseIntArg(args[0]));
		if (source == null || source == owner.localCharacter) {
			return;
		}
		var direction = source.x < owner.localCharacter.x ? "left" : (source.x > owner.localCharacter.x ? "right" : "");
		owner.characterLayer.addChild(new StingEffect(owner.localCharacter, direction));
		owner.localCharacter.receiveSting();
	}

	public function zapCommand(args:Array<String>):Void {
		if (owner.localCharacter == null || owner.characterLayer == null || args.length == 0) {
			return;
		}
		var sourceId = Course.parseIntArg(args[0]);
		for (character in owner.playerArray) {
			if (character != null && character.tempID != sourceId) {
				owner.characterLayer.addChild(new ZapEffect(character, true, false, false));
			}
		}
		if (sourceId == owner.localCharacter.tempID) {
			return;
		}
		owner.characterLayer.addChild(new ZapEffect(owner.localCharacter, true, true, true));
		owner.localCharacter.receiveZap();
	}

	public function playerByTempId(tempId:Int):Null<Character> {
		if (owner.playerArray == null || tempId < 0 || tempId >= owner.playerArray.length) {
			return null;
		}
		return owner.playerArray[tempId];
	}

	public function activateCommand(args:Array<String>):Void {
		if (owner.remoteBlockActivation == null || owner.localCharacter == null || args.length < 2) {
			return;
		}
		var segX = Course.parseIntArg(args[0]);
		var segY = Course.parseIntArg(args[1]);
		var payload = args.length > 2 ? args[2] : "";
		owner.recordCrumbleActivation(segX, segY, payload);
		if (owner.localCharacter.applyRemoteBlockActivation(segX, segY, payload)) {
			owner.syncBlockVisuals();
		} else {
			owner.remoteBlockActivation.activateSegment(segX, segY, payload);
		}
	}

	public function remoteBlockTouch(segX:Int, segY:Int):Void {
		if (owner.localCharacter != null
			&& owner.localCharacter.applyRemoteBlockTouch(segX, segY)) {
			owner.syncBlockVisuals();
		} else if (owner.remoteBlockActivation != null) {
			owner.remoteBlockActivation.touch(segX, segY);
		}
	}

	public function createRemoteCharacter(init:RemoteCharacterInit):RemoteCharacter {
		removeRemoteCharacter(init.tempId);
		var dot = owner.miniMap == null ? null : owner.miniMap.getDot();
		if (dot != null) {
			dot.setHoverInfo(init.tempId + 1, init.userName, true);
		}
		var remote = new RemoteCharacter(init.tempId, dot, init.userName, Std.int(init.hatId), Std.int(init.headId), Std.int(init.bodyId),
			Std.int(init.feetId), init.group, owner.commandHandler);
		remote.setHatsAllowed(owner.config.gameMode != Modes.roguelike);
		remote.setColors(Std.int(init.hatColor), Std.int(init.hatColor2), Std.int(init.headColor), Std.int(init.headColor2),
			Std.int(init.bodyColor), Std.int(init.bodyColor2), Std.int(init.feetColor), Std.int(init.feetColor2));
		if (owner.remoteBlockActivation != null) {
			remote.onBlockTouch = remoteBlockTouch;
		}
		remote.onPlayJumpSound = owner.playRemoteJumpSound;
		remote.onPlayCharacterSound = owner.playCharacterSound;
		remote.onStartJetSound = owner.startJetSound;
		remote.onStopJetSound = owner.stopJetSound;
		owner.particleEffects.install(remote);
		remote.onParentChange = function(parentLayer:String):Void {
			owner.moveCharacterToLayer(remote, parentLayer);
		};
		owner.remoteCharacters.set(init.tempId, remote);
		owner.playerArray[init.tempId] = remote;
		syncNetworkPlayerCount();
		if (owner.characterLayer != null) {
			owner.characterLayer.addChild(remote);
		}
		positionRemoteAtStartCenter(remote);
		return remote;
	}

	public function positionRemoteAtStartCenter(remote:RemoteCharacter):Void {
		if (remote == null || owner.levelRenderer == null || owner.startPositions.length == 0) {
			return;
		}
		var startIndex = LobbySession.tournamentMode ? 0 : remote.tempID;
		if (startIndex < 0 || startIndex >= owner.startPositions.length) {
			startIndex = 0;
		}
		var start = owner.startPositions[startIndex];
		// Flash stores every Character in map/world coordinates and lets
		// frontBackground/backBackground supply the camera translation.
		remote.setPos(start.x, start.y);
	}

	public function getRemoteCharacter(tempId:Int):Null<RemoteCharacter> {
		return owner.remoteCharacters == null ? null : owner.remoteCharacters.get(tempId);
	}

	public function remoteCharacterCount():Int {
		if (owner.remoteCharacters == null) {
			return 0;
		}
		var count = 0;
		for (_ in owner.remoteCharacters.keys()) {
			count++;
		}
		return count;
	}

	public function removeRemoteCharacter(tempId:Int):Void {
		if (owner.remoteCharacters == null) {
			return;
		}
		var remote = owner.remoteCharacters.get(tempId);
		if (remote == null) {
			return;
		}
		if (owner.snakeManager != null) {
			owner.snakeManager.stopOwner(tempId);
		}
		remote.remove();
		owner.remoteCharacters.remove(tempId);
		syncNetworkPlayerCount();
		if (owner.playerArray != null && tempId >= 0 && tempId < owner.playerArray.length) {
			owner.playerArray[tempId] = null;
		}
		if (owner.playerSpectating == remote) {
			owner.changeSpectate(-1);
			if (owner.spectatePicker != null) {
				owner.spectatePicker.stopSpectating();
			}
		}
	}

	public function syncNetworkPlayerCount():Void {
		if (owner.localCharacter != null) {
			owner.localCharacter.networkPlayerCount = remoteCharacterCount() + 1;
		}
	}

	public function removeAllRemoteCharacters():Void {
		if (owner.remoteCharacters == null) {
			return;
		}
		var ids = [for (id in owner.remoteCharacters.keys()) id];
		for (id in ids) {
			removeRemoteCharacter(id);
		}
	}

}
