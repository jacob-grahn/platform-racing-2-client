package pr2.mobile;

import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import pr2.lobby.LobbyRight;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.lobby.level.LevelInfoActions;
import pr2.lobby.level.LevelInfoData;
import pr2.lobby.level.LevelInfoSource;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

/** Touch-friendly detail view sharing the original level endpoint and rules. */
class MobileLevelInfoPopup extends MobilePanelPopup {
	public static var post:String->Map<String,String>->(String->Void)->(String->Void)->AsyncRemovable = FormPostClient.post;
	public final levelId:Int;
	private var view:LobbyView;
	private var pane:MobileScrollPane;
	private var source:LevelInfoSource;
	private var data:LevelInfoData;
	private var guard = new AsyncRemovalGuard();
	private var busy=false;
	private var error="";
	private var notice="";
	private var reportDraft="";
	private var reporting=false;
	private var reportText:TextField;
	private var confirmModeration="";
	private var cw:Float=796;
	private var ch:Float=306;
	public function new(id:Int) {
		super("LEVEL DETAILS"); levelId=id;
		view=new LobbyView(); pane=new MobileScrollPane(); content.addChild(view); content.addChild(pane);
		load(); layoutForSize(w,h);
	}
	private function load():Void {
		if(source!=null) source.remove(); source=new LevelInfoSource(); data=null; error=""; render();
		source.load(levelId,function(value){if(isRemoved()||fadeOutStarted)return;data=value;render();},function(message){if(isRemoved()||fadeOutStarted)return;error=message;render();});
	}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(view!=null)render();}
	private function addText(value:String,size:Int=18,heading:Bool=false):Void {
		var width=cw-56;var field=pane.content.label(value,10,contentHeight,width,42,size,heading,0x18334B);
		field.height=Math.max(32,field.textHeight+8);contentHeight+=field.height+8;
	}
	private var contentHeight:Float=0;
	private function render():Void {
		if(view==null||isRemoved())return;
		view.clear();pane.content.clear();reportText=null;contentHeight=8;
		view.panel(0,0,cw,ch);
		if(data==null) {
			addText(error==""?"Loading level details…":error,20,true);
			if(error!="")view.button("Try again",12,Math.max(12,ch-58),150,load,true);
			return;
		}
		if(reporting) { renderReport(); return; }
		if(confirmModeration!="") { renderModerationConfirm(); return; }
		addText(data.title==""?"Untitled level":data.title,26,true);
		addText("By "+data.userName+(data.live?"  •  Live":"")+(data.hasPass?"":"  •  No pass required"),17);
		addText("Mode: "+data.gameMode+"     Updated: "+LevelInfoData.shortDate(data.time));
		addText("Rating: "+Std.string(data.rating)+" / 5     Plays: "+data.plays+"     Version: "+data.version);
		var timeLimit=data.maxTime==0||(data.maxTime==999&&data.time<1358640000)?"Infinite":LevelInfoData.formatTime(data.maxTime);
		addText(data.minRankText()+"     Time limit: "+timeLimit);
		addText("Song: "+data.song+"     Gravity: "+data.gravity+"     Cowboy chance: "+data.cowboyChance+"%");
		addText("Items: "+StringTools.replace(data.items,"`",", "));
		if(data.badHats!="")addText("Hats allowed: "+data.badHats);
		if(data.note!="") {addText("Author's note",20,true);addText(data.note);}
		if(notice!="")addText(notice,17,true);
		pane.x=10;pane.y=10;pane.setSize(cw-20,ch-82,contentHeight+12);
		var buttonY=ch-60;var gap=8;var buttons:Array<{label:String,action:Void->Void,primary:Bool}>=[
			{label:"Play",action:play,primary:true},
			{label:"View racer",action:function(){startFadeOut();pr2.app.ScreenFactory.profile(data.userName);},primary:false}
		];
		if(LobbySession.group>=1)buttons.push({label:"Share",action:share,primary:false});
		if(LobbySession.group==1)buttons.push({label:"Report",action:function(){reporting=true;render();},primary:false});
		if(LobbySession.group>=2)buttons.push({label:"Moderate",action:function(){confirmModeration="choose";render();},primary:false});
		var bw=(cw-24-gap*(buttons.length-1))/buttons.length;
		for(i in 0...buttons.length)view.button(buttons[i].label,12+i*(bw+gap),buttonY,bw,buttons[i].action,buttons[i].primary);
	}
	private function renderReport():Void {
		addText("Report this level",24,true);addText("Tell the moderators what is inappropriate or needs review.");
		reportText=new TextField();reportText.type=TextFieldType.INPUT;reportText.multiline=true;reportText.wordWrap=true;reportText.border=true;reportText.background=true;reportText.backgroundColor=0xFFFFFF;reportText.defaultTextFormat=new TextFormat("Nunito Bold",18,0x18334B);reportText.x=10;reportText.y=contentHeight;reportText.width=cw-56;reportText.height=Math.max(90,ch-190);reportText.text=reportDraft;pane.content.addChild(reportText);
		contentHeight+=reportText.height+12;if(notice!="")addText(notice);
		pane.x=10;pane.y=10;pane.setSize(cw-20,ch-82,contentHeight+12);
		view.button("Back",12,ch-60,140,function(){reporting=false;notice="";render();});
		view.button(busy?"Sending…":"Submit report",cw-196,ch-60,184,submitReport,true).enabled=!busy;
	}
	private function submitReport():Void {
		if(busy||data==null)return;var reason=reportText==null?"":StringTools.trim(reportText.text);if(reason==""){notice="Please describe why this level should be reviewed.";render();return;}
		reportDraft=reason;pr2.app.ScreenFactory.confirm("Submit this report to the moderators? Please report only inappropriate or harmful content.",function()sendReport(reason),"REPORT LEVEL");
	}
	private function sendReport(reason:String):Void {
		if(busy||data==null)return;busy=true;notice="Sending report…";render();var fields=LevelInfoActions.reportFields(levelId,data.version,reason);
		guard.watch(post(ServerConfig.levelReportUrl(),fields,guard.wrap(function(body){busy=false;var result=SuperLoader.decodeJson(ServerConfig.levelReportUrl(),body,false);if(result.success){notice="Report sent to the moderators.";reporting=false;reportDraft="";}else notice=result.message;render();}),guard.wrap(function(message){busy=false;notice=message;render();})));
	}
	private function renderModerationConfirm():Void {
		addText("Moderate this level",24,true);addText(confirmModeration=="choose"?"Choose how this level should be handled.":(confirmModeration=="restrict"?"Restrict this level? It will remain playable but disappear from most lists.":"Unpublish this level? The author must republish it."));
		if(notice!="")addText(notice);
		pane.x=10;pane.y=10;pane.setSize(cw-20,ch-82,contentHeight+12);
		view.button("Back",12,ch-60,130,function(){confirmModeration="";notice="";render();});
		if(confirmModeration=="choose") {
			view.button("Restrict",cw/2-150,ch-60,140,function(){confirmModeration="restrict";render();});
			view.button("Unpublish",cw/2+10,ch-60,160,function(){confirmModeration="unpublish";render();},true);
		} else view.button(busy?"Working…":"Confirm",cw-196,ch-60,184,moderate,true).enabled=!busy;
	}
	private function moderate():Void {
		if(busy||confirmModeration=="")return;busy=true;notice="Updating level…";render();var action=confirmModeration;
		guard.watch(post(ServerConfig.levelModerateUrl(),LevelInfoActions.moderationFields(levelId,action),guard.wrap(function(body){busy=false;var result=SuperLoader.decodeJson(ServerConfig.levelModerateUrl(),body,false);if(result.success){notice=action=="restrict"?"Level restricted.":"Level unpublished.";confirmModeration="";}else notice=result.message;render();}),guard.wrap(function(message){busy=false;notice=message;render();})));
	}
	private function play():Void {
		if(data==null)return;
		if(pr2.lobby.players.ProfileActions.active!=null)pr2.lobby.players.ProfileActions.active.startFadeOut();
		if(pr2.lobby.dialogs.GuildPopup.instance!=null)pr2.lobby.dialogs.GuildPopup.instance.startFadeOut();
		var id=Std.string(levelId);if(LevelInfoPopup.lookupLevelHandler!=null)LevelInfoPopup.lookupLevelHandler(id);else if(LobbyRight.instance!=null)LobbyRight.instance.lookupLevel(id);startFadeOut();
	}
	private function share():Void {if(data!=null)pr2.app.ScreenFactory.composeMessage("",LevelInfoActions.shareMessage(levelId,data.title,data.userName),false,true);}
	override public function remove():Void {
		if(source!=null)source.remove();source=null;guard.remove();if(reportText!=null){reportText.text="";reportText=null;}if(pane!=null){pane.remove();pane=null;}if(view!=null){view.remove();view=null;}super.remove();
	}
}
