package pr2.mobile;

import pr2.lobby.LobbySession;
import pr2.lobby.LobbyPopups;
import pr2.lobby.NumberFormat;
import pr2.lobby.players.GuildData;
import pr2.lobby.players.GuildSource;
import pr2.lobby.players.ProfileActions;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;
import pr2.ui.EmblemLoader;
import pr2.net.FormPostClient;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

/** Mobile guild profile, roster, and member actions. */
class MobileGuildPopup extends MobilePanelPopup {
	public static var post:String->Map<String,String>->(String->Void)->(String->Void)->AsyncRemovable=FormPostClient.post;
	private var view:LobbyView;
	private var pane:MobileScrollPane;
	private var source:GuildSource;
	private var guild:GuildData;
	private var emblem:EmblemLoader;
	private var requestedId:Int;
	private var requestedName:String;
	private var error:String = "";
	private var notice:String = "";
	private var busy:Bool = false;
	private var requestGuard=new AsyncRemovalGuard();
	private var cw:Float = 796;
	private var ch:Float = 306;
	public function new(id:Int = 0, name:String = "", autoLoad:Bool = true) {
		super(name == "" ? "GUILD" : name.toUpperCase());
		requestedId = id; requestedName = name;
		ProfileActions.guildOpened(this);
		view = new LobbyView(); pane = new MobileScrollPane(); content.addChild(view); content.addChild(pane);
		emblem = new EmblemLoader(100, 50, ServerConfig.emblemUploadUrl(), ServerConfig.emblemsUrl()); emblem.mouseEnabled = false; emblem.mouseChildren = false; content.addChild(emblem);
		if (autoLoad) load();
		layoutForSize(w,h);
	}
	private function load():Void {
		if (source != null) source.remove(); source = new GuildSource(); guild = null; error = ""; render();
		source.load(requestedId, requestedName, function(data) { guild = data; error = ""; if (emblem != null) emblem.getImage(data.emblem == "" ? "default-emblem.jpg" : data.emblem); render(); }, function(message) { error = message; render(); });
	}
	override private function resizeContent(width:Float,height:Float):Void { cw = width; ch = height; if (view != null) render(); }
	private function render():Void {
		if (view == null || isRemoved()) return;
		view.clear(); pane.content.clear();
		view.panel(0,0,cw,ch); pane.x = 12; pane.y = 12; pane.visible = true;
		var v = pane.content; var y:Float = 4; var width = cw - 24;
		function text(value:String, size:Int = 17, bold:Bool = false):Void { var f = v.label(value,8,y,width-16,34,size,bold); f.height = Math.max(30,f.textHeight+6); y += f.height + 6; }
		if (guild == null) {
			text(error == "" ? "Loading guild…" : error,20,true);
			if (error != "") v.button("Try again",8,y,152,load,true);
			pane.setSize(width,Math.max(44,ch-24),y+8); return;
		}
		if(notice!="")text(notice,16,true);
		text(guild.name,26,true);
		text("GP today: " + NumberFormat.withCommas(guild.gpToday) + "     GP total: " + NumberFormat.withCommas(guild.gpTotal),16);
		text("Members: " + guild.memberCount + " (" + guild.activeCount + " active)",16);
		if (guild.note != "") text(guild.note,16);
		var sameGuild = LobbySession.isMember() && LobbySession.guildId == guild.id;
		var guildless = LobbySession.isMember() && LobbySession.guildId == 0;
		var actions:Array<{label:String, run:Void->Void}> = [];
		if (sameGuild) actions.push({label:"Message guild",run:function() pr2.app.ScreenFactory.composeMessage("guild","",true)});
		if (guildless) actions.push({label:"Join guild",run:join});
		if (sameGuild && !LobbySession.guildOwner) actions.push({label:"Leave guild",run:leave});
		if (sameGuild && LobbySession.guildOwner) actions.push({label:"Transfer ownership",run:transfer});
		if (LobbySession.group >= 2 && !LobbySession.isTrialMod) actions.push({label:"Edit guild",run:function() pr2.app.ScreenFactory.editGuild(guild.id)});
		if (LobbySession.group == 3 && !LobbySession.isTrialMod) actions.push({label:"Delete guild",run:deleteGuild});
		if (actions.length > 0) {
			var bw = (width - 28) / 2;
			for (i in 0...actions.length) { var action = actions[i]; v.button(action.label,8+(i%2)*(bw+12),y+Std.int(i/2)*54,bw,action.run,i==0).enabled=!busy; }
			y += Math.ceil(actions.length/2)*54+6;
		}
		text("MEMBERS",20,true);
		text("Name                                      GP today       GP total",13,true);
		if (guild.members.length == 0) text("No member list was returned.",15);
		for (member in guild.members) {
			v.graphics.lineStyle(1,0xD5E2E9); v.graphics.moveTo(8,y+46); v.graphics.lineTo(width-8,y+46);
			var n = member.owner ? "♛ " + member.name : member.name;
			v.singleLine(n,8,y+1,width*.45,40,18,true,member.group == "0" ? 0x18334B : 0x18334B);
			v.singleLine(NumberFormat.withCommas(member.gpToday),width*.48,y+3,width*.22,36,15);
			v.singleLine(NumberFormat.withCommas(member.gpTotal),width*.71,y+3,width*.24,36,15);
			v.button("View",width-86,y+1,78,function() { pr2.app.ScreenFactory.profile(member.name); },false,42);
			y += 50;
		}
		pane.setSize(width,Math.max(44,ch-24),y+8);
		if (emblem != null && guild != null) { emblem.x = cw-132; emblem.y = 74; emblem.visible = cw >= 560; }
	}
	private function join():Void {
		if (guild == null || !LobbySession.isMember() || LobbySession.guildId != 0) return;
		pr2.app.ScreenFactory.confirm("Join " + StringTools.htmlEscape(guild.name) + "?",function() request(ServerConfig.guildJoinUrl(),["guild_id"=>Std.string(guild.id)],function(data)LobbySession.updateGuildFromData(data,false)),"JOIN GUILD");
	}
	private function leave():Void {
		if (guild == null || !LobbySession.isMember() || LobbySession.guildId != guild.id || LobbySession.guildOwner) return;
		pr2.app.ScreenFactory.confirm("Are you sure you want to leave " + StringTools.htmlEscape(guild.name) + "?",function()request(ServerConfig.guildLeaveUrl(),new Map<String,String>(),function(_)LobbySession.clearGuild()),"LEAVE GUILD");
	}
	private function transfer():Void {
		if (!LobbySession.guildOwner) return;
		if (LobbySession.canUseRememberMeAccountAction()) pr2.app.ScreenFactory.guildTransfer(); else pr2.app.ScreenFactory.message(LobbySession.REMEMBER_ME_REQUIRED_COPY);
	}
	private function deleteGuild():Void {
		if (guild == null || LobbySession.group != 3 || LobbySession.isTrialMod) return;
		pr2.app.ScreenFactory.confirm("Are you sure you want to delete " + StringTools.htmlEscape(guild.name) + "?",function()request(ServerConfig.guildDeleteUrl(),["guild_id"=>Std.string(guild.id)],function(_){if(LobbySession.guildId==guild.id)LobbySession.clearGuild();startFadeOut();}),"DELETE GUILD");
	}
	private function request(url:String,fields:Map<String,String>,onSuccess:Dynamic->Void):Void {
		if(busy)return;busy=true;notice="Working…";render();
		requestGuard.watch(post(url,fields,requestGuard.wrap(function(body){var result=SuperLoader.decodeJson(url,body,false);busy=false;if(result.success){notice="Updated.";onSuccess(result.data);}else notice=result.message;render();}),requestGuard.wrap(function(message){busy=false;notice=message;render();})));
	}
	override public function startFadeOut():Void { if (source != null) source.remove(); super.startFadeOut(); }
	override public function remove():Void {
		if (isRemoved()) return;
		requestGuard.remove();if (source != null) source.remove(); if (emblem != null) { emblem.remove(); emblem = null; }
		ProfileActions.guildRemoved(this);
		if (pane != null) pane.remove(); if (view != null) view.remove(); super.remove();
	}
}
