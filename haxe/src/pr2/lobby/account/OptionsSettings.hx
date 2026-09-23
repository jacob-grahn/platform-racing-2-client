package pr2.lobby.account;

import pr2.audio.AudioManager;

/** Shared persisted option rules used by classic and mobile settings views. */
class OptionsSettings {
	public static final SONGS:Map<Int,String> = [
		1=>"Orbital Trance", 2=>"Code", 3=>"Paradise on E", 4=>"Crying Soul", 5=>"My Vision", 6=>"Switchblade",
		7=>"The Wires", 8=>"Before Mydnite", 10=>"Broked It", 11=>"Hello?", 12=>"Pyrokinesis", 13=>"Flowers 'n' Herbs",
		14=>"Instrumental #4", 15=>"Prismatic", 17=>"Toodaloo", 18=>"Night Shade", 19=>"Blizzard!", 20=>"Pasture", 21=>"Sunset Raiders"
	];
	private function new() {}
	public static function setMusic(value:Float):Void { Settings.setValue(Settings.MUSIC_VOLUME, Std.int(value)); AudioManager.musicLevelChanged(); }
	public static function setSound(value:Float):Void Settings.setValue(Settings.SOUND_VOLUME, Std.int(value));
	public static function setDrawArt(value:Bool):Void Settings.setValue(Settings.DRAW_ART, value);
	public static function setSwearFilter(value:Bool):Void Settings.setValue(Settings.FILTER_SWEARS, value);
	public static function setSongEnabled(songId:Int, enabled:Bool):Void {
		if (!SONGS.exists(songId)) return;
		var disabled:Array<Int> = [];
		for (value in Settings.disabledSongs()) {
			var id = Std.parseInt(value);
			if (id != null && disabled.indexOf(id) < 0) disabled.push(id);
		}
		if (enabled) disabled.remove(songId); else if (disabled.indexOf(songId) < 0) disabled.push(songId);
		setDisabledSongs(disabled);
	}
	public static function setDisabledSongs(disabled:Array<Int>):Void Settings.setValue(Settings.DISABLED_SONGS, disabled);
	public static function controlCode(action:String):Int {
		var controls:Dynamic=Settings.getValue(Settings.ALTERNATE_CONTROLS,Settings.DEFAULT_ALT_CONTROLS);
		var code:Null<Int>=Reflect.field(controls,action);if(code==null)code=Reflect.field(Settings.DEFAULT_ALT_CONTROLS,action);
		return code==null?0:code;
	}
	public static function setControl(action:String, keyCode:Int):Void {
		if (["up","right","down","left","item"].indexOf(action) < 0 || !((keyCode >= 48 && keyCode <= 57) || (keyCode >= 65 && keyCode <= 90))) return;
		var patch:Dynamic = {}; Reflect.setField(patch, action, keyCode);
		Settings.setValue(Settings.ALTERNATE_CONTROLS, patch);
	}
}
