package pr2.mobile;

import openfl.events.Event;
import openfl.events.KeyboardEvent;
import pr2.lobby.LobbySession;
import pr2.lobby.account.OptionsSettings;
import pr2.lobby.account.Settings;
import pr2.net.ServerConfig;
import pr2.app.AppStage;
import pr2.gameplay.RaceSounds;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;

/** Landscape touch settings for sound, gameplay preferences, songs, controls, and account actions. */
class MobileOptionsPopup extends MobilePanelPopup {
	private static final CONTROL_NAMES:Array<String> = ["up", "right", "down", "left", "item"];
	private static final CONTROL_LABELS:Array<String> = ["Move up", "Move right", "Move down", "Move left", "Use item"];
	private var view:LobbyView;
	private var pane:MobileScrollPane;
	private var page:String = "audio";
	private var awaitingControl:String = "";
	private var cw:Float = 796;
	private var ch:Float = 306;
	public function new(initialPage:String = "audio") {
		super("OPTIONS"); page = initialPage == "account" ? "account" : "audio";
		view = new LobbyView(); pane = new MobileScrollPane(); content.addChild(view); content.addChild(pane);
		if (AppStage.stage != null) AppStage.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 1000);
		layoutForSize(w,h);
	}
	override private function resizeContent(width:Float,height:Float):Void { cw=width; ch=height; if(view!=null) render(); }
	private function choose(value:String):Void { awaitingControl=""; page=value; pane.reset(); render(); }
	private function render():Void {
		if(view==null||isRemoved())return;
		view.clear(); pane.content.clear(); view.panel(0,0,cw,ch);
		var tabs=["audio","gameplay","songs","controls","account"];
		var gap=8.0; var tabW=(cw-gap*(tabs.length-1))/tabs.length;
		for(i in 0...tabs.length){var key=tabs[i];view.button(key.toUpperCase(),i*(tabW+gap),0,tabW,function()choose(key),page==key);}
		pane.x=12;pane.y=56;var width=cw-24;var height=ch-68;var v=pane.content;var y:Float=8;
		function heading(value:String):Void {v.label(value,8,y,width-16,38,23,true);y+=42;}
		function line(value:String):Void {v.label(value,8,y,width-16,30,16);y+=34;}
		switch page {
			case "audio":
				heading("Sound and music");
				var music=slider(v,"Music volume",Settings.musicLevel,8,y,width,function(value) OptionsSettings.setMusic(value)); y=music;
				var sound=slider(v,"Sound volume",Settings.soundLevel,8,y,width,function(value) OptionsSettings.setSound(value)); y=sound;
				v.button("Preview jump sound",8,y,220,function(){if(Assets.exists(RaceSounds.JUMP_SOUND))SoundEffects.playSound(Assets.getSound(RaceSounds.JUMP_SOUND),.75*(Settings.soundLevel/100));});y+=56;
			case "gameplay":
				heading("Gameplay preferences");
				toggle(v,"Draw course artwork",Settings.getValue(Settings.DRAW_ART,true),function(value) OptionsSettings.setDrawArt(value),width,y);y+=58;
				toggle(v,"Filter swear words in chat",Settings.getValue(Settings.FILTER_SWEARS,true),function(value) OptionsSettings.setSwearFilter(value),width,y);y+=58;
				line("These preferences are saved to this account on this device.");
			case "songs":
				heading("Allowed level music");
				line("Choose which original tracks can play during a race.");
				var disabled=Settings.disabledSongs();var colW=(width-28)/2;var leftRow=0;var rightRow=0;
					for(id in 1...22){if(!OptionsSettings.SONGS.exists(id))continue;var col=id>=12?1:0;var currentRow=col==0?leftRow++:rightRow++;var text=OptionsSettings.SONGS.get(id);var on=disabled.indexOf(Std.string(id))<0;
						v.button((on?"✓  ":"○  ")+text,8+col*(colW+12),y+currentRow*48,colW,function(){OptionsSettings.setSongEnabled(id,!on);render();},on,44);
				}
				y+=Math.max(leftRow,rightRow)*48;
			case "controls":
				heading("Keyboard controls");
				line(awaitingControl==""?"Tap a control, then press a letter or number.":"Press a letter or number for "+labelFor(awaitingControl)+".");
				for(i in 0...CONTROL_NAMES.length){var action=CONTROL_NAMES[i];var code=OptionsSettings.controlCode(action);var label=CONTROL_LABELS[i];
					v.button(label+"     [ "+(code==0?"?":String.fromCharCode(code).toUpperCase())+" ]",8,y,width-16,function(){awaitingControl=action;render();},awaitingControl==action);y+=52;
				}
			case "account": y=renderAccount(v,width,y);
			default:
		}
		pane.setSize(width,Math.max(44,height),y+8);
	}
	private function slider(v:LobbyView,label:String,value:Int,x:Float,y:Float,width:Float,onChange:Float->Void):Float {
		var valueLabel=v.label(label+"  "+value+"%",8,y,width*.33,44,17,true);
		var control=v.own(new MobileValueSlider(100,value));control.x=width*.36;control.y=y;control.setSize(width*.60,44);control.addEventListener(Event.CHANGE,function(_) {onChange(control.value);valueLabel.text=label+"  "+Std.int(control.value)+"%";});return y+58;
	}
	private function toggle(v:LobbyView,label:String,value:Bool,onChange:Bool->Void,width:Float,y:Float):Void {
		v.label(label,8,y,width*.62,44,18,true);v.button(value?"ON":"OFF",width-138,y,128,function(){onChange(!value);render();},value);
	}
	private function renderAccount(v:LobbyView,width:Float,start:Float):Float {
		var y=start;v.label("Account and guild",8,y,width-16,40,23,true);y+=48;
		if(!LobbySession.isMember()){v.label("Sign in to change account or guild settings.",8,y,width-16,60,18);return y+64;}
		v.label("Account",8,y,width-16,30,17,true);y+=36;
		v.button("Change password",8,y,width*.48,function()pr2.app.ScreenFactory.changePassword());v.button("Change email",width*.52,y,width*.44,openSetEmail);y+=54;
		v.label("Guild",8,y,width-16,30,17,true);y+=36;
		if(LobbySession.guildId==0){v.button("Create guild",8,y,width-16,function()pr2.app.ScreenFactory.editGuild(0),true);y+=52;}
		else if(LobbySession.guildOwner){v.button("Edit guild",8,y,width*.48,function()pr2.app.ScreenFactory.editGuild(LobbySession.guildId));v.button("Transfer guild",width*.52,y,width*.44,function(){if(LobbySession.canUseRememberMeAccountAction())pr2.app.ScreenFactory.guildTransfer();else pr2.app.ScreenFactory.message(LobbySession.REMEMBER_ME_REQUIRED_COPY);});y+=54;}
		else {v.button("Leave guild",8,y,width-16,function()pr2.app.ScreenFactory.confirm("Are you sure you want to leave your guild?",function()pr2.app.ScreenFactory.upload(ServerConfig.guildLeaveUrl(),new Map<String,String>(),"Leaving guild…",function(_){LobbySession.clearGuild();}),"LEAVE GUILD"),true);y+=52;}
		return y+8;
	}
	private function openSetEmail():Void { pr2.app.ScreenFactory.setEmail(); LobbySession.hasEmail=true; }
	private function onKeyDown(e:KeyboardEvent):Void {
		if(awaitingControl==""||!((e.keyCode>=48&&e.keyCode<=57)||(e.keyCode>=65&&e.keyCode<=90)))return;
		OptionsSettings.setControl(awaitingControl,e.keyCode);awaitingControl="";render();e.preventDefault();e.stopImmediatePropagation();
	}
	private static function labelFor(action:String):String { var index=CONTROL_NAMES.indexOf(action); return index<0?action:CONTROL_LABELS[index]; }
	override public function remove():Void {
		if(isRemoved())return;if(AppStage.stage!=null)AppStage.stage.removeEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
		awaitingControl="";if(pane!=null)pane.remove();if(view!=null)view.remove();super.remove();
	}
}
