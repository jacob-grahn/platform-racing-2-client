package pr2.mobile;

/** Landscape confirmation dialog shared by mobile actions that can change account state. */
class MobileConfirmPopup extends MobilePanelPopup {
	private var view:LobbyView;
	private var message:String;
	private var confirmAction:Void->Void;
	private var cw:Float=796;
	private var ch:Float=306;
	public function new(message:String,confirm:Void->Void,title:String="PLEASE CONFIRM") {
		super(title);this.message=message;confirmAction=confirm;view=new LobbyView();content.addChild(view);render();
	}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(view!=null)render();}
	private function render():Void {if(view==null||isRemoved())return;view.clear();view.panel(0,0,cw,ch);var field=view.label(message,20,20,cw-40,Math.max(80,ch-100),22,true);field.height=Math.max(field.height,field.textHeight+12);view.button("Cancel",cw/2-172,ch-60,160,startFadeOut);view.button("Confirm",cw/2+12,ch-60,160,confirm,true);}
	private function confirm():Void {if(confirmAction!=null)confirmAction();startFadeOut();}
	override public function remove():Void {if(isRemoved())return;confirmAction=null;if(view!=null){view.remove();view=null;}super.remove();}
}
