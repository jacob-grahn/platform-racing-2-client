package pr2.mobile;

import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import pr2.lobby.LobbySession;
import pr2.lobby.players.GuildManagementActions;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

/** Responsive transfer form retaining the encrypted classic request payload. */
class MobileGuildTransferPopup extends MobilePanelPopup {
	public static var post:String->Map<String,String>->(String->Void)->(String->Void)->AsyncRemovable=FormPostClient.post;
	private var view:LobbyView;
	private var fields:Array<TextField>=[];
	private var guard=new AsyncRemovalGuard();
	private var busy=false;
	private var notice="";
	private var cw:Float=796;
	private var ch:Float=306;
	public function new(){super("TRANSFER GUILD OWNERSHIP");view=new LobbyView();content.addChild(view);for(i in 0...3)fields.push(createInput(i==1));render();}
	private function createInput(password:Bool):TextField {var input=new TextField();input.type=TextFieldType.INPUT;input.displayAsPassword=password;input.defaultTextFormat=new TextFormat("Nunito Bold",18,0x18334B);input.embedFonts=true;input.border=true;input.background=true;input.backgroundColor=0xFFFFFF;content.addChild(input);return input;}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(view!=null)render();}
	private function render():Void {if(view==null||isRemoved())return;view.clear();view.panel(0,0,cw,ch);view.label("Confirm your account, then enter the racer who should own the guild.",8,4,cw-16,42,18);var labels=["Account email","Account password","New owner racer name"];for(i in 0...fields.length){var y=52+i*66;view.label(labels[i],10,y,cw-20,22,16,true);fields[i].x=10;fields[i].y=y+24;fields[i].width=cw-20;fields[i].height=38;}if(notice!="")view.label(notice,12,ch-56,cw-220,44,16);view.button("Cancel",cw-184,ch-72,82,startFadeOut);view.button(busy?"Sending…":"Transfer",cw-92,ch-72,82,submit,true).enabled=!busy;}
	private function submit():Void {if(busy)return;var email=StringTools.trim(fields[0].text);var password=fields[1].text;var owner=StringTools.trim(fields[2].text);if(email==""||password==""||owner==""){notice="Please fill in all fields.";render();return;}busy=true;notice="Transferring ownership…";render();var url=ServerConfig.guildTransferUrl();var payload=GuildManagementActions.transferPayload(email,password,owner,LobbySession.userName);for(field in fields)field.text="";guard.watch(post(url,["data"=>payload],guard.wrap(function(body){busy=false;var result=SuperLoader.decodeJson(url,body,false);if(result.success){LobbySession.updateGuildState(LobbySession.guildId,LobbySession.guildName,false,LobbySession.emblem);startFadeOut();}else{notice=result.message;render();}}),guard.wrap(function(message){busy=false;notice=message;render();})));}
	private function cleanup():Void {guard.remove();for(field in fields){field.text="";if(field.parent!=null)field.parent.removeChild(field);}fields=[];if(view!=null){view.remove();view=null;}}
	override public function remove():Void {if(isRemoved())return;cleanup();super.remove();}
}
