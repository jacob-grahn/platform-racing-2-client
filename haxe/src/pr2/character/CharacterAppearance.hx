package pr2.character;

import pr2.runtime.PR2MovieClip;

typedef CharacterPartIds = {
	var hat:Int;
	var head:Int;
	var body:Int;
	var feet:Int;
}

class CharacterAppearance {
	private static final STATE_CLIP_NAMES = [
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

	public static function applyPartIds(characterClip:PR2MovieClip, partIds:CharacterPartIds):Void {
		for (stateName in STATE_CLIP_NAMES) {
			var stateClip = getClipChild(characterClip, stateName);
			if (stateClip == null) {
				continue;
			}

			updatePart(stateClip, "head", partIds.head);
			updatePart(stateClip, "body", partIds.body);
			updatePart(stateClip, "foot1", partIds.feet);
			updatePart(stateClip, "foot2", partIds.feet);

			updateHat(stateClip, "hat1", partIds.hat, partIds.body);
			updateHat(stateClip, "hat2", 1, partIds.body);
			updateHat(stateClip, "hat3", 1, partIds.body);
			updateHat(stateClip, "hat4", 1, partIds.body);

			hideHeadFeetForFredBody(stateClip, partIds.body);
		}
	}

	private static function updatePart(stateClip:PR2MovieClip, childName:String, partId:Int):Void {
		var part = getClipChild(stateClip, childName);
		gotoPartFrame(part, partId);
	}

	private static function updateHat(stateClip:PR2MovieClip, hatName:String, hatId:Int, bodyId:Int):Void {
		var container = getClipChild(stateClip, bodyId == 29 ? "body" : "head");
		if (container == null) {
			return;
		}
		gotoPartFrame(getClipChild(container, hatName), hatId);
	}

	private static function gotoPartFrame(part:Null<PR2MovieClip>, partId:Int):Void {
		if (part == null) {
			return;
		}

		part.gotoAndStop(partId);

		var colorMC = getClipChild(part, "colorMC");
		if (colorMC != null) {
			colorMC.gotoAndStop(partId);
		}

		var colorMC2 = getClipChild(part, "colorMC2");
		if (colorMC2 != null) {
			colorMC2.gotoAndStop(partId);
		}
	}

	private static function hideHeadFeetForFredBody(stateClip:PR2MovieClip, bodyId:Int):Void {
		var visible = bodyId != 29;
		setChildVisible(stateClip, "head", visible);
		setChildVisible(stateClip, "foot1", visible);
		setChildVisible(stateClip, "foot2", visible);
	}

	private static function setChildVisible(parent:PR2MovieClip, childName:String, visible:Bool):Void {
		var child = parent.getChildByTimelineName(childName);
		if (child != null) {
			child.visible = visible;
		}
	}

	private static function getClipChild(parent:PR2MovieClip, childName:String):Null<PR2MovieClip> {
		return Std.downcast(parent.getChildByTimelineName(childName), PR2MovieClip);
	}

	private function new() {}
}
