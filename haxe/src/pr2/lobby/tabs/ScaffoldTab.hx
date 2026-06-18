package pr2.lobby.tabs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.net.LobbySocket;
import pr2.page.Page;
import pr2.runtime.FontResolver;
import pr2.runtime.PR2MovieClip;

/**
	Shared base for lobby tab pages that already render their real Flash art and
	emit their gameserver room/list commands, but whose live data rendering (level
	grids, message lists, player lists, character preview) is still being ported.

	Subclasses declare their art linkage and the socket commands to write on
	enter/leave. The base draws the art plus a small "pending live data" note so
	the tab is visually present and its command emission is testable through
	`LobbySocket`, while the remaining list/preview work is tracked per subclass.
**/
class ScaffoldTab extends Page {
	private var linkage:String;
	private var enterCommand:Null<String>;
	private var leaveCommand:Null<String>;
	private var note:String;
	private var art:Null<PR2MovieClip>;
	private var noteField:Null<TextField>;

	public function new(linkage:String, ?enterCommand:String, ?leaveCommand:String, note:String = "") {
		super();
		this.linkage = linkage;
		this.enterCommand = enterCommand;
		this.leaveCommand = leaveCommand;
		this.note = note;
	}

	override public function initialize():Void {
		art = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 8});
		addChild(art);
		onArtReady(art);
		if (note != "") {
			noteField = makeNote(note);
			addChild(noteField);
		}
		if (enterCommand != null) {
			LobbySocket.write(enterCommand);
		}
	}

	/** Hook for subclasses to wire controls once the art exists. */
	private function onArtReady(art:PR2MovieClip):Void {}

	/** Update the pending-data note (e.g. once an async list load resolves). */
	private function setNote(text:String):Void {
		if (noteField != null) {
			noteField.text = text;
		}
	}

	override public function remove():Void {
		if (leaveCommand != null) {
			LobbySocket.write(leaveCommand);
		}
		onTeardown();
		if (noteField != null && noteField.parent != null) {
			noteField.parent.removeChild(noteField);
		}
		noteField = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private function onTeardown():Void {}

	private static function makeNote(text:String):TextField {
		var field = new TextField();
		field.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 10, 0x6C7888, false, false, false, null, null, TextFormatAlign.CENTER);
		field.x = 10;
		field.y = 168;
		field.width = 320;
		field.height = 40;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = false;
		field.mouseEnabled = false;
		field.text = text;
		return field;
	}
}
