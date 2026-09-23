package pr2.lobby.dialogs;

import openfl.events.TextEvent;
import openfl.text.TextField;
import pr2.Constants;
import pr2.util.DisplayUtil;

/** Shared version text and page/navigation behavior for both credits presentations. */
class CreditsContent {
	public var artPage(default,null):Int=1;
	public var musicPage(default,null):Int=1;
	public var section(default,null):String="art";
	private var view:CreditsView;
	private var artNav:Null<TextField>;
	private var musicNav:Null<TextField>;
	private var listenToLinks:Bool;
	public function new(view:CreditsView,listenToLinks:Bool=true) {
		this.view=view;this.listenToLinks=listenToLinks;
		setText("versionBox","PR2 v"+Constants.VERSION+(Constants.BETA?" Beta":""));
		setText("buildBox","Build: "+Constants.BUILD);
		artNav=findText("art_nav_bts");musicNav=findText("music_nav_bt");
		if(listenToLinks){if(artNav!=null)artNav.addEventListener(TextEvent.LINK,clickArtNav);if(musicNav!=null)musicNav.addEventListener(TextEvent.LINK,clickMusicNav);}
		show("art",1);
	}
	public function show(nextSection:String,page:Int):Void {
		section=nextSection=="music"?"music":"art";
		if(section=="art")artPage=page<1?1:page>3?3:page;else musicPage=page<1?1:page>2?2:page;
		for(i in 1...4){setPageVisible("artPg"+i,i==artPage&&(listenToLinks||section=="art"));}
		for(i in 1...3){setPageVisible("musicPg"+i,i==musicPage&&(listenToLinks||section=="music"));}
		updateNav();
	}
	public function pageCount():Int return section=="art"?3:2;
	public function currentPage():Int return section=="art"?artPage:musicPage;
	public function remove():Void {
		if(artNav!=null)artNav.removeEventListener(TextEvent.LINK,clickArtNav);
		if(musicNav!=null)musicNav.removeEventListener(TextEvent.LINK,clickMusicNav);
		artNav=musicNav=null;view=null;
	}
	private function clickArtNav(event:TextEvent):Void show("art",artPage+(event.text=="artBack"?-1:1));
	private function clickMusicNav(_:TextEvent):Void show("music",musicPage==1?2:1);
	private function updateNav():Void {
		if(artNav!=null){var links=[];if(artPage>1)links.push('<a href="event:artBack">(&lt;- back)</a>');if(artPage<3)links.push('<a href="event:artNext">(next -&gt;)</a>');artNav.htmlText=links.join(" ");artNav.visible=listenToLinks;}
		if(musicNav!=null){musicNav.htmlText='<a href="event:musicToggle">'+(musicPage==2?"(&lt;- back)":"(more -&gt;)")+"</a>";musicNav.visible=listenToLinks;}
	}
	private function findText(name:String):Null<TextField> return Std.downcast(DisplayUtil.directChildByName(view,name),TextField);
	private function setText(name:String,value:String):Void {var field=findText(name);if(field!=null)field.text=value;}
	private function setPageVisible(name:String,visible:Bool):Void {var page=DisplayUtil.directChildByName(view,name);if(page!=null)page.visible=visible;}
}
