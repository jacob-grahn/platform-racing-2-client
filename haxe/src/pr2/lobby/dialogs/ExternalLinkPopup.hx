package pr2.lobby.dialogs;

#if js
import js.Browser;
#end

/** Port of Flash `dialogs.ExternalLinkPopup`. */
class ExternalLinkPopup extends Popup {
	private static var instance:Null<ExternalLinkPopup>;

	/** Replaceable so the confirmation behavior can be tested without navigation. */
	public static var navigate:String->Void = defaultNavigate;

	public var url(default, null):String;

	private var art:ExternalLinkView;

	public function new(url:String) {
		if (instance != null) instance.startFadeOut();
		super();
		instance = this;
		this.url = url;
		art = new ExternalLinkView(url);
		addChild(art);
		art.onProceed = proceed;
		art.onClose = startFadeOut;
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
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
