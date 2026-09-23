package pr2.mobile;

import pr2.lobby.dialogs.CreditsContent;
import pr2.lobby.dialogs.CreditsView;

/** Scrollable, touch-sized credits with section and page controls. */
class MobileCreditsPopup extends MobilePanelPopup {
	private var controls:LobbyView;
	private var pane:MobileScrollPane;
	private var creditsView:CreditsView;
	private var credits:CreditsContent;
	private var cw:Float=796;
	private var ch:Float=306;
	public function new() {
		super("COMMUNITY CREDITS");
		controls=new LobbyView();pane=new MobileScrollPane();creditsView=new CreditsView();creditsView.closeButton.visible=false;
		credits=new CreditsContent(creditsView,false);content.addChild(controls);content.addChild(pane);pane.content.addChild(creditsView);
		layoutForSize(w,h);
	}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(controls!=null)render();}
	private function choose(section:String,page:Int):Void {credits.show(section,page);pane.reset();render();}
	private function render():Void {
		if(controls==null||isRemoved())return;
		controls.clear();
		var half=(cw-10)/2;
		controls.button("ART & DESIGN",0,0,half,function()choose("art",1),credits.section=="art");
		controls.button("MUSIC",half+10,0,half,function()choose("music",1),credits.section=="music");
		if(credits.currentPage()>1)controls.button("Previous page",0,52,half,function()choose(credits.section,credits.currentPage()-1));
		if(credits.currentPage()<credits.pageCount())controls.button("Next page",half+10,52,half,function()choose(credits.section,credits.currentPage()+1),true);
		pane.x=0;pane.y=104;
		var bounds=creditsView.getBounds(creditsView);
		var scale=Math.min(1.75,(cw-20)/Math.max(1,bounds.width));if(scale<=0||Math.isNaN(scale))scale=1;
		creditsView.scaleX=creditsView.scaleY=scale;
		creditsView.x=10-bounds.x*scale;creditsView.y=8-bounds.y*scale;
		pane.setSize(cw,Math.max(44,ch-104),bounds.height*scale+16);
	}
	override public function remove():Void {
		if(isRemoved())return;
		if(credits!=null){credits.remove();credits=null;}
		if(pane!=null){pane.remove();pane=null;}if(controls!=null){controls.remove();controls=null;}
		if(creditsView!=null){creditsView.dispose();creditsView=null;}super.remove();
	}
}
