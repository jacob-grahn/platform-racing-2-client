package pr2.mobile;

/** The Messages editor in the shared modal shell; no inbox request or badge reset. */
class MobileComposePopup extends MobilePanelPopup {
	private var editor:MobileMessagesPage;
	private var focusName:Bool;
	public function new(to:String, body:String = "", guild:Bool = false, focusName:Bool = false) {
		super(guild ? "GUILD MESSAGE" : "PRIVATE MESSAGE");
		this.focusName = focusName;
		editor = new MobileMessagesPage(); editor.setupComposer(to, body, guild);
		editor.onComposerClose = startFadeOut; content.addChild(editor); editor.initialize();
		layoutForSize(w,h);
		addEventListener(pr2.lobby.dialogs.Popup.LOADED, focusEditor);
	}
	private function focusEditor(_:openfl.events.Event):Void { removeEventListener(pr2.lobby.dialogs.Popup.LOADED, focusEditor); if (editor != null) editor.focusComposer(focusName); }
	override private function resizeContent(width:Float,height:Float):Void { if (editor != null) editor.setLayout(width,height); }
	override public function remove():Void { removeEventListener(pr2.lobby.dialogs.Popup.LOADED, focusEditor); if (editor != null) editor.remove(); editor = null; super.remove(); }
}
