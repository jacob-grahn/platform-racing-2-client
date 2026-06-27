package pr2.gameplay;

import openfl.ui.Keyboard;
import pr2.lobby.LobbySession;
import pr2.net.LobbySocket;

typedef PlaceArtifactRequest = {
	final levelId:Int;
	final x:Int;
	final y:Int;
	final rot:Int;
}

enum SpecialEventAction {
	NoAction;
	PlaceArtifactAction(request:PlaceArtifactRequest);
	CancelPrizeAction;
}

/**
	Ports the click-hotkey decision from Flash `gameplay.SpecialEvent`.

	Privileged users can hold G+C and click the course to open the artifact
	placement prompt, or hold C+X while a prize is active to emit `cancel_prize`.
**/
class SpecialEvent {
	private final writeCommand:String->Void;
	private final openPlaceArtifact:PlaceArtifactRequest->Void;
	private final pressed:Map<UInt, Bool> = new Map();

	public function new(?writeCommand:String->Void, ?openPlaceArtifact:PlaceArtifactRequest->Void) {
		this.writeCommand = writeCommand == null ? LobbySocket.write : writeCommand;
		this.openPlaceArtifact = openPlaceArtifact == null ? function(request:PlaceArtifactRequest):Void new PlaceArtifact(request) : openPlaceArtifact;
	}

	public function keyDown(keyCode:UInt):Void {
		pressed.set(keyCode, true);
	}

	public function keyUp(keyCode:UInt):Void {
		pressed.remove(keyCode);
	}

	public function click(stageX:Float, stageY:Float, course:Null<Course>, currentPrize:Dynamic):SpecialEventAction {
		if (!canUse()) {
			return NoAction;
		}
		if (isPressed(Keyboard.G) && isPressed(Keyboard.C)) {
			if (course == null) {
				return NoAction;
			}
			var request = course.artifactPlacementAt(stageX, stageY);
			openPlaceArtifact(request);
			return PlaceArtifactAction(request);
		}
		if (isPressed(Keyboard.C) && isPressed(Keyboard.X) && currentPrize != null) {
			writeCommand("cancel_prize`");
			return CancelPrizeAction;
		}
		return NoAction;
	}

	public static function canUse():Bool {
		return LobbySession.group == 3
			|| LobbySession.isSpecialUser
			|| LobbySession.isPrizer
			|| (LobbySession.group == 2 && !LobbySession.isTempMod && !LobbySession.isTrialMod);
	}

	private function isPressed(keyCode:UInt):Bool {
		return pressed.exists(keyCode);
	}
}
