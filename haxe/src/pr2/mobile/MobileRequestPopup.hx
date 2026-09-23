package pr2.mobile;

import pr2.net.FormPostClient;
import pr2.net.SuperLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

/** Small progress/result surface for legacy form requests launched from mobile UI. */
class MobileRequestPopup extends MobilePanelPopup {
	public static var post:String->Map<String,String>->(String->Void)->(String->Void)->AsyncRemovable=FormPostClient.post;
	private var view:LobbyView;
	private var url:String;
	private var fields:Map<String,String>;
	private var message:String;
	private var onResult:Null<Dynamic->Void>;
	private var onError:Null<String->Void>;
	private var guard=new AsyncRemovalGuard();
	private var busy=false;
	private var failed=false;
	private var cw:Float=796;
	private var ch:Float=306;
	public function new(url:String,fields:Map<String,String>,message:String,onResult:Dynamic->Void,onError:String->Void) {
		super("PLEASE WAIT");this.url=url;this.fields=fields;this.message=message;this.onResult=onResult;this.onError=onError;view=new LobbyView();content.addChild(view);render();submit();
	}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(view!=null)render();}
	private function render():Void {if(view==null||isRemoved())return;view.clear();view.panel(0,0,cw,ch);view.label(message,16,24,cw-32,Math.max(80,ch-110),24,true);if(failed)view.button("Try again",cw/2-180,ch-60,164,submit,true);view.button("Close",cw/2+16,ch-60,164,startFadeOut);}
	private function submit():Void {if(busy)return;busy=true;failed=false;render();guard.watch(post(url,fields,guard.wrap(function(body){busy=false;var result=SuperLoader.decodeJson(url,body,false);if(result.success){var callback=onResult;if(callback!=null)callback(result.data);startFadeOut();}else fail(result.message);}),guard.wrap(function(problem){busy=false;fail(problem);})));}
	private function fail(problem:String):Void {failed=true;message=problem;if(onError!=null)onError(problem);render();}
	override public function remove():Void {if(isRemoved())return;guard.remove();onResult=null;onError=null;fields=null;view.remove();view=null;super.remove();}
}
