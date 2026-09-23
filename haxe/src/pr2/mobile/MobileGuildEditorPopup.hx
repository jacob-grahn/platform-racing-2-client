package pr2.mobile;

import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.CreateGuildPopup;
import pr2.lobby.players.GuildManagementActions;
import pr2.net.ServerConfig;
import pr2.ui.EmblemLoader;
import pr2.util.AsyncRemovalGuard;

/** Mobile authoring form using the same guild load/save transport as classic. */
class MobileGuildEditorPopup extends MobilePanelPopup {
	private static inline var DEFAULT_EMBLEM="default-emblem.jpg";
	private var guildId:Int;
	private var view:LobbyView;
	private var nameInput:TextField;
	private var noteInput:TextField;
	private var emblem:EmblemLoader;
	private var guard=new AsyncRemovalGuard();
	private var busy=false;
	private var error="";
	private var cw:Float=796;
	private var ch:Float=306;
	public function new(id:Int=0) {
		super(id==0?"CREATE GUILD":"EDIT GUILD");guildId=id;view=new LobbyView();content.addChild(view);
		nameInput=createInput(false);noteInput=createInput(true);
		emblem=new EmblemLoader(100,50,ServerConfig.emblemUploadUrl(),ServerConfig.emblemsUrl());content.addChild(emblem);emblem.getImage(DEFAULT_EMBLEM);
		if(id!=0){busy=true;error="Loading guild details…";CreateGuildPopup.infoFactory(id,guard.wrap(function(data)applyInfo(data)),guard.wrap(function(message){busy=false;error=message;render();}));}
		render();
	}
	private function createInput(multiline:Bool):TextField {
		var input=new TextField();input.type=TextFieldType.INPUT;input.defaultTextFormat=new TextFormat("Nunito Bold",18,0x18334B);input.embedFonts=true;input.border=true;input.background=true;input.backgroundColor=0xFFFFFF;input.multiline=multiline;input.wordWrap=multiline;content.addChild(input);return input;
	}
	private function applyInfo(value:Dynamic):Void {
		var guild=Reflect.field(value,"guild");if(guild==null)guild=value;
		nameInput.text=field(guild,["guild_name","guildName"]);noteInput.text=field(guild,["note"]);var file=field(guild,["emblem"]);if(file!="")emblem.getImage(file);
		busy=false;error="";render();
	}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(view!=null)render();}
	private function render():Void {
		if(view==null||isRemoved())return;view.clear();view.panel(0,0,cw,ch);
		view.label(guildId==0?"Choose a name, write a short description, and pick an emblem.":"Update your guild name, description, and emblem.",8,4,cw-16,42,18);
		view.label("Guild name",10,52,cw-20,24,16,true);nameInput.x=10;nameInput.y=78;nameInput.width=cw-20;nameInput.height=42;nameInput.maxChars=32;
		view.label("Description",10,130,cw-20,24,16,true);noteInput.x=10;noteInput.y=156;noteInput.width=cw-20;noteInput.height=Math.max(64,ch-254);
		emblem.x=12;emblem.y=ch-74;view.button("Choose emblem",128,ch-72,176,function(){if(!busy)emblem.openBrowse();});
		if(guildId!=0&&LobbySession.guildId==guildId&&LobbySession.guildOwner)view.button("Transfer",cw-320,ch-72,132,function(){if(LobbySession.canUseRememberMeAccountAction())pr2.app.ScreenFactory.guildTransfer();else pr2.app.ScreenFactory.message(LobbySession.REMEMBER_ME_REQUIRED_COPY);});
		if(error!="")view.label(error,310,ch-68,Math.max(100,cw-520),48,16);
		view.button("Cancel",cw-184,ch-72,82,startFadeOut);
		view.button(busy?(guildId==0?"Saving…":"Loading…"):"Save",cw-92,ch-72,82,save,true).enabled=!busy;
	}
	private function save():Void {
		if(busy)return;
		busy=true;error="Saving guild…";render();
		if(emblem.isLoading())emblem.addEventListener(EmblemLoader.FINISH_LOADING,emblemReady);else submitSave();
	}
	private function emblemReady(_:Event):Void {emblem.removeEventListener(EmblemLoader.FINISH_LOADING,emblemReady);submitSave();}
	private function submitSave():Void {
		var url=guildId==0?ServerConfig.guildCreateUrl():ServerConfig.guildEditUrl();
		CreateGuildPopup.saveFactory(url,GuildManagementActions.saveFields(guildId,nameInput.text,noteInput.text,emblem.getFileName()),guard.wrap(function(data){busy=false;if(Reflect.field(data,"success")==false){error=field(data,["error","message"]);render();return;}if(busy==false&&LobbySession.guildId!=guildId&&guildId!=0){startFadeOut();return;}LobbySession.updateGuildFromData(data,true);startFadeOut();}),guard.wrap(function(message){busy=false;error=message;render();}));
	}
	private function field(data:Dynamic,names:Array<String>):String {for(name in names){var value=Reflect.field(data,name);if(value!=null)return Std.string(value);}return "";}
	private function cleanup():Void {guard.remove();if(emblem!=null){emblem.removeEventListener(EmblemLoader.FINISH_LOADING,emblemReady);emblem.remove();emblem=null;}if(nameInput!=null){nameInput.text="";if(nameInput.parent!=null)nameInput.parent.removeChild(nameInput);nameInput=null;}if(noteInput!=null){noteInput.text="";if(noteInput.parent!=null)noteInput.parent.removeChild(noteInput);noteInput=null;}if(view!=null){view.remove();view=null;}}
	public function emblemForTests():DisplayObject return emblem;
	override public function remove():Void {if(isRemoved())return;cleanup();super.remove();}
}
