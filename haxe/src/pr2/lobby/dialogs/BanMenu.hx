package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.lobby.chat.ChatText;
import pr2.lobby.tabs.ChatTab;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.runtime.FlComboBox;
import pr2.runtime.FlComponents;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;
import pr2.util.DisplayUtil;

typedef BanUploadFactory = String->Map<String, String>->String->(Dynamic->Void)->(String->Void)->Null<UploadingPopup>;

/**
	Port of Flash `dialogs.BanMenu`: full moderators can warn, kick, view priors,
	and submit account/IP/social/game bans from player and guest popups.
**/
class BanMenu extends Sprite {
	public static var uploadFactory:BanUploadFactory = defaultUpload;
	public static var chatRecordProvider:Void->String = defaultChatRecord;

	private var art:Null<BanMenuView>;
	private var target:Popup;
	private var userName:String;
	private var banSecs:Int = 0;
	private var uploading:Null<UploadingPopup>;
	private var uploadActive:Bool = false;
	private var bindings:Array<Null<Binding>> = [];

	public function new(name:String, popup:Popup) {
		super();
		userName = name;
		target = popup;
		art = new BanMenuView();
		addChild(art);

		if (LobbySession.isTrialMod) {
			restrictTrialModOptions();
		} else {
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

	private function restrictTrialModOptions():Void {
		var duration = combo("duration");
		if (duration != null) {
			var allowed:Array<Dynamic> = [];
			for (i in 0...duration.length) {
				var item = duration.dataProvider.getItemAt(i);
				var seconds = Std.parseInt(Std.string(Reflect.field(item, "data")));
				if (seconds != null && seconds <= 86400) {
					allowed.push(item);
				}
			}
			duration.removeAll();
			for (item in allowed) {
				duration.addItem({label: Reflect.field(item, "label"), data: Reflect.field(item, "data")});
			}
		}
		var scope = combo("scope");
		if (scope != null) {
			var allowedScopes:Array<Dynamic> = [];
			for (i in 0...scope.length) {
				var item = scope.dataProvider.getItemAt(i);
				if (Reflect.field(item, "data") != "game") {
					allowedScopes.push(item);
				}
			}
			scope.removeAll();
			for (item in allowedScopes) {
				scope.addItem({label: Reflect.field(item, "label"), data: Reflect.field(item, "data")});
			}
			scope.enabled = false;
		}
	}

	private function bind(name:String, handler:Void->Void):Void {
		bindings.push(LobbyArt.bind(DisplayUtil.findByName(art, name), handler));
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
		var message = "Are you sure you want to " + scopeText + " " + ChatText.escapeString(userName) + "?";
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
			"scope" => selectedData(combo("scope"), "social")
		];
		if (shouldIncludeChatRecord()) {
			fields.set("record", chatRecordProvider());
		}
		uploadActive = true;
		var popup = uploadFactory(ServerConfig.banUserUrl(), fields, "Banning...", onBanSuccess, onBanError);
		if (uploadActive) {
			uploading = popup;
		} else if (popup != null) {
			popup.startFadeOut();
		}
	}

	private function onBanError(_:String):Void {
		if (!uploadActive) {
			return;
		}
		uploadActive = false;
		uploading = null;
		target.startFadeOut();
	}

	private function onBanSuccess(parsedData:Dynamic):Void {
		if (!uploadActive) {
			return;
		}
		uploadActive = false;
		uploading = null;
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

	private static function shouldIncludeChatRecord():Bool {
		var room = Memory.getString("chatRoom", "");
		return room != "mod" && room != "admin";
	}

	public static function defaultChatRecord():String {
		return ChatTab.instance == null ? "" : ChatTab.instance.getChatRecord();
	}

	private function combo(name:String):Null<FlComboBox> {
		return Std.downcast(DisplayUtil.findByName(art, name), FlComboBox);
	}

	private function reasonText():String {
		var field = FlComponents.asTextField(DisplayUtil.findByName(art, "reason"));
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
		uploadActive = false;
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

private class BanMenuView extends NativeView {
	public function new() {
		super();
		name = "BanMenuGraphic";
		graphics.beginFill(0xF2F2F2, 0.98);
		graphics.lineStyle(1, 0x666666);
		graphics.drawRoundRect(-180, -112, 360, 224, 11, 11);
		graphics.endFill();
		label("-- Moderator Actions --", -135, -99, 270, 20, 14, true, TextFormatAlign.CENTER);
		button("warning1Button", "Warning 1", -164, -70, 76);
		button("warning2Button", "Warning 2", -83, -70, 76);
		button("warning3Button", "Warning 3", -2, -70, 76);
		button("kickButton", "30m Kick", 79, -70, 76);
		label("Duration", -164, -35, 66, 18, 10, false, TextFormatAlign.RIGHT);
		var duration = combo("duration", -92, -38, 104);
		duration.addItem({label: "30 Minutes", data: 1800});
		duration.addItem({label: "12 Hours", data: 43200});
		duration.addItem({label: "One Day", data: 86400});
		label("Type", 18, -35, 38, 18, 10, false, TextFormatAlign.RIGHT);
		var type = combo("type", 62, -38, 94);
		type.addItem({label: "Account + IP", data: "both"});
		type.addItem({label: "Account", data: "account"});
		type.addItem({label: "IP", data: "ip"});
		label("Scope", -164, -3, 66, 18, 10, false, TextFormatAlign.RIGHT);
		var scope = combo("scope", -92, -6, 104);
		scope.addItem({label: "Social", data: "social"});
		label("Reason", -164, 29, 66, 18, 10, false, TextFormatAlign.RIGHT);
		var reason = new TextField();
		reason.name = "reason";
		reason.x = -92;
		reason.y = 25;
		reason.width = 248;
		reason.height = 24;
		reason.type = TextFieldType.INPUT;
		reason.background = true;
		reason.backgroundColor = 0xFFFFFF;
		reason.border = true;
		reason.borderColor = 0x777777;
		reason.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x222222);
		addChild(reason);
		button("banButton", "Ban", -147, 66, 78);
		button("viewPriorsButton", "View Priors", -39, 66, 94);
	}

	private function combo(name:String, x:Float, y:Float, width:Float):FlComboBox {
		var control = new FlComboBox();
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 22);
		addChild(control);
		return control;
	}

	private function button(name:String, value:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		addChild(control);
	}

	private function label(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):Void {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
	}
}
