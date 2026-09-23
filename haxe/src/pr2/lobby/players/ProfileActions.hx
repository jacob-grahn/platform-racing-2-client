package pr2.lobby.players;

import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.lobby.LobbyRight;

/** Shared profile lifetime and navigation, independent of profile artwork. */
class ProfileActions {
	public static var active:Popup;
	public static var lookupUserHandler:Null<String->Void>;
	public static var activeGuild:Popup;
	public static function opened(popup:Popup):Void {
		if (active != null && active != popup) active.startFadeOut();
		closeGuild();
		active = popup;
	}
	public static function close():Void { if (active != null) active.startFadeOut(); }
	public static function removed(popup:Popup):Void { if (active == popup) active = null; }
	public static function guildOpened(popup:Popup):Void {
		if (activeGuild != null && activeGuild != popup) activeGuild.startFadeOut();
		if (active != null && active != popup) active.startFadeOut();
		active = null; activeGuild = popup;
	}
	public static function guildRemoved(popup:Popup):Void { if (activeGuild == popup) activeGuild = null; }
	public static function closeGuild():Void { if (activeGuild != null) activeGuild.startFadeOut(); }
	public static function levels(name:String):Void {
		if (lookupUserHandler != null) lookupUserHandler(name);
		else if (LobbyRight.instance != null) LobbyRight.instance.lookupUser(name);
		closeGuild();
		if (LevelInfoPopup.instance != null) LevelInfoPopup.instance.startFadeOut();
		close();
	}
	public static function guildFields(id:Int, name:String):Map<String,String> return ["target_name" => name, "user_id" => Std.string(id)];
}
