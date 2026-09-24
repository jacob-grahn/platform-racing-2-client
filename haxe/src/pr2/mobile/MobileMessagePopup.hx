package pr2.mobile;

import openfl.text.TextField;
import openfl.text.TextFormat;

/** Touch-readable informational dialog for mobile release flows. */
class MobileMessagePopup extends MobilePanelPopup {
	private var view:LobbyView;
	private var scroll:MobileScrollPane;
	private var messageField:TextField;
	private var cw:Float=796;private var ch:Float=306;
	public function new(message:String,title:String="MESSAGE"){
		super(title);
		view=new LobbyView();content.addChild(view);
		scroll=new MobileScrollPane();content.addChild(scroll);
		messageField=new TextField();messageField.defaultTextFormat=new TextFormat("Nunito Bold",18,0x18334B);
		messageField.embedFonts=true;messageField.multiline=true;messageField.wordWrap=true;messageField.selectable=false;
		messageField.htmlText=message==null?"":message;scroll.content.addChild(messageField);
		render();
	}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(view!=null)render();}
	private function render():Void {
		if(view==null||isRemoved())return;
		view.clear();view.panel(0,0,cw,ch);
		messageField.width=cw-44;messageField.height=Math.max(72,messageField.textHeight+12);
		scroll.x=18;scroll.y=16;scroll.setSize(cw-36,ch-94,messageField.height);
		view.button("OK",cw/2-85,ch-58,170,startFadeOut,true);
	}
	public function messageTextForTests():String return messageField.text;
	override public function remove():Void {if(isRemoved())return;if(scroll!=null){scroll.remove();scroll=null;}if(view!=null){view.remove();view=null;}super.remove();}
}
