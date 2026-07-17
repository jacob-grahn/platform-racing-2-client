package pr2.runtime;

/**
	Runtime-owned loader for the archival CharacterGraphic rig.

	CharacterDisplay owns all gameplay state, appearance, caching, and animation
	semantics; this boundary keeps catalog/timeline construction out of production
	feature code until each nested authored part is converted independently.
**/
class CharacterRigAsset {
	private function new() {}

	public static function create():PR2MovieClip {
		return PR2MovieClip.fromLinkage("CharacterGraphic", {maxNestedDepth: 12});
	}
}
