package pr2.lobby.dialogs;

import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.runtime.PR2MovieClip;
import pr2.Constants;
import openfl.events.TextEvent;
import openfl.text.TextField;

/**
	Port of Flash `menu.CreditsPopup`: the credits modal reached from the lobby
	bottom strip. Renders the authored `CreditsPopupGraphic` and wires the close
	button to fade out, matching the base `Popup` lifecycle.

	The XFL authors inactive credit pages on hidden layers. This popup opts into
	instantiating those layers, then applies the same initial state and link-driven
	pagination as the original ActionScript.
**/
class CreditsPopup extends Popup {
	public var artPage(default, null):Int = 1;
	public var musicPage(default, null):Int = 1;

	private var art:PR2MovieClip;
	private var closeBinding:Null<Binding>;
	private var artNav:Null<TextField>;
	private var musicNav:Null<TextField>;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("CreditsPopupGraphic", {maxNestedDepth: 4, includeHiddenLayers: true});
		addChild(art);
		setText("versionBox", "PR2 v" + Constants.VERSION + (Constants.BETA ? " Beta" : ""));
		setText("buildBox", "Build: " + Constants.BUILD);
		setPageVisible("artPg1", true);
		setPageVisible("artPg2", false);
		setPageVisible("artPg3", false);
		setPageVisible("musicPg1", true);
		setPageVisible("musicPg2", false);

		artNav = findText("art_nav_bts");
		musicNav = findText("music_nav_bt");
		updateArtNav();
		updateMusicNav();
		if (artNav != null) artNav.addEventListener(TextEvent.LINK, clickArtNav);
		if (musicNav != null) musicNav.addEventListener(TextEvent.LINK, clickMusicNav);
		closeBinding = LobbyArt.bind(LobbyArt.findByName(art, "close_bt"), function():Void startFadeOut());
	}

	private function clickArtNav(event:TextEvent):Void {
		var next = event.text == "artBack" ? artPage - 1 : artPage + 1;
		if (next < 1 || next > 3) return;
		setPageVisible("artPg" + artPage, false);
		artPage = next;
		setPageVisible("artPg" + artPage, true);
		updateArtNav();
	}

	private function clickMusicNav(_:TextEvent):Void {
		setPageVisible("musicPg" + musicPage, false);
		musicPage = musicPage == 1 ? 2 : 1;
		setPageVisible("musicPg" + musicPage, true);
		updateMusicNav();
	}

	private function updateArtNav():Void {
		if (artNav == null) return;
		var links = [];
		if (artPage > 1) links.push('<a href="event:artBack">(&lt;- back)</a>');
		if (artPage < 3) links.push('<a href="event:artNext">(next -&gt;)</a>');
		artNav.htmlText = links.join(" ");
	}

	private function updateMusicNav():Void {
		if (musicNav != null) {
			musicNav.htmlText = '<a href="event:musicToggle">' + (musicPage == 2 ? "(&lt;- back)" : "(more -&gt;)") + "</a>";
		}
	}

	private function findText(name:String):Null<TextField> {
		return Std.downcast(LobbyArt.findByName(art, name), TextField);
	}

	private function setText(name:String, value:String):Void {
		var field = findText(name);
		if (field != null) field.text = value;
	}

	private function setPageVisible(name:String, visible:Bool):Void {
		var page = LobbyArt.findByName(art, name);
		if (page != null) page.visible = visible;
	}

	override public function remove():Void {
		if (artNav != null) artNav.removeEventListener(TextEvent.LINK, clickArtNav);
		if (musicNav != null) musicNav.removeEventListener(TextEvent.LINK, clickMusicNav);
		artNav = null;
		musicNav = null;
		LobbyArt.unbind(closeBinding);
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
