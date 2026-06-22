package pr2.lobby.dialogs;

#if js
import js.Browser;
#end
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.runtime.PR2MovieClip;

/** Port of Flash `dialogs.ExternalLinkPopup`. */
class ExternalLinkPopup extends Popup {
	private static var instance:Null<ExternalLinkPopup>;

	/** Replaceable so the confirmation behavior can be tested without navigation. */
	public static var navigate:String->Void = defaultNavigate;

	public var url(default, null):String;

	private var art:PR2MovieClip;
	private var proceedBinding:Null<Binding>;
	private var closeBinding:Null<Binding>;

	public function new(url:String) {
		if (instance != null) instance.startFadeOut();
		super();
		instance = this;
		this.url = url;
		art = PR2MovieClip.fromLinkage("ExternalLinkPopupGraphic", {maxNestedDepth: 5});
		var linkBox = LobbyArt.text(art, "linkBox");
		if (linkBox != null) linkBox.text = url;
		addChild(art);
		proceedBinding = LobbyArt.bind(LobbyArt.findByName(art, "proceed_bt"), proceed);
		closeBinding = LobbyArt.bind(LobbyArt.findByName(art, "close_bt"), startFadeOut);
	}

	private function proceed():Void {
		navigate(url);
		startFadeOut();
	}

	private static function defaultNavigate(url:String):Void {
		#if js
		Browser.window.open(url, "_blank");
		#end
	}

	public static function resetNavigator():Void {
		navigate = defaultNavigate;
	}

	override public function remove():Void {
		if (instance == this) instance = null;
		LobbyArt.unbind(proceedBinding);
		LobbyArt.unbind(closeBinding);
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
