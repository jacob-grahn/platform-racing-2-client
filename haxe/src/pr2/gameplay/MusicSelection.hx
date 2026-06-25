package pr2.gameplay;

import openfl.events.Event;
import pr2.audio.GameMusic;
import pr2.audio.MusicCatalog;
import pr2.audio.MusicCatalog.MusicTrack;
import pr2.lobby.account.Settings;
import pr2.runtime.FlComboBox;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `gameplay.MusicSelection` and its `ui.GameSound` dropdown.
**/
class MusicSelection extends openfl.display.Sprite {
	private var art:Null<PR2MovieClip>;
	private var music:Null<GameMusic>;
	private var songs:Array<MusicTrack>;

	public final dropdown:FlComboBox;

	public function new(?music:GameMusic) {
		super();
		art = PR2MovieClip.fromLinkage("MusicSelectionGraphic", {maxNestedDepth: 5});
		addChild(art);

		this.music = music == null ? new GameMusic() : music;
		songs = MusicCatalog.enabled(Settings.disabledSongs());
		dropdown = new FlComboBox();
		dropdown.x = 7;
		dropdown.y = 7;
		dropdown.setSize(200, 22);
		dropdown.rowCount = 4;
		for (song in songs) dropdown.addItem(song);
		dropdown.selectedIndex = 0;
		dropdown.addEventListener(Event.CHANGE, changeSong);
		addChild(dropdown);
	}

	public function setSong(songId:String, ?randomIndex:Int):Void {
		var index = MusicCatalog.select(songs, songId, randomIndex == null ? Std.random(0x3FFFFFFF) : randomIndex);
		dropdown.selectedIndex = index;
		music.setSong(songs[index]);
	}

	public function gotArtifact():Void {
		for (song in songs) {
			if (song.id == MusicCatalog.ARTIFACT.id) {
				setSong(song.id);
				return;
			}
		}
		songs.push(MusicCatalog.ARTIFACT);
		dropdown.addItem(MusicCatalog.ARTIFACT);
		setSong(MusicCatalog.ARTIFACT.id);
	}

	public function selectedSongId():String {
		var selected:MusicTrack = cast dropdown.selectedItem;
		return selected == null ? "" : selected.id;
	}

	private function changeSong(_:Event):Void {
		var selected:MusicTrack = cast dropdown.selectedItem;
		if (selected != null) music.setSong(selected);
		if (stage != null) stage.focus = stage;
	}

	public function remove():Void {
		dropdown.removeEventListener(Event.CHANGE, changeSong);
		if (dropdown.parent == this) removeChild(dropdown);
		if (music != null) {
			music.remove();
			music = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		songs = [];
		if (parent != null) parent.removeChild(this);
	}
}
