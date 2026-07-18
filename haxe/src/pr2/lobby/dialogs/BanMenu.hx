package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.lobby.chat.ChatText;
import pr2.lobby.tabs.ChatTab;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameSelect;
import pr2.ui.view.NativeView;

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
		bindings.push(LobbyArt.bind(art == null ? null : art.buttonNamed(name), handler));
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

	private function combo(name:String):Null<GameSelect<Dynamic>> {
		if (art == null) return null;
		return switch (name) {
			case "duration": art.durationSelect;
			case "type": art.typeSelect;
			case "scope": art.scopeSelect;
			default: null;
		};
	}

	private function reasonText():String {
		return art == null ? "" : art.reasonInput.text;
	}

	private static function selectedData(combo:Null<GameSelect<Dynamic>>, fallback:String):String {
		if (combo == null || combo.selectedItem == null) {
			return fallback;
		}
		var data:Dynamic = Reflect.field(combo.selectedItem, "data");
		return data == null ? fallback : Std.string(data);
	}

	private static function selectedDataInt(combo:Null<GameSelect<Dynamic>>, fallback:Int):Int {
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
	public final panel:DisplayObject;
	public final durationSelect:GameSelect<Dynamic>;
	public final typeSelect:GameSelect<Dynamic>;
	public final scopeSelect:GameSelect<Dynamic>;
	public final reasonInput:TextField;
	private final buttons:Map<String, GameButton> = [];

	public function buttonNamed(name:String):Null<GameButton> return buttons.get(name);

	public function new() {
		super();
		name = "BanMenuGraphic";
		panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.name = "panel";
		panel.x = -86;
		panel.y = -180;
		panel.scaleX = 0.632369995117188;
		panel.scaleY = 1.884765625;
		addChild(panel);
		var separator = new Shape();
		separator.name = "separator";
		separator.graphics.lineStyle(1, 0xCCCCCC);
		separator.graphics.moveTo(-66.5, -29);
		separator.graphics.lineTo(66.5, -29);
		addChild(separator);
		label("-- Mod --", "modTitle", -32.15, -172.1, 64.3, 17.05, 14, false, TextFormatAlign.CENTER);
		button("warning1Button", "Warning 1", -50, -147, 100);
		button("warning2Button", "Warning 2", -50, -121, 100);
		button("warning3Button", "Warning 3", -50, -95, 100);
		button("kickButton", "30 Minute Kick", -50, -69, 100);
		label("-- Ban --", "banTitle", -84, -17.55, 168, 17.05, 14, false, TextFormatAlign.CENTER);
		button("viewPriorsButton", "View Priors", -29, -2.5, 59.75, 14.55);
		label("Length", null, -78, 108.75, 46, 14.55, 12, false, TextFormatAlign.RIGHT);
		durationSelect = combo("duration", -24, 105.5, 100);
		var duration = durationSelect;
		duration.addItem({label: "Choose...", data: ""});
		duration.addItem({label: "One Hour", data: 3600});
		duration.addItem({label: "One Day", data: 86400});
		label("Type", null, -78, 51.75, 46, 14.55, 12, false, TextFormatAlign.RIGHT);
		typeSelect = combo("type", -24, 48.5, 100);
		var type = typeSelect;
		type.addItem({label: "Both", data: "both"});
		type.addItem({label: "Account Only", data: "account"});
		type.addItem({label: "IP Only", data: "ip"});
		label("Scope", null, -78, 80.25, 46, 14.55, 12, false, TextFormatAlign.RIGHT);
		scopeSelect = combo("scope", -24, 77, 100);
		var scope = scopeSelect;
		scope.addItem({label: "Social", data: "social"});
		scope.enabled = false;
		label("Reason", null, -78, 23.25, 46, 14.55, 12, false, TextFormatAlign.RIGHT);
		reasonInput = new TextField();
		var reason = reasonInput;
		reason.name = "reason";
		reason.x = -24;
		reason.y = 20;
		reason.width = 100;
		reason.height = 22;
		reason.maxChars = 100;
		reason.restrict = "^`";
		reason.type = TextFieldType.INPUT;
		reason.background = true;
		reason.backgroundColor = 0xFFFFFF;
		reason.border = true;
		reason.borderColor = 0x777777;
		reason.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x222222);
		addChild(reason);
		button("banButton", "Ban", -50, 140, 100);
	}

	private function combo(name:String, x:Float, y:Float, width:Float):GameSelect<Dynamic> {
		var control = ownControl(new GameSelect<Dynamic>());
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 22);
		addChild(control);
		return control;
	}

	private function button(name:String, value:String, x:Float, y:Float, width:Float, height:Float = 22):Void {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, height);
		addChild(control);
		buttons.set(name, control);
	}

	private function label(value:String, name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):Void {
		var field = new TextField();
		if (name != null) field.name = name;
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
