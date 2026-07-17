package pr2.levelEditor;

import openfl.events.Event;
import openfl.text.TextField;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.ui.controls.GameCheckBox;
import pr2.util.DisplayUtil;
import pr2.levelEditor.EditorPersistenceTypes.SaveLevelUploadFactory;

class SaveLevelPopup extends Popup {
	public static var uploadFactory:SaveLevelUploadFactory = defaultUpload;

	public final editor:LevelEditor;
	public var art(default, null):Null<SaveLevelView>;
	private var bindings:Array<Binding> = [];

	public function new(editor:LevelEditor) {
		super();
		this.editor = editor;
		art = new SaveLevelView();
		addChild(art);
		var titleBox = titleField();
		if (titleBox != null) {
			titleBox.text = editor.title;
			titleBox.addEventListener(Event.CHANGE, countChars);
		}
		var noteBox = noteField();
		if (noteBox != null) {
			noteBox.text = editor.note;
			noteBox.addEventListener(Event.CHANGE, countChars);
		}
		var publish = publishCheck();
		var newest = newestCheck();
		if (editor.live == 1 && publish != null) {
			publish.selected = true;
			if (newest != null) {
				newest.enabled = true;
				newest.selected = editor.toNewest;
			}
		} else if (newest != null) {
			newest.enabled = false;
			newest.selected = false;
		}
		if (publish != null) {
			publish.addEventListener(Event.CHANGE, updateChks);
		}
		bind("cancel_bt", function():Void startFadeOut());
		bind("save_bt", clickSave);
		countChars();
	}

	private function countChars(?_:Event):Void {
		var titleCount = LobbyArt.text(art, "titleCharsRemaining");
		if (titleCount != null) {
			titleCount.text = fieldText(titleField()).length + " / 50";
		}
		var noteCount = LobbyArt.text(art, "noteCharsRemaining");
		if (noteCount != null) {
			noteCount.text = fieldText(noteField()).length + " / 255";
		}
	}

	private function updateChks(?_:Event):Void {
		var newest = newestCheck();
		if (newest == null) {
			return;
		}
		var selected = publishCheck() != null && publishCheck().selected;
		newest.enabled = selected;
		newest.selected = selected;
	}

	private function clickSave():Void {
		var title = fieldText(titleField());
		if (title == "") {
			new MessagePopup("I'm not sure what would happen if you didn't enter a title, but it would probably destroy the world.");
			return;
		}
		editor.title = title;
		editor.note = fieldText(noteField());
		editor.live = publishCheck() != null && publishCheck().selected ? 1 : 0;
		editor.toNewest = newestCheck() != null && newestCheck().selected;
		uploadFactory(editor);
		startFadeOut();
	}

	override public function remove():Void {
		var titleBox = titleField();
		if (titleBox != null) {
			titleBox.removeEventListener(Event.CHANGE, countChars);
		}
		var noteBox = noteField();
		if (noteBox != null) {
			noteBox.removeEventListener(Event.CHANGE, countChars);
		}
		var publish = publishCheck();
		if (publish != null) {
			publish.removeEventListener(Event.CHANGE, updateChks);
		}
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.findByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function titleField():Null<TextField> {
		return LobbyArt.text(art, "titleBox");
	}

	private function noteField():Null<TextField> {
		return LobbyArt.text(art, "noteBox");
	}

	private function publishCheck():Null<GameCheckBox> {
		return Std.downcast(DisplayUtil.findByName(art, "publish_chk"), GameCheckBox);
	}

	private function newestCheck():Null<GameCheckBox> {
		return Std.downcast(DisplayUtil.findByName(art, "newest_chk"), GameCheckBox);
	}

	private static function fieldText(field:Null<TextField>):String {
		return field == null || field.text == null ? "" : field.text;
	}

	public static function defaultUpload(editor:LevelEditor):Null<Popup> {
		return new UploadingLevelPopup(editor);
	}
}
