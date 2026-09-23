package pr2.mobile;

import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.gameplay.PrizeContent;
import pr2.lobby.account.PartPopup;
import pr2.lobby.account.PartPreview;
import pr2.runtime.EpicFlash;

/** Touch-sized race prize announcement over the still-running course. */
class MobilePrizePopup extends MobilePanelPopup {
	private var view:LobbyView;
	private var prize:PrizeContent;
	private var preview:Null<PartPreview>;
	private var epicFlash=new EpicFlash();
	private var type:String;private var id:Int;private var flavorDescription:String;
	private var cw:Float=796;private var ch:Float=306;
	public function new(type:String,id:Int,name:String,description:String="",universal:Bool=false,finished:Bool=false) {
		super("RACE PRIZE",0.65);this.type=type;this.id=id;flavorDescription=description;prize=new PrizeContent(type,id,name,description,universal,finished);view=new LobbyView();content.addChild(view);
		var part=partType(type);if(part!=""){preview=PartPopup.setupPartPreview(content,part,id,true,1.1);if(preview!=null){preview.x=cw*.67;preview.y=ch*.50;preview.scaleX=preview.scaleY=2.2;}if(type.charAt(0)=="e"&&preview!=null){preview.showEpic();epicFlash.addItem(preview.epicTarget);epicFlash.setDelay(300);epicFlash.start();}}
		render();
	}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(view!=null)render();}
	private function render():Void {
		if(view==null||isRemoved())return;view.clear();var panelW=Math.min(620,cw-20);var panelH=Math.min(300,ch-8);var left=(cw-panelW)/2;var top=(ch-panelH)/2;view.panel(left,top,panelW,panelH);
		view.singleLine(prize.titleText,left+18,top+14,panelW-36,40,27,true);
		var textWidth=preview==null?panelW-44:panelW*.55;if(type!="cancel")view.label(prize.bodyText,left+22,top+66,textWidth,56,20,true);
		var detail=prize.detailText!=""?prize.detailText:(prize.flavorVisible?prize.flavorText:flavorDescription);
		if(detail!=""){var field=new TextField();field.defaultTextFormat=new TextFormat("Nunito Bold",17,0x18334B);field.embedFonts=true;field.multiline=true;field.wordWrap=true;field.selectable=false;field.x=left+22;field.y=top+(type=="cancel"?82:126);field.width=textWidth;field.height=panelH-110;if(prize.flavorHtml)field.htmlText=prize.flavorText;else field.text=detail;view.addChild(field);}
		if(preview!=null){preview.x=left+panelW*.72;preview.y=top+panelH*.68;}
	}
	private static function partType(value:String):String return switch(value){case "hat","eHat":"HAT";case "head","eHead":"HEAD";case "body","eBody":"BODY";case "feet","eFeet":"FEET";default:"";};
	public function close():Void startFadeOut();
	override public function remove():Void {if(isRemoved())return;epicFlash.remove();if(preview!=null){preview.remove();preview=null;}if(view!=null){view.remove();view=null;}super.remove();}
}
