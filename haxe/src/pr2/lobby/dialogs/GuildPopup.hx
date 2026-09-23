package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import pr2.app.AppStage;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbySession;
import pr2.lobby.NumberFormat;
import pr2.lobby.players.GuildData;
import pr2.lobby.players.GuildSource;
import pr2.lobby.players.ProfileActions;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;
import pr2.ui.CustomScrollBar;
import pr2.ui.EmblemLoader;
import pr2.ui.StageFocus;
import pr2.util.AsyncRemovalGuard;
import pr2.util.DisplayUtil;

typedef GuildDeleteFactory = String->Map<String, String>->SuperLoader;

/**
	Port of Flash `dialogs.GuildPopup`: loads `guild_info.php`, renders the
	authored guild popup, fills stats/prose/member rows, and exposes the member
	guild PM action for current guild members.
**/
class GuildPopup extends Popup {
	public static var instance:Null<GuildPopup>;
	public static var deleteFactory:GuildDeleteFactory = defaultDelete;

	private var art:Null<GuildView>;
	private var guildMembers:Array<GuildMemberName> = [];
	private var scroll:Null<CustomScrollBar>;
	private var closeBinding:Null<LobbyArt.Binding>;
	private var messageBinding:Null<LobbyArt.Binding>;
	private var editBinding:Null<LobbyArt.Binding>;
	private var deleteBinding:Null<LobbyArt.Binding>;
	private var titleBox:Null<TextField>;
	private var guildName:String = "";
	private var guildId:Int = 0;
	private var ownerId:Int = 0;
	private var guildIdShown:Bool = false;
	private var asyncGuard:AsyncRemovalGuard = new AsyncRemovalGuard();
	private var source:GuildSource;
	private var emblemLoader:Null<EmblemLoader>;

	public function new(id:Int = 0, name:String = "", autoLoad:Bool = true) {
		if (GuildPopup.instance != null) {
			GuildPopup.instance.startFadeOut();
		}
		super();
		GuildPopup.instance = this;
		ProfileActions.guildOpened(this);
		guildId = id;

		art = new GuildView();
		closeBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "close_bt"), clickClose);
		addChild(art);

		if (autoLoad) {
			source = new GuildSource();
			source.load(id, name, function(data:GuildData):Void { if (!fadeOutStarted) applyGuildData(data); }, function(_:String):Void startFadeOut());
		}
	}

	public function applyReturnData(parsed:Dynamic):Void {
		applyGuildData(new GuildData(parsed));
	}

	private function applyGuildData(data:GuildData):Void {
		if (art == null) return;
		guildId = data.id;
		ownerId = data.ownerId;
		guildName = data.name;

		var isMember = LobbySession.guildId != 0 && LobbySession.guildId == guildId;
		art.setMember(isMember);
		titleBox = LobbyArt.directText(art, "titleBox");
		setText("titleBox", "-- " + guildName + " --");
		setText("gpTodayBox", "GP Today: " + NumberFormat.withCommas(data.gpToday));
		setText("gpTotalBox", "GP Total: " + NumberFormat.withCommas(data.gpTotal));
		setText("membersCount", "Members: " + data.memberCount + " (" + data.activeCount + " active)");
		setText("guildProse", data.note);
		addEmblem(data.emblem);

		var loading = DisplayUtil.directChildByName(art, "loadingGraphic");
		if (loading != null) loading.visible = false;
		setVisible("edit_bt", LobbySession.group >= 2 && !LobbySession.isTrialMod);
		setVisible("delete_bt", LobbySession.group == 3 && !LobbySession.isTrialMod);
		if (LobbySession.group >= 2 && !LobbySession.isTrialMod) {
			editBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "edit_bt"), clickEdit);
			if (LobbySession.group == 3) {
				deleteBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "delete_bt"), clickDelete);
			}
		}

		var holder = Std.downcast(DisplayUtil.directChildByName(art, "membersHolder"), DisplayObjectContainer);
		if (holder != null) {
			for (member in data.members) {
				var row = new GuildMemberName(member.raw, member.owner);
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

		closeBinding = replaceBinding(closeBinding, DisplayUtil.directChildByName(art, "close_bt"), clickClose);
		if (isMember) {
			messageBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "messageButton"), clickMessage);
		}
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(KeyboardEvent.KEY_DOWN, toggleGuildIdShown);
			StageFocus.reset();
		}
	}

	public function emblemForTests():Null<EmblemLoader> {
		return emblemLoader;
	}

	private function clickMessage():Void {
		pr2.app.ScreenFactory.composeMessage("guild", "", true);
	}

	private function clickEdit():Void {
		new CreateGuildPopup(guildId);
	}

	private function clickDelete():Void {
		var confirmStr = guildName == "" ? "Are you sure you want to delete this guild?"
			: "Are you sure you want to delete " + StringTools.htmlEscape(guildName) + "?";
		new ConfirmPopup(confirmDelete, confirmStr);
	}

	public function confirmDelete():Void {
		var fields = ["guild_id" => Std.string(guildId)];
		asyncGuard.watch(deleteFactory(ServerConfig.guildDeleteUrl(), fields));
		if (LobbySession.guildId == guildId) {
			LobbySession.clearGuild();
		}
		startFadeOut();
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
		var field = LobbyArt.directText(art, name);
		if (field != null) field.text = value;
	}

	private function setVisible(name:String, value:Bool):Void {
		var target = DisplayUtil.directChildByName(art, name);
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
		if (source != null) { source.remove(); source = null; }
		asyncGuard.remove();
		if (GuildPopup.instance == this) {
			GuildPopup.instance = null;
		}
		ProfileActions.guildRemoved(this);
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(KeyboardEvent.KEY_DOWN, toggleGuildIdShown);
		}
		LobbyArt.unbind(closeBinding);
		LobbyArt.unbind(messageBinding);
		LobbyArt.unbind(editBinding);
		LobbyArt.unbind(deleteBinding);
		closeBinding = null;
		messageBinding = null;
		editBinding = null;
		deleteBinding = null;
		for (member in guildMembers.copy()) {
			member.remove();
		}
		guildMembers = [];
		if (scroll != null) {
			scroll.remove();
			scroll = null;
		}
		if (emblemLoader != null) {
			emblemLoader.remove();
			emblemLoader = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		titleBox = null;
		super.remove();
	}

	private function addEmblem(fileName:String):Void {
		if (emblemLoader != null) {
			emblemLoader.remove();
		}
		emblemLoader = new EmblemLoader(100, 50, ServerConfig.emblemUploadUrl(), ServerConfig.emblemsUrl());
		emblemLoader.x = -140;
		emblemLoader.y = -109;
		emblemLoader.mouseEnabled = false;
		emblemLoader.mouseChildren = false;
		emblemLoader.getImage(fileName == null || fileName == "" ? "default-emblem.jpg" : fileName);
		addChild(emblemLoader);
	}

	private static function defaultDelete(url:String, fields:Map<String, String>):SuperLoader {
		return FormPostClient.post(url, fields, function(_:String):Void {}, function(_:String):Void {});
	}
}
