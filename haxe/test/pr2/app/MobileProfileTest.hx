package pr2.app;

import pr2.lobby.LobbySession;
import pr2.lobby.messages.UnreadNotif;
import pr2.lobby.players.ProfileSource;
import pr2.lobby.players.ProfileData;
import pr2.lobby.players.ProfileActions;
import pr2.lobby.players.SocialAction;
import pr2.mobile.MobileProfilePopup;
import pr2.mobile.MobileComposePopup;
import pr2.mobile.MobileMessagesPage;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;

@:access(pr2.mobile.MobileProfilePopup)
@:access(pr2.mobile.MobileComposePopup)
@:access(pr2.mobile.MobileMessagesPage)
@:access(pr2.lobby.players.ProfileSource)
class MobileProfileTest {
	static var replies:Array<String->Void> = [];
	static var errors:Array<String->Void> = [];
	static var urls:Array<String> = [];
	static var posts:Array<{url:String, fields:Map<String,String>, done:String->Void,error:String->Void}> = [];
	static var cancelled:Int=0;
	static function fetch(url:String, done:String->Void,error:String->Void):pr2.util.AsyncRemovalGuard.AsyncRemovable {
		urls.push(url); replies.push(done); errors.push(error); return {remove:function() cancelled++};
	}
	static function post(url:String,fields:Map<String,String>,done:String->Void,error:String->Void):pr2.util.AsyncRemovalGuard.AsyncRemovable {
		posts.push({url:url,fields:fields,done:done,error:error}); return {remove:function() cancelled++};
	}
	static function data():Dynamic return {userId:42,group:1,status:"Offline",rank:25,hats:7,registerDate:0,loginDate:1720000000,guildId:0,hat:1,head:1,body:1,feet:1,following:0,friend:0,ignored:0,verified:true,hof:true,exp_points:500,exp_to_rank:1000};
	public static function main():Void {
		var oldFetch=ProfileSource.fetch; var oldConnected=ProfileSource.connected; var oldPost=MobileProfilePopup.post; var oldMessagePost=MobileMessagesPage.post;
		ProfileSource.fetch=fetch; ProfileSource.connected=function() return true; MobileProfilePopup.post=post; MobileMessagesPage.post=post;
		LobbySession.clear(); LobbySocket.resetSent();
		var first=new ProfileSource(); var received=0; first.load("First",function(_) received++,function(_){});
		check(LobbySocket.lastSent()=="get_player_info`First","socket-first lookup"); first.remove();
		var second=new ProfileSource(); second.load("Second",function(_) received+=10,function(_){});
		check(urls.length==1 && urls[0].indexOf("name=Second")>=0,"overlapping untagged lookup uses HTTP");
		CommandHandler.commandHandler.dispatch("playerInfo",[haxe.Json.stringify(data())]); check(received==0,"old socket response cannot populate new target");
		replies[0](haxe.Json.stringify(data())); check(received==10,"new HTTP target receives its own response"); second.remove();
		var fallback=new ProfileSource(); fallback.load("Fallback",function(_) received++,function(_){});
		CommandHandler.commandHandler.dispatch("playerInfo",["0"]); check(urls.length==2,"missing socket data falls back");
		replies[1](haxe.Json.stringify(data())); fallback.remove();
		var timeout=new ProfileSource(); timeout.load("Timeout",function(_) received++,function(_){}); timeout.fromHTTP(); timeout.remove();
		CommandHandler.commandHandler.dispatch("playerInfo",[haxe.Json.stringify(data())]);
		ProfileSource.connected=function() return false;
		var popup=new MobileProfilePopup("Target"); var last=replies.length-1; errors[last]("offline"); check(popup.error=="offline","load error offers retry");
		popup.load(); replies[replies.length-1]("bad JSON"); check(popup.error!="","malformed payload is an error");
		popup.load(); replies[replies.length-1](haxe.Json.stringify(data()));
		popup.layoutForSize(667,375); check(popup.profile.groupLabel()=="Member" && popup.character!=null,"profile and avatar populated"); layout(popup);
		popup.choose(true); popup.social(Follow); check(posts.length==0,"guests cannot modify relationships");
		LobbySession.group=1; popup.choose(true);
		for (action in [Follow,Unfollow,AddFriend,RemoveFriend,Ignore,Unignore]) {
			popup.social(action); var n=posts.length-1; check(popup.busy,"pending action disables repeats"); popup.social(action); check(posts.length==n+1,"duplicate mutation suppressed");
			check(posts[n].fields.get("target_id")=="42" && posts[n].url.indexOf("user_list_modify.php")>=0,"shared relationship fields");
			posts[n].done('{"success":true}'); check(!popup.busy,"successful relationship settles");
		}
		check(LobbySocket.lastSent()=="unignore_user`Target","shared socket verb");
		popup.social(Follow); posts[posts.length-1].done('{"error":"Rejected"}'); check(popup.profile.number("following")==0 && popup.notice=="Rejected","failure does not claim persisted relationship change");
		LobbySession.guildOwner=true; LobbySession.guildId=7; popup.guildAction("invite"); var count=posts.length; check(popup.pendingGuild=="invite" && posts.length==count,"guild action waits for confirmation");
		popup.confirmGuild(); check(posts[count].fields.get("target_name")=="Target" && posts[count].fields.get("user_id")=="42","shared guild fields"); posts[count].done('{"success":true}');
		Reflect.setField(popup.profile.raw,"guildId",7); check(popup.profile.canKick() && !popup.profile.canInvite(),"own guild permissions"); popup.guildAction("kick"); popup.confirmGuild(); posts[posts.length-1].done('{"success":true}'); check(popup.profile.number("guildId")==0,"kick updates successful result");
		layout(popup); popup.remove(); popup.remove();
		popup=new MobileProfilePopup("Late"); last=replies.length-1; popup.remove(); replies[last](haxe.Json.stringify(data())); check(popup.profile==null,"late HTTP reply ignored");
		popup=new MobileProfilePopup("Late post",false,false); popup.applyData(data()); popup.social(Follow); var late=posts[posts.length-1]; popup.startFadeOut(); late.done('{"success":true}'); check(popup.profile.number("following")==0,"fading profile ignores mutation callback"); popup.remove();
		var guest=new MobileProfilePopup("Guest",true); check(guest.profile.isGuest() && guest.character==null,"guest profile has no invented stats"); guest.remove();
		var pd=new ProfileData(data()); LobbySession.serverOwner=42; check(pd.groupLabel()=="Server Owner","owner label override"); LobbySession.group=1; LobbySession.isTempMod=true; check(pd.staffTools(),"temporary mod tools for members");
		Reflect.setField(pd.raw,"group",2); check(!pd.staffTools(),"temporary moderator cannot moderate staff");
		UnreadNotif.notifyUser(100); var compose=new MobileComposePopup("Target"); check(UnreadNotif.numUnread()==1,"profile composer does not mark inbox read");
		check(compose.editor.composing && compose.editor.draftTo=="Target","composer prefill"); compose.editor.bodyInput.text="Draft"; compose.editor.submit(); count=posts.length-1;
		posts[count].error("offline"); check(compose.editor.draftBody=="Draft" && !compose.fadeOutStarted,"failed send preserves composer"); compose.editor.submit(); posts[posts.length-1].done('{"success":true}'); check(compose.fadeOutStarted,"successful send closes modal"); compose.remove();
		compose=new MobileComposePopup("guild","Announcement",true); check(!compose.editor.toInput.editable,"guild recipient locked"); compose.editor.submit(); check(posts[posts.length-1].url.indexOf("guild_message.php")>=0,"guild compose endpoint"); compose.remove();
		ProfileSource.fetch=oldFetch; ProfileSource.connected=oldConnected; MobileProfilePopup.post=oldPost; MobileMessagesPage.post=oldMessagePost;
		LobbySession.clear(); UnreadNotif.reset(); ProfileActions.lookupUserHandler=null;
		trace("MobileProfileTest passed"); Sys.exit(0);
	}
	static function layout(popup:MobileProfilePopup):Void {
		for (c in popup.view.controls) check(c.controlHeight>=44 && c.x+c.controlWidth<=619,"compact tabs fit");
		for (c in popup.pane.content.controls) check(c.controlHeight>=44 && c.x+c.controlWidth<=popup.pane.scrollRect.width,"compact actions fit");
	}
	static function check(value:Bool,message:String):Void { if (!value) throw message; }
}
