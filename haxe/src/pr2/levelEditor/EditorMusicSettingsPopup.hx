package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.app.AppStage;
import pr2.audio.MusicCatalog;
import pr2.audio.MusicCatalog.MusicTrack;
import pr2.lobby.dialogs.AutoDismissController;
import pr2.ui.controls.GameSelect;
import pr2.ui.StageFocus;

class EditorMusicSettingsPopup extends Sprite {
	public final editor:LevelEditor;
	public final art:EditorSettingsMenuView;
	public final dropdown:GameSelect<MusicTrack>;
	private final songs:Array<MusicTrack>;
	private var autoDismiss:Null<AutoDismissController>;
	private var removed:Bool = false;

	public function new(editor:LevelEditor, target:DisplayObject) {
		super();
		this.editor = editor;
		art = new EditorSettingsMenuView("music");
		addChild(art);
		songs = MusicCatalog.enabled([], true);
		dropdown = new GameSelect<MusicTrack>();
		dropdown.x = -100;
		dropdown.y = -15;
		dropdown.setSize(200, 22);
		for (song in songs) {
			dropdown.addOption(song.label, song);
		}
		selectSong(editor.song == "" ? "random" : editor.song);
		dropdown.addEventListener(Event.CHANGE, changeSong);
		addChild(dropdown);
		mountNear(target);
		autoDismiss = new AutoDismissController(this, remove);
	}

	public function selectedSongId():String {
		var selected = dropdown.selectedOption == null ? null : dropdown.selectedOption.value;
		return selected == null ? "" : selected.id;
	}

	public function setSelectedSongId(songId:String):Void {
		selectSong(songId);
		changeSong(null);
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (autoDismiss != null) {
			autoDismiss.remove();
			autoDismiss = null;
		}
		dropdown.removeEventListener(Event.CHANGE, changeSong);
		dropdown.dispose();
		if (dropdown.parent == this) {
			removeChild(dropdown);
		}
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.musicSettingsPopupRemoved(this);
	}

	private function selectSong(songId:String):Void {
		for (i in 0...songs.length) {
			if (songs[i].id == songId) {
				dropdown.selectedIndex = i;
				return;
			}
		}
		dropdown.selectedIndex = songs.length > 1 ? 1 : 0;
	}

	private function changeSong(_:Event):Void {
		var selected = dropdown.selectedOption == null ? null : dropdown.selectedOption.value;
		if (selected != null) {
			editor.setSong(selected.id);
		}
			StageFocus.reset();
	}

	private function mountNear(target:DisplayObject):Void {
		if (AppStage.stage == null) {
			return;
		}
		AppStage.stage.addChild(this);
		var targetBounds = target.getBounds(AppStage.stage);
		var popupBounds = getBounds(this);
		var popupWidth = popupBounds.width <= 0 ? 240 : popupBounds.width;
		var popupHeight = popupBounds.height <= 0 ? 115 : popupBounds.height;
		x = targetBounds.left > popupWidth ? targetBounds.left - popupWidth - 7 : targetBounds.right + 7;
		y = targetBounds.top;
		if (y < 0) {
			y = 0;
		}
		if (y + popupHeight > 400) {
			y = 400 - popupHeight;
		}
		x = Math.round(x);
		y = Math.round(y);
	}

}
