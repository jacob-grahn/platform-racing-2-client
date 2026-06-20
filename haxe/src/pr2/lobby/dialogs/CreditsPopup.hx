package pr2.lobby.dialogs;

import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `menu.CreditsPopup`: the credits modal reached from the lobby
	bottom strip. Renders the authored `CreditsPopupGraphic` and wires the close
	button to fade out, matching the base `Popup` lifecycle.

	The committed XFL `CreditsPopupGraphic` is the newer jiggmin2-era credits art.
	It carries the art (`artPg1`-`artPg3`) and music (`musicPg1`/`musicPg2`) page
	sub-symbols and the `close_bt` component, but it no longer exports the older
	decompiled `CreditsPopup.as` instances `versionBox`, `buildBox`, `art_nav_bts`,
	or `music_nav_bt`. Without those named instances there is nothing to drive the
	version/build text or the page-to-page navigation links.

	The symbol authors the later credit pages as the visible ones (`artPg3` and
	`musicPg2`); the earlier pages live on layers flagged `visible: false`, which
	`PR2MovieClip` does not instantiate at all, so they cannot be revealed at
	runtime. This port therefore shows the authored-visible pages and wires only
	the close button. The missing pagination nav and version/build display, and
	the unreachable earlier credit pages, are documented parity gaps (see
	`TODO.md`).
**/
class CreditsPopup extends Popup {
	private var art:PR2MovieClip;
	private var closeBinding:Null<Binding>;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("CreditsPopupGraphic", {maxNestedDepth: 4});
		addChild(art);
		closeBinding = LobbyArt.bind(LobbyArt.findByName(art, "close_bt"), function():Void startFadeOut());
	}

	override public function remove():Void {
		LobbyArt.unbind(closeBinding);
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
