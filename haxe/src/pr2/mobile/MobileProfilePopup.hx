package pr2.mobile;

import pr2.lobby.LobbySession;
import pr2.lobby.LobbyPopups;
import pr2.lobby.account.AccountCharacter;
import pr2.lobby.players.ProfileData;
import pr2.lobby.players.ProfileSource;
import pr2.lobby.players.ProfileActions;
import pr2.lobby.players.ProfileCharacter;
import pr2.lobby.players.SocialAction;
import pr2.lobby.players.SocialActions;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

class MobileProfilePopup extends MobilePanelPopup {
	public static var post:String->Map<String,String>->(String->Void)->(String->Void)->AsyncRemovable = FormPostClient.post;
	private var view:LobbyView;
	private var pane:MobileScrollPane;
	private var source:ProfileSource;
	private var guard = new AsyncRemovalGuard();
	private var userName:String;
	private var profile:ProfileData;
	private var character:AccountCharacter;
	private var actions:Bool = false;
	private var busy:Bool = false;
	private var error:String = "";
	private var notice:String = "";
	private var pendingGuild:String = "";
	private var cw:Float = 796;
	private var ch:Float = 306;
	public function new(name:String, guest:Bool = false, autoLoad:Bool = true) {
		super(name); userName = name; ProfileActions.opened(this);
		view = new LobbyView(); pane = new MobileScrollPane(); content.addChild(view); content.addChild(pane);
		if (guest) applyData({group:0}); else if (autoLoad) load();
		layoutForSize(w,h);
	}
	private function load():Void {
		if (source != null) source.remove();
		profile = null; error = ""; source = new ProfileSource(); render();
		source.load(userName, applyData, function(message) { error = message; render(); });
	}
	public function applyData(data:Dynamic):Void {
		if (isRemoved() || fadeOutStarted) return;
		profile = new ProfileData(data);
		if (character != null) character.remove(); character = null;
		if (!profile.isGuest()) { character = ProfileCharacter.create(profile); content.addChild(character); }
		error = ""; render();
	}
	override private function resizeContent(width:Float,height:Float):Void { cw = width; ch = height; if (view != null) render(); }
	private function choose(value:Bool):Void { actions = value; pendingGuild = ""; notice = ""; pane.reset(); render(); }
	private function social(action:SocialAction):Void {
		if (busy || profile == null || profile.isGuest() || !LobbySession.isMember()) return;
		var fields = SocialActions.fields(action, profile.number("userId"));
		SocialActions.notifyServer(action, userName);
		upload(ServerConfig.userListModifyUrl(), fields, function() {
			switch action {
				case Follow: Reflect.setField(profile.raw,"following",1);
				case Unfollow: Reflect.setField(profile.raw,"following",0);
				case AddFriend: Reflect.setField(profile.raw,"friend",1);
				case RemoveFriend: Reflect.setField(profile.raw,"friend",0);
				case Ignore: Reflect.setField(profile.raw,"ignored",1);
				case Unignore: Reflect.setField(profile.raw,"ignored",0);
			}
			notice = "Updated.";
		});
	}
	private function guildAction(action:String):Void {
		if (busy || profile == null || (action == "invite" ? !profile.canInvite() : !profile.canKick())) return;
		pendingGuild = action; notice = ""; pane.reset(); render();
	}
	private function confirmGuild():Void {
		if (pendingGuild == "" || busy) return;
		var action = pendingGuild;
		if (action == "invite" ? !profile.canInvite() : !profile.canKick()) return;
		upload(action == "invite" ? ServerConfig.guildInviteUrl() : ServerConfig.guildKickUrl(), ProfileActions.guildFields(profile.number("userId"), userName), function() {
			pendingGuild = ""; notice = action == "invite" ? "Guild invitation sent." : "Player removed from the guild.";
			if (action == "kick") Reflect.setField(profile.raw,"guildId",0);
		});
	}
	private function upload(url:String, fields:Map<String,String>, success:Void->Void):Void {
		busy = true; notice = "Updating…"; render();
		guard.watch(post(url,fields,guard.wrap(function(body) {
			var result = SuperLoader.decodeJson(url,body,false);
			busy = false;
			if (result.success) success(); else notice = result.message;
			render();
		}),guard.wrap(function(message) { busy = false; notice = message; render(); })));
	}
	private function message():Void { startFadeOut(); pr2.app.ScreenFactory.composeMessage(userName); }
	private function render():Void {
		if (view == null || isRemoved()) return;
		view.clear(); pane.content.clear();
		if (character != null) character.visible = !actions && profile != null && !profile.isGuest();
		view.button("Racer info",0,0,160,function() choose(false),!actions).enabled = !busy;
		view.button("Actions",172,0,160,function() choose(true),actions).enabled = profile != null && !busy;
		view.panel(0,56,cw,Math.max(80,ch-56));
		var left = character != null && character.visible ? 160.0 : 0;
		if (character != null) {
			character.scaleX = character.scaleY = profile.number("body") == 29 ? 1.5 : 2;
			character.x = 82; character.y = Math.min(ch-20,226);
		}
		pane.x = 12 + left; pane.y = 68; var width = cw - 24 - left; var v = pane.content; var y:Float = 8;
		function text(value:String, size:Int = 18):Void {
			var field = v.label(value,8,y,width-16,32,size); field.height = Math.max(30,field.textHeight+6); y += field.height + 8;
		}
		if (profile == null) {
			text(error == "" ? "Loading racer…" : error);
			if (error != "") { v.button("Try again",8,y,150,load,true); y += 56; }
		} else if (pendingGuild != "") {
			text(pendingGuild == "invite" ? "Invite " + userName + " to your guild?" : "Remove " + userName + " from your guild?");
			text(notice);
			v.button("Back",8,y,120,function() { pendingGuild = ""; render(); }).enabled = !busy;
			v.button("Confirm",140,y,150,confirmGuild,true).enabled = !busy; y += 56;
		} else if (actions) {
			if (notice != "") text(notice);
			var items:Array<{label:String, action:Void->Void, enabled:Bool}> = [];
			if (!profile.isGuest()) {
				items.push({label:"Message",action:message,enabled:true});
				items.push({label:"View levels",action:function() ProfileActions.levels(userName),enabled:true});
				items.push({label:profile.number("following") == 1 ? "Unfollow" : "Follow",action:function() social(profile.number("following") == 1 ? Unfollow : Follow),enabled:LobbySession.isMember()});
				items.push({label:profile.number("friend") == 1 ? "Remove friend" : "Add friend",action:function() social(profile.number("friend") == 1 ? RemoveFriend : AddFriend),enabled:LobbySession.isMember()});
				items.push({label:profile.number("ignored") == 1 ? "Unignore" : "Ignore",action:function() social(profile.number("ignored") == 1 ? Unignore : Ignore),enabled:LobbySession.isMember()});
				if (profile.canInvite()) items.push({label:"Invite to guild",action:function() guildAction("invite"),enabled:true});
				if (profile.canKick()) items.push({label:"Remove from guild",action:function() guildAction("kick"),enabled:true});
			}
			if (profile.staffTools()) items.push({label:"Staff tools",action:function() new MobileStaffPopup(userName,profile.isGuest()),enabled:true});
			if (items.length == 0) text("Guest racers do not have account actions.");
			var bw = (width-28)/2;
			for (i in 0...items.length) { var item = items[i]; v.button(item.label,8+(i%2)*(bw+12),y+Std.int(i/2)*56,bw,item.action,i==0).enabled = item.enabled && !busy; }
			y += Math.ceil(items.length/2)*56;
			if (!profile.isGuest() && !LobbySession.isMember()) text("Log in to follow, friend, or ignore racers.",16);
		} else {
			text(profile.groupLabel(),22);
			if (!profile.isGuest()) {
				text(profile.text("status"));
				text("Rank " + profile.number("rank") + "  •  " + profile.text("hats") + " hats",22);
				text(pr2.lobby.NumberFormat.withCommas(profile.number("exp_points")) + " / " + pr2.lobby.NumberFormat.withCommas(profile.number("exp_to_rank")) + " XP",16);
				text("User ID: " + profile.number("userId"),16);
				if (profile.number("guildId") == 0) text("Guild: none",16);
				else { v.button("Guild: " + profile.text("guildName"),8,y,width-16,function() { startFadeOut(); LobbyPopups.showGuild(profile.number("guildId")); }); y+=56; }
				text("Joined: " + (profile.number("registerDate") == 0 ? "Age of Heroes" : ProfileData.longDate(profile.number("registerDate"))),16);
				text("Last active: " + ProfileData.longDate(profile.number("loginDate")),16);
				if (profile.flag("verified")) { text("Verified — notable member of the community.",16); v.button("About verification",8,y,width-16,function() LobbyPopups.openUrl("https://jiggmin2.com/forums/showthread.php?tid=4227")); y+=56; }
				if (profile.flag("hof")) { text("Hall of Fame — recognized for exceptional talent and dedication.",16); v.button("About Hall of Fame",8,y,width-16,function() LobbyPopups.openUrl("https://jiggmin2.com/forums/showthread.php?tid=4226")); y+=56; }
			}
		}
		pane.setSize(width,Math.max(44,ch-80),y+8);
	}
	override public function startFadeOut():Void { if (source != null) source.remove(); guard.remove(); super.startFadeOut(); }
	override public function remove():Void {
		if (isRemoved()) return;
		if (source != null) source.remove(); guard.remove(); ProfileActions.removed(this);
		if (character != null) character.remove(); if (pane != null) pane.remove(); if (view != null) view.remove();
		super.remove();
	}
}
