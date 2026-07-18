package pr2.gameplay;

import openfl.events.Event;
import openfl.display.Shape;
import openfl.display.Sprite;
import pr2.audio.GameMusic;
import pr2.audio.MusicCatalog;
import pr2.audio.MusicCatalog.MusicTrack;
import pr2.display.Removable;
import pr2.lobby.account.Settings;
import pr2.ui.StageFocus;
import pr2.ui.controls.GameSelect;
import pr2.runtime.SvgAsset;

/**
	Port of Flash `gameplay.MusicSelection` and its `ui.GameSound` dropdown.
**/
class MusicSelection extends Removable {
	public static inline final BACKGROUND_ASSET = "assets/svg/effects/music_selection_01.svg";

	private var art:Null<Sprite>;
	private var music:Null<GameMusic>;
	private var songs:Array<MusicTrack>;

	public final dropdown:GameSelect<MusicTrack>;
	public final exactBackground:Shape;

	public function new(?music:GameMusic) {
		super();
		art = new Sprite();
		exactBackground = SvgAsset.create(BACKGROUND_ASSET);
		art.addChild(exactBackground);
		addChild(art);

		this.music = music == null ? new GameMusic() : music;
		songs = MusicCatalog.enabled(Settings.disabledSongs());
		dropdown = new GameSelect<MusicTrack>();
		dropdown.x = 7;
		dropdown.y = 7;
		dropdown.setSize(200, 22);
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
		var selected = dropdown.selectedItem;
		return selected == null ? "" : selected.id;
	}

	private function changeSong(_:Event):Void {
		var selected = dropdown.selectedItem;
		if (selected != null) music.setSong(selected);
		StageFocus.reset();
	}

	override public function remove():Void {
		if (isRemoved()) return;
		dropdown.removeEventListener(Event.CHANGE, changeSong);
		dropdown.dispose();
		if (dropdown.parent == this) removeChild(dropdown);
		if (music != null) {
			music.remove();
			music = null;
		}
		if (art != null) {
			if (art.parent != null) art.parent.removeChild(art);
			art = null;
		}
		songs = [];
		super.remove();
	}
}
