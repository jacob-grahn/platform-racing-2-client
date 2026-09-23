package pr2.mobile;

import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.lobby.chat.ChatText;
import pr2.lobby.dialogs.BanMenu;
import pr2.lobby.players.StaffActions;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;

/** Touch-targeted staff tools with the same commands, ban fields, and permissions as classic. */
class MobileStaffPopup extends MobilePanelPopup {
	private var view:LobbyView;
	private var pane:MobileScrollPane;
	private var userName:String;
	private var guest:Bool;
	private var section:String="moderation";
	private var banMode:Bool=false;
	private var durationIndex:Int=-1;
	private var typeIndex:Int=0;
	private var scope:String="social";
	private var reason:TextField;
	private var notice:String="";
	private var durationOptions:Array<{label:String,seconds:Int}>;
	private var typeOptions:Array<{label:String,value:String}>=[{label:"Both",value:"both"},{label:"Account only",value:"account"},{label:"IP only",value:"ip"}];
	private var cw:Float=796;private var ch:Float=306;
	public function new(name:String,guest:Bool) {
		super("STAFF TOOLS");userName=name;this.guest=guest;view=new LobbyView();pane=new MobileScrollPane();content.addChild(view);content.addChild(pane);
		durationOptions=LobbySession.group>=2&&!LobbySession.isTrialMod?[{label:"3 days",seconds:259200},{label:"1 week",seconds:604800},{label:"2 weeks",seconds:1209600},{label:"1 month",seconds:2592000},{label:"6 months",seconds:15768000},{label:"1 year",seconds:31536000}]:[{label:"1 hour",seconds:3600},{label:"1 day",seconds:86400}];
		reason=new TextField();reason.type=TextFieldType.INPUT;reason.maxChars=100;reason.restrict="^`";reason.defaultTextFormat=new TextFormat("Nunito Bold",18,0x18334B);reason.embedFonts=true;reason.border=true;reason.background=true;reason.backgroundColor=0xFFFFFF;
		layoutForSize(w,h);
	}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(view!=null)render();}
	private function render():Void {
		if(view==null||isRemoved())return;view.clear();pane.content.clear();view.panel(0,0,cw,ch);view.button("Moderation",0,0,160,function(){section="moderation";banMode=false;render();},section=="moderation");
		if(LobbySession.group>=3&&!guest)view.button("Admin",172,0,120,function(){section="admin";banMode=false;render();},section=="admin");
		pane.x=10;pane.y=54;var width=cw-20;var y:Float=8;var v=pane.content;
		if(notice!=""){v.label(notice,8,y,width-16,42,17,true);y+=46;}
		y=section=="admin"?renderAdmin(v,width,y):renderModeration(v,width,y);
		pane.setSize(width,Math.max(44,ch-66),y+8);
	}
	private function renderModeration(v:LobbyView,width:Float,y:Float):Float {
		v.label("Moderation for "+userName,8,y,width-16,34,22,true);y+=40;
		var gap=8.0;var bw=(width-24)/3;
		for(i in 1...4){var level=i;v.button("Warning "+level,8+(level-1)*(bw+8),y,bw,function()warn(level));}
		y+=52;v.button("30 minute kick",8,y,bw,function()confirmKick(),true);v.button("View priors",16+bw,y,bw,function()viewPriors());y+=56;
		if(LobbySession.group<1)return y;
		v.button(banMode?"Cancel ban":"Ban options",8,y,width-16,function(){banMode=!banMode;notice="";render();},banMode);y+=54;
		if(!banMode)return y;
		v.label("Ban length",8,y,width-16,24,16,true);y+=28;var durationText=durationIndex<0?"Choose ban length":durationOptions[durationIndex].label;
		v.button("‹",8,y,58,function(){cycleDuration(-1);});v.button(durationText,74,y,width-148,function(){cycleDuration(1);},durationIndex>=0);v.button("›",width-66,y,58,function(){cycleDuration(1);});y+=54;
		v.label("Ban type",8,y,width-16,24,16,true);y+=28;
		for(i in 0...typeOptions.length){var index=i;v.button(typeOptions[i].label,8+i*(bw+8),y,bw,function(){typeIndex=index;render();},typeIndex==index);}
		y+=52;
		if(LobbySession.group>=2&&!LobbySession.isTrialMod){v.label("Scope",8,y,width-16,24,16,true);y+=28;v.button("Social",8,y,bw,function(){scope="social";render();},scope=="social");v.button("Game",16+bw,y,bw,function(){scope="game";render();},scope=="game");y+=52;}
		v.label("Reason",8,y,width-16,24,16,true);v.addChild(reason);reason.x=8;reason.y=y+28;reason.width=width-16;reason.height=42;y+=82;
		v.button("Submit ban",8,y,width-16,submitBan,true);y+=54;
		return y;
	}
	private function renderAdmin(v:LobbyView,width:Float,y:Float):Float {
		v.label("Change staff role for "+userName,8,y,width-16,36,22,true);y+=46;
		v.button("Temporary moderator",8,y,width-16,function()confirmPromote("temporary"),true);y+=52;
		v.button("Trial moderator",8,y,width-16,function()confirmPromote("trial"));y+=52;
		v.button("Permanent moderator",8,y,width-16,function()confirmPromote("permanent"));y+=52;
		v.button("Demote",8,y,width-16,confirmDemote);y+=52;
		return y;
	}
	private function cycleDuration(step:Int):Void {if(durationOptions.length==0)return;durationIndex=durationIndex<0?(step>0?0:durationOptions.length-1):(durationIndex+step+durationOptions.length)%durationOptions.length;render();}
	private function warn(level:Int):Void {if(!LobbySocket.isConnected()){notice="You are not connected to a server.";render();return;}LobbySocket.write(StaffActions.warningCommand(userName,level));startFadeOut();}
	private function viewPriors():Void {if(!LobbySocket.isConnected()){notice="You are not connected to a server.";render();return;}LobbySocket.write(StaffActions.priorsCommand(userName));startFadeOut();}
	private function confirmKick():Void pr2.app.ScreenFactory.confirm("Kick "+userName+"? They cannot re-enter this server for 30 minutes.",function(){if(LobbySocket.isConnected())LobbySocket.write(StaffActions.kickCommand(userName));startFadeOut();},"30 MINUTE KICK");
	private function submitBan():Void {
		if(durationIndex<0){notice="Choose a ban length first.";render();return;}
		var scopeText=scope=="game"?"ban":"socially ban";var message="Are you sure you want to "+scopeText+" "+ChatText.escapeString(userName)+"?";
		if(scope=="game")message+=" They will not be able to log on or use PR2 Hub pages.";else message+=" They will not be able to register new accounts, use guest accounts, message, use guild features, publish, or rate levels.";
		pr2.app.ScreenFactory.confirm(message,function()sendBan(),"CONFIRM BAN");
	}
	private function sendBan():Void {
		if(durationIndex<0)return;var duration=durationOptions[durationIndex].seconds;var type=typeOptions[typeIndex].value;var reasonText=reason.text;var room=Memory.getString("chatRoom","");var record=StaffActions.shouldIncludeChatRecord(room)?BanMenu.chatRecordProvider():"";
		var chatRecord:Null<String>=StaffActions.shouldIncludeChatRecord(room)?record:null;
		pr2.app.ScreenFactory.upload(ServerConfig.banUserUrl(),StaffActions.banFields(userName,duration,reasonText,type,scope,chatRecord),"Banning…",function(data){var id=0;if(data!=null){var n=Std.parseInt(Std.string(Reflect.field(data,"ban_id")));if(n!=null)id=n;}if(LobbySocket.isConnected())LobbySocket.write(StaffActions.banCommand(userName,duration,scope,id,reasonText));startFadeOut();},function(message){notice=message;render();});
	}
	private function confirmPromote(mode:String):Void {
		var message=switch(mode){case "temporary":"Promote "+userName+" to a temporary moderator on this server? They can administer 30-minute kicks until logging off.";case "trial":"Promote "+userName+" to a trial moderator? Their bans will be limited to one day.";default:"Promote "+userName+" to a permanent moderator? They can issue longer bans, see IP addresses, unpublish levels, edit guilds, and use PR2 Hub moderation tools.";};
		pr2.app.ScreenFactory.confirm(message,function(){if(LobbySocket.isConnected())LobbySocket.write(StaffActions.promoteCommand(userName,mode));startFadeOut();},"PROMOTE RACER");
	}
	private function confirmDemote():Void pr2.app.ScreenFactory.confirm("Demote "+userName+" from moderator?",function(){if(LobbySocket.isConnected())LobbySocket.write(StaffActions.demoteCommand(userName));startFadeOut();},"DEMOTE RACER");
	override public function remove():Void {if(isRemoved())return;if(reason!=null){reason.text="";if(reason.parent!=null)reason.parent.removeChild(reason);reason=null;}if(pane!=null)pane.remove();if(view!=null)view.remove();super.remove();}
}
