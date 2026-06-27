package pr2.gameplay;

import pr2.lobby.dialogs.Popup;
import pr2.runtime.PR2MovieClip;
import pr2.gameplay.SpecialEvent.PlaceArtifactRequest;

/**
	Authored artifact-placement prompt shell opened by `SpecialEvent`.

	The date/submit upload flow remains part of the larger PlaceArtifact task; this
	class preserves the singleton popup behavior and the placement payload selected
	from the course click.
**/
class PlaceArtifact extends Popup {
	public static var instance:Null<PlaceArtifact>;

	public final request:PlaceArtifactRequest;
	private var art:Null<PR2MovieClip>;

	public function new(request:PlaceArtifactRequest) {
		super();
		this.request = request;
		if (PlaceArtifact.instance != null) {
			remove();
			return;
		}
		PlaceArtifact.instance = this;
		art = PR2MovieClip.fromLinkage("PlaceArtifactGraphic", {maxNestedDepth: 6});
		addChild(art);
	}

	override public function remove():Void {
		if (PlaceArtifact.instance == this) {
			PlaceArtifact.instance = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
