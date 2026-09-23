package pr2.mobile;

/** Touch-readable informational dialog for mobile release flows. */
class MobileMessagePopup extends MobilePanelPopup {
	private var view:LobbyView;
	private var message:String;
	private var cw:Float=796;private var ch:Float=306;
	public function new(message:String,title:String="MESSAGE"){super(title);this.message=message;view=new LobbyView();content.addChild(view);render();}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(view!=null)render();}
	private function render():Void {if(view==null||isRemoved())return;view.clear();view.panel(0,0,cw,ch);var field=view.label(message,18,16,cw-36,Math.max(72,ch-92),20,true);field.height=Math.max(field.height,field.textHeight+12);view.button("OK",cw/2-85,ch-58,170,startFadeOut,true);}
	override public function remove():Void {if(isRemoved())return;if(view!=null){view.remove();view=null;}super.remove();}
}
