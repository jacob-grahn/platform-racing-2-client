package pr2.lobby.dialogs;

import haxe.Json;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import pr2.app.AppStage;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbySession;
import pr2.lobby.NumberFormat;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.runtime.PR2MovieClip;
import pr2.ui.CustomScrollBar;
import pr2.util.DisplayUtil;

/**
	Port of Flash `dialogs.GuildPopup`: loads `guild_info.php`, renders the
	authored guild popup, fills stats/prose/member rows, and exposes the member
	guild PM action for current guild members.
**/
class GuildPopup extends Popup {
	public static var instance:Null<GuildPopup>;

	private var art:Null<PR2MovieClip>;
	private var guildMembers:Array<GuildMemberName> = [];
	private var scroll:Null<CustomScrollBar>;
	private var closeBinding:Null<LobbyArt.Binding>;
	private var messageBinding:Null<LobbyArt.Binding>;
	private var titleBox:Null<TextField>;
	private var guildName:String = "";
	private var guildId:Int = 0;
	private var ownerId:Int = 0;
	private var guildIdShown:Bool = false;

	public function new(id:Int = 0, name:String = "", autoLoad:Bool = true) {
		if (GuildPopup.instance != null) {
			GuildPopup.instance.startFadeOut();
		}
		super();
		GuildPopup.instance = this;
		guildId = id;

		art = PR2MovieClip.fromLinkage("GuildPopupGraphic", {maxNestedDepth: 8});
		art.gotoAndStop("loading");
		closeBinding = LobbyArt.bind(DisplayUtil.findByName(art, "close_bt"), clickClose);
		addChild(art);

		if (autoLoad) {
			TextLoader.load(ServerConfig.guildInfoUrl(id, name), function(body:String):Void {
				if (fadeOutStarted) return;
				try {
					applyReturnData(Json.parse(body));
				} catch (_:Dynamic) {
					startFadeOut();
				}
			}, function(_:String):Void startFadeOut());
		}
	}

	public function applyReturnData(parsed:Dynamic):Void {
		if (art == null) return;
		var ret:Dynamic = Reflect.field(parsed, "guild");
		if (ret == null) ret = parsed;
		var members:Array<Dynamic> = cast Reflect.field(parsed, "members");
		if (members == null) members = [];

		guildId = intAny(ret, ["guild_id", "guildId"]);
		ownerId = intAny(ret, ["owner_id", "ownerId"]);
		guildName = strAny(ret, ["guild_name", "guildName"]);

		art.gotoAndStop(LobbySession.guildId != 0 && LobbySession.guildId == guildId ? "member" : "nonMember");
		titleBox = LobbyArt.text(art, "titleBox");
		setText("titleBox", "-- " + guildName + " --");
		setText("gpTodayBox", "GP Today: " + NumberFormat.withCommas(intAny(ret, ["gp_today", "gpToday"])));
		setText("gpTotalBox", "GP Total: " + NumberFormat.withCommas(intAny(ret, ["gp_total", "gpTotal"])));
		setText("membersCount", "Members: " + intAny(ret, ["member_count", "memberCount"]) + " (" + intAny(ret, ["active_count", "activeCount"]) + " active)");
		setText("guildProse", strField(ret, "note"));

		var loading = DisplayUtil.findByName(art, "loadingGraphic");
		if (loading != null) loading.visible = false;
		setVisible("edit_bt", LobbySession.group >= 2 && !LobbySession.isTrialMod);
		setVisible("delete_bt", LobbySession.group == 3);

		var holder = Std.downcast(DisplayUtil.findByName(art, "membersHolder"), DisplayObjectContainer);
		if (holder != null) {
			for (member in members) {
				var row = new GuildMemberName(member, ownerId != 0 && ownerId == intAny(member, ["user_id", "userId"]));
				row.y = guildMembers.length * 16;
				holder.addChild(row);
				guildMembers.push(row);
			}
			scroll = new CustomScrollBar();
			scroll.x = 126;
			scroll.y = -28;
			addChild(scroll);
			scroll.init(holder, 100, 100);
		}

		closeBinding = replaceBinding(closeBinding, DisplayUtil.findByName(art, "close_bt"), clickClose);
		if (LobbySession.guildId != 0 && LobbySession.guildId == guildId) {
			messageBinding = LobbyArt.bind(DisplayUtil.findByName(art, "messageButton"), clickMessage);
		}
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(KeyboardEvent.KEY_DOWN, toggleGuildIdShown);
			AppStage.stage.focus = AppStage.stage;
		}
	}

	private function clickMessage():Void {
		new SendMessagePopup("guild", "", true);
	}

	private function clickClose():Void {
		startFadeOut();
	}

	private function toggleGuildIdShown(e:KeyboardEvent):Void {
		if (e.keyCode != 16 || titleBox == null) return;
		titleBox.text = !guildIdShown ? "-- Guild ID: " + guildId + " --" : "-- " + guildName + " --";
		guildIdShown = !guildIdShown;
	}

	private function replaceBinding(binding:Null<LobbyArt.Binding>, target:Null<DisplayObject>, handler:Void->Void):Null<LobbyArt.Binding> {
		LobbyArt.unbind(binding);
		return LobbyArt.bind(target, handler);
	}

	private function setText(name:String, value:String):Void {
		var field = LobbyArt.text(art, name);
		if (field != null) field.text = value;
	}

	private function setVisible(name:String, value:Bool):Void {
		var target = DisplayUtil.findByName(art, name);
		if (target != null) target.visible = value;
	}

	private static function intAny(ret:Dynamic, names:Array<String>):Int {
		for (name in names) {
			var parsed = intField(ret, name);
			if (parsed != 0 || Reflect.hasField(ret, name)) return parsed;
		}
		return 0;
	}

	private static function intField(ret:Dynamic, name:String):Int {
		var value:Dynamic = Reflect.field(ret, name);
		if (value == null) return 0;
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) return Std.int(value);
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? 0 : parsed;
	}

	private static function strAny(ret:Dynamic, names:Array<String>):String {
		for (name in names) {
			var value = strField(ret, name);
			if (value != "") return value;
		}
		return "";
	}

	private static function strField(ret:Dynamic, name:String):String {
		var value:Dynamic = Reflect.field(ret, name);
		return value == null ? "" : Std.string(value);
	}

	override public function remove():Void {
		if (GuildPopup.instance == this) {
			GuildPopup.instance = null;
		}
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(KeyboardEvent.KEY_DOWN, toggleGuildIdShown);
		}
		LobbyArt.unbind(closeBinding);
		LobbyArt.unbind(messageBinding);
		closeBinding = null;
		messageBinding = null;
		for (member in guildMembers.copy()) {
			member.remove();
		}
		guildMembers = [];
		if (scroll != null) {
			scroll.remove();
			scroll = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		titleBox = null;
		super.remove();
	}
}
