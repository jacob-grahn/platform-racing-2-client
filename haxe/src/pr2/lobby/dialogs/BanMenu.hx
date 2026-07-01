package pr2.lobby.dialogs;

import openfl.display.Sprite;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.LobbySession;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.runtime.FlComboBox;
import pr2.runtime.FlComponents;
import pr2.runtime.PR2MovieClip;

typedef BanUploadFactory = String->Map<String, String>->String->(Dynamic->Void)->(String->Void)->Null<UploadingPopup>;

/**
	Port of Flash `dialogs.BanMenu`: full moderators can warn, kick, view priors,
	and submit account/IP/social/game bans from player and guest popups.
**/
class BanMenu extends Sprite {
	public static var uploadFactory:BanUploadFactory = defaultUpload;

	private var art:Null<PR2MovieClip>;
	private var target:Popup;
	private var userName:String;
	private var banSecs:Int = 0;
	private var uploading:Null<UploadingPopup>;
	private var bindings:Array<Null<Binding>> = [];

	public function new(name:String, popup:Popup) {
		super();
		userName = name;
		target = popup;
		art = PR2MovieClip.fromLinkage("BanMenuGraphic", {maxNestedDepth: 4});
		addChild(art);

		if (!LobbySession.isTrialMod) {
			addDuration("Three Days", 259200);
			addDuration("One Week", 604800);
			addDuration("Two Weeks", 1209600);
			addDuration("One Month", 2592000);
			addDuration("Six Months", 15768000);
			addDuration("One Year", 31536000);
			var scope = combo("scope");
			if (scope != null) {
				scope.addItem({label: "Game", data: "game"});
				scope.enabled = true;
			}
		}

		bind("warning1Button", function():Void warnUser(1));
		bind("warning2Button", function():Void warnUser(2));
		bind("warning3Button", function():Void warnUser(3));
		bind("kickButton", clickKick);
		bind("banButton", confirmBan);
		bind("viewPriorsButton", viewPriors);
	}

	private function addDuration(label:String, data:Int):Void {
		var duration = combo("duration");
		if (duration != null) {
			duration.addItem({label: label, data: data});
		}
	}

	private function bind(name:String, handler:Void->Void):Void {
		bindings.push(LobbyArt.bind(LobbyArt.findByName(art, name), handler));
	}

	private function viewPriors():Void {
		if (LobbySocket.isConnected()) {
			LobbySocket.write("view_priors`" + userName);
		} else {
			new MessagePopup("Error: You are not connected to a server. Please log in and try again.");
		}
	}

	private function confirmBan():Void {
		banSecs = selectedDataInt(combo("duration"), 0);
		if (banSecs == 0) {
			new MessagePopup("Error: You must specify a ban length.");
			return;
		}
		var scope = selectedData(combo("scope"), "social");
		var scopeText = scope == "game" ? "ban" : "socially ban";
		var message = "Are you sure you want to " + scopeText + " " + userName + "?";
		if (scope == "game") {
			message += " They won't be able to log onto PR2 or use any of the pages on pr2hub.com.";
		} else {
			message += " They won't be able to register new accounts, use guest accounts, or use any messaging, contest, or guild-related features. They also won't be able to publish or rate levels.";
		}
		new ConfirmPopup(banUser, message);
	}

	private function banUser():Void {
		var fields:Map<String, String> = [
			"banned_name" => userName,
			"duration" => Std.string(banSecs),
			"reason" => reasonText(),
			"type" => selectedData(combo("type"), "both"),
			"scope" => selectedData(combo("scope"), "social"),
			"record" => ""
		];
		uploading = uploadFactory(ServerConfig.banUserUrl(), fields, "Banning...", onBanSuccess, onBanError);
	}

	private function onBanError(_:String):Void {
		target.startFadeOut();
	}

	private function onBanSuccess(parsedData:Dynamic):Void {
		var banId = 0;
		if (parsedData != null) {
			var raw:Dynamic = Reflect.field(parsedData, "ban_id");
			var parsed = Std.parseInt(Std.string(raw));
			if (parsed != null) {
				banId = parsed;
			}
		}
		LobbySocket.write("ban`" + userName + "`" + banSecs + "`" + selectedData(combo("scope"), "social") + "`" + banId + "`" + reasonText());
		target.startFadeOut();
	}

	private function warnUser(warnLevel:Int):Void {
		LobbySocket.write("warn`" + userName + "`" + warnLevel);
		target.startFadeOut();
	}

	private function clickKick():Void {
		new ConfirmPopup(kickUser,
			"Are you sure you want to kick " + userName + "? They will not be able to re-enter this server for 30 minutes.");
	}

	private function kickUser():Void {
		LobbySocket.write("kick`" + userName);
		target.startFadeOut();
	}

	private function combo(name:String):Null<FlComboBox> {
		return Std.downcast(LobbyArt.findByName(art, name), FlComboBox);
	}

	private function reasonText():String {
		var field = FlComponents.asTextField(LobbyArt.findByName(art, "reason"));
		return field == null ? "" : field.text;
	}

	private static function selectedData(combo:Null<FlComboBox>, fallback:String):String {
		if (combo == null || combo.selectedItem == null) {
			return fallback;
		}
		var data:Dynamic = Reflect.field(combo.selectedItem, "data");
		return data == null ? fallback : Std.string(data);
	}

	private static function selectedDataInt(combo:Null<FlComboBox>, fallback:Int):Int {
		var parsed = Std.parseInt(selectedData(combo, Std.string(fallback)));
		return parsed == null ? fallback : parsed;
	}

	public function remove():Void {
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		if (uploading != null) {
			uploading.startFadeOut();
			uploading = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	public static function defaultUpload(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
			onError:String->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult, onError);
	}
}
