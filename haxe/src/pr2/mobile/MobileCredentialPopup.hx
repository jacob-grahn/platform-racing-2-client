package pr2.mobile;

import pr2.lobby.account.AccountCredentialActions;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;
import pr2.mobile.MobileAuthControls.AuthInput;

/** Mobile password/email editor using the same validation and encrypted fields as classic. */
class MobileCredentialPopup extends MobilePanelPopup {
	public static var post:String->Map<String,String>->(String->Void)->(String->Void)->AsyncRemovable=FormPostClient.post;
	private var kind:String;
	private var view:LobbyView;
	private var pane:MobileScrollPane;
	private var guard=new AsyncRemovalGuard();
	private var currentPass="";
	private var newPass="";
	private var confirmPass="";
	private var email="";
	private var confirmEmail="";
	private var emailPass="";
	private var message="";
	private var busy:Bool=false;
	private var complete:Bool=false;
	private var panelWidth:Float=796;
	private var panelHeight:Float=306;
	public function new(kind:String) {
		this.kind=kind;
		super(kind=="password"?"CHANGE PASSWORD":"CHANGE EMAIL");
		view=new LobbyView();pane=new MobileScrollPane();content.addChild(pane);pane.content.addChild(view);layoutForSize(w,h);
	}
	override private function resizeContent(width:Float,height:Float):Void {panelWidth=width;panelHeight=width<=570?390:height;if(view!=null){render();pane.setSize(width,height,panelHeight);}}
	private function render():Void {
		if(view==null||isRemoved())return;
		view.clear();view.panel(0,0,panelWidth,panelHeight);
		var two=panelWidth>570;var colW=two?(panelWidth-44)/2:panelWidth-24;var x2=two?colW+28:12;var y1:Float=52;var y2:Float=two?142:130;var y3:Float=208;
		view.label(kind=="password"?"Enter your current password and choose a new one.":"Enter your new email twice and confirm with your password.",12,8,panelWidth-24,40,16);
		if(kind=="password"){
			currentPass=field("Current password",currentPass,12,y1,colW,true);newPass=field("New password",newPass,x2,two?y1:y2,colW,true);confirmPass=field("Confirm new password",confirmPass,12,two?y2:y3,colW,true);
		}else{
			email=field("New email",email,12,y1,colW,false);confirmEmail=field("Confirm email",confirmEmail,x2,two?y1:y2,colW,false);emailPass=field("Password",emailPass,12,two?y2:y3,colW,true);
		}
		var status=complete?"Your account change was accepted.":message;
		if(status!="")view.label(status,12,panelHeight-116,panelWidth-240,52,16,true,status=="Your account change was accepted."?0x25723D:0x9A372B);
		view.button(complete?"Done":"Save changes",panelWidth-202,panelHeight-60,184,function(){if(complete)startFadeOut();else submit();},true).enabled=!busy;
	}
	private function field(label:String,value:String,x:Float,y:Float,width:Float,password:Bool):String {
		view.label(label,x,y,width,24,15,true);
		var input=new AuthInput(value);input.displayAsPassword=password;view.own(input);input.x=x;input.y=y+28;input.setSize(width,46);
		input.onChange=function(next) { switch label {case "Current password":currentPass=next;case "New password":newPass=next;case "Confirm new password":confirmPass=next;case "New email":email=next;case "Confirm email":confirmEmail=next;case "Password":emailPass=next;default:} };
		return value;
	}
	private function submit():Void {
		if(busy||complete)return;
		var error=kind=="password"?AccountCredentialActions.validatePassword(currentPass,newPass,confirmPass):AccountCredentialActions.validateEmail(email,confirmEmail,emailPass);
		if(error!=""){message=error;render();return;}
		var url=kind=="password"?ServerConfig.changePasswordUrl():ServerConfig.accountChangeEmailUrl();
		var fields:Map<String,String>=kind=="password"?["i"=>AccountCredentialActions.passwordPayload(currentPass,newPass)]:["data"=>AccountCredentialActions.emailPayload(email,emailPass)];
		busy=true;message="Saving…";render();
		guard.watch(post(url,fields,guard.wrap(function(body) {
			var result=SuperLoader.decodeJson(url,body,false);busy=false;
			if(result.success){complete=true;message="";currentPass=newPass=confirmPass=email=confirmEmail=emailPass="";}
			else message=result.message==""?"Could not save this change. Try again.":result.message;
			render();
		}),guard.wrap(function(error) {busy=false;message=error;render();})));
	}
	override public function startFadeOut():Void {guard.remove();super.startFadeOut();}
	override public function remove():Void {
		if(isRemoved())return;guard.remove();currentPass=newPass=confirmPass=email=confirmEmail=emailPass="";
		if(pane!=null){pane.remove();pane=null;}if(view!=null){view.remove();view=null;}super.remove();
	}
}
